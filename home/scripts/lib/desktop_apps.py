#!/usr/bin/env python3
"""Helper de gamescope-launcher.sh.

Lee los .desktop del usuario, los presenta para wofi y lanza la app elegida
dentro de Gamescope. No usa `eval`: parsea el Exec como argumentos (shlex) y
solo recurre a `bash -c` cuando el Exec trae operadores de shell (||, &&, ;),
como el .desktop de GeForce NOW.

Subcomandos:
  list                      imprime líneas "icono<TAB>label<TAB>keywords" para wofi
  launch --label L ...      lanza la app L dentro de gamescope

Variables de entorno:
  GAMESCOPE_APP_DIRS        directorios de .desktop separados por ':' (default:
                            ~/.local/share/applications + exports de flatpak)
  GAMESCOPE_NO_CURSOR_GRAB  =1 para NO pasar --force-grab-cursor
  GAMESCOPE_GRAB_KEYBOARD   =1 para añadir --grab (teclado capturado)
  GAMESCOPE_EXTRA_ARGS      flags extra para gamescope (se parten por espacios)
"""

from __future__ import annotations

import argparse
import html
import os
import re
import shlex
import shutil
import subprocess
import sys
import time
from collections import Counter
from pathlib import Path

# Glifos Nerd Font por categoría (coherente con el menú de system_control).
CATEGORY_ICONS = (
    ("Game", "󰊴"),
    ("AudioVideo", "󰝚"),
    ("Audio", "󰓃"),
    ("Video", "󰕧"),
    ("Development", "󰅩"),
    ("Graphics", "󰏘"),
    ("Network", "󰖟"),
    ("Office", "󰈙"),
    ("Education", "󰑴"),
    ("Science", "󰬈"),
    ("Settings", "󰒓"),
    ("System", "󰒓"),
    ("Utility", "󰒓"),
)
DEFAULT_ICON = "󰀄"

# Códigos de campo que se eliminan (archivos/URLs no aplican a un lanzador).
DROP_FIELD_CODES = set("fFuUdDnNvm")
SHELL_OPS = {"||", "&&", ";", "|", "&", "|&"}
SHELL_REDIR = re.compile(r"^[0-9]*(?:>>?|<<?|&>|>&|<&)[0-9-]*$")


def truthy(value: str | None) -> bool:
    return (value or "").strip().lower() in {"1", "true", "yes"}


def desktop_unescape(value: str) -> str:
    """Deshace los escapes de string de la spec Desktop Entry."""
    mapping = {"s": " ", "n": "\n", "t": "\t", "r": "\r", "\\": "\\", ";": ";"}
    out: list[str] = []
    i = 0
    while i < len(value):
        if value[i] == "\\" and i + 1 < len(value) and value[i + 1] in mapping:
            out.append(mapping[value[i + 1]])
            i += 2
        else:
            out.append(value[i])
            i += 1
    return "".join(out)


def locale_candidates() -> list[str]:
    langs: list[str] = []
    for var in ("LANGUAGE", "LC_ALL", "LC_MESSAGES", "LANG"):
        for part in os.environ.get(var, "").split(":"):
            part = part.split(".")[0].split("@")[0].strip()
            if not part or part in langs:
                continue
            langs.append(part)
            base = part.split("_")[0]
            if base and base not in langs:
                langs.append(base)
    return langs


class Entry:
    def __init__(self, path: Path, keys: dict[str, str]):
        self.path = path
        self.keys = keys
        self.name = self.localized("Name") or path.stem
        self.comment = self.localized("Comment") or ""
        self.generic = self.localized("GenericName") or ""
        self.keywords = self.localized("Keywords") or ""
        self.icon = self.category_icon(keys.get("Categories", ""))
        self.label = self.name

    def get(self, key: str, default: str = "") -> str:
        return self.keys.get(key, default)

    def localized(self, key: str) -> str:
        for lang in locale_candidates():
            value = self.keys.get(f"{key}[{lang}]")
            if value:
                return desktop_unescape(value)
        return desktop_unescape(self.keys.get(key, ""))

    def category_icon(self, categories: str) -> str:
        cats = {c.strip() for c in categories.split(";") if c.strip()}
        for cat, glyph in CATEGORY_ICONS:
            if cat in cats:
                return glyph
        return DEFAULT_ICON

    def search_terms(self) -> str:
        exec_base = ""
        if self.get("Exec"):
            try:
                exec_base = Path(shlex.split(self.get("Exec"))[0]).name
            except (ValueError, IndexError):
                exec_base = ""
        words = [
            self.name,
            self.label,
            self.comment,
            self.generic,
            self.keywords.replace(";", " "),
            self.get("Categories").replace(";", " "),
            self.path.stem,
            exec_base,
            "gamescope",
        ]
        return " ".join(w for w in words if w).strip()


