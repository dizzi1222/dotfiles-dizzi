#!/bin/bash
# Devuelve el icono de DND si SwayNC O Dunst están activos, basado en su estado DND.

# Define los iconos
ICON_DND="󰂞"    # Silencio/Pausado
ICON_ACTIVE="󰂛" # Timbre/Notificación
DND_STATUS=""

# 1. Verificar si SwayNC está corriendo
if pgrep -x "swaync" >/dev/null || pgrep -x ".swaync-wrapped" >/dev/null; then
  # SwayNC activo: Obtener estado DND
  DND_STATUS=$(swaync-client --get-dnd)
elif pgrep -x "dunst" >/dev/null; then
  # SwayNC inactivo, pero Dunst activo: Obtener estado DND
  DND_STATUS=$(dunstctl is-paused)
else
  # Ningún demonio de notificaciones activo.
  echo ""
  exit 0
fi

# 2. Devolver el icono basado en el estado (DND_STATUS debe ser "true" o "false")
# El comando pgrep garantiza que el comando swaync-client/dunstctl solo se ejecuta si el demonio existe.
if [ "$DND_STATUS" = "true" ]; then
  echo "$ICON_DND"
else
  echo "$ICON_ACTIVE"
fi
