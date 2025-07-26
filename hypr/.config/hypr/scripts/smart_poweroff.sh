#!/bin/bash

# Obtener el ID del workspace activo y el número de ventanas en él
# La redirección 2>/dev/null evita mensajes de error si hyprctl falla temporalmente
ACTIVE_WS_ID=$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id')
NUM_WINDOWS=$(hyprctl clients -j 2>/dev/null | jq -r --arg WS_ID "$ACTIVE_WS_ID" '.[] | select(.workspace.id == ($WS_ID | tonumber)) | .address' | wc -l)

# Eliminar espacios en blanco y asegurarse de que sea un número válido
NUM_WINDOWS=$(echo "$NUM_WINDOWS" | tr -d '[:space:]')

# Si no hay ventanas, apaga el sistema
if [ "$NUM_WINDOWS" -eq 0 ]; then
  echo "No hay ventanas abiertas en el workspace actual. Apagando el sistema..."
  systemctl poweroff
else
  # Si hay ventanas, notifica al usuario (opcional, requiere `notify-send`)
  echo "Hay ventanas abiertas en el workspace actual. Por favor, ciérralas antes de apagar."
  notify-send "Advertencia de Apagado" "¡Cierra todas las ventanas del workspace actual antes de apagar el sistema!" -t 5000 # Muestra notificación por 5 segundos
fi