def parse_desktop(path: Path) -> Entry | None:
    keys: dict[str, str] = {}
    in_entry = False
    try:
        with path.open(encoding="utf-8", errors="replace") as fh:
            for raw in fh:
                line = raw.strip()
                if not line or line.startswith("#"):
                    continue
                if line.startswith("["):
                    in_entry = line == "[Desktop Entry]"
                    continue
                if not in_entry or "=" not in line:
                    continue
                key, value = line.split("=", 1)
                # La primera aparición gana (igual que la spec).
                keys.setdefault(key.strip(), value.strip())
    except OSError:
        return None

    if truthy(keys.get("Hidden")) or truthy(keys.get("NoDisplay")):
        return None
    if keys.get("Type", "Application") != "Application":
        return None
    if not keys.get("Exec"):
        return None

    tryexec = keys.get("TryExec", "")
    if tryexec:
        found = tryexec if "/" in tryexec else shutil.which(tryexec)
        if not found or not os.access(found, os.X_OK):
            return None

    return Entry(path, keys)


def app_dirs() -> list[Path]:
    env = os.environ.get("GAMESCOPE_APP_DIRS", "")
    if env:
        return [Path(p).expanduser() for p in env.split(":") if p]

    data_home = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share"))
    candidates = [
        data_home / "applications",
        Path.home() / ".local/share/flatpak/exports/share/applications",
        Path("/var/lib/flatpak/exports/share/applications"),
    ]
    return [p for p in candidates if p.is_dir()]


def load_entries() -> list[Entry]:
    entries: list[Entry] = []
    seen_ids: set[str] = set()
    for directory in app_dirs():
        try:
            files = sorted(directory.glob("*.desktop"))
        except OSError:
            continue
        for path in files:
            if not path.is_file():
                continue
            desktop_id = path.name
            if desktop_id in seen_ids:
                continue
            seen_ids.add(desktop_id)
            entry = parse_desktop(path)
            if entry is not None:
                entries.append(entry)

    # Nombres repetidos: se desambiguan con el nombre del archivo.
    counts = Counter(e.name for e in entries)
    for entry in entries:
        if counts[entry.name] > 1:
            entry.label = f"{entry.name} · {entry.path.stem}"

    used: Counter[str] = Counter()
    for entry in entries:
        used[entry.label] += 1
        if used[entry.label] > 1:
            entry.label = f"{entry.label} ({used[entry.label]})"

    entries.sort(key=lambda e: e.name.casefold())
    return entries


def pango(text: str) -> str:
    text = " ".join(text.split())
    return html.escape(text, quote=False)


def plain_text(text: str) -> str:
    return " ".join(text.split())


def cmd_list(args: argparse.Namespace) -> int:
    for entry in load_entries():
        if args.plain:
            # fuzzel: sin pango, columnas icono / nombre / keywords.
            print(
                "{icon}\t{label}\t{kw}".format(
                    icon=entry.icon,
                    label=plain_text(entry.label),
                    kw=plain_text(entry.search_terms()),
                )
            )
            continue
        line = "{icon}\t{label}\t<span alpha=\"1\" font_size=\"1\">{kw}</span>".format(
            icon=entry.icon,
            label=pango(entry.label),
            kw=pango(entry.search_terms()),
        )
        print(line)
    return 0


def expand_field_codes(tokens: list[str], entry: Entry) -> list[str]:
    """Expande %f/%u/%i/%c/%k/%% según la spec Desktop Entry."""
    name = entry.name
    icon = entry.get("Icon")
    expanded: list[str] = []
    for token in tokens:
        if token == "%i":
            if icon:
                expanded.extend(["--icon", icon])
            continue
        out: list[str] = []
        i = 0
        while i < len(token):
            if token[i] == "%" and i + 1 < len(token):
                code = token[i + 1]
                if code == "%":
                    out.append("%")
                elif code == "c":
                    out.append(name)
                elif code == "k":
                    out.append(str(entry.path))
                elif code == "i":
                    out.append(icon)
                elif code not in DROP_FIELD_CODES:
                    out.append("%" + code)
                i += 2
            else:
                out.append(token[i])
                i += 1
        value = "".join(out)
        if value:
            expanded.append(value)
    return expanded


def strip_outer_gamescope(tokens: list[str]) -> list[str]:
    """Evita gamescope dentro de gamescope (ej. GeForce NOW ya lo trae)."""
    if not tokens or Path(tokens[0]).name != "gamescope":
        return tokens
    try:
        inner = tokens[tokens.index("--") + 1 :]
    except ValueError:
        return tokens
    return inner or tokens


def has_shell_syntax(tokens: list[str]) -> bool:
    return any(t in SHELL_OPS or SHELL_REDIR.match(t) for t in tokens)


def join_shell(tokens: list[str]) -> str:
    parts: list[str] = []
    for token in tokens:
        if token in SHELL_OPS or SHELL_REDIR.match(token):
            parts.append(token)
        else:
            parts.append(shlex.quote(token))
    return " ".join(parts)


