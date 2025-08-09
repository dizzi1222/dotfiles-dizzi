#!/bin/bash

# Directorio donde están tus fondos de pantalla
WALLPAPERS_DIR="$HOME/wallpapers/Wallpapers"

# Archivo temporal donde se copiará el fondo seleccionado para hyprlock
# Este será el 'path' que uses en hyprlock.conf
TEMP_WALLPAPER_PATH="/tmp/hyprlock_random_wallpaper.jpg"

# Encuentra todos los archivos de imagen (jpg, png, jpeg, webp) en el directorio
# y selecciona uno al azar.
# Si tienes otros formatos, añádelos a la lista (-o -iname "*.gif").
RANDOM_IMAGE=$(find "$WALLPAPERS_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" \) | shuf -n 1)

# Comprueba si se encontró alguna imagen
if [ -z "$RANDOM_IMAGE" ]; then
  echo "Error: No se encontraron imágenes en $WALLPAPERS_DIR"
  # Opcional: podrías poner una imagen de fallback si no se encuentra ninguna
  # cp /ruta/a/tu/imagen/de/fallback.jpg "$TEMP_WALLPAPER_PATH"
  exit 1
fi

# Copia (o crea un enlace simbólico) la imagen seleccionada a la ubicación temporal.
# Usar 'cp' es más simple para asegurar que el archivo esté disponible.
cp "$RANDOM_IMAGE" "$TEMP_WALLPAPER_PATH"

echo "Fondo de pantalla para el bloqueo seleccionado: $RANDOM_IMAGE"

# NOTA: Este script solo selecciona y copia la imagen.
# La llamada a hyprlock la harás en el siguiente paso.
