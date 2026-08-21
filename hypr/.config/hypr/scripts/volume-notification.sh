#!/bin/bash
# Script de notificación de volumen en tiempo real con SwayNC
# Optimizado para tu sistema - VERSION CORREGIDA
# Uso: volume-notification.sh [up|down|mute]

TIMEOUT=2000

get_volume() {
  pamixer --get-volume
}

get_mute_status() {
  pamixer --get-mute
}

send_notification() {
  local volume=$1
  local muted=$2

  if [ "$muted" == "true" ]; then
    icon="audio-volume-muted"
    text="Muted"
    notify-send -t $TIMEOUT -h string:x-canonical-private-synchronous:volume \
      -h int:value:0 -i "$icon" "Volume" "$text"
  else
    if [ "$volume" -eq 0 ]; then
      icon="audio-volume-muted"
    elif [ "$volume" -lt 33 ]; then
      icon="audio-volume-low"
    elif [ "$volume" -lt 66 ]; then
      icon="audio-volume-medium"
    else
      icon="audio-volume-high"
    fi

    notify-send -t $TIMEOUT -h string:x-canonical-private-synchronous:volume \
      -h int:value:"$volume" -i "$icon" "Volume" "${volume}%"
  fi
}

case "$1" in
up)
  pamixer --allow-boost -i 5 # Permite superar 100%

  VOLUME=$(get_volume)
  MUTED=$(get_mute_status)
  send_notification "$VOLUME" "$MUTED"
  ;;
down)
  pamixer --allow-boost -d 5 # Mantén la flag para consistencia

  VOLUME=$(get_volume)
  MUTED=$(get_mute_status)
  send_notification "$VOLUME" "$MUTED"
  ;;
mute)
  # FIX: Obtener el estado ANTES de cambiar
  CURRENT_MUTE=$(get_mute_status)

  # Cambiar el estado
  pamixer -t

  # Pequeña pausa para asegurar que el cambio se aplicó
  sleep 0.05

  # Obtener el nuevo estado
  VOLUME=$(get_volume)
  MUTED=$(get_mute_status)

  # Enviar notificación con el nuevo estado
  send_notification "$VOLUME" "$MUTED"
  ;;
*)
  echo "Uso: $0 [up|down|mute]"
  exit 1
  ;;
esac