def build_app_argv(entry: Entry) -> tuple[list[str], str | None]:
    raw_exec = entry.get("Exec")
    try:
        tokens = shlex.split(raw_exec, posix=True)
    except ValueError as exc:
        raise SystemExit(f"Exec inválido en {entry.path}: {exc}") from exc

    tokens = expand_field_codes(tokens, entry)
    tokens = strip_outer_gamescope(tokens)
    if not tokens:
        raise SystemExit(f"Exec vacío tras expandir: {entry.path}")

    if truthy(entry.get("Terminal")):
        terminal = os.environ.get("TERMINAL") or (
            "kitty" if shutil.which("kitty") else "xterm"
        )
        tokens = [terminal, "-e", *tokens]

    if has_shell_syntax(tokens):
        argv = ["bash", "-c", join_shell(tokens)]
    else:
        argv = tokens

    cwd = entry.get("Path") or None
    if cwd:
        cwd = os.path.expanduser(cwd)
        if not os.path.isdir(cwd):
            cwd = None
    return argv, cwd


def find_entry(label: str) -> Entry:
    entries = load_entries()
    variants: list[str] = []
    for candidate in (label.strip(), html.unescape(label).strip()):
        if candidate and candidate not in variants:
            variants.append(candidate)

    def exact(wanted: str) -> list[Entry]:
        return [e for e in entries if e.label == wanted]

    def casefold(wanted: str) -> list[Entry]:
        folded = wanted.casefold()
        return [
            e
            for e in entries
            if e.label.casefold() == folded or e.name.casefold() == folded
        ]

    def partial(wanted: str) -> list[Entry]:
        folded = wanted.casefold()
        return [
            e
            for e in entries
            if folded in e.label.casefold() or folded in e.name.casefold()
        ]

    matches: list[Entry] = []
    for matcher in (exact, casefold, partial):
        for wanted in variants:
            matches = matcher(wanted)
            if matches:
                break
        if matches:
            break

    if not matches:
        raise SystemExit(f"No se encontró una app .desktop para: {label.strip()}")
    if len(matches) > 1:
        options = "\n".join(f"  - {e.label}" for e in matches[:10])
        raise SystemExit(f"Selección ambigua: {label.strip()}\n{options}")
    return matches[0]


def cmd_launch(args: argparse.Namespace) -> int:
    entry = find_entry(args.label)
    app_argv, cwd = build_app_argv(entry)

    cmd = [
        args.gamescope,
        "-f",
        "-W",
        str(args.width),
        "-H",
        str(args.height),
        "-w",
        str(args.width),
        "-h",
        str(args.height),
    ]

    if not args.no_cursor_grab:
        cmd.append("--force-grab-cursor")
    if args.grab_keyboard:
        cmd.append("--grab")
    cmd.extend(args.gamescope_arg)
    cmd.extend(["--", *app_argv])

    cache_dir = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache"))
    cache_dir.mkdir(parents=True, exist_ok=True)
    log_path = cache_dir / "gamescope-launcher.log"

    with log_path.open("ab") as log:
        log.write(
            (
                f"\n=== {time.strftime('%Y-%m-%d %H:%M:%S')} · {entry.label}\n"
                f"cwd: {cwd or os.getcwd()}\n"
                f"cmd: {shlex.join(cmd)}\n"
            ).encode()
        )
        log.flush()
        try:
            proc = subprocess.Popen(
                cmd,
                cwd=cwd or None,
                stdin=subprocess.DEVNULL,
                stdout=log,
                stderr=log,
                start_new_session=True,
                close_fds=True,
            )
        except OSError as exc:
            print(f"No se pudo ejecutar gamescope: {exc}\nLog: {log_path}", file=sys.stderr)
            return 1

    # Detecta fallos inmediatos (flag inválida, backend roto, etc.).
    time.sleep(0.5)
    rc = proc.poll()
    if rc is not None and rc != 0:
        tail = ""
        try:
            lines = log_path.read_text(errors="replace").splitlines()[-8:]
            tail = "\n".join(lines)
        except OSError:
            pass
        print(
            f"gamescope terminó con código {rc}.\nLog: {log_path}\n{tail}",
            file=sys.stderr,
        )
        return rc if rc > 0 else 1

    print(f"{proc.pid}\t{entry.label}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    list_parser = sub.add_parser("list", help="lista apps para wofi/fuzzel")
    list_parser.add_argument(
        "--plain", action="store_true", help="sin markup pango (para fuzzel)"
    )

    launch = sub.add_parser("launch", help="lanza una app dentro de gamescope")
    launch.add_argument("--label", required=True)
    launch.add_argument("--gamescope", default="gamescope")
    launch.add_argument("--width", type=int, default=1920)
    launch.add_argument("--height", type=int, default=1080)
    launch.add_argument("--no-cursor-grab", action="store_true")
    launch.add_argument("--grab-keyboard", action="store_true")
    launch.add_argument("--gamescope-arg", action="append", default=[])

    args = parser.parse_args()
    if args.command == "list":
        return cmd_list(args)
    return cmd_launch(args)


if __name__ == "__main__":
    sys.exit(main())
