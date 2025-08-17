#!/usr/bin/env bash

# Forzar salida consistente en inglés
export LC_ALL=C
export LANG=C

# Obtener URL de la carátula del reproductor activo
cover=$(playerctl metadata --format '{{mpris:artUrl}}' 2>/dev/null)

# Obtener el título de la canción del reproductor activo
title=$(playerctl metadata --format '{{title}}' 2>/dev/null)

# Obtener la posición de la canción en segundos y la duración en microsegundos
position=$(playerctl position 2>/dev/null)
length_microseconds=$(playerctl metadata --format "{{mpris:length}}" 2>/dev/null)

# Quitar el esquema file:// si existe
cover="${cover#file://}"

# Decodificar los caracteres %XX
cover=$(printf '%b' "${cover//%/\\x}")

# Calcular el porcentaje de progreso (usando bc para manejar decimales)
percentage=$(echo "scale=2; ($position / ($length_microseconds / 1000000)) * 100" | bc 2>/dev/null)

# Imprimir la ruta final y el título, separados por un '|'
# Si la carátula o el título no existen, la cadena estará vacía.
echo "$cover"

