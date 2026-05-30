#!/bin/bash
# niri-satty-fullscreen.sh - Captura pantalla completa

f=$HOME/Escritorio/satty-$(date '+%Y%m%d-%H%M%S').png
grim -t ppm - | satty --filename - \
  --output-filename "$f"
