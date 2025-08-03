#!/bin/bash

# Este script muestra el historial de CopyQ con Wofi y pega el elemento seleccionado.

# Obtener el número total de elementos en el historial
MAX_DISPLAY_ITEMS=20
TOTAL_ITEMS=$(copyq count)

# Construir el historial formateado para Wofi, incluyendo el índice de CopyQ al principio de cada línea
HISTORY_FOR_WOFI=""
for i in $(seq 0 $((TOTAL_ITEMS > MAX_DISPLAY_ITEMS ? MAX_DISPLAY_ITEMS - 1 : TOTAL_ITEMS - 1))); do
  # Intentar leer el contenido de texto plano
  # Redirige stderr a /dev/null para no ver errores si el formato no existe
  ITEM_CONTENT_PLAIN=$(copyq read "$i" text/plain 2>/dev/null | tr -d '\n' | sed 's/.$//')

  DISPLAY_TEXT=""

  # Heurística: Si el texto plano es muy corto o parece vacío, y NO es una URL de imagen obvia
  # Consideramos que podría ser una imagen binaria o contenido no textual.
  if [[ -z "$ITEM_CONTENT_PLAIN" || "$ITEM_CONTENT_PLAIN" == *"copyq read"* ]]; then
    # Definitivamente no hay texto útil, marcamos como contenido binario/imagen
    DISPLAY_TEXT="🔗🖼️ [IMAGEN BINARIA]🔗🖼️" # Símbolo de imagen Unicode
  elif [[ "$ITEM_CONTENT_PLAIN" =~ \.(png|jpg|jpeg|gif|bmp|webp)$ ]]; then
    # Heurística: Si el texto plano parece una URL de imagen
    DISPLAY_TEXT="🔗🖼️ https://deepmind.google/models/imagen/ ${ITEM_CONTENT_PLAIN}" # Símbolo de enlace + imagen
  elif [[ ${#ITEM_CONTENT_PLAIN} -lt 5 ]]; then
    # Si el texto plano es muy corto (menos de 5 caracteres), podría ser algo no textual significativo
    DISPLAY_TEXT="${ITEM_CONTENT_PLAIN} [?]"
  else
    # Es contenido de texto plano normal y útil
    DISPLAY_TEXT="${ITEM_CONTENT_PLAIN}"
  fi

  # Si tenemos algo que mostrar, lo añadimos al historial de Wofi
  if [[ -n "$DISPLAY_TEXT" ]]; then
    HISTORY_FOR_WOFI+="${i}  ${DISPLAY_TEXT}\n"
  fi
done

# Si el historial está vacío, ponemos un mensaje.
if [ -z "$HISTORY_FOR_WOFI" ]; then
  HISTORY_FOR_WOFI="  (Historial de CopyQ vacío)\n"
fi

# Usar wofi para mostrar el historial y capturar la selección
selected_line=$(echo -e "$HISTORY_FOR_WOFI" | wofi --dmenu --show dmenu --insensitive --width 600 --height 400 --prompt "Clipboard:")

# Si se seleccionó algo (es decir, el usuario no canceló Wofi)
if [ -n "$selected_line" ]; then
  # Extraer el índice de CopyQ del inicio de la línea seleccionada
  final_copyq_index=$(echo "$selected_line" | awk '{print $1}')

  # Validar que el índice es un número
  if [[ "$final_copyq_index" =~ ^[0-9]+$ ]]; then
    # Seleccionar y pegar el elemento
    copyq select "$final_copyq_index" && copyq paste
  else
    # Mensaje de error si no se pudo determinar el índice
    # notify-send "Error en CopyQ Script" "No se pudo determinar el índice para pegar."
    exit 1
  fi
fi
