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
import tempfile
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

# Extracción de iconos → PNG 128x128 para el tema hicolor del usuario.
ICON_EXTS = (".png", ".svg", ".xpm")
ICON_SIZE = 128


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


def parse_desktop(
    path: Path, *, allow_hidden: bool = False, require_exec: bool = True
) -> Entry | None:
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

    if not allow_hidden and (
        truthy(keys.get("Hidden")) or truthy(keys.get("NoDisplay"))
    ):
        return None
    if keys.get("Type", "Application") != "Application":
        return None
    if require_exec and not keys.get("Exec"):
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
        Path("/usr/local/share/applications"),
        Path("/usr/share/applications"),
        Path("/run/current-system/sw/share/applications"),
        Path.home() / ".nix-profile/share/applications",
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


def ini_value(path: Path, section: str, key: str) -> str:
    current = ""
    try:
        lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    except OSError:
        return ""
    for raw in lines:
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("[") and line.endswith("]"):
            current = line[1:-1].strip()
            continue
        if current != section or "=" not in line:
            continue
        k, v = line.split("=", 1)
        if k.strip() == key:
            return v.strip()
    return ""


def icon_roots() -> list[Path]:
    home = Path.home()
    user = os.environ.get("USER") or ""
    data_home = Path(os.environ.get("XDG_DATA_HOME", home / ".local/share"))
    candidates: list[Path | None] = [
        home / ".local/share/icons",
        home / ".icons",
        data_home / "icons",
        home / ".local/share/flatpak/exports/share/icons",
        Path("/var/lib/flatpak/exports/share/icons"),
        Path("/usr/share/icons"),
        Path("/usr/local/share/icons"),
        Path("/run/current-system/sw/share/icons"),
        home / ".nix-profile/share/icons",
        Path("/etc/profiles/per-user") / user / "share/icons" if user else None,
    ]
    roots: list[Path] = []
    seen: set[Path] = set()
    for candidate in candidates:
        if candidate is None or not candidate.is_dir():
            continue
        try:
            real = candidate.resolve()
        except OSError:
            real = candidate
        if real in seen:
            continue
        seen.add(real)
        roots.append(candidate)
    return roots


def configured_icon_theme() -> str:
    for path in (
        Path.home() / ".config/gtk-4.0/settings.ini",
        Path.home() / ".config/gtk-3.0/settings.ini",
    ):
        value = ini_value(path, "Settings", "gtk-icon-theme-name")
        if value:
            return value
    return "hicolor"


def theme_parents(theme: str) -> list[str]:
    for root in icon_roots():
        index = root / theme / "index.theme"
        if index.is_file():
            value = ini_value(index, "Icon Theme", "Inherits")
            if value:
                return [t.strip() for t in value.split(",") if t.strip()]
    return []


def theme_chain() -> list[str]:
    chain: list[str] = []

    def add(name: str) -> None:
        name = name.strip()
        if name and name not in chain:
            chain.append(name)

    add("hicolor")
    theme = configured_icon_theme()
    add(theme)
    for parent in theme_parents(theme):
        add(parent)
    for name in ("Adwaita", "breeze", "breeze-dark", "breeze-light"):
        add(name)
    return chain



def icon_score(path: Path) -> int:
    """Puntúa un icono: vectorial y grande primero, simbólicos al final."""
    text = path.as_posix().lower()
    suffix = path.suffix.lower()
    size = 0
    match = re.search(r"/(\d+)x(\d+)/", text) or re.search(
        r"/(?:apps|applications)/(\d+)/", text
    )
    if match:
        size = int(match.group(1))
    if suffix == ".svg":
        # Un SVG es nítido a cualquier tamaño; los "scalable" son los buenos.
        score = 900 if "/scalable/" in text else 400 + size
    else:
        score = size
    if "/apps/" in text or "/applications/" in text:
        score += 50
    if "/hicolor/" in text:
        score += 150
    if "symbolic" in path.name.lower() or "/symbolic/" in text:
        score -= 5000
    if suffix != ".svg" and 0 < size < 48:
        # Iconos de panel (16/22/24) quedan horribles al ampliarlos a 128.
        score -= 200
    if "/oxygen/" in text:
        score += 30
    return score


