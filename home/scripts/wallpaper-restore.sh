#!/bin/bash
#######################################################################################
# Configs DIZZI - Wallpaper Restore (silent, no GUI)
# Restaura el último wallpaper al iniciar Hyprland.
# Detecta swww (preferido) o hyprpaper, corre pywal, recarga waybar/eww.
#######################################################################################

WALL_DIR="$HOME/wallpapers/wallpapers/wallpapers/"
CACHE_DIR="$HOME/.cache/wallpaper"
LAST_FILE="$CACHE_DIR/last"

mkdir -p "$CACHE_DIR"

# Leer último wallpaper guardado por walset-menu
if [ -f "$LAST_FILE" ] && [ -s "$LAST_FILE" ]; then
  WALLPAPER=$(cat "$LAST_FILE")
else
  # Primer inicio — tomar el primer wallpaper disponible
  WALLPAPER=$(find "$WALL_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' \) | sort | head -1)
  [ -z "$WALLPAPER" ] && { notify-send "❌ No wallpapers found" "WALL_DIR: $WALL_DIR"; exit 1; }
  echo "$WALLPAPER" > "$LAST_FILE"
fi

# Esperar a que swww-daemon esté listo (lo inició exec-once antes)
if command -v swww >/dev/null 2>&1; then
  for i in $(seq 1 10); do
    swww query 2>/dev/null && break
    sleep 0.5
  done
  swww img "$WALLPAPER" --transition-type none --transition-fps 60
elif command -v hyprpaper >/dev/null 2>&1; then
  hyprctl hyprpaper wallpaper ",$WALLPAPER" 2>/dev/null || true
fi

# Pywal (silencioso)
wal -q -i "$WALLPAPER" 2>/dev/null || true

# Recargar waybar (si está corriendo)
if pgrep -x waybar >/dev/null; then
  pkill -9 waybar 2>/dev/null
  waybar -c ~/.config/waybar/config &>/dev/null &
fi

# Recargar eww (si está corriendo)
if pgrep -x eww >/dev/null; then
  eww reload 2>/dev/null
fi

# Recargar swaync
swaync-client -rs 2>/dev/null || true
