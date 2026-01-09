#!/bin/bash
# fase2-HyprInstall-full.sh
# Script OPTIMIZADO SIN COMPILACIONES LARGAS
# Ejecutar como usuario normal después de archinstall
# Version ULTRA-FAST: Solo paquetes -bin precompilado

# +++- anotaciones
# Script perfeccionado con todas las mejoras solicitadas
# - Caelestia/Quickshell/Eww: Instalación interactiva (s/n)
# - Stremio: Instalación interactiva opcional
# - Editor: Selección interactiva VSCode/Cursor/Antigravity
# - Ollama + opencommit (oco) con modelo qwen2.5:0.5b
# - Kafka cursor: Búsqueda en múltiples rutas + config Hyprland
# - 35 pasos totales con todas las features esenciales

set -e

# ═══════════════════════════════════════════════════════════
# COLORES Y FUNCIONES
# ═══════════════════════════════════════════════════════════
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

function print_header() {
  echo
  echo -e "${BOLD}${CYAN}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${CYAN}║ $1${NC}"
  echo -e "${BOLD}${CYAN}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
  echo
}

function print_step() {
  echo
  echo -e "${BOLD}${BLUE}▶ PASO $1${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

function print_package() { echo -e "  ${MAGENTA}📦${NC} $1"; }
function print_status() { echo -e "${BLUE}[⚡]${NC} $1"; }
function print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
function print_error() { echo -e "${RED}[✗]${NC} $1"; }
function print_warning() { echo -e "${YELLOW}[⚠]${NC} $1"; }
function print_installing() { echo -e "${CYAN}[↓]${NC} Instalando: ${BOLD}$1${NC}"; }

# ═══════════════════════════════════════════════════════════
# VERIFICACIONES
# ═══════════════════════════════════════════════════════════
if [[ $EUID -eq 0 ]]; then
  print_error "NO ejecutar como root. Ejecuta como usuario normal."
  exit 1
fi

if ! command -v sudo &>/dev/null; then
  print_error "Sudo no está instalado. Configúralo primero."
  exit 1
fi

if ! ping -c 1 archlinux.org &>/dev/null; then
  print_error "Sin internet. Conecta con: sudo systemctl start NetworkManager && nmtui"
  exit 1
fi

# ═══════════════════════════════════════════════════════════
# INTRO
# ═══════════════════════════════════════════════════════════
clear
cat <<"EOF"

██╗░░██╗██╗░░░██╗██████╗░██████╗░██╗░░░░░░█████╗░███╗░░██╗██████╗░
██║░░██║╚██╗░██╔╝██╔══██╗██╔══██╗██║░░░░░██╔══██╗████╗░██║██╔══██╗
███████║░╚████╔╝░██████╔╝██████╔╝██║░░░░░███████║██╔██╗██║██║░░██║
██╔══██║░░╚██╔╝░░██╔═══╝░██╔══██╗██║░░░░░██╔══██║██║╚████║██║░░██║
██║░░██║░░░██║░░░██║░░░░░██║░░██║███████╗██║░░██║██║░╚███║██████╔╝
╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░░░╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░

╔══════════════════════════════════════════════════════════════════════╗
║        🚀 INSTALACIÓN ULTRA-FAST HYPRLAND 🚀                         ║
║            VERSIÓN OPTIMIZADA SIN COMPILACIONES                      ║
╚══════════════════════════════════════════════════════════════════════╝

EOF

echo -e "${GREEN}${BOLD}Esta instalación incluye:${NC}"
echo "  • Configuraciones de Grub Mine-Craft"
echo "  • Algunos scripts de Omarchy [webpack, arch install]"
echo "  • Hyprland + Waybar + Rofi + Dunst + Swaync"
echo "  • Audio: PipeWire + EasyEffects"
echo "  • Gaming: Steam, Lutris, Wine (INTERACTIVO)"
echo "  • Apps: Brave, Spotify, OBS, Discord, YouTube Music"
echo "  • Editor: VSCode/Cursor/Antigravity (INTERACTIVO)"
echo "  • Dev: Docker, Node.js, Rust, Python, Neovim, Ollama + IA"
echo "  • Utilidades: zsh, tmux, fastfetch, yazi, btop, pywal"
echo "  • Widgets: Eww (esencial), Quickshell + Caelestia (OPCIONAL)"
echo "  • Iconos/Glyphs: Nerd Fonts, Rofimoji || Launchers: Fuzzel [rofi], Vicinae (Raycast para Hyprland)"
echo "  • Extras: Input Remapper, Wine Dark Theme, Kafka Cursor"
echo "  • Temas: Oh-My-Posh, Rofimoji, Qt/GTK automático"
echo "  • Servicios: Gemini, Espanso, Kanata, GDrive mounts, ydotool"
echo "  • Dotfiles dizzi1222"
echo
echo -e "${RED}${BOLD}OPTIMIZACIONES:${NC}"
echo "  • Solo paquetes -bin (precompilados)"
echo "  • Caelestia/Quickshell: OPCIONAL (compilación ~30min)"
echo "  • Stremio: OPCIONAL (compilación ~10-15min)"
echo "  • Gemini CLI: OPCIONAL (omitir si ya configurado)"
echo "  • Eww: ESENCIAL (instalación rápida)"
echo "  • Bottles: OMITIDO (compila 1+ hora)"
echo "  • Stremio, discord-rpc (redundante si uso customRP en wine), qt5-webengine: OMITIDOS (compilan mucho)"
echo
echo -e "${YELLOW}${BOLD}Duración estimada: 25-35 minutos${NC}"
echo
read -p "¿Continuar? [S/n]: " confirm
[[ "$confirm" =~ ^[Nn]$ ]] && exit 0

# ═══════════════════════════════════════════════════════════
# SUDO KEEPALIVE
# ═══════════════════════════════════════════════════════════
sudo -v
(while true; do
  sudo -n true
  sleep 50
done 2>/dev/null) &
SUDO_PID=$!
trap "kill $SUDO_PID 2>/dev/null" EXIT

# ═══════════════════════════════════════════════════════════
# PASO 28: OLLAMA + OPENCOMMIT (OCO)
# ═══════════════════════════════════════════════════════════
print_step "27/35: Ollama + opencommit (IA Local)"

echo
read -p "¿Instalar Ollama + opencommit para commits con IA? [S/n]: " install_ollama

if [[ ! "$install_ollama" =~ ^[Nn]$ ]]; then
  print_installing "Ollama"
  sudo pacman -S --needed --noconfirm ollama
  yay -S --needed --noconfirm open-webui # Interfaz gráfica para Ollama
  sudo systemctl enable --now ollama

  print_installing "Descargando modelo qwen2.5:0.5b (más ligero y rápido)"
  ollama pull qwen2.5:0.5b
  # Modelos Onlines
  ollama run qwen3-coder:480b-cloud
  ollama run gpt-oss:120b-cloud
  ollama run gemma3:27b-cloud
  ollama run deepseek-v3.1:671b-cloud

  print_installing "opencommit (npm)"
  npm install -g opencommit

  # Configurar opencommit (CORREGIDO: OCO_TIMEOUT no es válido)
  print_installing "Configurando opencommit"
  oco config set OCO_MODEL=qwen2.5:0.5b
  oco config set OCO_LANGUAGE=es_ES # Commits en español (es_ES es el código soportado)
  # Nota: OCO_TIMEOUT no es un parámetro válido en opencommit

  print_success "Ollama + opencommit instalado"
  print_status "Uso: git add . && oco"
else
  print_warning "Ollama omitido"
fi

# ═════════════════════════════════════════════════════════════════
# PASO 29: GLYPHS, ICONOS Y EMOJIS (RAYCAST-LIKE): Vicinae + Fuzzel
# ═════════════════════════════════════════════════════════════════
print_step "28/35: Glyphs, Iconos y Emojis"

echo
echo -e "${BOLD}${YELLOW}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${YELLOW}║          🎨 ICONOS, GLYPHS Y EMOJIS 🎨                   ║${NC}"
echo -e "${BOLD}${YELLOW}╚═══════════════════════════════════════════════════════════╝${NC}"
echo
echo -e "${CYAN}Este paso instala herramientas para buscar e insertar:${NC}"
echo -e "  ${MAGENTA}•${NC} Emojis (rofimoji)"
echo -e "  ${MAGENTA}•${NC} Nerd Font glyphs (iconos para nvim, terminal, etc.)"
echo -e "  ${MAGENTA}•${NC} Font Awesome, Material Icons, etc."
echo -e "  ${MAGENTA}•${NC} Alternativa a Raycast para Linux (Ulauncher + extensiones)"
echo

# Paquetes base de emojis y fuentes
print_installing "Emojis y Nerd Fonts completos"
sudo pacman -S --needed --noconfirm \
  noto-fonts-emoji \
  ttf-nerd-fonts-symbols ttf-nerd-fonts-symbols-mono \
  ttf-nerd-fonts-symbols-common \
  gucharmap font-manager

# Rofimoji para emojis
yay -S --needed --noconfirm --answerdiff=None --answerclean=None --removemake \
  rofimoji 2>/dev/null || print_warning "rofimoji falló"

print_success "Emojis y Nerd Fonts instalados"

# Vicinae - Raycast para Hyprland (RECOMENDADO)
echo
read -p "¿Instalar Vicinae (Raycast para Hyprland - fork optimizado)? [S/n]: " install_vicinae

if [[ ! "$install_vicinae" =~ ^[Nn]$ ]]; then
  print_header "Instalando Vicinae (Raycast para Hyprland)"

  print_installing "vicinae desde AUR"
  yay -S --needed --noconfirm --answerdiff=None --answerclean=None --removemake \
    vicinae-bin 2>/dev/null || print_warning "Vicinae falló"

  print_status "Vicinae es un fork de Raycast optimizado para Hyprland"
  print_status "Usa Super+Space para abrir (configurable en Hyprland)"

  # Aplicar dotfiles de Raycast-vicinae si existen
  if [[ -d ~/dotfiles-dizzi/Raycast-vicinae ]]; then
    cd ~/dotfiles-dizzi
    stow Raycast-vicinae 2>/dev/null || print_warning "Stow Raycast-vicinae falló"
    cd ~
  fi

  print_success "Vicinae instalado"
else
  print_warning "Vicinae omitido"
fi

print_success "Sistema de iconos y glyphs configurado"

# ═══════════════════════════════════════════════════════════
# PASO 30: WIDGETS (EWW/QUICKSHELL/CAELESTIA)
# ═══════════════════════════════════════════════════════════
print_step "29/35: Widgets Desktop (Eww/Quickshell/Caelestia)"

echo
echo -e "${BOLD}${YELLOW}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${YELLOW}║          🎨 CONFIGURACIÓN DE WIDGETS 🎨                   ║${NC}"
echo -e "${BOLD}${YELLOW}╚═══════════════════════════════════════════════════════════╝${NC}"
echo
echo -e "${CYAN}Opciones disponibles:${NC}"
echo
echo -e "${BOLD}${GREEN}1. Eww (Elkowar's Wacky Widgets)${NC} - ${MAGENTA}ESENCIAL${NC}"
echo -e "  ${MAGENTA}•${NC} Widgets ligeros y rápidos"
echo -e "  ${MAGENTA}•${NC} Configuración en Yuck (similar a Lisp)"
echo -e "  ${MAGENTA}•${NC} Compatible con Hyprland"
echo -e "  ${MAGENTA}•${NC} Instalación: ~2 minutos"
echo
echo -e "${BOLD}${GREEN}2. Quickshell${NC} - ${YELLOW}OPCIONAL${NC}"
echo -e "  ${MAGENTA}•${NC} Widgets modernos en QML"
echo -e "  ${MAGENTA}•${NC} Soporte Qt6"
echo -e "  ${MAGENTA}•${NC} Compilación: ~15-20 minutos"
echo
echo -e "${BOLD}${GREEN}3. Caelestia Shell${NC} - ${YELLOW}OPCIONAL${NC}"
echo -e "  ${MAGENTA}•${NC} Shell completo basado en Quickshell"
echo -e "  ${MAGENTA}•${NC} Temas visuales impresionantes"
echo -e "  ${MAGENTA}•${NC} Compilación: ~30 minutos"
echo -e "  ${MAGENTA}•${NC} Requiere Quickshell"
echo
read -p "¿Instalar Eww (esencial)? [S/n]: " install_eww
read -p "¿Instalar Quickshell (compilación ~15min)? [s/N]: " install_quickshell
read -p "¿Instalar Caelestia Shell (compilación ~30min, requiere Quickshell)? [s/N]: " install_caelestia

# ═══════════════════════════════════════════════════════════
# Eww (ESENCIAL)
# ═══════════════════════════════════════════════════════════
if [[ ! "$install_eww" =~ ^[Nn]$ ]]; then
  print_header "Instalando Eww (Esencial)"

  # CORREGIDO: Eww está en AUR, no en repos oficiales
  print_installing "Eww desde AUR"
  yay -S --needed --noconfirm --answerdiff=None --answerclean=None --removemake \
    eww 2>/dev/null || print_warning "Eww falló"

  # Aplicar dotfiles de eww si existen
  if [[ -d ~/dotfiles-dizzi/eww ]]; then
    cd ~/dotfiles-dizzi
    stow eww 2>/dev/null || print_warning "Stow eww falló"
    cd ~
  fi

  if command -v eww &>/dev/null; then
    print_success "Eww instalado"
  else
    print_error "Eww no se instaló correctamente"
  fi
else
  print_warning "Eww omitido (NO RECOMENDADO)"
fi

# ═══════════════════════════════════════════════════════════
# Quickshell (OPCIONAL)
# ═══════════════════════════════════════════════════════════
if [[ "$install_quickshell" =~ ^[Ss]$ ]]; then
  print_header "Instalando Quickshell (~15 minutos)"

  # CORREGIDO: quickshell está en repos oficiales, no en AUR
  print_installing "Quickshell desde repos oficiales"
  sudo pacman -S --needed --noconfirm quickshell 2>/dev/null || {
    print_warning "Quickshell no está en repos, intentando AUR..."
    yay -S --needed --noconfirm --answerdiff=None --answerclean=None --removemake \
      quickshell 2>/dev/null || print_warning "Quickshell falló"
  }

  # Aplicar dotfiles de quickshell si existen
  if [[ -d ~/dotfiles-dizzi/quickshell ]]; then
    cd ~/dotfiles-dizzi
    stow quickshell 2>/dev/null || print_warning "Stow quickshell falló"
    cd ~
  fi

  if command -v quickshell &>/dev/null; then
    print_success "Quickshell instalado"
  else
    print_error "Quickshell no se instaló correctamente"
  fi
else
  print_warning "Quickshell omitido"
fi

# ═══════════════════════════════════════════════════════════
# Caelestia Shell (OPCIONAL, requiere Quickshell)
# ═══════════════════════════════════════════════════════════
if [[ "$install_caelestia" =~ ^[Ss]$ ]]; then
  if [[ "$install_quickshell" =~ ^[Ss]$ ]] || command -v quickshell &>/dev/null; then
    print_header "Instalando Caelestia Shell (~30 minutos)"

    print_installing "Caelestia Shell desde AUR"
    yay -S --needed --noconfirm --answerdiff=None --answerclean=None --removemake \
      caelestia-shell 2>/dev/null || print_warning "Caelestia falló"
    sudo pacman -S papirus-icon-theme # para caelestia usar iconos de papirus, ya que "Rompe mi Qt5ct y Qt6ct"

    # Aplicar dotfiles de caelestia si existen
    if [[ -d ~/dotfiles-dizzi/caelestia ]]; then
      cd ~/dotfiles-dizzi
      stow caelestia 2>/dev/null || print_warning "Stow caelestia falló"
      cd ~
    fi

    if command -v caelestia-shell &>/dev/null || pacman -Qi caelestia-shell &>/dev/null 2>&1; then
      print_success "Caelestia Shell instalado"
    else
      print_error "Caelestia Shell no se instaló correctamente"
    fi
  else
    print_error "Caelestia requiere Quickshell. Instalación omitida."
  fi
else
  print_warning "Caelestia Shell omitido"
fi

# ═══════════════════════════════════════════════════════════
# PASO 31: MUSIC PRESENCE (OPCIONAL)
# ═══════════════════════════════════════════════════════════
print_step "31/35: Music Presence (Opcional)"

echo
read -p "¿Instalar Music Presence para Discord? [s/N]: " install_music_presence

if [[ "$install_music_presence" =~ ^[Ss]$ ]]; then
  print_header "Instalando Music Presence"

  # Verificar si ya está instalado
  if [[ -d ~/musicpresence ]]; then
    print_warning "Music Presence ya instalado en ~/musicpresence"
  else
    print_installing "Descargando Music Presence"

    # Crear directorio
    mkdir -p ~/musicpresence
    cd ~/musicpresence

    # Descargar última release
    MUSIC_PRESENCE_URL="https://github.com/ungive/discord-music-presence/releases/download/v2.3.2/musicpresence-2.3.2-linux-x86_64.tar.gz"

    wget -q --show-progress "$MUSIC_PRESENCE_URL" -O musicpresence.tar.gz || {
      print_error "Error descargando Music Presence"
      cd ~
    }

    if [[ -f musicpresence.tar.gz ]]; then
      # Extraer
      tar -xzf musicpresence.tar.gz
      rm musicpresence.tar.gz

      # Dar permisos
      chmod +x musicpresence-*/usr/bin/musicpresence 2>/dev/null || true
    fi

    cd ~
  fi

  # Agregar PATH automáticamente
  print_installing "Configurando PATH"

  MUSIC_PRESENCE_PATH="export PATH=\$HOME/musicpresence/musicpresence-2.3.2-linux-x86_64/usr/bin:\$PATH"

  # Agregar a .zshrc si no existe
  if [[ -f ~/.zshrc ]]; then
    if ! grep -q "musicpresence" ~/.zshrc; then
      echo "" >>~/.zshrc
      echo "# Music Presence PATH" >>~/.zshrc
      echo "$MUSIC_PRESENCE_PATH" >>~/.zshrc
      print_success "PATH agregado a .zshrc"
    fi
  fi

  # Agregar a .bashrc si existe
  if [[ -f ~/.bashrc ]]; then
    if ! grep -q "musicpresence" ~/.bashrc; then
      echo "" >>~/.bashrc
      echo "# Music Presence PATH" >>~/.bashrc
      echo "$MUSIC_PRESENCE_PATH" >>~/.bashrc
      print_success "PATH agregado a .bashrc"
    fi
  fi

  print_success "Music Presence instalado"
  print_status "Ejecuta: source ~/.zshrc && musicpresence"

else
  print_warning "Music Presence omitido"
fi

# ═══════════════════════════════════════════════════════════
# PASO 32: RCLONE GOOGLE DRIVE (OPCIONAL)
# ═══════════════════════════════════════════════════════════
print_step "32/35: Rclone Google Drive (Opcional)"

echo
read -p "¿Configurar Rclone para Google Drive? [s/N]: " setup_rclone

if [[ "$setup_rclone" =~ ^[Ss]$ ]]; then
  print_header "Configurando Rclone para Google Drive"

  # Instalar rclone si no está
  if ! command -v rclone &>/dev/null; then
    print_installing "rclone"
    sudo pacman -S --needed --noconfirm rclone
  fi

  print_status "Iniciando configuración interactiva de rclone..."
  print_warning "Sigue las instrucciones para configurar Google Drive"
  echo
  echo -e "${CYAN}Pasos recomendados:${NC}"
  echo "  1. Escribe: n (nueva configuración)"
  echo "  2. Nombre: gdrive"
  echo "  3. Tipo: 20 (Google Drive)"
  echo "  4. Client ID: Enter (vacío)"
  echo "  5. Scope: 1 (Full access)"
  echo "  6. Autoconfig: y (si tienes navegador)"
  echo
  read -p "Presiona Enter para continuar..."

  rclone config

  # Crear scripts de montaje (CORREGIDO: scripts faltaban)
  print_installing "Creando scripts de montaje"

  # Script para gdrive principal
  cat >~/montar_gdrive.sh <<'EOL'
#!/bin/bash
fusermount -u ~/mi_gdrive 2>/dev/null
mkdir -p ~/mi_gdrive
rclone mount gdrive:/ ~/mi_gdrive --vfs-cache-mode full &
EOL
  chmod +x ~/montar_gdrive.sh

  # Script para gdrive música
  cat >~/montar_gdmusica.sh <<'EOL'
#!/bin/bash
fusermount -u ~/mi_gdmusica 2>/dev/null
mkdir -p ~/mi_gdmusica
rclone mount gd-musica:/ ~/mi_gdmusica --vfs-cache-mode full &
EOL
  chmod +x ~/montar_gdmusica.sh

  # Crear servicios systemd
  mkdir -p ~/.config/systemd/user

  cat >~/.config/systemd/user/montar_gdrive.service <<'EOL'
[Unit]
Description=Montar Google Drive al iniciar sesión

[Service]
ExecStart=/home/diego/montar_gdrive.sh
Type=oneshot

[Install]
WantedBy=default.target
EOL

  cat >~/.config/systemd/user/montar_gdmusica.service <<'EOL'
[Unit]
Description=Montar Google Drive Música al iniciar sesión

[Service]
ExecStart=/home/diego/montar_gdmusica.sh
Type=oneshot

[Install]
WantedBy=default.target
EOL

  # Habilitar servicios
  systemctl --user daemon-reload
  systemctl --user enable montar_gdrive.service
  systemctl --user enable montar_gdmusica.service

  print_success "Rclone configurado"
  print_status "Monta manualmente con: ~/montar_gdrive.sh"

else
  print_warning "Rclone omitido"
fi

# ═══════════════════════════════════════════════════════════
# PASO 33: CONFIGURACIÓN AUTOMÁTICA DE TEMAS QT/GTK
# ═══════════════════════════════════════════════════════════
print_step "33/35: Configuración Automática de Temas"

echo
read -p "¿Configurar temas Qt/GTK automáticamente? [S/n]: " config_themes

if [[ ! "$config_themes" =~ ^[Nn]$ ]]; then
  print_header "Configurando Temas del Sistema"

  # Instalar gestores de temas si no están
  sudo pacman -S --needed --noconfirm \
    qt5ct qt6ct nwg-look lxappearance kvantum

  # Configurar Qt para usar temas oscuros
  print_installing "Configurando Qt5/Qt6"

  # Qt5
  mkdir -p ~/.config/qt5ct
  cat >~/.config/qt5ct/qt5ct.conf <<'EOL'
[Appearance]
style=kvantum-dark
color_scheme_path=~/.config/qt5ct/colors/darker.conf

[Fonts]
fixed=@Variant(\0\0\0@\0\0\0\x12\0J\0e\0t\0B\0r\0a\0i\0n\0s@$\0\0\0\0\0\0\xff\xff\xff\xff\x5\x1\0\x32\x10)
general=@Variant(\0\0\0@\0\0\0\x12\0J\0e\0t\0B\0r\0a\0i\0n\0s@$\0\0\0\0\0\0\xff\xff\xff\xff\x5\x1\0\x32\x10)
EOL

  # Qt6
  mkdir -p ~/.config/qt6ct
  cat >~/.config/qt6ct/qt6ct.conf <<'EOL'
[Appearance]
style=kvantum-dark
color_scheme_path=~/.config/qt6ct/colors/darker.conf

[Fonts]
fixed=@Variant(\0\0\0@\0\0\0\x12\0J\0e\0t\0B\0r\0a\0i\0n\0s@$\0\0\0\0\0\0\xff\xff\xff\xff\x5\x1\0\x32\x10)
general=@Variant(\0\0\0@\0\0\0\x12\0J\0e\0t\0B\0r\0a\0i\0n\0s@$\0\0\0\0\0\0\xff\xff\xff\xff\x5\x1\0\x32\x10)
EOL

  # Variables de entorno para Qt
  if [[ -f ~/.config/hypr/hyprland.conf ]]; then
    if ! grep -q "QT_QPA_PLATFORMTHEME" ~/.config/hypr/hyprland.conf; then
      echo "env = QT_QPA_PLATFORMTHEME,qt6ct" >>~/.config/hypr/hyprland.conf
    fi
  fi

  # Configurar GTK para tema oscuro
  print_installing "Configurando GTK"

  gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' 2>/dev/null || true
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true

  # Si existe tema Colloid en dotfiles, aplicarlo
  if [[ -d ~/.themes/Colloid-Dark ]]; then
    gsettings set org.gnome.desktop.interface gtk-theme 'Colloid-Dark' 2>/dev/null || true
  fi

  print_success "Temas configurados"
else
  print_warning "Configuración de temas omitida"
fi

# ═══════════════════════════════════════════════════════════
# PASO 34: DESACTIVAR GESTOR DE LOGIN ACTUAL
# ═══════════════════════════════════════════════════════════
print_step "33.5/35: Desactivar Display Manager Actual"

# Detectar gestor actual
CURRENT_DM=""
if systemctl is-enabled gdm &>/dev/null; then
  CURRENT_DM="gdm"
elif systemctl is-enabled sddm &>/dev/null; then
  CURRENT_DM="sddm"
elif systemctl is-enabled lightdm &>/dev/null; then
  CURRENT_DM="lightdm"
fi

if [[ -n "$CURRENT_DM" ]]; then
  print_warning "Gestor actual detectado: $CURRENT_DM"

  read -p "¿Desactivar $CURRENT_DM antes de instalar nuevo gestor? [S/n]: " disable_dm

  if [[ ! "$disable_dm" =~ ^[Nn]$ ]]; then
    print_status "Desactivando $CURRENT_DM..."
    sudo systemctl stop $CURRENT_DM 2>/dev/null || true
    sudo systemctl disable $CURRENT_DM
    print_success "$CURRENT_DM desactivado"
  fi
else
  print_status "No se detectó ningún gestor de login activo"
fi

# ═══════════════════════════════════════════════════════════
# PASO 35: DISPLAY MANAGER (GDM O SDDM) - MEJORADO
# ═══════════════════════════════════════════════════════════
print_step "34/35: Display Manager (GDM o SDDM)"

echo
echo -e "${BOLD}${YELLOW}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${YELLOW}║          🖥️  SELECCIONAR DISPLAY MANAGER 🖥️              ║${NC}"
echo -e "${BOLD}${YELLOW}╚═══════════════════════════════════════════════════════════╝${NC}"
echo
echo -e "${CYAN}Opciones disponibles:${NC}"
echo
echo -e "${BOLD}${GREEN}1. GDM (GNOME Display Manager)${NC}"
echo -e "  ${MAGENTA}•${NC} Interfaz limpia y moderna"
echo -e "  ${MAGENTA}•${NC} Soporte Wayland nativo"
echo -e "  ${MAGENTA}•${NC} Más ligero (~100MB RAM)"
echo
echo -e "${BOLD}${GREEN}2. SDDM + Astronaut Theme (MEJORADO)${NC}"
echo -e "  ${MAGENTA}•${NC} ${BOLD}Setup.sh interactivo funcional${NC}"
echo -e "  ${MAGENTA}•${NC} 10 temas visuales pre-hechos"
echo -e "  ${MAGENTA}•${NC} Wallpapers animados"
echo -e "  ${MAGENTA}•${NC} Teclado virtual integrado"
echo -e "  ${MAGENTA}•${NC} Instalación robusta y confiable"
echo
echo -e "${BOLD}${GREEN}3. Ninguno${NC} (mantener actual)"
echo
read -p "Seleccionar Display Manager [1=GDM, 2=SDDM, 3=Ninguno]: " dm_choice

if [[ "$dm_choice" == "2" ]]; then
  print_header "🚀 Instalando SDDM + Astronaut Theme (Versión Mejorada)"

  # Paso 1: Instalar SDDM y dependencias
  print_installing "SDDM + Dependencias Qt6"
  sudo pacman -S --needed --noconfirm \
    sddm qt6-svg qt6-virtualkeyboard qt6-multimedia qt6-multimedia-ffmpeg

  print_success "SDDM instalado"

  # Paso 2: Limpiar instalación anterior si existe
  print_status "Limpiando instalaciones previas del tema..."
  sudo rm -rf /usr/share/sddm/themes/sddm-astronaut-theme
  rm -rf /tmp/sddm-astronaut-theme

  # Paso 3: Clonar tema en /tmp
  print_installing "Clonando tema Astronaut"
  cd /tmp
  git clone --depth 1 https://github.com/keyitdev/sddm-astronaut-theme.git
  cd sddm-astronaut-theme

  print_success "Tema clonado"

  # Paso 4: Verificar que setup.sh existe
  if [[ ! -f "setup.sh" ]]; then
    print_error "Error: setup.sh no encontrado"
    print_warning "Instalando tema manualmente..."

    # Fallback: instalación manual
    sudo cp -r /tmp/sddm-astronaut-theme /usr/share/sddm/themes/

    if [[ -d /usr/share/sddm/themes/sddm-astronaut-theme/Fonts ]]; then
      sudo cp -r /usr/share/sddm/themes/sddm-astronaut-theme/Fonts/* /usr/share/fonts/ 2>/dev/null || true
      fc-cache -fv >/dev/null
    fi
  else
    # Paso 5: Hacer setup.sh ejecutable
    chmod +x setup.sh

    # Paso 6: Ejecutar setup.sh INTERACTIVO
    print_status "Iniciando configuración interactiva del tema..."
    echo
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  ${BOLD}CONFIGURACIÓN INTERACTIVA DEL TEMA ASTRONAUT${NC}${CYAN}    ║${NC}"
    echo -e "${CYAN}╠═══════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║  Podrás elegir:                                       ║${NC}"
    echo -e "${CYAN}║  • Uno de los 10 temas visuales disponibles          ║${NC}"
    echo -e "${CYAN}║  • Personalizar colores y apariencia                 ║${NC}"
    echo -e "${CYAN}║  • Configurar wallpaper                              ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${YELLOW}${BOLD}Temas disponibles:${NC}"
    echo -e "  ${GREEN}1.${NC} classic           ${GREEN}6.${NC} penguin"
    echo -e "  ${GREEN}2.${NC} astronaut         ${GREEN}7.${NC} jake_the_dog"
    echo -e "  ${GREEN}3.${NC} future            ${GREEN}8.${NC} rick_and_morty"
    echo -e "  ${GREEN}4.${NC} cyberpunk         ${GREEN}9.${NC} space_ship"
    echo -e "  ${GREEN}5.${NC} nixos            ${GREEN}10.${NC} custom"
    echo
    echo -e "${CYAN}${BOLD}Presiona Enter para continuar con la configuración...${NC}"
    read -p ""

    # Ejecutar setup.sh con sudo (necesario para copiar a /usr/share)
    sudo bash setup.sh

    print_success "Tema configurado mediante setup.sh"
  fi

  # Paso 7: Configurar SDDM para usar el tema
  print_status "Configurando SDDM..."

  sudo tee /etc/sddm.conf >/dev/null <<EOF
[Theme]
Current=sddm-astronaut-theme

[General]
InputMethod=qtvirtualkeyboard
EOF

  # Paso 8: Configurar teclado virtual en conf.d
  sudo mkdir -p /etc/sddm.conf.d
  sudo tee /etc/sddm.conf.d/virtualkbd.conf >/dev/null <<EOF
[General]
InputMethod=qtvirtualkeyboard
EOF

  print_success "Configuración de SDDM completada"

  # Paso 9: Copiar fuentes si existen
  if [[ -d /usr/share/sddm/themes/sddm-astronaut-theme/Fonts ]]; then
    print_status "Instalando fuentes del tema..."
    sudo cp -r /usr/share/sddm/themes/sddm-astronaut-theme/Fonts/* /usr/share/fonts/ 2>/dev/null || true
    fc-cache -fv >/dev/null
    print_success "Fuentes instaladas"
  fi

  # Paso 10: Habilitar servicio SDDM
  print_status "Habilitando servicio SDDM..."
  sudo systemctl enable sddm
  print_success "SDDM habilitado"

  # Resumen final
  echo
  echo -e "${GREEN}${BOLD}✨ SDDM + Astronaut Theme instalado correctamente ✨${NC}"
  echo
  echo -e "${CYAN}Comandos útiles:${NC}"
  echo -e "  ${YELLOW}•${NC} Probar tema: ${YELLOW}sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/sddm-astronaut-theme/${NC}"
  echo -e "  ${YELLOW}•${NC} Editar config: ${YELLOW}sudo nano /etc/sddm.conf${NC}"
  echo -e "  ${YELLOW}•${NC} Cambiar tema: ${YELLOW}cd /usr/share/sddm/themes/sddm-astronaut-theme && sudo bash setup.sh${NC}"
  echo

elif [[ "$dm_choice" == "1" ]]; then
  print_header "Instalando GDM"

  print_installing "GDM (GNOME Display Manager)"
  sudo pacman -S --needed --noconfirm gdm
  sudo systemctl enable gdm
  print_success "GDM habilitado"
else
  print_warning "Display Manager omitido (manteniendo actual)"
fi

# ═══════════════════════════════════════════════════════════
# PASO 35: LIMPIEZA FINAL
# ═══════════════════════════════════════════════════════════
print_step "35/35: Limpieza Final"
print_status "Eliminando paquetes huérfanos..."
sudo pacman -Rns $(pacman -Qtdq) --noconfirm 2>/dev/null || true
yay -Rns $(yay -Qdtq) --noconfirm 2>/dev/null || true

print_status "Limpiando caché..."
yay -Sc --noconfirm 2>/dev/null || true
sudo pacman -Sc --noconfirm 2>/dev/null || true
rm -rf ~/.cache/yay 2>/dev/null || true
rm -rf /tmp/sddm-astronaut-theme 2>/dev/null || true

print_success "Limpieza completada"

# ═══════════════════════════════════════════════════════════
# RESUMEN
# ═══════════════════════════════════════════════════════════
kill $SUDO_PID 2>/dev/null || true

clear
cat <<"EOF"

╔══════════════════════════════════════════════════════════════════════╗
║              🎉 INSTALACIÓN ULTRA-FAST COMPLETADA 🎉                 ║
╠══════════════════════════════════════════════════════════════════════╣
║  ✅ Hyprland + Waybar + Rofi + Widgets                               ║
║  ✅ Gaming (sin compilaciones largas)                                ║
║  ✅ Apps (solo binarios precompilados)                               ║
║  ✅ Servicios systemd habilitados                                    ║
║  ✅ Symlinks a /etc configurados                                     ║
║  ✅ Temas Qt/GTK configurados automáticamente                        ║
║  ✅ Oh-My-Zsh + Plugins completos                                    ║
║  ✅ Python-pywal + Oh-My-Posh + Rofimoji                             ║
║  ✅ Ollama + opencommit (si seleccionado)                            ║
║  ✨ SDDM Astronaut Theme configurado interactivamente                ║
║  ✅  Grub Mine-Craft 󰍳 restaurado correctamente                     ║
╚══════════════════════════════════════════════════════════════════════╝

EOF

echo -e "${GREEN}${BOLD}Siguiente paso:${NC}"
echo -e "  ${CYAN}1.${NC} ${RED}CERRAR SESIÓN Y VOLVER A ENTRAR${NC} (crucial para grupos)"
echo -e "  ${CYAN}2.${NC} ${YELLOW}reboot${NC}"
echo -e "  ${CYAN}3.${NC} Seleccionar ${YELLOW}Hyprland${NC} en GDM/SDDM"
echo
echo -e "${YELLOW}${BOLD}SDDM Astronaut Theme:${NC}"
echo -e "  ${CYAN}•${NC} Tema activo: ${GREEN}$(grep -A1 '\[Theme\]' /etc/sddm.conf 2>/dev/null | grep Current | cut -d'=' -f2 || echo 'No configurado')${NC}"
echo -e "  ${CYAN}•${NC} Cambiar tema: ${YELLOW}cd /usr/share/sddm/themes/sddm-astronaut-theme && sudo bash setup.sh${NC}"
echo -e "  ${CYAN}•${NC} Probar: ${YELLOW}sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/sddm-astronaut-theme/${NC}"
echo
echo -e "${YELLOW}${BOLD}Configuraciones post-instalación:${NC}"
echo -e "  ${CYAN}•${NC} Neovim: Abre ${YELLOW}nvim${NC} y ejecuta ${YELLOW}:MasonInstall prettier markdownlint-cli2${NC}"
echo -e "  ${CYAN}•${NC} Copilot: En nvim ejecuta ${YELLOW}:CopilotAuth${NC}"
echo -e "  ${CYAN}•${NC} Gemini CLI: ${YELLOW}gemini-cli setup${NC}"
echo -e "  ${CYAN}•${NC} Pywal: ${YELLOW}wal -i ~/wallpapers/tu-imagen.jpg${NC}"
echo -e "  ${CYAN}•${NC} Music Presence: ${YELLOW}source ~/.zshrc && musicpresence${NC}"
echo -e "  ${CYAN}•${NC} Rclone: ${YELLOW}~/montar_gdrive.sh${NC} (si configuraste)"
echo
echo -e "${YELLOW}${BOLD}Instalación manual (si omitiste):${NC}"
echo -e "  ${CYAN}•${NC} Bottles: ${YELLOW}yay -S bottles${NC} (1+ hora)"
echo -e "  ${CYAN}•${NC} Caelestia: ${YELLOW}yay -S caelestia-shell${NC} (30min)"
echo -e "  ${CYAN}•${NC} Quickshell: ${YELLOW}yay -S quickshell-git${NC} (15min)"
echo -e "  ${CYAN}•${NC} Stremio: ${YELLOW}yay -S stremio${NC} (10-15min)"
echo -e "  ${CYAN}•${NC} Ollama: ${YELLOW}sudo pacman -S ollama && ollama pull qwen2.5:0.5b${NC}"
echo
echo -e "${GREEN}${BOLD}Dotfiles:${NC}"
echo -e "  ${CYAN}•${NC} Aplicar todos: ${YELLOW}cd ~/dotfiles-dizzi && stow .${NC}"
echo -e "  ${CYAN}•${NC} Quitar todos: ${YELLOW}cd ~/dotfiles-dizzi && stow -D .${NC}"
echo -e "  ${CYAN}•${NC} Aplicar específico: ${YELLOW}cd ~/dotfiles-dizzi && stow hypr waybar rofi${NC}"
echo -e "  ${CYAN}•${NC}   PROBLEMAS CON LA CPU al 100%? # Ver CPU de otros procesos
  htop # --> Usa F6 para ordenar por CPU
  sudo intel_gpu_top # Ver GPU en tiempo real de Intel [latitude 7440]

  # O para ver CPU de otros procesos con grep (busca por nombre)
  # ...
  Btw ya parche y mejore los intervalos de waybar, eww, hypr, scripts etc.
  ps aux --sort=-%cpu | grep -E "eww | hypr | waybar | dunst | swaync | swww | caelestia" | head -20.${NC}"
echo
echo -e "${GREEN}¡Disfruta tu setup Hyprland perfeccionado con SDDM Astronaut! 🚀${NC}"
echo
