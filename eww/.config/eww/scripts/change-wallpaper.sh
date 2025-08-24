#!/bin/bash
SELECTED_WALLPAPER=$1
WALLPAPER_DIR="$HOME/wallpapers"

# Buscar el archivo real (puede ser .jpg o .png, pero sin "preview-")
REAL_WALLPAPER=$(ls "$WALLPAPER_DIR"/"$SELECTED_WALLPAPER".* 2>/dev/null | head -n 1)

if [ -f "$REAL_WALLPAPER" ]; then
  SYMLINK_CONFIG_FILE="$HOME/.config/hypr/hyprpaper.conf"
  SYMLINK_LOCK_CONFIG="$HOME/.config/hypr/hyprlock.conf"
  TARGET_FILE=$(readlink -f "$SYMLINK_CONFIG_FILE")
  TARGET_FILE2=$(readlink -f "$SYMLINK_LOCK_CONFIG")

  sed -i -e "s|preload = .*|preload = $REAL_WALLPAPER|" \
    -e "s|wallpaper = ,.*|wallpaper = ,$REAL_WALLPAPER|" "$TARGET_FILE"
  sed -i -e "s|path = .*|path = $REAL_WALLPAPER|" "$TARGET_FILE2"

  ~/.config/eww/scripts/update-color.sh "$REAL_WALLPAPER"
else
  echo "Wallpaper not found: $SELECTED_WALLPAPER"
fi
