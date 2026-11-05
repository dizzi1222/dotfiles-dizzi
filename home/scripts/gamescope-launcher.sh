#!/usr/bin/env bash
# ============================================================
# gamescope-launcher.sh — lanza apps .desktop dentro de Gamescope
# con el cursor confinado (--force-grab-cursor).
#
# Uso:
#   gamescope-launcher.sh              # selector fuzzel (wofi como fallback)
#   gamescope-launcher.sh steam        # lanza la primera app que coincida
#
# Variables:
#   GAMESCOPE_WIDTH / GAMESCOPE_HEIGHT   resolución (default: monitor actual)
#   GAMESCOPE_GRAB_KEYBOARD=1            añade --grab (teclado capturado)
#   GAMESCOPE_NO_CURSOR_GRAB=1           no confina el cursor
#   GAMESCOPE_PICKER=fuzzel|wofi|auto    selector (auto: fuzzel si está)
#   GAMESCOPE_EXTRA_ARGS="-s 1.5 --mangoapp"  flags extra para gamescope
#   GAMESCOPE_APP_DIRS="/ruta/a/applications:..."  directorios .desktop
#
# Log: ~/.cache/gamescope-launcher.log
# ============================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
HELPER="$SCRIPT_DIR/lib/desktop_apps.py"
WOFI_CONF="${WOFI_CONF:-$HOME/.config/wofi/system-control.conf}"
WOFI_STYLE="${WOFI_STYLE:-$HOME/.config/wofi/system-control.css}"
PROMPT_ICON="󰊴"

notify_error() {
  notify-send -u critical -a "Gamescope" "Gamescope: error" "$*" 2>/dev/null ||
    printf 'Gamescope: %s\n' "$*" >&2
}

die() {
  notify_error "$*"
  exit 1
}

# Resolución del monitor enfocado (Hyprland → niri → Plasma/KDE → 1920x1080).
detect_geometry() {
  local res=""

  if [ -n "${GAMESCOPE_WIDTH:-}" ] && [ -n "${GAMESCOPE_HEIGHT:-}" ]; then
    printf '%sx%s\n' "$GAMESCOPE_WIDTH" "$GAMESCOPE_HEIGHT"
    return
  fi

  if command -v hyprctl >/dev/null 2>&1 && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    res=$(hyprctl -j monitors 2>/dev/null |
      jq -r '([.[] | select(.focused)] + .)[0] // empty | "\(.width)x\(.height)"' 2>/dev/null)
  fi

  if [ -z "$res" ] && command -v niri >/dev/null 2>&1 && [ -n "${NIRI_SOCKET:-}" ]; then
    res=$(niri msg --json outputs 2>/dev/null |
      jq -r '[to_entries[].value.logical | select(. != null)] | .[0] // empty
             | "\(.width)x\(.height)"' 2>/dev/null)
  fi

  if [ -z "$res" ] && command -v kscreen-doctor >/dev/null 2>&1; then
    res=$(kscreen-doctor -j 2>/dev/null |
      jq -r '[.outputs[] | select(.enabled)] | sort_by(.priority) | .[0] as $o
             | $o.modes[] | select(.id == $o.currentModeId)
             | "\(.size.width)x\(.size.height)"' 2>/dev/null | head -n1)
  fi

  case "$res" in
  [0-9]*x[0-9]*) printf '%s\n' "$res" ;;
  *) printf '1920x1080\n' ;;
  esac
}

command -v gamescope >/dev/null 2>&1 || die "gamescope no está instalado"
command -v python3 >/dev/null 2>&1 || die "python3 no está disponible"
[ -f "$HELPER" ] || die "falta el helper: $HELPER"

GEOMETRY="$(detect_geometry)"
WIDTH="${GEOMETRY%x*}"
HEIGHT="${GEOMETRY#*x}"

# Selector: fuzzel (rápido, fuzzy nativo) o wofi (estilo del system-control).
# GAMESCOPE_PICKER=fuzzel|wofi|auto
PICKER="${GAMESCOPE_PICKER:-auto}"
if [ "$PICKER" = "auto" ]; then
  if command -v fuzzel >/dev/null 2>&1; then
    PICKER="fuzzel"
  else
    PICKER="wofi"
  fi
fi

