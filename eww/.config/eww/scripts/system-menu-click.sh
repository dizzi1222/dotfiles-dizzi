#!/bin/bash
# system-menu-click.sh — dispatcher del menú de sistema Eww (grid icon→texto).
# Recibe el ícono como único argumento (puede tener espacios, ej. "󰌌 󱊮") y
# delega a system_control.sh <ícono>. Cierra el menú tras la acción.
# Llamado por widgets/system-menu.yuck → system_control.sh (modo dual).
set -euo pipefail

ICON="$1"
REPO_SCRIPT="$HOME/dotfiles-dizzi/home/scripts/system_control.sh"
LIVE_SCRIPT="$HOME/scripts/system_control.sh"

# Preferir el script en vivo (~/scripts → symlink a dotfiles home/scripts)
if [ -f "$LIVE_SCRIPT" ]; then
  SCRIPT="$LIVE_SCRIPT"
elif [ -f "$REPO_SCRIPT" ]; then
  SCRIPT="$REPO_SCRIPT"
else
  notify-send "System Menu" "system_control.sh no encontrado" -t 3000
  exit 1
fi

# Cerrar el menú y ejecutar la acción
eww -c "$HOME/.config/eww" close system-menu 2>/dev/null || true
exec "$SCRIPT" "$ICON"