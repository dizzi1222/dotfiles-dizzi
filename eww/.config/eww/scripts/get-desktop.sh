#!/bin/bash
# ~/.config/eww/scripts/get-desktop.sh
# Detecta el escritorio/WM actual: hyprland | niri | plasma | cinnamon | gnome | unknown

if [ -n "$NIRI_SOCKET" ] || pgrep -x "niri" >/dev/null 2>&1; then
    echo "niri"
elif [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ] || pgrep -x "Hyprland" >/dev/null 2>&1; then
    echo "hyprland"
elif pgrep -x "plasmashell" >/dev/null 2>&1; then
    echo "plasma"
elif pgrep -x "cinnamon" >/dev/null 2>&1; then
    echo "cinnamon"
elif pgrep -x "gnome-shell" >/dev/null 2>&1; then
    echo "gnome"
else
    echo "unknown"
fi