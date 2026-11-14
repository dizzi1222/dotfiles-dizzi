#!/usr/bin/env bash
# arzopa-launcher.sh — elige una app .desktop y la abre en la Arzopa (card0)
# usando cage, igual que gamescope-launcher.sh pero para el monitor externo.
#
# Selector: gum filter → fzf → menú numerado → wofi (Desktop Mode sin TTY).
# Requiere: setup-via-a-arzopa.sh (card0 en seat-arzopa, shim libseat, udev).
# Uso: arzopa-launcher.sh [nombre-de-app]
#      arzopa-launcher.sh --list
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
HELPER="$SCRIPT_DIR/../lib/desktop_apps.py"
SHIM="$SCRIPT_DIR/arzopa-gamescope-shim.sh"
WOFI_CONF="${WOFI_CONF:-$SCRIPT_DIR/wofi-arzopa.conf}"
WOFI_STYLE="${WOFI_STYLE:-$SCRIPT_DIR/wofi-arzopa.css}"
PROMPT_ICON="󰍹"

# TTY para gum/fzf/read cuando se lanza desde Steam/Lutris (stdin no es TTY).
if [ ! -t 0 ]; then
  { exec < /dev/tty; } 2>/dev/null || true
fi

command -v python3 >/dev/null 2>&1 || { notify-send -u critical "Arzopa" "python3 no disponible" 2>/dev/null; exit 1; }
[ -f "$HELPER" ] || { notify-send -u critical "Arzopa" "falta $HELPER" 2>/dev/null; exit 1; }
[ -x "$SHIM" ] || { notify-send -u critical "Arzopa" "falta $SHIM" 2>/dev/null; exit 1; }

LISTING="$(python3 "$HELPER" list)" || { notify-send -u critical "Arzopa" "no se pudo leer la lista de apps" 2>/dev/null; exit 1; }
LABELS="$(printf '%s\n' "$LISTING" | cut -f2)"

if [ "${1:-}" = "--list" ]; then
  printf '%s\n' "$LABELS"
  exit 0
fi

pick_app() {
  local label
  if [ -t 0 ] && command -v gum >/dev/null 2>&1; then
    label=$(printf '%s\n' "$LABELS" |
      gum filter --height=20 --placeholder "Arzopa · buscar app")
  elif [ -t 0 ] && command -v fzf >/dev/null 2>&1; then
    label=$(printf '%s\n' "$LABELS" |
      fzf --prompt="Arzopa · app ▸ " --height=20 --reverse --no-sort)
  elif [ -t 0 ]; then
    local -a arr=()
    local -i i=0 n=0
    mapfile -t arr <<< "$LABELS"
    for i in "${!arr[@]}"; do
      printf '%3d) %s\n' "$((i + 1))" "${arr[$i]}"
    done >&2
    read -rp "Número de app (vacío = cancelar): " n || return 1
    [[ "$n" =~ ^[0-9]+$ ]] || return 0
    label="${arr[$((n - 1))]:-}"
  elif command -v wofi >/dev/null 2>&1; then
    local choice
    choice=$(printf '%s\n' "$LISTING" |
      wofi --dmenu --allow-markup --cache-file /dev/null -l center \
        --conf "$WOFI_CONF" --style "$WOFI_STYLE" --columns 1 \
        --prompt "$PROMPT_ICON Arzopa · app")
    label=$(printf '%s' "$choice" | cut -f2)
  fi
  printf '%s' "$label"
}

if [ "$#" -gt 0 ]; then
  SELECTED="$*"
else
  SELECTED="$(pick_app)" || exit 0
fi
[ -z "$SELECTED" ] && exit 0

# Prueba del selector sin lanzar nada.
if [ "${ARZOPA_DRYRUN:-0}" = "1" ]; then
  printf '%s\n' "$SELECTED"
  exit 0
fi

# El servicio de Zen también usa cage en card0: liberarlo antes de lanzar otra app.
systemctl --user stop arzopa-gamemode.service 2>/dev/null || true

OUT=$(python3 "$HELPER" launch \
  --label "$SELECTED" \
  --gamescope "$SHIM" \
  --width 1920 --height 1080 \
  --no-cursor-grab 2>&1)
RC=$?
if [ "$RC" -ne 0 ]; then
  notify-send -u critical -a "Arzopa" "Arzopa: error" "$OUT" 2>/dev/null || printf '%s\n' "$OUT" >&2
  exit "$RC"
fi

notify-send -a "Arzopa" "$PROMPT_ICON Arzopa" "$SELECTED
1920x1080 · touchpad en seat-arzopa" 2>/dev/null || true
exit 0
