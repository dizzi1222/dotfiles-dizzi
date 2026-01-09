#!/bin/bash
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

  # Guardar IDs de ventanas activas por workspace
  WINDOWS=$(hyprctl clients -j | jq -r '.[] | "\(.workspace.id):\(.address)"')

  # Aplicar scale
  hyprctl keyword monitor "$MONITOR,preferred,auto,$SCALE"
  sleep 0.3

  # Para cada ventana, forzar refocus en su workspace
  echo "$WINDOWS" | while IFS=: read -r ws_id win_addr; do
    hyprctl dispatch focuswindow "address:$win_addr" 2>/dev/null
  done

  # Volver al workspace original
  CURRENT_WS=$(hyprctl activeworkspace -j | jq -r '.id')
  hyprctl dispatch workspace "$CURRENT_WS"

  echo "$SCALE" >~/.config/hypr/last_scale
  notify-send " Zoom: $SCALE" "Ventanas restauradas"
fi
