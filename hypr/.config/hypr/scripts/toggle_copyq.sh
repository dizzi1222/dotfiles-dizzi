#!/bin/bash
# ~/.config/hypr/scripts/delayed_copyq.sh
copyq
sleep 2
pkill copyq
# Esperar a que Hyprland esté completamente inicializado
sleep 4

# Establecer variables de entorno para Qt/Wayland
export QT_QPA_PLATFORM=wayland
export QT_QPA_PLATFORMTHEME=qt5ct
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export QT_AUTO_SCREEN_SCALE_FACTOR=0

# Iniciar CopyQ
copyq &
exit 0 # <- opcional, solo deja claro que terminó
