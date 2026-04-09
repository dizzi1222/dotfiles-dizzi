#!/bin/bash
# color-picker.sh - Selector de color (on-demand)
# Usa la herramienta apropiada según el compositor

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
hyprland)
	if command -v hyprpicker &>/dev/null; then
		hyprpicker -a -n
	else
		notify-send "hyprpicker" "No instalado. Instala: yay -S hyprpicker"
	fi
	;;
plasma)
	if command -v kcolorchooser &>/dev/null; then
		kcolorchooser --print | xclip -selection clipboard
		notify-send "Color copiado" "$(kcolorchooser --print)"
	elif command -v spectacle &>/dev/null; then
		spectacle -r -n -b
	else
		notify-send "Color picker" "Instala kcolorchooser: pacman -S kcolorchooser"
	fi
	;;
sway | niri)
	if command -v hyprpicker &>/dev/null; then
		hyprpicker -a -n
	else
		notify-send "color picker" "Instala hyprpicker"
	fi
	;;
*)
	notify-send "color picker" "Compositor no soportado"
	;;
esac
