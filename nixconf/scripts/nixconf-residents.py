#!/usr/bin/env python3
"""Reporte de paquetes residentes para nixconf-cleanup.

Cruza el closure de la generacion activa de home-manager contra el system
profile de NixOS, agrupa lo que sobra por paquete y mapea cada uno a la linea
de la config que lo declara. Solo LECTURA: no borra nada, no toca la config.

Se invoca desde nixconf/home-manager/features/cleanup.nix:
   python3 nixconf/scripts/nixconf-residents.py <sizes.json> <index.tsv> <max> <never> [nixconf_dir] [hm_gen]

Entradas:
  sizes.json  salida de `nix path-info --json <paths>`  (mapa path -> {narSize})
  index.tsv   indice de la config, TSV de 5 columnas:
                paquete \\t archivo \\t linea \\t estado(LIVE|COMMENT) \\t tipo(REF|LISTA)
              REF   = una referencia ${pkgs.X} (referencia invisible)
              LISTA = una linea suelta de una lista de paquetes
  max         cuantos paquetes mostrar como maximo
  never       paquetes que JAMAS deberian quedar residentes. Acepta saltos de
              linea y comentarios con '#': comentar una linea SI la saca de la
              lista. (Un split() pelado no lo hacia: '# pgadmin4' producia los
              tokens '#' y 'pgadmin4', y 'pgadmin4' seguia vigilado.)
  nixconf_dir opcional. Raiz del flake, para detectar config desfasada.
  hm_gen      opcional. Path de la generacion activa de home-manager, para
              diagnosticar que bloquea cada paquete.

AGRUPACION: el store tiene varios paths por paquete (electron-unwrapped-43.1.0,
electron-unwrapped-42.5.1, ...). Se agrupan por nombre base y se suma el tamano,
porque lo que interesa es "cuanto ocupa esto", no "cuantos paths tiene".

Ordena por tamano descendente. El usuario decide que sacar: el script solo
informa. Los estados ayudan a distinguir lo que declaraste de lo que se
arrastro solo.

Clasificacion de cada paquete:
  LISTA-NEGRA          esta en `never`: alguien lo reintrodujo
  COMENTADO-PERO-VIVO  comentado en la config pero con una referencia ${pkgs.X}
                       viva en otro sitio. Esta es la trampa: comentar en
                       home.packages NO basta si el paquete sigue referenciado
                       en sessionVariables / shellAliases / stringsToFile.
  ACTIVO               referenciado con una linea sin comentar
  DEPENDENCIA         no aparece en la config; lo arrastra otro paquete
"""

import sys
import os
import json
import glob
import time
import re
import subprocess
from collections import defaultdict

GIB = 1024.0 ** 3


def human(n):
    """Bytes -> 1.2G / 782M / 4.0K."""
    for unit in ("B", "K", "M", "G", "T"):
        if n < 1024 or unit == "T":
            if unit == "B":
                return "%dB" % n
            return "%.1f%s" % (n, unit)
        n /= 1024.0


def pkgname(path):
    """/nix/store/<hash>-electron-unwrapped-43.1.0 -> electron-unwrapped"""
    b = path.rsplit("/", 1)[-1]
    if "-" in b:
        b = b.split("-", 1)[1]
    # quita la version: primer guion seguido de digito. count=1 para no comerse
    # el "-2024" de un nombre que lo tenga como parte real.
    return re.sub(r"-\d[\w.+-]*$", "", b)


def load_index(path):
    """Lee el TSV de la config -> dict nombre -> [(archivo, linea, estado, tipo)]"""
    idx = {}
    try:
        fh = open(path, encoding="utf-8", errors="replace")
    except OSError as e:
        sys.stderr.write("no se pudo abrir el indice: %s\n" % e)
        return idx
    with fh:
        for raw in fh:
            parts = raw.rstrip("\n").split("\t")
            if len(parts) < 5:
                continue
            idx.setdefault(parts[0], []).append(
                (parts[1], parts[2], parts[3], parts[4])
            )
    return idx


def parse_never(blob):
    """NEVER_RESIDENT -> set de nombres, respetando comentarios.

    OJO (esto es lo que faltaba): antes era `blob.split()`, un split por
    espacios pelado. Eso hacia que comentar una linea NO sacara el paquete
    de la lista: "# pgadmin4" producia los tokens '#' y 'pgadmin4', y
    'pgadmin4' seguia en el set. Ademas colaba un token basura '#'.
    Con esta version, comentar la linea la saca de verdad.
    """
    out = set()
    for line in blob.splitlines():
        line = line.split("#", 1)[0]  # todo desde el # es comentario
        out.update(line.split())
    out.discard("#")
    return out


