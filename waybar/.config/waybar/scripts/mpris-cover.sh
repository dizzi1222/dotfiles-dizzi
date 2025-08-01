#!/bin/bash

# Directorio donde se guardarán las carátulas (asegúrate de que exista y sea escribible)
COVER_CACHE_DIR="/tmp/waybar-mpris-covers"
mkdir -p "$COVER_CACHE_DIR" # Asegura que el directorio exista

# Limpia el caché si está muy lleno o es viejo (opcional, pero bueno para depurar)
# find "$COVER_CACHE_DIR" -maxdepth 1 -mtime +7 -delete 2>/dev/null # Borra archivos de más de 7 días

COVER_SIZE="40" # width for album art in px

# Redirige stderr a /dev/null para evitar que mensajes de error rompan el JSON
PLAYER_STATUS=$(playerctl status 2>/dev/null)
PLAYER_METADATA=$(playerctl metadata --format "{{ title }}|{{ artist }}|{{ album }}|{{ mpris:artUrl }}|{{ status }}" 2>/dev/null)

# Mensaje de depuración: Si playerctl no encuentra nada
if [ -z "$PLAYER_METADATA" ]; then
  echo '{"text": "", "tooltip": "No hay música reproduciéndose o playerctl no encontró nada", "class": "mpris-inactive"}'
  exit 0
fi

IFS='|' read -r TITLE ARTIST ALBUM ART_URL STATUS <<<"$PLAYER_METADATA"

TITLE=$(echo "$TITLE" | sed 's/"/\\"/g')
ARTIST=$(echo "$ARTIST" | sed 's/"/\\"/g')
ALBUM=$(echo "$ALBUM" | sed 's/"/\\"/g')

if [ "$STATUS" = "Playing" ]; then
  STATUS_ICON="▶"
elif [ "$STATUS" = "Paused" ]; then
  STATUS_ICON="⏸"
else
  STATUS_ICON="?"
fi

# --- MANEJO DE LA CARÁTULA DEL ÁLBUM (MODIFICADO) ---
COVER_PATH_FINAL="" # Esta será la ruta final en nuestro caché de Waybar
if [[ -n "$ART_URL" ]]; then
  # Eliminar el prefijo "file://" si existe para obtener la ruta del archivo
  CLEAN_ART_URL=$(echo "$ART_URL" | sed 's|^file://||')

  # Generar un hash para el nombre del archivo en caché
  COVER_HASH=$(echo "$ART_URL" | md5sum | awk '{print $1}')
  COVER_PATH_FINAL="${COVER_CACHE_DIR}/${COVER_HASH}.jpg" # Usamos .jpg por defecto, puedes adaptarlo

  # Si el archivo de la carátula ya está en nuestro caché, lo usamos
  if [ -f "$COVER_PATH_FINAL" ]; then
    : # No hacemos nada, ya existe
  # Si es una URL HTTP(S), la descargamos a nuestro caché
  elif [[ "$ART_URL" == http* ]]; then
    wget -q -O "$COVER_PATH_FINAL" --timeout=5 "$ART_URL" 2>/dev/null
    if [ $? -ne 0 ]; then
      COVER_PATH_FINAL="" # Descarga fallida
    fi
  # Si es una ruta de archivo local proporcionada por playerctl, LA COPIAMOS a nuestro caché
  elif [[ -f "$CLEAN_ART_URL" ]]; then
    cp -f "$CLEAN_ART_URL" "$COVER_PATH_FINAL" 2>/dev/null # Copiar, sobreescribir si ya existe
    if [ $? -ne 0 ]; then
      COVER_PATH_FINAL="" # Copia fallida
    fi
  else
    # Si ART_URL no es una URL web ni un archivo local existente que podamos copiar
    COVER_PATH_FINAL=""
  fi
fi

# Prepara el formato de la carátula para Waybar.
# Usamos COVER_PATH_FINAL para el src de la imagen
if [[ -n "$COVER_PATH_FINAL" && -f "$COVER_PATH_FINAL" ]]; then # Verifica que el archivo exista realmente
  ICON_COVER="<img height='${COVER_SIZE}' width='${COVER_SIZE}' src='${COVER_PATH_FINAL}'/>"
else
  ICON_COVER="🎜" # Icono de música de Nerd Fonts si no hay carátula
fi

# Formato para el tooltip (resto del script sin cambios)
TOOLTIP_TEXT="<b>${TITLE}</b>\n<i>${ARTIST}</i>\nAlbum: ${ALBUM}\nEstado: ${STATUS_ICON} ${STATUS}\n\n"
TOOLTIP_TEXT+="<span size='medium' foreground='#88c0d0'> backward</span> <span size='medium' foreground='#81a1c1'>${STATUS_ICON}</span> <span size='medium' foreground='#b48ead'> forward</span>"

echo "{\"text\": \"${ICON_COVER} ${STATUS_ICON} ${TITLE}\", \"tooltip\": \"${TOOLTIP_TEXT}\", \"class\": \"mpris-active ${STATUS}\"}"

exit 0
