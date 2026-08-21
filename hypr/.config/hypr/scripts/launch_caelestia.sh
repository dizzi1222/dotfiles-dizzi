#!/usr/bin/env bash
pkill -f swww-daemon
pkill -f hyprpaper
# Verificar si quickshell ya está corriendo
if ! pgrep -f "quickshell -c caelestia" >/dev/null; then
  quickshell -c caelestia
fi
exit 0 # <- opcional, solo deja claro que terminó
