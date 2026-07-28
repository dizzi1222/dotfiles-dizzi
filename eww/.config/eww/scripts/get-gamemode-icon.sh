#!/bin/bash
# ~/.config/eww/scripts/get-gamemode-icon.sh

# Archivo de estado para game mode
GAME_MODE_FILE="/tmp/hypr_game_mode"

if [ -f "$GAME_MODE_FILE" ]; then
    # Game mode activo - rotación basada en tiempo
    INDEX=$(( $(date +%s) / 30 % 5 ))  # Cambia cada 30 segundos entre 5 iconos
    
    if [ $INDEX -eq 0 ]; then
        echo ""
    elif [ $INDEX -eq 1 ]; then
        echo ""
    elif [ $INDEX -eq 2 ]; then
        echo "󰖫" 
    elif [ $INDEX -eq 3 ]; then
        echo "󰐔"
    else
        echo "󰊗"
    fi
else
    # Game mode inactivo
    echo "󰊵"
fi