# A partir de aquí el icono es suficientemente bueno (SVG o PNG grande).
ICON_GOOD_ENOUGH = 200


def same_file(a: Path, b: Path) -> bool:
    try:
        return a.resolve() == b.resolve()
    except OSError:
        return False


_THEME_INDEX: dict[tuple[str, str], dict[str, list[Path]]] = {}


def theme_index(root: Path, theme: str) -> dict[str, list[Path]]:
    """Índice filename → rutas de un tema (se construye una sola vez)."""
    key = (str(root), theme)
    index = _THEME_INDEX.get(key)
    if index is not None:
        return index
    index = {}
    base = root / theme
    if base.is_dir():
        for dirpath, _dirnames, filenames in os.walk(base):
            for filename in filenames:
                if filename.endswith(ICON_EXTS):
                    index.setdefault(filename, []).append(
                        Path(dirpath) / filename
                    )
    _THEME_INDEX[key] = index
    return index


def search_theme(theme: str, name: str, exclude: Path | None = None) -> Path | None:
    wanted = [f"{name}{ext}" for ext in ICON_EXTS]
    best: tuple[int, Path] | None = None
    for root in icon_roots():
        if not (root / theme).is_dir():
            continue
        index = theme_index(root, theme)
        for filename in wanted:
            for candidate in index.get(filename, ()):
                if exclude is not None and same_file(candidate, exclude):
                    continue
                score = icon_score(candidate)
                if best is None or score > best[0]:
                    best = (score, candidate)
    return best[1] if best else None


_ICON_CACHE: dict[tuple[str, str], Path | None] = {}


def find_icon(name: str, exclude: Path | None = None) -> Path | None:
    key = (name, str(exclude) if exclude is not None else "")
    if key in _ICON_CACHE:
        return _ICON_CACHE[key]
    result = _find_icon(name, exclude)
    _ICON_CACHE[key] = result
    return result


def _find_icon(name: str, exclude: Path | None = None) -> Path | None:
    for root in (
        Path.home() / ".local/share/icons",
        Path.home() / ".icons",
        Path("/usr/share/pixmaps"),
    ):
        for ext in ICON_EXTS:
            flat = root / f"{name}{ext}"
            if flat.is_file() and not (exclude is not None and same_file(flat, exclude)):
                return flat

    # Se queda el mejor de la cadena de temas; un 22px de Colloid no debe
    # ganarle a un SVG de hicolor.
    best: tuple[int, int, Path] | None = None
    for rank, theme in enumerate(theme_chain()):
        hit = search_theme(theme, name, exclude)
        if hit is None:
            continue
        score = icon_score(hit)
        if best is None or (score, -rank) > (best[0], best[1]):
            best = (score, -rank, hit)
        if score >= ICON_GOOD_ENOUGH:
            return hit
    if best is not None:
        return best[2]

    # Fallback: cualquier tema instalado (Colloid-Pink-Light, Gruvbox, etc.)
    seen: set[str] = set()
    for root in icon_roots():
        try:
            themes = [d for d in root.iterdir() if d.is_dir()]
        except OSError:
            continue
        for directory in themes:
            if directory.name in seen:
                continue
            seen.add(directory.name)
            hit = search_theme(directory.name, name, exclude)
            if hit is None:
                continue
            if icon_score(hit) < -1000:  # simbólico: no sirve como icono de app
                continue
            return hit
    return None

def icon_field_name(entry: Entry) -> str:
    raw = entry.get("Icon").strip()
    if not raw:
        return entry.path.stem
    path = Path(raw)
    if path.suffix.lower() in ICON_EXTS:
        return path.stem
    return path.name


