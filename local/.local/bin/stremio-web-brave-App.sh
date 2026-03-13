#!/bin/bash
# Inicia stremio-service: intenta AUR primero, luego flatpak
if command -v stremio-service &>/dev/null; then
  stremio-service &
else
  flatpak run com.stremio.service &
fi

# Espera a que el servicio levante en el puerto 11470
sleep 2

# Abre la interfaz web local en Brave
zen-browser --kiosk "http://127.0.0.1:11470/"
