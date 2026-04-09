#!/bin/bash
# quickshell-launch.sh - Lanza Quickshell (on-demand)

if ! command -v quickshell &>/dev/null; then
	notify-send "quickshell" "No está instalado. Instala: yay -S quickshell"
	exit 1
fi

# Ya está corriendo?
if pgrep -f "quickshell" &>/dev/null; then
	notify-send "quickshell" "Ya está corriendo"
	exit 0
fi

# Iniciar en background
nohup quickshell >/dev/null 2>&1 &
sleep 0.5
notify-send "quickshell" "Iniciado"
