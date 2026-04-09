#!/bin/bash
# swaync-toggle.sh - Toggle notification center (on-demand)
# Detecta compositor y usa el sistema de notificaciones apropiado

detect_compositor() {
	if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
		echo "hyprland"
	elif pgrep -x niri &>/dev/null; then
		echo "niri"
	elif pgrep -x plasmashell &>/dev/null || pgrep -x kwin_wayland &>/dev/null; then
		echo "plasma"
	elif pgrep -x sway &>/dev/null; then
		echo "sway"
	else
		echo "unknown"
	fi
}

compositor=$(detect_compositor)

case "$compositor" in
plasma)
	# Plasma tiene sus propias notificaciones, usar notify-send
	if pgrep -x swaync &>/dev/null; then
		swaync-client -t
	else
		notify-send "Notificaciones" "Usa el panel de Plasma para notificaciones"
	fi
	;;
hyprland | niri | sway)
	# Swaync funciona con estos compositors
	if ! command -v swaync &>/dev/null; then
		notify-send "swaync" "No está instalado. Instala: yay -S swaync"
		exit 1
	fi

	if pgrep -x swaync &>/dev/null; then
		swaync-client -t
	else
		swaync &
		sleep 0.5
		swaync-client -t
	fi
	;;
*)
	notify-send "swaync" "Compositor no soportado: $compositor"
	;;
esac
