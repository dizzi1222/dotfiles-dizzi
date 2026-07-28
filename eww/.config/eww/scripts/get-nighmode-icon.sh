#!/bin/bash
# ~/.config/eww/scripts/get-nightmode-icon.sh

# Archivo de estado para night mode
NIGHT_MODE_FILE="/tmp/night_mode_active"

# Devolver el icono correspondiente
if [ -f "$NIGHT_MODE_FILE" ]; then
  # Night mode activo - icono de luna
  echo ""
else
  # Night mode inactivo - icono de sol
  echo ""
fi
