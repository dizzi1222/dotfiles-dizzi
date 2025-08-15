#!/usr/bin/env bash

# Obtener URL de la carátula del reproductor activo
cover=$(playerctl metadata --format '{{mpris:artUrl}}' 2>/dev/null)

# Quitar el esquema file:// si existe
cover="${cover#file://}"

# Decodificar los caracteres %XX
cover=$(printf '%b' "${cover//%/\\x}")

# Imprimir la ruta final
echo "$cover"
