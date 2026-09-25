#!/usr/bin/env python3
"""Reporte de paquetes residentes para nixconf-cleanup.

Cruza el closure de la generacion activa de home-manager contra el system
profile de NixOS, agrupa lo que sobra por paquete y mapea cada uno a la linea
de la config que lo declara. Solo LECTURA: no borra nada, no toca la config.

Se invoca desde nixconf/home-manager/features/cleanup.nix:
    python3 nixconf/scripts/nixconf-residents.py <sizes.json> <index.tsv> <max> <never>

Entradas:
  sizes.json  salida de `nix path-info --json <paths>`  (mapa path -> {narSize})
  index.tsv   indice de la config, TSV de 5 columnas:
                paquete \\t archivo \\t linea \\t estado(LIVE|COMMENT) \\t tipo(REF|LISTA)
              REF   = una referencia ${pkgs.X} (referencia invisible)
              LISTA = una linea suelta de una lista de paquetes
  max         cuantos paquetes mostrar como maximo
  never       paquetes que JAMAS deberian quedar residentes (space separated)

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
import json
import re
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


def classify(refs, never):
    """-> (estado, donde)"""
    live = [r for r in refs if r[2] == "LIVE"]
    commented = [r for r in refs if r[2] == "COMMENT"]
    listed = [r for r in refs if r[3] == "LISTA"]

    if not refs:
        return "DEPENDENCIA", ""

    # comentario + referencia viva = la trampa de los ${pkgs.X}
    if commented and (listed or live):
        state = "COMENTADO-PERO-VIVO"
    elif commented:
        state = "COMENTADO-PERO-VIVO"
    elif live:
        state = "ACTIVO"
    else:
        state = "ACTIVO"

    pick = live or commented or listed
    where = "%s:%s" % (pick[0][0], pick[0][1]) if pick else ""
    return state, where


def main():
    if len(sys.argv) < 5:
        sys.stderr.write(__doc__)
        return 2

    sizes_f, idx_f = sys.argv[1], sys.argv[2]
    max_rows = int(sys.argv[3])
    never = set(x for x in sys.argv[4].split() if x)

    with open(sizes_f, encoding="utf-8") as fh:
        sizes = {k: v.get("narSize", 0) for k, v in json.load(fh).items()}
    idx = load_index(idx_f)

    # agrupar por paquete: suma los bytes de todos sus paths
    agg = defaultdict(lambda: {"size": 0, "paths": 0})
    for path, size in sizes.items():
        entry = agg[pkgname(path)]
        entry["size"] += size
        entry["paths"] += 1

    rows = []
    for name, entry in agg.items():
        state, where = classify(idx.get(name, []), never)
        if name in never:
            state = "LISTA-NEGRA"
        rows.append((entry["size"], name, state, where, entry["paths"]))
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
    print("__WARN  --- ordenado por tamano (lo que declares tu primero) ---")

    for size, name, state, where, paths in rows[:max_rows]:
        pfx = "%d p" % paths if paths > 1 else ""
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

    if neg:
        print(
            "__ALERT  LISTA NEGRA presente (%s): alguien los reintrodujo"
            % human(neg_size)
        )
        for size, name, _s, where, _p in neg:
            print("__ALERT  %s  %s  %s" % (human(size).rjust(8), name[:38].ljust(38), where))
    else:
        print("__OK  lista negra: limpia")

    if shadow:
        print(
            "__WARN  comentados pero VIVOS (%s): ref ${pkgs.X} en otro sitio"
            % human(shadow_size)
        )
        for size, name, _s, where, _p in shadow:
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
