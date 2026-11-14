#!/usr/bin/env bash
# arzopa-menu.sh — menú único para las opciones de la Arzopa.
# Un solo icono en system-control; adentro están las dos vías.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
WOFI_CONF="${WOFI_CONF:-$HOME/.config/wofi/system-control.conf}"
WOFI_STYLE="${WOFI_STYLE:-$HOME/.config/wofi/system-control.css}"

CHOICE=$(printf '%s\n' \
  "󰓓 Abrir app en Arzopa" \
  "󰍹 Zen en Arzopa (Game Mode)" \
  "󰕮 Zen → Arzopa (Desktop Mode)" |
  wofi --dmenu --cache-file /dev/null -l center \
    --conf "$WOFI_CONF" --style "$WOFI_STYLE" --columns 1 \
    --prompt "󰓓 Arzopa")

case "$CHOICE" in
  *"Abrir app"*) "$SCRIPT_DIR/arzopa-launcher.sh" ;;
  *"Game Mode"*)
    kitty -e bash -c 'sudo "'"$SCRIPT_DIR"'/setup-via-a-arzopa.sh" && sudo /usr/local/bin/arzopa-attach && systemctl --user restart arzopa-gamemode.service; read -p "Enter para cerrar..."'
    ;;
  *"Desktop"*) "$SCRIPT_DIR/zen-to-arzopa.sh" ;;
  *) exit 0 ;;
esac
