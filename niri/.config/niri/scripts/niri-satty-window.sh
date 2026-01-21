#!/bin/bash
# niri-satty-region.sh - Captura región seleccionada

slurp | grim -g - -t ppm - | satty --filename - \
  --output-filename ~/Pictures/Screenshots/satty-$(date '+%Y%m%d-%H%M%S').png
