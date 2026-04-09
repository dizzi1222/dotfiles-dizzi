#!/bin/bash
# quickshell-kill.sh - Cierra Quickshell (on-demand)

if pgrep -f "quickshell" &>/dev/null; then
	pkill -f quickshell
	sleep 0.3
	notify-send "quickshell" "Cerrado"
else
	notify-send "quickshell" "No estaba corriendo"
fi