def user_icon_roots() -> list[Path]:
    """Rutas de iconos instaladas por el usuario."""
    home = Path.home()
    data_home = Path(os.environ.get("XDG_DATA_HOME", home / ".local/share"))
    return [
        p
        for p in (
            data_home / "icons",
            home / ".icons",
            home / ".local/share/flatpak/exports/share/icons",
        )
        if p.is_dir()
    ]


def find_user_icon(name: str, exclude: Path | None = None) -> Path | None:
    """Icono por nombre solo en las rutas del usuario (icono propio de la app)."""
    for root in user_icon_roots():
        for ext in ICON_EXTS:
            flat = root / f"{name}{ext}"
            if flat.is_file() and not (
                exclude is not None and same_file(flat, exclude)
            ):
                return flat
    best: tuple[int, Path] | None = None
    for root in user_icon_roots():
        try:
            themes = [d for d in root.iterdir() if d.is_dir()]
        except OSError:
            continue
        for theme in themes:
            hit = search_theme(theme.name, name, exclude)
            if hit is None:
                continue
            score = icon_score(hit)
            if score < 0:
                continue
            if best is None or score > best[0]:
                best = (score, hit)
    return best[1] if best else None


def find_entry_icon(entry: Entry, exclude: Path | None = None) -> Path | None:
    raw = entry.get("Icon").strip()
    if raw:
        path = Path(raw).expanduser()
        if path.is_file() and not (exclude is not None and same_file(path, exclude)):
            return path
        if not path.is_absolute():
            for base in (Path.home(), entry.path.parent):
                candidate = base / raw
                if candidate.is_file() and not (
                    exclude is not None and same_file(candidate, exclude)
                ):
                    return candidate

    # Icono propio instalado por el usuario (p. ej. wine-discord-ipc-bridge.svg)
    # aunque el .desktop use un Icon= genérico como "wine".
    stem = entry.path.stem
    parts = stem.split("-")
    candidates = [stem]
    for cut in range(1, min(3, len(parts))):
        candidates.append("-".join(parts[:-cut]))
    for name in candidates:
        own = find_user_icon(name, exclude)
        if own is not None:
            return own

    name = icon_field_name(entry)
    found = find_icon(name, exclude)
    if found:
        return found
    return find_icon(entry.path.stem, exclude)


def icon_output_name(
    entry: Entry, override: str = "", src: Path | None = None
) -> str:
    base = override or (src.stem if src is not None else "") or icon_field_name(entry)
    name = base.strip()
    name = name.replace("/", "_").replace("\\", "_").replace("\0", "")
    if not name or name in {".", ".."}:
        name = entry.path.stem
    return name if name.lower().endswith(".png") else f"{name}.png"


def png_dimensions(path: Path) -> tuple[int, int] | None:
    try:
        with path.open("rb") as fh:
            head = fh.read(24)
    except OSError:
        return None
    if len(head) >= 24 and head[:8] == b"\x89PNG\r\n\x1a\n" and head[12:16] == b"IHDR":
        return (
            int.from_bytes(head[16:20], "big"),
            int.from_bytes(head[20:24], "big"),
        )
    return None


def render_png(src: Path, size: int, tmpdir: Path) -> Path:
    out = tmpdir / "icon.png"
    suffix = src.suffix.lower()
    if suffix == ".png" and png_dimensions(src) == (size, size):
        shutil.copy2(src, out)
        return out
    magick = shutil.which("magick") or shutil.which("convert")
    ffmpeg = shutil.which("ffmpeg")
    rsvg = shutil.which("rsvg-convert")
    intermediate = src
    if suffix == ".svg" and rsvg:
        rendered = tmpdir / "rendered.png"
        run_quiet([rsvg, "-w", str(size), "-o", str(rendered), str(src)])
        intermediate = rendered
    if magick:
        run_quiet([magick, str(intermediate), "-background", "none",
                   "-resize", f"{size}x{size}", "-gravity", "center",
                   "-extent", f"{size}x{size}", str(out)])
        return out
    if ffmpeg:
        video_filter = (
            f"scale={size}:{size}:force_original_aspect_ratio=decrease,"
            f"pad={size}:{size}:(ow-iw)/2:(oh-ih)/2:color=0x00000000"
        )
        run_quiet([ffmpeg, "-y", "-loglevel", "error", "-i", str(intermediate),
                   "-vf", video_filter, "-frames:v", "1", str(out)])
        return out
    if intermediate.suffix.lower() == ".png":
        shutil.copy2(intermediate, out)
        return out
    raise RuntimeError("no hay convertidor PNG disponible")