def classify(refs):
    """-> (estado, donde)

    Estados:
      DEPENDENCIA          el store lo trae, pero no aparece en tu config
      ACTIVO               hay una linea sin comentar que lo declara
      COMENTADO-PERO-VIVO  esta comentado PERO sigue en el closure. Puede ser
                           por una referencia ${pkgs.X} viva en otro fichero
                           (sessionVariables, stringsToFile, ExecStart), o
                           porque la generacion activa todavia no se
                           reconstruyo despues del comentario.
    """
    if not refs:
        return "DEPENDENCIA", ""

    live = [r for r in refs if r[2] == "LIVE" and r[3] != "LISTA"]
    commented = [r for r in refs if r[2] == "COMMENT"]

    # una referencia ${pkgs.X} VIVA tiene prioridad sobre el comentario: es la
    # trampa real, y el archivo:linea que la contiene es lo accionable.
    if live:
        where = "%s:%s" % (live[0][0], live[0][1])
        if commented:
            return "COMENTADO-PERO-VIVO", where
        return "ACTIVO", where

    if commented:
        return "COMENTADO-PERO-VIVO", "%s:%s" % (commented[0][0], commented[0][1])

    # solo entradas de lista suelta (LISTA), sin estado LIVE ni COMMENT util
    listed = [r for r in refs if r[3] == "LISTA"]
    if listed:
        return "ACTIVO", "%s:%s" % (listed[0][0], listed[0][1])
    return "DEPENDENCIA", ""


def newest_config_mtime(nixconf_dir):
    """mtime del .nix mas reciente de la config (None si no hay)."""
    newest = None
    for f in glob.glob(os.path.join(nixconf_dir, "home-manager/features/*.nix")) + [
        os.path.join(nixconf_dir, "home-manager/home.nix")
    ]:
        try:
            m = os.path.getmtime(f)
        except OSError:
            continue
        if newest is None or m > newest:
            newest = m
    return newest


def generation_mtime(hm_link):
    """mtime REAL del ultimo switch, o None.

    OJO: hay que usar lstat sobre el SYMLINK del perfil, no getmtime sobre el
    path del store. Los store paths de Nix tienen mtime = epoch (1970), asi
    que getmtime sobre el path resuelto devuelve "hace 56 anos" y el aviso de
    config desfasada sale con una edad absurda. El symlink del perfil si tiene
    el mtime de cuando se creo la generacion.
    """
    if not hm_link:
        return None
    try:
        return os.lstat(hm_link).st_mtime
    except OSError:
        return None


def config_is_stale(nixconf_dir, hm_link):
    """-> True si editaste la config DESPUES del ultimo switch.

    Esto importa porque todo el reporte se arma cruzando el closure de la
    generacion ACTIVA contra el .nix que esta en disco. Si comentaste un
    paquete y no rehiciste el switch, la generacion activa todavia lo trae y
    el reporte no puede distinguir "comentado y pendiente" de "comentado pero
    alguien lo reintrodujo". Sin este aviso, el reporte miente.
    """
    if not nixconf_dir:
        return None
    cfg = newest_config_mtime(nixconf_dir)
    gen = generation_mtime(hm_link)
    if cfg is None or gen is None:
        return None
    return cfg > gen


def _closure(root):
    """Closure de un path del store como set (best-effort, sin sudo)."""
    try:
        out = subprocess.run(
            ["nix-store", "-qR", root],
            capture_output=True, text=True, timeout=120,
        )
    except (OSError, subprocess.TimeoutExpired):
        return set()
    return set(out.stdout.split())


def _mapped_procs(paths):
    """store path -> "proceso vivo" que lo tiene mapeado.

    Solo mira los paths concretos: como signal global es inutil (casi todos
    los procesos tienen algo de /nix/store mapeado), pero para un path dado es
    una respuesta precisa y rara.
    """
    if not paths:
        return {}
    wanted = set(paths)
    hits = {}
    for maps in glob.glob("/proc/[0-9]*/maps"):
        pid = maps.split("/")[2]
        try:
            with open(maps, encoding="utf-8", errors="replace") as fh:
                for line in fh:
                    for p in wanted:
                        if p in line:
                            hits.setdefault(p, pid)
                            break
        except OSError:
            continue
        if len(hits) == len(wanted):
            break
    return hits


