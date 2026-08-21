#!/bin/bash
# Script para toggle floating manteniendo la posición exacta de la ventana
# Basado en: https://github.com/hyprwm/Hyprland/issues/7926

# Obtener información de la ventana activa en JSON
window_info=$(hyprctl activewindow -j)

# Verificar si hay una ventana activa
if [ -z "$window_info" ] || [ "$window_info" = "null" ]; then
    notify-send "Toggle Float" "No hay ventana activa" -u low
    exit 0
fi

# Extraer estado, posición y tamaño actuales
is_floating=$(echo "$window_info" | jq -r '.floating')
current_x=$(echo "$window_info" | jq -r '.at[0]')
current_y=$(echo "$window_info" | jq -r '.at[1]')
current_w=$(echo "$window_info" | jq -r '.size[0]')
current_h=$(echo "$window_info" | jq -r '.size[1]')

# Debug (opcional, comentar si no necesitas)
# echo "Estado: floating=$is_floating, pos=($current_x,$current_y), size=${current_w}x${current_h}"

if [ "$is_floating" = "false" ]; then
    # Cambiar a flotante y mantener posición exacta
    hyprctl --batch "dispatch togglefloating ; dispatch movewindowpixel exact $current_x $current_y"
    
    # Opcional: Si quieres redimensionar al flotar, descomenta estas líneas
    # hyprctl dispatch resizewindowpixel exact 80% 80%
    # hyprctl dispatch centerwindow
else
    # Solo quitar el modo flotante (mantener posición automáticamente)
    hyprctl dispatch togglefloating
fi
