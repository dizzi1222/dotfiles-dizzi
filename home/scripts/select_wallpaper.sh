#!/bin/bash

# #######################################################################################
# CONFIG de ZENITIES- THEMES - hayyaoe
# #######################################################################################

NORMALIZE="$HOME/scripts/normalize_wallpaper.sh"
WINDOW_NAME="wallpaper"

# Check if the window is open
if eww active-windows | grep -q "$WINDOW_NAME"; then
  # If open, close it
  eww close "$WINDOW_NAME"
else
  # Regenerar previews faltantes antes de abrir (patron zenities 5 meses atras)
  if [ -f "$NORMALIZE" ]; then
    bash "$NORMALIZE" >/dev/null 2>&1
  fi
  # If not open, open it
  eww open "$WINDOW_NAME"
fi