def run_quiet(cmd: list[str], timeout: int = 30) -> None:
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL,
                   stderr=subprocess.DEVNULL, timeout=timeout)


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


def extract_icon(
    entry: Entry, outdir: Path, size: int, name_override: str = ""
) -> tuple[Path, Path] | None:
    """Extrae el icono de `entry`; None si no hay un icono válido."""
    guess = outdir / icon_output_name(entry, name_override)
    src = find_entry_icon(entry, exclude=guess)
    if src is None:
        return None
    dest = outdir / icon_output_name(entry, name_override, src)
    if src.resolve() != dest.resolve():
        with tempfile.TemporaryDirectory(prefix="desktop-icon-") as tmp:
            rendered = render_png(src, size, Path(tmp))
            data = rendered.read_bytes()
        with dest.open("wb") as fh:
            fh.write(data)
    return dest, src


def matching_entries(term: str) -> list[Entry]:
    folded = term.strip().casefold()
    if not folded:
        return []
    return [
        e
        for e in load_entries()
        if folded in e.label.casefold() or folded in e.search_terms().casefold()
    ]


def cmd_icon(args: argparse.Namespace) -> int:
    outdir = (
        Path(args.output_dir).expanduser()
        if args.output_dir
        else Path.home() / f".local/share/icons/hicolor/{args.size}x{args.size}/apps"
    )
    outdir.mkdir(parents=True, exist_ok=True)

    if args.file:
        entry = parse_desktop(Path(args.file).expanduser(),
                              allow_hidden=True, require_exec=False)
        if entry is None:
            raise SystemExit(f"No se pudo leer el .desktop: {args.file}")
        entries = [entry]
    elif args.match:
        entries = matching_entries(args.match)
        if not entries:
            raise SystemExit(f"Ninguna app coincide con: {args.match}")
    elif args.all:
        entries = load_entries()
    else:
        entries = [find_entry(args.label)]

    done: set[Path] = set()
    failed: list[str] = []
    for entry in entries:
        result = extract_icon(entry, outdir, args.size, args.name)
        if result is None:
            failed.append(entry.label)
            continue
        dest, src = result
        if dest in done:
            continue
        done.add(dest)
        print(f"{dest}\t{entry.label}\t{src}")

    cache = shutil.which("gtk-update-icon-cache")
    if cache:
        parent = outdir
        while parent != parent.parent and parent.name != "hicolor":
            parent = parent.parent
        if parent.name == "hicolor":
            try:
                run_quiet([cache, "-f", "-t", str(parent)], timeout=10)
            except (OSError, subprocess.SubprocessError):
                pass

    for label in failed:
        print(f"AVISO: sin icono para {label}", file=sys.stderr)
    return 0


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

    icon = sub.add_parser("icon", help="extrae el icono .desktop a PNG")
    icon.add_argument("--label")
    icon.add_argument("--match")
    icon.add_argument("--all", action="store_true")
    icon.add_argument("--file")
    icon.add_argument("--output-dir")
    icon.add_argument("--name", default="")
    icon.add_argument("--size", type=int, default=ICON_SIZE)

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
    if args.command == "icon":
        if not args.label and not args.match and not args.all and not args.file:
            parser.error("icon requiere --label, --match o --file")
        return cmd_icon(args)
    return cmd_launch(args)


if __name__ == "__main__":
    sys.exit(main())
