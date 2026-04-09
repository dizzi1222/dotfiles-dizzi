#!/bin/bash
# eww-kill.sh - Cierra todos los widgets eww (on-demand)

# Verificar que eww esté instalado
if ! command -v eww &>/dev/null; then
	exit 0
fi

# Cerrar todos los widgets abiertos
eww close-all 2>/dev/null

# Opcional: matar el daemon
if [ "$1" = "--kill-daemon" ]; then
	pkill -x eww 2>/dev/null
fi
