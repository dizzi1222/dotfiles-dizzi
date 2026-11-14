#!/usr/bin/env bash
# arzopa-launcher.sh — elige una app .desktop y la abre en la Arzopa (card0)
# usando cage, igual que gamescope-launcher.sh pero para el monitor externo.
#
# Requiere: setup-via-a-arzopa.sh (card0 en seat-arzopa, shim libseat, udev).
# Uso: arzopa-launcher.sh [nombre-de-app]
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
HELPER="$SCRIPT_DIR/lib/desktop_apps.py"
WOFI_CONF="${WOFI_CONF:-$SCRIPT_DIR/wofi-arzopa.conf}"
WOFI_STYLE="${WOFI_STYLE:-$SCRIPT_DIR/wofi-arzopa.css}"
SHIM="$SCRIPT_DIR/arzopa/arzopa-gamescope-shim.sh"
PROMPT_ICON="󰍹"

command -v python3 >/dev/null 2>&1 || { notify-send -u critical "Arzopa" "python3 no disponible"; exit 1; }
[ -f "$HELPER" ] || { notify-send -u critical "Arzopa" "falta $HELPER"; exit 1; }
[ -x "$SHIM" ] || { notify-send -u critical "Arzopa" "falta $SHIM"; exit 1; }

if [ "$#" -gt 0 ]; then
  SELECTED="$*"
else
  CHOICE=$(python3 "$HELPER" list |
    wofi --dmenu --allow-markup --cache-file /dev/null -l center \
      --conf "$WOFI_CONF" --style "$WOFI_STYLE" --columns 1 \
      --prompt "$PROMPT_ICON Arzopa · app")
  [ -z "$CHOICE" ] && exit 0
  SELECTED=$(printf '%s' "$CHOICE" | awk -F'\t' '{print $2}')
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
