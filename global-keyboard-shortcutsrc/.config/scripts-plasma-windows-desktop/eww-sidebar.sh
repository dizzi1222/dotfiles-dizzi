#!/bin/bash
# eww-sidebar.sh - Toggle sidebar de eww (on-demand)

if ! command -v eww &>/dev/null; then
	notify-send "eww" "No está instalado. Instala: yay -S eww"
	exit 1
fi

# Asegurar que el daemon de eww esté corriendo
if ! pgrep -x eww &>/dev/null; then
	eww daemon
	sleep 0.5
fi

# Toggle sidebar
if eww active-windows 2>/dev/null | grep -q "side-bar"; then
	eww close side-bar
else
	eww open side-bar
fi
