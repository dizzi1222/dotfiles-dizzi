#!/bin/bash

# Variables
SELECTED_WALLPAPER=$1
WALLPAPER_DIR="$HOME/wallpapers/wallpapers"

# Ensure the wallpaper exists
if [ ! -f "$WALLPAPER_DIR/$SELECTED_WALLPAPER.jpg" ]; then
  echo "Error: Wallpaper not found: $WALLPAPER_DIR/$SELECTED_WALLPAPER.jpg"
  exit 1
fi

WALL_FILE="$WALLPAPER_DIR/$SELECTED_WALLPAPER.jpg"

# Aplicar pywal
wal -i "$WALL_FILE" || {
  echo "Error: pywal failed"
  exit 1
}

# Cambiar wallpaper con swww (compatible con walset-menu / GIFs).
# swww y hyprpaper NO pueden correr a la vez; aquí usamos swww.
if pgrep -x swww-daemon >/dev/null; then
  swww img "$WALL_FILE" --transition-type=center --transition-fps=30 --transition-step=2
else
  swww-daemon &
  sleep 1
  swww img "$WALL_FILE" --transition-type=center --transition-fps=30 --transition-step=2
fi

# Recargar Eww (matando y reabriendo para aplicar colores)
pkill eww 2>/dev/null || echo "Warning: No eww process found"
eww reload 2>/dev/null || true

# Actualizar hyprlock con la misma imagen
if [ -f "$HOME/.config/hypr/hyprlock.conf" ]; then
  sed -i -e "s|path = .*|path = \$HOME/wallpapers/wallpapers/$SELECTED_WALLPAPER.jpg|" \
    "$HOME/.config/hypr/hyprlock.conf" 2>/dev/null || true
fi

# Quickshell/quickshell: recargar si está activo
if pgrep -x quickshell >/dev/null; then
  quickshell --reload 2>/dev/null || true
fi