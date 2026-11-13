#!/usr/bin/env bash
# ============================================================
# desktop-icon-extractor.sh — extrae el icono de un .desktop
# a PNG 128x128 y lo instala en el tema hicolor del usuario.
#
# Uso:
#   desktop-icon-extractor.sh                 # selector fuzzel/wofi
#   desktop-icon-extractor.sh wine            # TODAS las apps que coincidan
#   desktop-icon-extractor.sh --match wine
#   desktop-icon-extractor.sh --all           # todas las apps visibles
#   desktop-icon-extractor.sh --file app.desktop
#
# Destino por defecto:
#   ~/.local/share/icons/hicolor/128x128/apps/<icono>.png
#
# Variables:
#   ICON_PICKER=fuzzel|wofi|auto   selector (auto: fuzzel si está)
#   ICON_OUTPUT_DIR=/ruta          destino alternativo
#   ICON_SIZE=128                  tamaño cuadrado del PNG
# ============================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
HELPER="$SCRIPT_DIR/lib/desktop_apps.py"
WOFI_CONF="${WOFI_CONF:-$HOME/.config/wofi/system-control.conf}"
WOFI_STYLE="${WOFI_STYLE:-$HOME/.config/wofi/system-control.css}"
PROMPT_ICON="󰋩"

die() {
  notify-send -u critical -a "Iconos" "Extractor de iconos: error" "$*" 2>/dev/null ||
    printf 'Extractor de iconos: %s\n' "$*" >&2
  exit 1
}

[ -f "$HELPER" ] || die "falta el helper: $HELPER"
command -v python3 >/dev/null 2>&1 || die "python3 no está disponible"

PICKER="${ICON_PICKER:-auto}"
if [ "$PICKER" = "auto" ]; then
  if command -v fuzzel >/dev/null 2>&1; then
    PICKER="fuzzel"
  else
    PICKER="wofi"
  fi
fi

QUERY=""
MATCH=""
ALL=0
DESKTOP_FILE=""
OUTPUT_DIR="${ICON_OUTPUT_DIR:-}"
SIZE="${ICON_SIZE:-128}"

while [ "$#" -gt 0 ]; do
  case "$1" in
  --file) DESKTOP_FILE="${2:-}"; shift 2 ;;
  --file=*) DESKTOP_FILE="${1#*=}"; shift ;;
  --output) OUTPUT_DIR="${2:-}"; shift 2 ;;
  --output=*) OUTPUT_DIR="${1#*=}"; shift ;;
  --size) SIZE="${2:-128}"; shift 2 ;;
  --all) ALL=1; shift ;;
  --match) MATCH="${2:-}"; shift 2 ;;
  --match=*) MATCH="${1#*=}"; shift ;;
  -h | --help) sed -n '2,25p' "$0"; exit 0 ;;
  --) shift; MATCH="$*"; break ;;
  *) MATCH="$*"; break ;;
  esac
done

if [ -z "$DESKTOP_FILE" ] && [ -z "$MATCH" ] && [ "$ALL" -eq 0 ]; then
  ENTRIES=()
  case "$PICKER" in
  fuzzel)
    command -v fuzzel >/dev/null 2>&1 ||
      die "fuzzel no está instalado (usá ICON_PICKER=wofi)"
    mapfile -t ENTRIES < <(python3 "$HELPER" list --plain)
    [ "${#ENTRIES[@]}" -eq 0 ] && die "no hay apps .desktop"
    QUERY=$(printf '%s\n' "${ENTRIES[@]}" |
      fuzzel --dmenu --only-match --no-run-if-empty \
        --prompt "$PROMPT_ICON Icono · " \
        --with-nth="{1} {2}" --accept-nth=2 --match-nth=3)
    ;;
  wofi)
    mapfile -t ENTRIES < <(python3 "$HELPER" list)
    [ "${#ENTRIES[@]}" -eq 0 ] && die "no hay apps .desktop"
    CHOICE=$(printf '%s\n' "${ENTRIES[@]}" |
      wofi --dmenu --allow-markup --cache-file /dev/null -l center \
        --conf "$WOFI_CONF" --style "$WOFI_STYLE" --columns 1 \
        --prompt "$PROMPT_ICON Icono · .desktop")
    [ -z "$CHOICE" ] && exit 0
    QUERY=$(printf '%s' "$CHOICE" | awk -F'\t' '{print $2}')
    ;;
  *)
    die "ICON_PICKER inválido: $PICKER (fuzzel, wofi o auto)"
    ;;
  esac
  [ -z "$QUERY" ] && exit 0
fi

ARGS=(python3 "$HELPER" icon --size "$SIZE")
if [ -n "$DESKTOP_FILE" ]; then
  ARGS+=(--file "$DESKTOP_FILE")
elif [ -n "$MATCH" ]; then
  ARGS+=(--match "$MATCH")
elif [ "$ALL" -eq 1 ]; then
  ARGS+=(--all)
else
  ARGS+=(--label "$QUERY")
fi
[ -n "$OUTPUT_DIR" ] && ARGS+=(--output-dir "$OUTPUT_DIR")

OUTPUT=$("${ARGS[@]}" 2>/tmp/iconos-err.$$)
RC=$?
ERRS=$(cat "/tmp/iconos-err.$$" 2>/dev/null)
rm -f "/tmp/iconos-err.$$"
[ "$RC" -ne 0 ] && die "${ERRS:-$OUTPUT}"

COUNT=0
FIRST_DEST=""
FIRST_LABEL=""
FIRST_SRC=""
while IFS=$'\t' read -r DEST LABEL SRC; do
  [ -z "$DEST" ] && continue
  COUNT=$((COUNT + 1))
  if [ "$COUNT" -eq 1 ]; then
    FIRST_DEST="$DEST"
    FIRST_LABEL="$LABEL"
    FIRST_SRC="$SRC"
  fi
  printf '%s\n' "$DEST"
done <<<"$OUTPUT"

if [ "$COUNT" -eq 0 ]; then
  die "no se extrajo ningún icono${ERRS:+: $ERRS}"
fi

if [ "$COUNT" -eq 1 ]; then
  notify-send -a "Iconos" -i "$FIRST_DEST" \
    "Icono extraído: $FIRST_LABEL" \
    "$FIRST_DEST"$'\n'"${SIZE}x${SIZE} · $FIRST_SRC" 2>/dev/null || true
else
  notify-send -a "Iconos" -i "$FIRST_DEST" \
    "Iconos extraídos: $COUNT" "hicolor/${SIZE}x${SIZE}/apps" \
    2>/dev/null || true
fi
