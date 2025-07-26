#!/bin/bash

# Define la ruta donde se guardará temporalmente la captura
TEMP_IMG="/tmp/hypr-screenshot-$(date +%s).png"

# 1. Capturar pantalla
# Si quieres seleccionar un área:
grim -g "$(slurp)" "$TEMP_IMG"
# Si quieres toda la pantalla:
# grim "$TEMP_IMG"

# Verificar si la captura fue exitosa
if [ ! -f "$TEMP_IMG" ]; then
  dunstify "Captura de pantalla fallida" "No se pudo tomar la captura."
  exit 1
fi

# 2. Subir a Gyazo (requiere API o herramienta de línea de comandos de Gyazo)
# ATENCIÓN: Gyazo no tiene una API pública obvia para scripts.
# Necesitarías la CLI oficial de Gyazo si la tienen, o buscar una alternativa
# que simule la subida, o usar Imgur como alternativa.

# Ejemplo para subir a Imgur (MUCHO MÁS FÁCIL Y COMÚN):
# Necesitas 'curl' instalado: sudo pacman -S curl
# Y una cuenta de Imgur. Esto NO es Gyazo.

# CLIENT_ID="TU_CLIENT_ID_DE_IMGUR" # Reemplaza con tu ID de cliente de Imgur API
# UPLOAD_URL=$(curl -s -H "Authorization: Client-ID $CLIENT_ID" -F "image=@$TEMP_IMG" https://api.imgur.com/3/image | jq -r '.data.link')
# dunstify "Captura subida a Imgur" "$UPLOAD_URL"
# wl-copy "$UPLOAD_URL"

# SI INSISTES EN GYAZO Y TIENES LA CLI INSTALADA (ej. el binario 'gyazo' que intentamos instalar antes y falló):
# La versión AUR de Gyazo tenía el binario 'gyazo' en /usr/bin/gyazo.
# Si logras que funcione, su uso es algo así:
UPLOAD_URL=$(/usr/bin/gyazo "$TEMP_IMG" 2>/dev/null) # Asumiendo que /usr/bin/gyazo devuelve la URL en stdout

# 3. Copiar URL al portapapeles (wl-copy ya lo tienes)
if [ -n "$UPLOAD_URL" ]; then
  wl-copy "$UPLOAD_URL"
  dunstify "Gyazo/Imgur" "URL copiada: $UPLOAD_URL"
else
  dunstify "Error de subida" "No se pudo obtener la URL de Gyazo/Imgur."
fi

# Limpiar archivo temporal (opcional, puedes quererlo para debug)
# rm "$TEMP_IMG"
