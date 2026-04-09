#!/bin/bash
# eww-launch.sh - Lanza barra de widgets eww (on-demand)
# Funciona en Hyprland, Niri y otros Wayland compositors

# Verificar que eww esté instalado
if ! command -v eww &>/dev/null; then
	notify-send "eww" "No está instalado. Instala: yay -S eww"
	exit 1
fi

# Detectar compositor actual
detect_compositor() {
	if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
		echo "hyprland"
	elif pgrep -x niri &>/dev/null; then
		echo "niri"
	elif pgrep -x sway &>/dev/null; then
		echo "sway"
	else
		echo "unknown"
	fi
}

compositor=$(detect_compositor)

# Asegurar que el daemon de eww esté corriendo
if ! pgrep -x eww &>/dev/null; then
	eww daemon
	sleep 0.5
fi

# Verificar que el daemon esté realmente corriendo
if pgrep -x eww &>/dev/null; then
	eww open bar
else
	notify-send "eww" "Error al iniciar el daemon"
fi
