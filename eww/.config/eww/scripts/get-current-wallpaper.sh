#!/bin/bash

CONFIG_FILE=~/.config/hypr/hyprpaper.conf

# Extraer solo el nombre del archivo sin extensión
wallpaper=$(grep 'wallpaper =' "$CONFIG_FILE" | awk -F'/' '{print $NF}' | sed -E 's/\.[a-zA-Z0-9]+$//')

echo "$wallpaper"