def _symlink_roots(paths):
    """store path -> symlink de $HOME o gcroots que lo mantiene vivo."""
    if not paths:
        return {}
    wanted = set(paths)
    hits = {}
    cands = glob.glob(os.path.expanduser("~/.*")) + \
        glob.glob(os.path.expanduser("~/.[!.]*"))
    for link in cands:
        try:
            if not os.path.islink(link):
                continue
            tgt = os.path.realpath(link)
        except OSError:
            continue
        for p in wanted:
            if tgt == p or tgt.startswith(p + "-"):
                hits.setdefault(p, link)
    for link in glob.glob("/nix/var/nix/gcroots/auto/*"):
        try:
            tgt = os.path.realpath(link)
        except OSError:
            continue
        for p in wanted:
            if tgt == p or tgt.startswith(p + "-"):
                hits.setdefault(p, link)
    return hits


def build_blockers(paths, hm_gen):
    """-> dict store_path -> explicacion de por que NO se puede borrar.

    hm_gen es el SYMLINK del perfil de home-manager: para el closure hay que
    resolverlo, pero para el mtime hay que usar lstat sobre el symlink.

    Orden de resolucion (de mas especifico a mas generico):
      1. proceso vivo con el path mapeado  -> cerrar la app
      2. closure de la generacion activa    -> rehacer el switch
      3. symlink en $HOME o gcroots         -> borrar el symlink
      4. tiene referenciadores             -> lo arrastra otro paquete
      5. sin referenciadores ni root        -> huerfano real, el GC lo saca
    """
    paths = list(paths)
    blockers = {}

    procs = _mapped_procs(paths)
    for p, pid in procs.items():
        try:
            name = open("/proc/%s/comm" % pid).read().strip()
        except OSError:
            name = "?"
        blockers[p] = "proceso vivo (pid %s %s) lo tiene mapeado" % (pid, name)

    rest = [p for p in paths if p not in blockers]
    if not rest:
        return blockers

    hm_closure = _closure(os.path.realpath(hm_gen)) if hm_gen else set()
    for p in rest:
        if p in hm_closure:
            blockers[p] = "esta en la generacion activa -> corré nixconf-rebuild"

    rest = [p for p in rest if p not in blockers]
    for p, link in _symlink_roots(rest).items():
        blockers[p] = "symlink vivo: %s" % link

    rest = [p for p in rest if p not in blockers]
    for p in rest:
        try:
            refs = subprocess.run(
                ["nix-store", "-q", "--referrers", p],
                capture_output=True, text=True, timeout=30,
            ).stdout.split()
        except (OSError, subprocess.TimeoutExpired):
            refs = [p]
        refs = [r for r in refs if r != p]
        if refs:
            blockers[p] = "lo arrastra %s (+%d mas)" % (
                refs[0].rsplit("/", 1)[-1][:28], len(refs) - 1)
        else:
            blockers[p] = "SIN referenciadores: huerfano, el GC lo libera"
    return blockers


