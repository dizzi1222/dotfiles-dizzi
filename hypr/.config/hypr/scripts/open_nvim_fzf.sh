#!/bin/bash

LOG_FILE="/tmp/nvim_fzf_debug.log"
TEMP_FILE="/tmp/fzf_selected_file.tmp"

echo "$(date): DEBUG: Iniciando script. Preparando para ejecutar fzf..." >>"$LOG_FILE" 2>&1

# Borra el archivo temporal anterior si existe
rm -f "$TEMP_FILE"

# Ejecuta fzf en kitty y redirige su salida al archivo temporal
# `-o` en kitty mantiene la ventana abierta al finalizar el comando,
# permitiendo que el script lea el archivo temporal antes de que kitty se cierre si lo hace.
# Sin embargo, la mejor forma es que fzf escriba directamente al archivo.
# fzf necesita un TTY para su interactividad. No podemos simplemente redirigir su stdout.
# La solución es que fzf sea ejecutado por kitty, y que kitty escriba el resultado en el archivo.

# Este es el truco: Kitty puede ejecutar un comando y redirigir su stdout.
# fzf imprime la selección a stdout. Kitty capturará eso.
kitty -e sh -c "fzf > '$TEMP_FILE'"

# Mensaje de depuración: Después de que kitty ejecutó fzf
echo "$(date): DEBUG: fzf (via kitty) ejecutado. Leyendo archivo temporal: '$TEMP_FILE'" >>"$LOG_FILE" 2>&1

# Lee el archivo seleccionado del archivo temporal
# Usamos `head -n 1` para asegurarnos de que solo se lee la primera línea
SELECTED_FILE=$(head -n 1 "$TEMP_FILE" 2>>"$LOG_FILE")

echo "$(date): DEBUG: SELECTED_FILE (leído de temp file): ---${SELECTED_FILE}---" >>"$LOG_FILE" 2>&1

# Limpia espacios en blanco, saltos de línea y verifica si la cadena es vacía
SELECTED_FILE=$(echo "$SELECTED_FILE" | tr -d '\n\r ' | xargs)

echo "$(date): DEBUG: SELECTED_FILE (limpiado): ---${SELECTED_FILE}---" >>"$LOG_FILE" 2>&1

# Si se seleccionó un archivo (la cadena no está vacía), y es un archivo real, abre nvim.
if [ -n "$SELECTED_FILE" ] && [ -f "$SELECTED_FILE" ]; then
  echo "$(date): DEBUG: Intentando abrir nvim con el archivo: '$SELECTED_FILE' en una nueva ventana de kitty." >>"$LOG_FILE" 2>&1
  kitty -e nvim "$SELECTED_FILE"
  echo "$(date): DEBUG: nvim command executed." >>"$LOG_FILE" 2>&1
elif [ -n "$SELECTED_FILE" ]; then
  echo "$(date): DEBUG: '$SELECTED_FILE' no es un archivo válido o no existe. Esto puede ocurrir si fzf devuelve un directorio." >>"$LOG_FILE" 2>&1
else
  echo "$(date): DEBUG: No se seleccionó ningún archivo o fzf devolvió vacío/errores." >>"$LOG_FILE" 2>&1
fi

# Limpia el archivo temporal
rm -f "$TEMP_FILE" >>"$LOG_FILE" 2>&1
echo "$(date): DEBUG: Script finalizado. Archivo temporal eliminado." >>"$LOG_FILE" 2>&1

# luego hazme ejecutable 🥵
# chmod +x ~/.config/hypr/scripts/open_nvim_fzf.sh
