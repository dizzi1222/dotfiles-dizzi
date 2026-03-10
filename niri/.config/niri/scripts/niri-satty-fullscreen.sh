#!/bin/bash
# niri-satty-fullscreen.sh - Captura pantalla completa

grim -t ppm - | satty --filename - \
  --output-filename ~/Pictures/Screenshots/satty-$(date '+%Y%m%d-%H%M%S').png
