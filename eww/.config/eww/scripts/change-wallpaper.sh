#!/bin/bash
# Get the wallpaper filename passed as an argument
SELECTED_WALLPAPER=$1
WALLPAPER_DIR="$HOME/wallpapers/wallpapers"

# Ensure the wallpaper file exists
if [ -f "$WALLPAPER_DIR/$SELECTED_WALLPAPER.jpg" ]; then
  # Actualizar hyprlock con la imagen seleccionada (path del lock)
  SYMLINK_LOCK_CONFIG="$HOME/.config/hypr/hyprlock.conf"
  TARGET_FILE2=$(readlink -f "$SYMLINK_LOCK_CONFIG")
  sed -i -e "s|path = .*|path = \$HOME/wallpapers/wallpapers/$SELECTED_WALLPAPER.jpg|" "$TARGET_FILE2" 2>/dev/null || true

  # Aplicar el wallpaper con swww (NO hyprpaper — swww es compatible con
  # walset-menu / GIFs; ambos daemons no pueden correr a la vez).
  ~/.config/eww/scripts/update-color.sh "$SELECTED_WALLPAPER"
else
  echo "Wallpaper not found: $WALLPAPER_DIR/$SELECTED_WALLPAPER.jpg"
fi