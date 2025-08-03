#!/bin/bash

# Reproductores a ignorar
IGNORED_PLAYERS="--ignore-player=firefox,chromium"

# Obtener el estado del reproductor
PLAYER_STATUS=$(playerctl $IGNORED_PLAYERS status 2>/dev/null)

# Si no hay ningún reproductor activo o está "Stopped", enviar JSON vacío para activar format-stopped de Waybar
if [ -z "$PLAYER_STATUS" ] || [ "$PLAYER_STATUS" = "Stopped" ]; then
  echo '{"text": "", "tooltip": "No hay música reproduciéndose", "class": "mpris-inactive"}'
  exit 0
fi

# Si llegamos aquí, hay un reproductor en "Playing" o "Paused".
PLAYER_METADATA=$(playerctl $IGNORED_PLAYERS metadata --format "{{ title }}|{{ artist }}|{{ album }}|{{ status }}" 2>/dev/null) # <-- Eliminado mpris:artUrl

if [ -z "$PLAYER_METADATA" ]; then
  echo '{"text": "", "tooltip": "Error al obtener metadatos, pero el reproductor está activo.", "class": "mpris-inactive"}'
  exit 0
fi

IFS='|' read -r TITLE ARTIST ALBUM CURRENT_STATUS <<<"$PLAYER_METADATA" # <-- Eliminado ART_URL

TITLE=$(echo "$TITLE" | sed 's/"/\\"/g')
ARTIST=$(echo "$ARTIST" | sed 's/"/\\"/g')
ALBUM=$(echo "$ALBUM" | sed 's/"/\\"/g')

if [ "$CURRENT_STATUS" = "Playing" ]; then
  STATUS_ICON="▶"
elif [ "$CURRENT_STATUS" = "Paused" ]; then
  STATUS_ICON="⏸"
else
  STATUS_ICON="♪♩" # Tu icono para estados no Play/Pause/Stop
fi

# Formato para el tooltip (usando CURRENT_STATUS)
TOOLTIP_TEXT="<b>${TITLE}</b>\n<i>${ARTIST}</i>\nAlbum: ${ALBUM}\nEstado: ${STATUS_ICON} ${CURRENT_STATUS}\n\n"
TOOLTIP_TEXT+="<span size='medium' foreground='#88c0d0'> backward</span> <span size='medium' foreground='#81a1c1'>${STATUS_ICON}</span> <span size='medium' foreground='#b48ead'> forward</span>"

# Aquí el texto ya NO incluye la etiqueta <img> de la carátula.
echo "{\"text\": \"${STATUS_ICON} ${TITLE}\", \"tooltip\": \"${TOOLTIP_TEXT}\", \"class\": \"mpris-active ${CURRENT_STATUS}\"}"

exit 0
