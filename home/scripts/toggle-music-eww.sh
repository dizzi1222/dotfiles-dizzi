#!/bin/bash

pkill eww
APP_PROCESS="kew"

if pgrep -x "$APP_PROCESS" >/dev/null; then
  echo "kew ya está en ejecución. Alternando visibilidad."
  caelestia toggle music
else
  echo "kew no está en ejecución. Iniciando..."

  # 1. Lanza kew PRIMERO (en el workspace actual, lo que sea)
  kitty --single-instance -e "$APP_PROCESS" &
  KITTY_PID=$!

  # 2. Espera a que la ventana se cree
  for i in {1..20}; do
    # Busca la ventana de kitty con kew en el título
    WINDOW_ADDR=$(hyprctl clients -j | jq -r '.[] | select(.title | contains("kew")) | .address')

    if [ -n "$WINDOW_ADDR" ]; then
      echo "Ventana detectada: $WINDOW_ADDR"

      # 3. Mueve esa ventana específica al workspace special:music
      hyprctl dispatch movetoworkspacesilent special:music,address:$WINDOW_ADDR

      # 4. Ahora SÍ muestra el workspace
      sleep 0.2
      hyprctl dispatch togglespecialworkspace music

      echo "kew movido a workspace music"
      # Para actualizar el widget de device [eww device impide que se mueva la ventana]
      sh ~/scripts/launch_widgets.sh
      eww update device-control-reveal=true
      exit 0
    fi

    sleep 0.1
  done

  echo "Error: No se detectó la ventana de kew en 2 segundos"
fi

exit 0
