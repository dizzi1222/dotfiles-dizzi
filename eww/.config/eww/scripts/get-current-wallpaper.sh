#!/bin/bash

# Fuente de verdad del wallpaper actual. walset-menu/update-color guardan la
# ruta absoluta aquí (swww). Ya no se usa hyprpaper.conf.
CACHE_FILE="$HOME/.cache/wallpaper/last"

if [ -f "$CACHE_FILE" ]; then
  # Extrae el identificador del último componente tipo NN(.jpg|.png|sin ext)
  current=$(basename "$(cat "$CACHE_FILE")" 2>/dev/null)
  current="${current%.*}"
else
  # Fallback: leer del hyprpaper.conf por compatibilidad
  CONFIG_FILE="$HOME/.config/hypr/hyprpaper.conf"
  current=$(awk -F'/' '{print $NF}' "$CONFIG_FILE" 2>/dev/null | grep -oP '\d+' | head -n 1)
fi

echo "$current"