def main():
    if len(sys.argv) < 5:
        sys.stderr.write(__doc__)
        return 2

    sizes_f, idx_f = sys.argv[1], sys.argv[2]
    max_rows = int(sys.argv[3])
    # NEVER_RESIDENT llega como UN argumento con saltos de linea y comentarios.
    never = parse_never(sys.argv[4])
    # args opcionales: NIXCONF_DIR y la generacion activa (para el diagnostico
    # de config desfasada y para el diagnostico de bloqueantes).
    nixconf_dir = sys.argv[5] if len(sys.argv) > 5 else ""
    hm_gen = sys.argv[6] if len(sys.argv) > 6 else ""

    with open(sizes_f, encoding="utf-8") as fh:
        sizes = {k: v.get("narSize", 0) for k, v in json.load(fh).items()}
    idx = load_index(idx_f)

    # agrupar por paquete: suma los bytes de todos sus paths
    agg = defaultdict(lambda: {"size": 0, "paths": 0, "paths_list": []})
    for path, size in sizes.items():
        entry = agg[pkgname(path)]
        entry["size"] += size
        entry["paths"] += 1
        entry["paths_list"].append(path)

    rows = []
    for name, entry in agg.items():
        state, where = classify(idx.get(name, []))
        if name in never:
            state = "LISTA-NEGRA"
        rows.append((entry["size"], name, state, where, entry["paths"],
                     entry["paths_list"]))
    rows.sort(reverse=True)

    total = sum(r[0] for r in rows)
    neg = [r for r in rows if r[2] == "LISTA-NEGRA"]
    neg_size = sum(r[0] for r in neg)
    shadow = [r for r in rows if r[2] == "COMENTADO-PERO-VIVO"]
    shadow_size = sum(r[0] for r in shadow)
    active = [r for r in rows if r[2] == "ACTIVO"]

    print(
        "__OK  %d paquetes, %d paths, %s solo en tu home (no es NixOS)"
        % (len(rows), len(sizes), human(total))
    )

    # Diagnostico 0: la config en disco es mas nueva que la generacion activa?
    # Si es asi, todo lo de abajo describe una generacion VIEJA y las alertas
    # pueden estar equivocadas. Esto solo lo detecta el mtime.
    if config_is_stale(nixconf_dir, hm_gen):
        gen_m = generation_mtime(hm_gen) or 0
        age = max(0, int(time.time() - gen_m))
        if age < 90:
            when = "hace nada"
        elif age < 5400:
            when = "hace %d min" % (age // 60)
        elif age < 172800:
            when = "hace %dh" % (age // 3600)
        else:
            when = "hace %dd" % (age // 86400)
        print(
            "__ALERT  CONFIG DESFASADA: editaste el .nix despues del ultimo switch (%s)."
            % when
        )
        print("        Este reporte describe la generacion VIEJA: rebuild antes de creerlo.")
    elif nixconf_dir and hm_gen:
        print("__OK  config al dia (el .nix no es mas nuevo que la generacion)")

    print("__WARN  --- ordenado por tamano (lo que declares tu primero) ---")

    for size, name, state, where, paths, _pl in rows[:max_rows]:
        print(
            "    %s  %s  %s  %s"
            % (human(size).rjust(8), name[:40].ljust(40),
               state.ljust(21), where)
        )

    if len(rows) > max_rows:
        rest_size = sum(r[0] for r in rows[max_rows:])
        print(
            "__WARN  ... y %d mas paquetes (%s): RESIDENTS_TOP=%d para verlos"
            % (len(rows) - max_rows, human(rest_size), max_rows)
        )

    # Diagnostico de bloqueantes: POR QUE no se pueden borrar. Antes el script
    # lo suponia ("lo tiene home-manager-path"); ahora lo verifica por paquete.
    # Solo los N mas grandes: la comprobacion cuesta un nix-store -qR + N
    # llamadas a -q --referrers.
    diag_n = min(max_rows, 8)
    if diag_n > 0:
        print("__WARN  --- por que NO se pueden borrar (top %d) ---" % diag_n)
        try:
            blk = build_blockers(
                [p for r in rows[:diag_n] for p in r[5]], hm_gen)
        except Exception as e:  # nunca romper el cleanup por un diagnostico
            blk = {}
            print("    (diagnostico de bloqueantes fallo: %s)" % e)
        for size, name, _s, where, _p, plist in rows[:diag_n]:
            reasons = [blk[p] for p in plist if p in blk]
            if not reasons:
                reasons = ["(sin datos)"]
            uniq = sorted(set(reasons))
            print(
                "    %s  %s  %s"
                % (human(size).rjust(8), name[:38].ljust(38), " | ".join(uniq))
            )

    if neg:
        print(
            "__ALERT  LISTA NEGRA presente (%s): alguien los reintrodujo"
            % human(neg_size)
        )
        for size, name, _s, where, _p, _pl in neg:
            print("__ALERT  %s  %s  %s" % (human(size).rjust(8), name[:38].ljust(38), where))
    else:
        print("__OK  lista negra: limpia (%d paquetes vigilados)" % len(never))

    if shadow:
        print(
            "__WARN  comentados pero VIVOS (%s): ref ${pkgs.X} en otro sitio"
            % human(shadow_size)
        )
        for size, name, _s, where, _p, _pl in shadow:
            print("__WARN  %s  %s  %s" % (human(size).rjust(8), name[:38].ljust(38), where))
    else:
        print("__OK  sin comentarios-pero-vivos")

    active_size = sum(r[0] for r in active)
    dep_size = sum(r[0] for r in rows if r[2] == "DEPENDENCIA")
    print(
        "__WARN  declared por ti: %d pkg (%s) · arrastrados: %d pkg (%s)"
        % (len(active), human(active_size),
           len(rows) - len(active), human(dep_size))
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
