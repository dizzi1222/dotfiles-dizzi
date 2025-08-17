#!/bin/bash
# Espera un poco para que la ventana de VLC se estabilice
sleep 0.5
# Redimensiona la ventana activa a 200x200 y la centra
hyprctl dispatch exactsize 200 200, dispatch centerwindow
