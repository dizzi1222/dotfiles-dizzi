#!/usr/bin/env bash
# arzopa-menu.sh — menú único para las opciones de la Arzopa.
# Un solo icono en system-control; adentro están las dos vías.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
WOFI_CONF="${WOFI_CONF:-$SCRIPT_DIR/wofi-arzopa.conf}"
WOFI_STYLE="${WOFI_STYLE:-$SCRIPT_DIR/wofi-arzopa.css}"

if loginctl seat-status seat-arzopa 2>/dev/null | grep -q 'AT Translated Set 2 keyboard'; then
  KB_ENTRY="󰌌 Teclado → Laptop"
else
  KB_ENTRY="󰌌 Teclado → Arzopa"
fi

CHOICE=$(printf '%s\n' \
  "󰍹 Abrir app en Arzopa" \
  "󰍹 Zen en Arzopa (Game Mode)" \
  "󰕮 Zen → Arzopa (Desktop Mode)" \
  "$KB_ENTRY" |
  wofi --dmenu --cache-file /dev/null -l center \
    --conf "$WOFI_CONF" --style "$WOFI_STYLE" --columns 1 \
    --prompt "󰍹 Arzopa")

case "$CHOICE" in
  *"Abrir app"*) "$SCRIPT_DIR/arzopa-launcher.sh" ;;
  *"Game Mode"*)
    kitty -e bash -c 'env -u TERMINFO sudo "'"$SCRIPT_DIR"'/setup-via-a-arzopa.sh" && env -u TERMINFO sudo /usr/local/bin/arzopa-attach --keyboard && systemctl --user restart arzopa-gamemode.service; read -p "Enter para cerrar..."'
    ;;
  *"Desktop"*) "$SCRIPT_DIR/zen-to-arzopa.sh" ;;
  *"Teclado → Laptop"*)
    env -u TERMINFO sudo -n /usr/local/bin/arzopa-detach --keyboard-only &&
      notify-send -a "Arzopa" "󰌌 Teclado en la laptop" "seat0 · Steam y KDE recuperan el teclado"
    ;;
  *"Teclado → Arzopa"*)
    env -u TERMINFO sudo -n /usr/local/bin/arzopa-attach --keyboard-only &&
      notify-send -a "Arzopa" "󰌌 Teclado en la Arzopa" "seat-arzopa · solo apps de la Arzopa"
    ;;
  *) exit 0 ;;
esac
