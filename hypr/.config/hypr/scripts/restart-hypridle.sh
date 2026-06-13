#!/bin/bash
pkill -9 hypridle 2>/dev/null
systemctl --user start hypridle
notify-send " Hypridle" "Iniciado" -i /home/diego/.local/share/icons/Hyprland_logo.png
