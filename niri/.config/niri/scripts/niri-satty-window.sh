#!/bin/bash
# niri-satty-region.sh - Captura región seleccionada

f=$HOME/Escritorio/satty-$(date '+%Y%m%d-%H%M%S').png
slurp | grim -g - -t ppm - | satty --filename - \
  --output-filename "$f"
