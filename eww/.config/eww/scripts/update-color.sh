##!/bin/bash
#
## Variables
#SELECTED_WALLPAPER=$1
#WALLPAPER_DIR="$HOME/wallpapers"
#
## Ensure the wallpaper exists
#if [ ! -f "$WALLPAPER_DIR/$SELECTED_WALLPAPER.jpg" ]; then
#  r echo "Error: Wallpaper not found: $SELECTED_WALLPAPER"
#  exit 1
#fi
#
## Apply pywal colors
#wal -i "$WALLPAPER_DIR/$SELECTED_WALLPAPER.jpg" || {
#  echo "Error: pywal failed"
#  exit 1
#}
#
## Reload eww
#killall eww || echo "Warning: No eww process found"
#eww open-many side-bar notifications
#
## Restart hyprpaper
#killall hyprpaper || echo "Warning: No hyprpaper process found"
#hyprpaper &
#
# 📌SI PREFIERES hyprpaper USA LO DE ARRIBA. Abajo lo mismo pero con sww.. 🚨
#!/bin/bash

SELECTED_WALLPAPER=$1
WALL_DIR="$HOME/wallpapers"
WALL_FILE="$WALL_DIR/$SELECTED_WALLPAPER.jpg"

if [ ! -f "$WALL_FILE" ]; then
  echo "Error: Wallpaper not found: $SELECTED_WALLPAPER"
  exit 1
fi

# Cambiar wallpaper con swww
swww img "$WALL_FILE" --transition-type=center --transition-fps=30 --transition-step=2

# Aplicar pywal
wal -i "$WALL_FILE"

# #1- Recargar Eww si está corriendo
# if pgrep -x eww >/dev/null; then
#   eww reload
# fi

# 📌 AMBAS FORMAS VALIDAS DE RECARGAR EWW. 🚨

# #2- Recargar Eww matando el proceso primero
killall eww 2>/dev/null || echo "Warning: No eww process found"
eww open-many side-bar notifications

# Recargar Waybar de manera eficiente
if pgrep -x waybar >/dev/null; then
  pkill -RTMIN+1 waybar
else
  waybar -c ~/.config/waybar/config &
fi
