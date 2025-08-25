#!/bin/bash

# File path to the hyprpaper.conf
CONFIG_FILE=~/.config/hypr/hyprpaper.conf

# Extract the wallpaper number using awk and grep
wallpaper=$(awk -F'/' '{print $NF}' "$CONFIG_FILE" | grep -oP '\d+' | head -n 1)

# Output the wallpaper number
echo "$wallpaper"

# 📌SI PREFIERES hyprpaper USA LO DE ARRIBA. Abajo lo mismo pero con sww.. 🚨
