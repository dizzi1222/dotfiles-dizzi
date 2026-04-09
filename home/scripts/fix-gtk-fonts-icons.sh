#!/bin/bash
# Configurar fuentes Mononoki y refrescar caché de iconos

# Colores básicos
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}[INFO]${NC} Estableciendo fuente Mononoki Nerd Font..."
gsettings set org.gnome.desktop.interface font-name 'Mononoki Nerd Font 11'
gsettings set org.gnome.desktop.interface monospace-font-name 'Mononoki Nerd Font 10'

echo -e "${BLUE}[INFO]${NC} Actualizando caché de fuentes..."
fc-cache -fv

echo -e "${BLUE}[INFO]${NC} Actualizando base de datos de iconos..."
find ~/.local/share/icons ~/.icons /usr/share/icons -maxdepth 1 -type d -exec gtk-update-icon-cache -f -t {} \; 2>/dev/null

echo -e "${GREEN}[OK]${NC} Fuentes e iconos actualizados correctamente."
