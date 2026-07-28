#!/bin/bash

# Cerrar swaync completamente
swaync-client -cp

# Pausa
sleep 0.3

# Abrir bluetuith (TUI de bluetooth) en kitty flotante
if hyprctl clients | grep -q "class: bluetooth"; then
  hyprctl dispatch focuswindow "class:bluetooth"
else
  hyprctl dispatch exec "[float; size 525 260; center; pin] kitty --class bluetooth bluetuith"
  sleep 0.5
  hyprctl dispatch focuswindow "class:bluetooth"
fi
