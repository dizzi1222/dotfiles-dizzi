#!/bin/bash
# Cross-WM Zoom Menu (Hyprland + Niri)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/platform.sh"

MONITOR="eDP-1"
LAUNCHER="wofi --show dmenu -i --prompt Zoom-Level"

OPTIONS="\
0.5 | 󰛐  Zoom Out Máximo
0.7 | 󰡨  Zoom Out Fuerte
0.8 | 󰍶  Zoom Out Medio
0.9 |   Zoom Out Suave
1.0 | 󰝳  Restablecer (Normal)
1.2 |   Zoom In Leve
1.5 |   Zoom In Suave
2.0 |   Zoom In Medio (Acercar)
2.5 | 󰻿  Zoom In Fuerte
3.0 | 󱍄  Zoom In Extremo"

CHOICE=$(echo -e "$OPTIONS" | $LAUNCHER | awk '{print $1}')

if [ -n "$CHOICE" ]; then
  SCALE=$(echo "$CHOICE" | awk '{print $1}')

  wm_monitor_scale "$MONITOR" "$SCALE"

  echo "$SCALE" >~/.cache/zoom_menu_last_scale
  notify-send " Zoom: $SCALE" "Escala aplicada a $MONITOR"
fi
