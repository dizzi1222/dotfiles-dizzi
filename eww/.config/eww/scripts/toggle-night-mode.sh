# ~/.config/eww/scripts/toggle-night-mode.sh

TEMP_NORMAL=6500
TEMP_NIGHT=3500
NIGHT_MODE_FILE="/tmp/night_mode_active"

case "$1" in
"status")
  if [ -f "$NIGHT_MODE_FILE" ]; then
    echo "true"
  else
    echo "false"
  fi
  ;;
*)
  if [ -f "$NIGHT_MODE_FILE" ]; then
    # Desactivar modo noche: restaurar temperatura normal
    pkill -x hyprsunset 2>/dev/null
    hyprsunset -t "$TEMP_NORMAL" >/dev/null 2>&1 &
    rm -f "$NIGHT_MODE_FILE"
    if [[ command -v niri >/dev/null ]]; then
      pkill -x wlsunset 2>/dev/null
      rm -f "$NIGHT_MODE_FILE"
    fi
  else
    # Activar modo noche: usar temperatura cálida
    pkill -x hyprsunset 2>/dev/null
    nohup hyprsunset -t "$TEMP_NIGHT" >/dev/null 2>&1 &
    touch "$NIGHT_MODE_FILE"
    if [[ command -v niri >/dev/null ]]; then
    # Activar modo noche
      pkill -x wlsunset 2>/dev/null
      wlsunset -T $TEMP_NIGHT &
      touch "$NIGHT_MODE_FILE"
    fi
  fi
  ;;
esac
