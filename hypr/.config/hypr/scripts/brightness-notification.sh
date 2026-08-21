#!/bin/bash
# Script de notificación de brillo para Intel backlight
# Optimizado para tu Dell con intel_backlight
# Uso: brightness-notification.sh [up|down|set VALUE]

TIMEOUT=2000
DEVICE="intel_backlight"

get_brightness() {
  brightnessctl -d "$DEVICE" get | awk -v max="$(brightnessctl -d "$DEVICE" max)" '{print int(($1/max)*100)}'
}

send_notification() {
  local brightness=$1

  if [ "$brightness" -eq 0 ]; then
    icon="display-brightness-off-symbolic"
  elif [ "$brightness" -lt 33 ]; then
    icon="display-brightness-low-symbolic"
  elif [ "$brightness" -lt 66 ]; then
    icon="display-brightness-medium-symbolic"
  else
    icon="display-brightness-high-symbolic"
  fi

  notify-send -t $TIMEOUT -h string:x-canonical-private-synchronous:brightness \
    -h int:value:"$brightness" -i "$icon" "Brightness" "${brightness}%"
}

case "$1" in
up)
  brightnessctl -d "$DEVICE" set +10%
  ;;
down)
  brightnessctl -d "$DEVICE" set 10%-
  ;;
set)
  if [ -z "$2" ]; then
    echo "Uso: $0 set VALUE"
    exit 1
  fi
  brightnessctl -d "$DEVICE" set "$2%"
  ;;
*)
  echo "Uso: $0 [up|down|set VALUE]"
  exit 1
  ;;
esac

BRIGHTNESS=$(get_brightness)
send_notification "$BRIGHTNESS"
