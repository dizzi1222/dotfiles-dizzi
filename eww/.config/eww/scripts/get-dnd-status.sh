#!/bin/bash
# Script: get-dnd-status.sh
# Propósito: Devuelve 'true' o 'false' para el estado del botón toggle en SwayNC.

# El comando swaync-client --get-dnd ya devuelve directamente "true" o "false",
# que es el formato exacto que SwayNC necesita para el estado del botón.

# swaync puede estar en ~/.local/bin (build desde fuente) o en /usr/bin.
SWAYNC_CLIENT="$(command -v swaync-client || echo "$HOME/.local/bin/swaync-client")"
exec "$SWAYNC_CLIENT" --get-dnd