picker_menu() {
  local prompt="$1"
  if [ "$PICKER" = "fuzzel" ]; then
    fuzzel --dmenu --only-match --no-run-if-empty --prompt "$prompt"
  else
    wofi --dmenu --cache-file /dev/null -l center \
      --conf "$WOFI_CONF" --style "$WOFI_STYLE" --columns 1 --prompt "$prompt"
  fi
}

# Si ya hay un Gamescope abierto, dos instancias compiten por el cursor.
if pgrep -x gamescope >/dev/null 2>&1 || pgrep -x gamescopereaper >/dev/null 2>&1; then
  CLOSE=$(printf 'Cancelar\nCerrar Gamescope y lanzar\n' |
    picker_menu "$PROMPT_ICON Gamescope activo")
  case "$CLOSE" in
  "Cerrar Gamescope y lanzar")
    pkill -x gamescopereaper 2>/dev/null
    pkill -x gamescope 2>/dev/null
    sleep 1
    ;;
  *) exit 0 ;;
  esac
fi

# Argumento opcional: nombre de app (para atajos de teclado).
if [ "$#" -gt 0 ]; then
  SELECTED="$*"
else
  ENTRIES=()
  case "$PICKER" in
  fuzzel)
    command -v fuzzel >/dev/null 2>&1 ||
      die "fuzzel no está instalado (usá GAMESCOPE_PICKER=wofi)"
    mapfile -t ENTRIES < <(python3 "$HELPER" list --plain)
    if [ "${#ENTRIES[@]}" -eq 0 ]; then
      die "no se encontraron apps .desktop en ~/.local/share/applications"
    fi
    # Columna 1: glifo · 2: nombre · 3: keywords ocultas para el matching.
    SELECTED=$(printf '%s\n' "${ENTRIES[@]}" |
      fuzzel --dmenu --only-match --no-run-if-empty \
        --prompt "$PROMPT_ICON Gamescope · " \
        --with-nth="{1} {2}" --accept-nth=2 --match-nth="{2} {3}")
    ;;
  wofi)
    mapfile -t ENTRIES < <(python3 "$HELPER" list)
    if [ "${#ENTRIES[@]}" -eq 0 ]; then
      die "no se encontraron apps .desktop en ~/.local/share/applications"
    fi
    CHOICE=$(printf '%s\n' "${ENTRIES[@]}" |
      wofi --dmenu --allow-markup --cache-file /dev/null -l center \
        --conf "$WOFI_CONF" --style "$WOFI_STYLE" --columns 1 \
        --prompt "$PROMPT_ICON Gamescope · cursor confinado")
    [ -z "$CHOICE" ] && exit 0
    SELECTED=$(printf '%s' "$CHOICE" | awk -F'\t' '{print $2}')
    ;;
  *)
    die "GAMESCOPE_PICKER inválido: $PICKER (usá fuzzel, wofi o auto)"
    ;;
  esac
  [ -z "$SELECTED" ] && exit 0
fi

ARGS=(
  python3 "$HELPER" launch
  --label "$SELECTED"
  --gamescope "$(command -v gamescope)"
  --width "$WIDTH"
  --height "$HEIGHT"
)

[ "${GAMESCOPE_GRAB_KEYBOARD:-0}" = "1" ] && ARGS+=(--grab-keyboard)
[ "${GAMESCOPE_NO_CURSOR_GRAB:-0}" = "1" ] && ARGS+=(--no-cursor-grab)

# GAMESCOPE_EXTRA_ARGS se parte por espacios a propósito (flags simples).
EXTRA_ARGS=()
read -r -a EXTRA_ARGS <<<"${GAMESCOPE_EXTRA_ARGS:-}"
for arg in "${EXTRA_ARGS[@]}"; do
  [ -n "$arg" ] && ARGS+=("--gamescope-arg=$arg")
done

OUTPUT=$("${ARGS[@]}" 2>&1)
RC=$?
if [ "$RC" -ne 0 ]; then
  notify_error "$OUTPUT"
  exit "$RC"
fi

APP_NAME="${OUTPUT#*$'\t'}"
notify-send -a "Gamescope" "$PROMPT_ICON Gamescope" \
  "$APP_NAME
${WIDTH}x${HEIGHT} · cursor confinado · Alt+F4 para cerrar" \
  2>/dev/null || true

exit 0
