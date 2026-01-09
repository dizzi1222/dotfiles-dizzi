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
# PASO 1: YAY
# ═══════════════════════════════════════════════════════════
print_step "1/35: YAY (AUR Helper)"

if ! command -v yay &>/dev/null; then
  print_installing "yay (AUR helper)"

  sudo pacman -S --needed --noconfirm git base-devel
  rm -rf ~/yay-tmp

  cd ~
  git clone https://aur.archlinux.org/yay.git ~/yay-tmp
  cd ~/yay-tmp
  makepkg -si --noconfirm
  cd ~
  rm -rf ~/yay-tmp

  print_success "yay instalado"
else
  print_success "yay ya instalado"
fi

if ! command -v yay &>/dev/null; then
  print_error "yay no se instaló. Abortando."
  exit 1
fi

# ═══════════════════════════════════════════════════════════
# PASO 2: ACTUALIZAR SISTEMA
# ═══════════════════════════════════════════════════════════
print_step "2/35: Actualizar Sistema"
print_installing "Actualizando paquetes del sistema"
sudo pacman -Syu --noconfirm
print_success "Sistema actualizado"

# ═══════════════════════════════════════════════════════════
# PASO 3: AUDIO
# ═══════════════════════════════════════════════════════════
print_step "3/35: Audio (PipeWire)"
print_installing "PipeWire + EasyEffects + Pavucontrol"
sudo pacman -S --needed --noconfirm \
  pipewire pipewire-pulse pipewire-alsa pipewire-jack \
  wireplumber pavucontrol easyeffects
print_success "Audio configurado"

# ═══════════════════════════════════════════════════════════
# PASO 4: BLUETOOTH
# ═══════════════════════════════════════════════════════════
print_step "4/35: Bluetooth"
print_installing "BlueZ + Blueman + Bluetuith"
sudo pacman -S --needed --noconfirm \
  bluez-utils blueman bluez-plugins
# bluez en conflicto con bluez-ps3 lo quite

yay -S --needed --noconfirm --answerdiff=None --answerclean=None --removemake \
  bluez-ps3 bluetuith 2>/dev/null || true

sudo systemctl enable --now bluetooth
print_success "Bluetooth habilitado"

# ═══════════════════════════════════════════════════════════
# PASO 5: FONTS
# ═══════════════════════════════════════════════════════════
print_step "5/35: Fuentes"
print_installing "Noto Fonts + Nerd Fonts + Adobe Source Han"
sudo pacman -S --needed --noconfirm \
  noto-fonts noto-fonts-emoji noto-fonts-cjk \
  ttf-jetbrains-mono-nerd ttf-firacode-nerd \
  ttf-font-awesome ttf-dejavu ttf-liberation \
  adobe-source-han-sans-otc-fonts \
  adobe-source-han-serif-otc-fonts

yay -S --needed --noconfirm --answerdiff=None --answerclean=None --removemake \
  ttf-iosevka ttf-mononoki-nerd otf-hermit-nerd 2>/dev/null || true

fc-cache -fv >/dev/null
print_success "Fuentes instaladas"

# ═══════════════════════════════════════════════════════════
# PASO 6: HABILITAR MULTILIB
# ═══════════════════════════════════════════════════════════
print_step "6/35: Multilib (soporte 32-bit)"
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
  print_status "Habilitando repositorio multilib..."
  sudo sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
  sudo pacman -Sy
  print_success "Multilib habilitado"
else
  print_success "Multilib ya habilitado"
fi

# ═══════════════════════════════════════════════════════════
# PASO 7: HYPRLAND
# ═══════════════════════════════════════════════════════════
print_step "7/35: Hyprland Ecosystem"
print_installing "Hyprland + Waybar + Rofi + Dunst + Kitty/Zellij + Nix Packer"
sudo pacman -S --needed --noconfirm \
  hyprland xdg-desktop-portal-hyprland \
  waybar rofi-wayland dunst \
  kitty ghostty thunar nemo \
  grim slurp wl-clipboard cliphist \
  brightnessctl playerctl pamixer \
  swaync hyprlock hypridle hyprpicker \
  wofi fuzzel polkit-kde-agent udiskie \
  swww hyprpaper hyprshot \
  qt5-wayland qt6-wayland gtk-layer-shell

yay -S --needed --noconfirm zellij nix
print_success "Hyprland instalado"

# ═══════════════════════════════════════════════════════════
# PASO 8: DRIVERS
# ═══════════════════════════════════════════════════════════
print_step "8/35: Drivers Gráficos"
print_installing "Mesa + Vulkan + Drivers 32-bit"
sudo pacman -S --needed --noconfirm \
  mesa vulkan-icd-loader vulkan-intel intel-gpu-tools \
  lib32-mesa lib32-vulkan-icd-loader lib32-vulkan-intel \
  xf86-input-libinput xf86-input-synaptics
print_success "Drivers instalados"

# ═══════════════════════════════════════════════════════════
# PASO 9: CODECS
# ═══════════════════════════════════════════════════════════
print_step "9/35: Codecs Multimedia"
print_installing "FFmpeg + GStreamer + NTFS"
sudo pacman -S --needed --noconfirm \
  gst-plugins-base gst-plugins-good \
  gst-plugins-bad gst-plugins-ugly \
  gst-libav ffmpeg ntfs-3g exfatprogs
print_success "Codecs instalados"

# ═══════════════════════════════════════════════════════════
# PASO 10: UTILIDADES
# ═══════════════════════════════════════════════════════════
print_step "10/35: Utilidades del Sistema"
print_installing "Neovim + Zsh + Tmux + Yazi + Btop + Fastfetch"
sudo pacman -S --needed --noconfirm \
  neovim zsh zsh-autosuggestions zsh-syntax-highlighting \
  zsh-history-substring-search zsh-completions starship tmux zellij bat eza dust fd ripgrep fzf \
  htop btop bottom ncdu tree jq socat \
  yazi stow ranger imagemagick \
  inotify-tools acpi power-profiles-daemon cpupower \
  gparted partitionmanager udiskie \
  tig git-filter-repo man-db fastfetch networkmanager-dmenu gedit hyprsunset rsync gnome-system-monitor

print_installing "Utilidades extra AUR (pokemon-colorscripts, cava, zoxide)"
yay -S --needed --noconfirm --answerdiff=None --answerclean=None --removemake \
  pokemon-colorscripts cmatrix cava zoxide thefuck \
  2>/dev/null || print_warning "Algunas utilidades AUR fallaron"

print_success "Utilidades instaladas"

# ═══════════════════════════════════════════════════════════
# PASO 10.5: INSTALAR KEW MUSIC PLAYER (OPCIONAL)
# ═══════════════════════════════════════════════════════════
print_step "10.5/25: Kew Music Player (OPCIONAL)"
echo
read -p "¿Instalar Kew Music Player? (compila 2-3 min) [s/N]: " install_kew

if [[ "$install_kew" =~ ^[Ss]$ ]]; then
  print_installing "Dependencias para Kew Music Player"
  sudo pacman -S --needed --noconfirm \
    pkg-config faad2 taglib fftw gcc make chafa glib2 opus opusfile libvorbis libogg

  print_installing "Clonando y compilando Kew (2-3 min)"

  if [[ -d ~/kew ]]; then
    rm -rf ~/kew
  fi

  cd ~
  git clone https://github.com/ravachol/kew.git
  cd kew
  make -j$(nproc)
  sudo make install
  cd ~

  # Crear .desktop
  mkdir -p ~/.local/share/applications
  cat >~/.local/share/applications/kew.desktop <<'EOL'
[Desktop Entry]
Name=Kew Music Player
Comment=Terminal music player
Exec=kitty kew
Icon=audio-x-generic
Terminal=false
Type=Application
Categories=AudioVideo;Audio;Player;
EOL

  print_success "Kew instalado. Usa: kew en la terminal"
else
  print_warning "Kew omitido"
fi

# ═══════════════════════════════════════════════════════════
# PASO 11: GAMING (INTERACTIVO) - SOLO -BIN
# ═══════════════════════════════════════════════════════════
print_step "11/35: Gaming (Optimizado - Solo binarios)"

echo
echo -e "${BOLD}${YELLOW}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${YELLOW}║          🎮 CONFIGURACIÓN DE GAMING 🎮                    ║${NC}"
echo -e "${BOLD}${YELLOW}╚═══════════════════════════════════════════════════════════╝${NC}"
echo
echo -e "${CYAN}Se instalará en 3 categorías (SOLO BINARIOS):${NC}"
echo
echo -e "${BOLD}${GREEN}Categoría 1: Plataformas Base${NC} (~2GB)"
echo -e "  ${MAGENTA}•${NC} Steam"
echo -e "  ${MAGENTA}•${NC} Lutris"
echo -e "  ${MAGENTA}•${NC} Wine-staging + Winetricks"
echo -e "  ${MAGENTA}•${NC} GameMode"
echo -e "  ${MAGENTA}•${NC} Bottles para Juegos [Wine-GE]"
echo -e "  ${MAGENTA}•${NC} Geforce Experience, Infinitty, Now"
echo -e "  ${RED}•${NC} ${RED}Bottles (compila 1+ hora)${NC}"
echo
echo -e "${BOLD}${GREEN}Categoría 2: Compatibilidad Windows${NC} (~500MB)"
echo -e "  ${MAGENTA}•${NC} Proton-GE-bin (precompilado)"
echo -e "  ${MAGENTA}•${NC} VKD3D (DirectX 12 → Vulkan)"
echo -e "  ${MAGENTA}•${NC} DXVK-bin (precompilado)"
echo -e "  ${MAGENTA}•${NC} Wine-GE Custom"
echo
echo -e "${BOLD}${GREEN}Categoría 3: Emuladores${NC} (~1.5GB)"
echo -e "  ${MAGENTA}•${NC} Ryujinx-bin (precompilado)"
echo -e "  ${MAGENTA}•${NC} Dolphin (GameCube/Wii)"
echo -e "  ${MAGENTA}•${NC} SNES9x (Super Nintendo)"
echo
read -p "¿Instalar Plataformas Base (Steam, Lutris, Wine) y Geforce Experience? [S/n]: " install_base
read -p "¿Instalar Compatibilidad Windows (Proton-GE, VKD3D, DXVK)? [S/n]: " install_compat
read -p "¿Instalar Emuladores? [S/n]: " install_emu

# ═══════════════════════════════════════════════════════════
# Categoría 1: Plataformas Base
# ═══════════════════════════════════════════════════════════
if [[ ! "$install_base" =~ ^[Nn]$ ]]; then
  echo
  print_header "Instalando Plataformas Base de Gaming"

  print_installing "Steam + Lutris + GameMode + Wine-staging"
  sudo pacman -S --needed --noconfirm \
    steam lutris wine-staging winetricks bottles \
    gamemode lib32-gamemode

  print_installing "Geforce Experience"
  yay -S --needed --noconfirm --answerdiff=None --answerclean=None --removemake \
    gfn-electron geforce-infinity-bin

  print_success "Plataformas base instaladas"
  print_warning "Bottles omitido (instalar después con: yay -S bottles)"
else
  print_warning "Plataformas base omitidas"
fi

# ═══════════════════════════════════════════════════════════
# Categoría 2: Compatibilidad Windows
# ═══════════════════════════════════════════════════════════
if [[ ! "$install_compat" =~ ^[Nn]$ ]]; then
  echo
  print_header "Instalando Compatibilidad Windows"

  print_installing "Proton-GE-bin + VKD3D + DXVK-bin + Wine-GE"
  yay -S --needed --noconfirm --answerdiff=None --answerclean=None --removemake \
    proton-ge-custom-bin vkd3d-proton dxvk-bin wine-ge-custom \
    2>/dev/null || print_warning "Algunos paquetes fallaron"

  print_success "Compatibilidad Windows instalada"
else
  print_warning "Compatibilidad Windows omitida"
fi

# ═══════════════════════════════════════════════════════════
# Categoría 3: Emuladores
# ═══════════════════════════════════════════════════════════
if [[ ! "$install_emu" =~ ^[Nn]$ ]]; then
  echo
  print_header "Instalando Emuladores"

  print_installing "Ryujinx-bin + Dolphin + SNES9x"
  yay -S --needed --noconfirm --answerdiff=None --answerclean=None --removemake \
    ryujinx-bin dolphin-emu snes9x-gtk \
    2>/dev/null || print_warning "Algunos emuladores fallaron"

  print_success "Emuladores instalados"
else
  print_warning "Emuladores omitidos"
fi

print_success "Gaming configurado (sin compilaciones)"

# ═══════════════════════════════════════════════════════════
# PASO 12: CONTROLLERS (CORREGIDO - Conflicto joyutils)
# ═══════════════════════════════════════════════════════════
print_step "12/35: Controllers (PS3/PS4/PS5/Xbox)"
print_installing "Drivers para controles + Input Remapper"
sudo pacman -S --needed --noconfirm \
  evtest android-udev \
  libusb-compat xorg-xinput

# 🔴 CORRECCIÓN: Remover linuxconsole antes de instalar joyutils
sudo pacman -R --noconfirm linuxconsole 2>/dev/null || true

# Ahora instalar joyutils sin conflicto
sudo pacman -S --needed --noconfirm joyutils

yay -S --needed --noconfirm --answerdiff=None --answerclean=None --removemake \
  ds4drv xpadneo-dkms sixpair input-remapper \
  2>/dev/null || print_warning "Algunos drivers fallaron"

# Crear grupos
sudo groupadd uinput 2>/dev/null || true
sudo usermod -aG input,uinput $USER

print_success "Controllers configurados"

# ═══════════════════════════════════════════════════════════
# PASO 12.5: CONFIGURACIÓN ESPECÍFICA PS3 (INTERACTIVO)
# ═══════════════════════════════════════════════════════════
print_step "12.5/35: Configuración PS3 Controller (Interactivo)"

echo
read -p "¿Configurar PS3 controller específicamente? [s/N]: " setup_ps3

if [[ "$setup_ps3" =~ ^[Ss]$ ]]; then
  print_header "Configurando PS3 Controller"

  # Dependencias específicas PS3
  print_installing "Dependencias PS3 (bluez-ps3, sixpair, ds4drv)"
  yay -S --needed --noconfirm --answerdiff=None --answerclean=None --removemake \
    bluez-ps3 sixpair ds4drv 2>/dev/null || print_warning "Algunas dependencias fallaron"

  # Configurar kernel module
  print_status "Configurando módulo hid_sony"
  echo 'hid_sony' | sudo tee /etc/modules-load.d/hid_sony.conf
  sudo modprobe hid_sony 2>/dev/null || true

  # Script de conexión PS3
  print_status "Creando script de conexión PS3"
  cat >~/conectar-ps3.sh <<'EOL'
#!/bin/bash
# Script para conectar PS3 controller

echo "🎮 Configurando PS3 Controller"
echo

# Verificar bluetooth
if ! systemctl is-active --quiet bluetooth; then
    echo "❌ Bluetooth no activo. Iniciando..."
    sudo systemctl start bluetooth
    sleep 2
fi

# Desbloquear RF
sudo rfkill unblock bluetooth

echo "✅ Bluetooth activo"
echo
echo "📋 INSTRUCCIONES:"
echo "  1. Conecta el mando por USB"
echo "  2. Presiona el botón PS durante 10 segundos"
echo "  3. Desconecta el USB"
echo "  4. Presiona PS nuevamente para emparejar"
echo
read -p "Presiona Enter cuando hayas conectado el mando por USB..."

# Ejecutar sixpair si está disponible
if command -v sixpair &>/dev/null; then
    echo "🔧 Ejecutando sixpair..."
    sudo sixpair
fi

echo
echo "🔵 Iniciando bluetoothctl..."
echo
echo "Comandos a ejecutar:"
echo "  1. default-agent"
echo "  2. power on"
echo "  3. scan on"
echo "Si tienes caelestia puedes usar su interfaz bluetooth para:"
echo "  4. trust [MAC_DEL_CONTROL]"
echo "  5. pair [MAC_DEL_CONTROL]"
echo "  6. connect [MAC_DEL_CONTROL]"
echo "desconecta el control Y Prende bluetooth"
echo
bluetoothctl
EOL

  chmod +x ~/conectar-ps3.sh

  print_success "PS3 configurado"
  print_status "Ejecuta: ~/conectar-ps3.sh para conectar tu control"

  # Ofrecer conectar ahora
  echo
  read -p "¿Conectar PS3 controller ahora? [s/N]: " connect_now

  if [[ "$connect_now" =~ ^[Ss]$ ]]; then
    ~/conectar-ps3.sh
  fi
else
  print_warning "Configuración PS3 omitida"
fi

# ═══════════════════════════════════════════════════════════
# PASO 13: APLICACIONES (SOLO -BIN)
# ═══════════════════════════════════════════════════════════
print_step "13/35: Aplicaciones (Solo binarios precompilados)"
print_installing "Firefox + VLC [+plugins] + OBS + GIMP + Krita + LibreOffice"
sudo pacman -S --needed --noconfirm \
  firefox vlc vlc-plugins-all mpv obs-studio \
  gimp inkscape krita \
  libreoffice-fresh filezilla transmission-gtk \
  pavucontrol loupe \
  scrcpy android-file-transfer \
  gvfs gvfs-gphoto2 kio-extras libxfce4ui

# ═══════════════════════════════════════════════════════════
# Kdenlive - Selección interactiva
# ═══════════════════════════════════════════════════════════
echo
echo -e "${BOLD}${YELLOW}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${YELLOW}║          🎬 KDENLIVE (EDITOR DE VIDEO) 🎬                ║${NC}"
echo -e "${BOLD}${YELLOW}╚═══════════════════════════════════════════════════════════╝${NC}"
echo
echo -e "${CYAN}Opciones disponibles:${NC}"
echo
echo -e "${BOLD}${GREEN}1. Solo Kdenlive${NC} (~150MB)"
echo -e "  ${MAGENTA}•${NC} Editor de video profesional (como Filmora)"
echo -e "  ${MAGENTA}•${NC} Compresor de video integrado (Ctrl+Enter)"
echo -e "  ${MAGENTA}•${NC} Sin dependencias extras de KDE"
echo
echo -e "${BOLD}${GREEN}2. Kdenlive + Dependencias Completas${NC} (~350MB)"
echo -e "  ${MAGENTA}•${NC} Kdenlive completo"
echo -e "  ${MAGENTA}•${NC} qt6-imageformats (mejor soporte de imágenes)"
echo -e "  ${MAGENTA}•${NC} kimageformats (formatos adicionales)"
echo -e "  ${MAGENTA}•${NC} recordmydesktop (grabación de pantalla)"
echo -e "  ${MAGENTA}•${NC} plasma-desktop (integración KDE)"
echo
echo -e "${BOLD}${GREEN}3. Ninguno${NC}"
echo -e "  ${MAGENTA}•${NC} Omitir instalación de Kdenlive"
echo
read -p "Seleccionar opción [1=Solo Kdenlive, 2=Con dependencias, 3=Ninguno]: " kdenlive_choice

case "$kdenlive_choice" in
1)
  print_header "Instalando Kdenlive (Solo)"
  print_installing "kdenlive"
  yay -S --needed --noconfirm --answerdiff=None --answerclean=None --removemake \
    kdenlive \
    2>/dev/null || print_warning "Kdenlive falló"
  print_success "Kdenlive instalado"
  ;;
2)
  print_header "Instalando Kdenlive + Dependencias"
  print_installing "kdenlive + qt6-imageformats + kimageformats + recordmydesktop + plasma-desktop"
  yay -S --needed --noconfirm --answerdiff=None --answerclean=None --removemake \
    kdenlive qt6-imageformats kimageformats recordmydesktop plasma-desktop \
    2>/dev/null || print_warning "Algunas dependencias de Kdenlive fallaron"
  print_success "Kdenlive + dependencias instalado"
  ;;
*)
  print_warning "Kdenlive omitido"
  ;;
esac

# ═══════════════════════════════════════════════════════════
# Aplicaciones de música y ocio
# ═══════════════════════════════════════════════════════════
print_installing "Aplicaciones extra y de Música/OCIO (solo binarios precompilados)"
yay -S --needed --noconfirm --answerdiff=None --answerclean=None --removemake \
  brave-bin spotify pear-desktop \
  vencord-bin gyazo-bin discord-screenaudio-bin \
  2>/dev/null || print_warning "Algunas apps fallaron"
# Youtube Music cambió de nombre a Pear Desktop

# ═══════════════════════════════════════════════════════════
# Selección interactiva de editor de código
# ═══════════════════════════════════════════════════════════
echo
echo -e "${BOLD}${YELLOW}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${YELLOW}║          💻 SELECCIONAR EDITOR DE CÓDIGO 💻              ║${NC}"
echo -e "${BOLD}${YELLOW}╚═══════════════════════════════════════════════════════════╝${NC}"
echo
echo -e "${CYAN}Opciones disponibles:${NC}"
echo
echo -e "${BOLD}${GREEN}1. Visual Studio Code${NC} (vscode-bin + code-features)"
echo -e "  ${MAGENTA}•${NC} Editor más popular"
echo -e "  ${MAGENTA}•${NC} Extensiones oficiales de Microsoft"
echo -e "  ${MAGENTA}•${NC} Incluye code-features para mejor integración"
echo
echo -e "${BOLD}${GREEN}2. Cursor${NC} (cursor-bin)"
echo -e "  ${MAGENTA}•${NC} Fork de VSCode con IA integrada"
echo -e "  ${MAGENTA}•${NC} Copilot++ nativo"
echo -e "  ${MAGENTA}•${NC} Compatible con extensiones de VSCode"
echo
echo -e "${BOLD}${GREEN}3. Antigravity${NC} (yay)"
echo -e "  ${MAGENTA}•${NC} Editor experimental"
echo -e "  ${MAGENTA}•${NC} Ligero y rápido"
echo
echo -e "${BOLD}${GREEN}4. Ninguno${NC}"
echo -e "  ${MAGENTA}•${NC} Omitir instalación de editor"
echo
read -p "Seleccionar editor [1=VSCode, 2=Cursor, 3=Antigravity, 4=Ninguno]: " editor_choice

case "$editor_choice" in
1)
  print_header "Instalando Visual Studio Code"
  print_installing "visual-studio-code-bin + code-features"
  yay -S --needed --noconfirm --answerdiff=None --answerclean=None --removemake \
    visual-studio-code-bin code-features \
    2>/dev/null || print_warning "VSCode falló"

  # Aplicar dotfiles de vscode si existen
  if [[ -d ~/dotfiles-dizzi/vscode ]]; then
    cd ~/dotfiles-dizzi
    stow vscode 2>/dev/null || print_warning "Stow vscode falló"
    cd ~
  fi

  print_success "Visual Studio Code instalado"
  ;;
2)
  print_header "Instalando Cursor"
  print_installing "cursor-bin"
  yay -S --needed --noconfirm --answerdiff=None --answerclean=None --removemake \
    cursor-bin \
    2>/dev/null || print_warning "Cursor falló"

  # Aplicar dotfiles de cursor si existen
  if [[ -d ~/dotfiles-dizzi/cursor ]]; then
    cd ~/dotfiles-dizzi
    stow cursor 2>/dev/null || print_warning "Stow cursor falló"
    cd ~
  fi

  print_success "Cursor instalado"
  ;;
3)
  print_header "Instalando Antigravity"
  print_installing "antigravity desde yay"
  yay -S --needed --noconfirm --answerdiff=None --answerclean=None --removemake \
    antigravity \
    2>/dev/null || print_warning "Antigravity falló"

  print_success "Antigravity instalado"
  ;;
*)
  print_warning "Editor de código omitido"
  ;;
esac

# ═══════════════════════════════════════════════════════════
# Extras
# ═══════════════════════════════════════════════════════════
print_installing "Extras (SOLO -bin, sin compilar)"
yay -S --needed --noconfirm --answerdiff=None --answerclean=None --removemake \
  stacer-bin jdownloader2 megasync \
  appimagelauncher music-presence-bin copyq pamac-aur \
  2>/dev/null || print_warning "Algunos extras fallaron"

print_success "Aplicaciones instaladas (solo binarios)"

# ═══════════════════════════════════════════════════════════
# PASO 13.5: STREMIO (AUR vs FLATPAK)
# ═══════════════════════════════════════════════════════════
print_step "13.5/35: Stremio (Opción: AUR o Flatpak+Server)"

echo
echo -e "${CYAN}Opciones de Stremio:${NC}"
echo -e "  ${MAGENTA}1.${NC} Compilar desde AUR (~10-15 min, nativo)"
echo -e "  ${MAGENTA}2.${NC} Omitir compilación"
echo
read -p "¿Intentar compilar Stremio nativo? [s/N]: " install_stremio_aur

# Variable para saber si ya se instaló Stremio
STREMIO_INSTALLED=false

if [[ "$install_stremio_aur" =~ ^[Ss]$ ]]; then
  print_header "Instalando Stremio Nativo (~10-15 minutos)"

  if yay -S --needed --noconfirm --answerdiff=None --answerclean=None --removemake stremio 2>/dev/null; then
    print_success "Stremio (AUR) instalado"
    STREMIO_INSTALLED=true
  else
    print_error "Stremio (AUR) falló"
  fi
else
  print_warning "Compilación nativa omitida"
fi

# Si no se instaló la versión AUR (porque se omitió o falló), ofrecer Flatpak
if [[ "$STREMIO_INSTALLED" == false ]]; then
  echo
  echo -e "${YELLOW}¿Instalar Stremio Service (Browser) via Flatpak? (Recomendado)${NC}"
  echo -e "  ${CYAN}•${NC} Instalación instantánea (sin compilar)"
  echo -e "  ${CYAN}•${NC} Incluye Stremio Server (funciona en navegador)"
  echo -e "  ${CYAN}•${NC} Aislado y seguro"
  echo
  read -p "¿Instalar Stremio WEB + Flatpak setup? [S/n]: " install_stremio_flatpak

  if [[ ! "$install_stremio_flatpak" =~ ^[Nn]$ ]]; then
    # ═══════════════════════════════════════════════════════════
    # SETUP FLATPAK
    # ═══════════════════════════════════════════════════════════
    print_installing "Configurando entorno Flatpak..."

    # Instalar Flatpak si no está
    if ! command -v flatpak &>/dev/null; then
      sudo pacman -S --needed --noconfirm flatpak
    fi

    # Agregar Flathub
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

    # CRÍTICO: Configurar XDG_DATA_DIRS para que las apps aparezcan en rofi/wofi
    print_status "Configurando visibilidad de apps Flatpak..."

    FLATPAK_EXPORTS='
# Flatpak exports para que apps aparezcan en launcher
export XDG_DATA_DIRS="$XDG_DATA_DIRS:/var/lib/flatpak/exports/share:/home/$USER/.local/share/flatpak/exports/share"'

    # Agregar a .zshrc
    if [[ -f ~/.zshrc ]]; then
      if ! grep -q "flatpak/exports/share" ~/.zshrc; then
        echo "$FLATPAK_EXPORTS" >>~/.zshrc
        print_success "XDG_DATA_DIRS agregado a .zshrc"
      fi
    fi

    # Agregar a .bashrc
    if [[ -f ~/.bashrc ]]; then
      if ! grep -q "flatpak/exports/share" ~/.bashrc; then
        echo "$FLATPAK_EXPORTS" >>~/.bashrc
        print_success "XDG_DATA_DIRS agregado a .bashrc"
      fi
    fi

    # Agregar a hyprland.conf (CRUCIAL para Wayland launch)
    if [[ -f ~/.config/hypr/hyprland.conf ]]; then
      if ! grep -q "XDG_DATA_DIRS.*flatpak" ~/.config/hypr/hyprland.conf; then
        echo "" >>~/.config/hypr/hyprland.conf
        echo "# Flatpak apps visibility" >>~/.config/hypr/hyprland.conf
        echo 'env = XDG_DATA_DIRS,$XDG_DATA_DIRS:/var/lib/flatpak/exports/share:/home/diego/.local/share/flatpak/exports/share' >>~/.config/hypr/hyprland.conf
        print_success "Env vars agregadas a Hyprland config"
      fi
    fi

    # Instalar Stremio Flatpak
    print_installing "Stremio (Flatpak)"
    flatpak install -y flathub com.stremio.Stremio
    print_success "Stremio Flatpak instalado"

    # Instalación de Stremio Server (Docker o binario) - Opcional, pero Stremio Flatpak ya trae lo básico
    # Si quieres el server standalone para navegador:
    # print_installing "Stremio Server"
    # ... (lógica server server si es necesaria, pero usualmente el cliente basta o se usa web)

    # Opcional: Instalar otras apps Flatpak ya que estamos aquí
    echo
    read -p "¿Aprovechar Flatpak para Discord/OBS/Telegram? [s/N]: " install_more_flatpaks

    if [[ "$install_more_flatpaks" =~ ^[Ss]$ ]]; then
      read -p "  ¿Instalar Discord? [s/N]: " f_discord
      read -p "  ¿Instalar OBS Studio? [s/N]: " f_obs
      read -p "  ¿Instalar Telegram? [s/N]: " f_telegram

      [[ "$f_discord" =~ ^[Ss]$ ]] && flatpak install -y flathub com.discordapp.Discord
      [[ "$f_obs" =~ ^[Ss]$ ]] && flatpak install -y flathub com.obsproject.Studio
      [[ "$f_telegram" =~ ^[Ss]$ ]] && flatpak install -y flathub org.telegram.desktop
    fi

    print_warning "IMPORTANTE: Cierre sesión para ver las apps Flatpak en el menú"
  else
    print_warning "Stremio (Flatpak) omitido"
  fi
fi

# ═══════════════════════════════════════════════════════════
# PASO 14: DEV TOOLS
# ═══════════════════════════════════════════════════════════
print_step "14/35: Herramientas de Desarrollo"
print_installing "Docker + Node.js + Python + Rust (repos)"
sudo pacman -S --needed --noconfirm \
  nodejs npm python python-pip python-gobject python-pipx \
  docker docker-compose rust \
  llvm clang patchelf git github-cli tgpt

sudo systemctl enable docker
sudo usermod -aG docker $USER

print_installing "Python LSP + Neovim support"
python -m pip install --user --break-system-packages pynvim 'python-lsp-server[all]' 2>/dev/null || true

print_installing "Node packages (neovim)"
npm install -g neovim 2>/dev/null || true

# Gemini CLI - Interactivo
echo
read -p "¿Instalar Gemini CLI? (omitir si ya lo tienes configurado) [s/N]: " install_gemini

if [[ "$install_gemini" =~ ^[Ss]$ ]]; then
  print_installing "Gemini CLI"
  pipx install google-generativeai 2>/dev/null || true
  npm install -g @google/gemini-cli 2>/dev/null || true
  print_success "Gemini CLI instalado"
  print_status "Configura con: gemini-cli setup"
else
  print_warning "Gemini CLI omitido"
fi

print_success "Dev tools instalados"

# ═══════════════════════════════════════════════════════════
# PASO 15: ZSH + OH-MY-ZSH
# ═══════════════════════════════════════════════════════════
print_step "15/35: Zsh + Oh-My-Zsh"

if [[ -f ~/dotfiles-dizzi/home/zsh-istall.sh ]]; then
  print_installing "Ejecutando zsh-istall.sh"
  sudo chmod +x ~/dotfiles-dizzi/home/zsh-istall.sh
  ~/dotfiles-dizzi/home/zsh-istall.sh
  print_success "ZSH configurado con script dizzi"
else
  print_warning "zsh-istall.sh no encontrado, instalando manual..."

  if [[ ! -d ~/.oh-my-zsh ]]; then
    print_installing "Oh-My-Zsh + Plugins"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

    ZSH_CUSTOM="${ZSH_CUSTOM:-~/.oh-my-zsh/custom}"

    git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions 2>/dev/null || true
    git clone https://github.com/zsh-users/zsh-syntax-highlighting $ZSH_CUSTOM/plugins/zsh-syntax-highlighting 2>/dev/null || true
    git clone https://github.com/zsh-users/zsh-completions $ZSH_CUSTOM/plugins/zsh-completions 2>/dev/null || true
    git clone https://github.com/zsh-users/zsh-history-substring-search $ZSH_CUSTOM/plugins/zsh-history-substring-search 2>/dev/null || true

    # Plugins extra que tu .zshrc busca en ~/.zsh/
    print_installing "Plugins extra (zsh-autocomplete, fzf-tab)"
    mkdir -p ~/.zsh

    if [[ ! -d ~/.zsh/zsh-autocomplete ]]; then
      git clone --depth 1 https://github.com/marlonrichert/zsh-autocomplete.git ~/.zsh/zsh-autocomplete 2>/dev/null || true
    fi

    if [[ ! -d ~/.zsh/fzf-tab ]]; then
      git clone --depth 1 https://github.com/Aloxaf/fzf-tab.git ~/.zsh/fzf-tab 2>/dev/null || true
    fi

    print_success "Oh-My-Zsh y plugins instalados"
  else
    print_success "Oh-My-Zsh ya instalado"

    # Asegurar plugins extra incluso si OMZ ya estaba
    mkdir -p ~/.zsh
    [[ ! -d ~/.zsh/zsh-autocomplete ]] && git clone --depth 1 https://github.com/marlonrichert/zsh-autocomplete.git ~/.zsh/zsh-autocomplete 2>/dev/null || true
    [[ ! -d ~/.zsh/fzf-tab ]] && git clone --depth 1 https://github.com/Aloxaf/fzf-tab.git ~/.zsh/fzf-tab 2>/dev/null || true
  fi
fi

sudo chsh -s $(which zsh) $USER 2>/dev/null || print_warning "Cambio de shell manual requerido"

# ═══════════════════════════════════════════════════════════
# PASO 16: DOTFILES
# ═══════════════════════════════════════════════════════════
print_step "16/35: Dotfiles dizzi1222"
if [[ ! -d ~/dotfiles-dizzi ]]; then
  print_installing "Clonando dotfiles desde GitHub"
  git clone https://github.com/dizzi1222/dotfiles-dizzi.git ~/dotfiles-dizzi || {
    print_warning "Error clonando dotfiles"
  }
fi

if [[ -d ~/dotfiles-dizzi ]]; then
  cd ~/dotfiles-dizzi

  print_status "Inicializando submódulos git..."
  git submodule update --init --recursive 2>/dev/null || print_warning "No hay submódulos o falló su actualización"

  print_status "Aplicando dotfiles con stow..."

  for pkg in kdenlive-compressor-editor pipewire sattyScreenshots Antigravity networkmanager-fuzzel nwg-gtk-3.0 nwg-gtk-4.0 qt5ct qt6ct thunar ibus Raycast-vicinae fuzzel-glyphs-rofimoji autostart copyq dunst easyeffects swaync espanso eww fastfetch font ghostty home hypr kew kitty local nvim rofi systemd themes wal wallpapers waybar wireplumber wofi yazi zsh input-remapper quickshell caelestia icons firefox vscode cursor manual-ln htop neofetch tmux polybar bottom starship qtile; do
    if [[ -d $pkg ]]; then
      print_package "Stow: $pkg"
      stow $pkg 2>/dev/null || print_warning "Stow falló para $pkg"
    fi
  done

  cd ~
  print_success "Dotfiles aplicados"
fi

# ═══════════════════════════════════════════════════════════
# PASO 17: SYMLINKS A /etc
# ═══════════════════════════════════════════════════════════
print_step "17/35: Symlinks a /etc (udev/polkit/bluetooth/pam.d) para Gnome Keyring y mas"

if [[ -d ~/dotfiles-dizzi/etc ]]; then
  print_status "Creando symlinks desde dotfiles a /etc"

  # UDEV rules para controles
  if [[ -f ~/dotfiles-dizzi/etc/udev/rules.d/99-dualsense-controllers.rules ]]; then
    print_package "Symlink: DualSense (PS5)"
    sudo ln -sf ~/dotfiles-dizzi/etc/udev/rules.d/99-dualsense-controllers.rules /etc/udev/rules.d/
  fi

  if [[ -f ~/dotfiles-dizzi/etc/udev/rules.d/99-ds4-controllers.rules ]]; then
    print_package "Symlink: DualShock 4 (PS4)"
    sudo ln -sf ~/dotfiles-dizzi/etc/udev/rules.d/99-ds4-controllers.rules /etc/udev/rules.d/
  fi

  if [[ -f ~/dotfiles-dizzi/etc/udev/rules.d/99-ds3-controllers.rules ]]; then
    print_package "Symlink: DualShock 3 (PS3)"
    sudo ln -sf ~/dotfiles-dizzi/etc/udev/rules.d/99-ds3-controllers.rules /etc/udev/rules.d/
  fi

  # Bluetooth input config
  if [[ -f ~/dotfiles-dizzi/etc/bluetooth/input.conf ]]; then
    print_package "Symlink: Bluetooth input.conf (deshabilitar PIN)"
    sudo ln -sf ~/dotfiles-dizzi/etc/bluetooth/input.conf /etc/bluetooth/
  fi

  # Input Remapper UDEV + Polkit
  if [[ -f ~/dotfiles-dizzi/etc/udev/rules.d/99-input-remapper.rules ]]; then
    print_package "Symlink: Input Remapper UDEV"
    sudo ln -sf ~/dotfiles-dizzi/etc/udev/rules.d/99-input-remapper.rules /etc/udev/rules.d/
  fi

  if [[ -f ~/dotfiles-dizzi/etc/polkit-1/rules.d/90-input-remapper-user.rules ]]; then
    print_package "Symlink: Input Remapper Polkit"
    sudo mkdir -p /etc/polkit-1/rules.d
    sudo ln -sf ~/dotfiles-dizzi/etc/polkit-1/rules.d/90-input-remapper-user.rules /etc/polkit-1/rules.d/
  fi

  # Para permisos de luces
  if [[ -f ~/dotfiles-dizzi/etc/udev/rules.d/90-kbd-backlight.rules ]]; then
    print_package "Symlink: Luces de teclado"
    sudo ln -sf ~/dotfiles-dizzi/etc/udev/rules.d/90-kbd-backlight.rules /etc/udev/rules.d/90-kbd-backlight.rules
  fi

  # GRUB config
  if [[ -f ~/dotfiles-dizzi/etc/default/grub ]]; then
    print_package "Symlink: GRUB config"
    sudo ln -sf ~/dotfiles-dizzi/etc/default/grub /etc/default/
  fi

  
# Para solucionar gnome Keyring en SDDM y GNOME
  if [[ -f ~/dotfiles-dizzi/etc/pam.d/sddm ]]; then
    print_package "Symlink: SDDM pam.d para Gnome Keyring"
    sudo pacman -S gnome-keyring --needed --noconfirm
    sudo ln -sf ~/dotfiles-dizzi/etc/pam.d/sddm /etc/pam.d/sddm
  fi

# Para solucionar Suspender al cerrar la laptop, viceversa
  if [[ -f ~/dotfiles-dizzi/etc/systemd/logind.conf ]]; then
    print_package "Symlink: Suspender al cerrar la laptop, viceversa"
    sudo ln -sf ~/dotfiles-dizzi/etc/systemd/logind.conf /etc/systemd/logind.conf
    # sudo systemctl restart systemd-logind
    print_status "Recuerda usar:
    sudo systemctl restart systemd-logind   O reiniciar el sistema
    systemctl status systemd-logind   para ver si se ejecuto
  "
  fi

  # Recargar servicios
  print_status "Recargando udev y polkit..."
  sudo udevadm control --reload-rules
  sudo udevadm trigger
  sudo systemctl restart polkit 2>/dev/null || true

  print_success "Symlinks a /etc creados"
else
  print_warning "No se encontró ~/dotfiles-dizzi/etc, omitiendo symlinks"
fi

# ═══════════════════════════════════════════════════════════
# PASO 19: SERVICIOS DEL SISTEMA
# ═══════════════════════════════════════════════════════════
print_step "19/35: Servicios del Sistema"
print_installing "UFW Firewall + Power Profiles"
sudo pacman -S --needed --noconfirm ufw
sudo ufw enable
sudo systemctl enable ufw
sudo systemctl enable power-profiles-daemon

print_status "Agregando usuario a grupos..."
for group in video audio storage input docker wheel uinput; do
  sudo usermod -aG $group $USER 2>/dev/null || true
  print_package "Grupo: $group"
done

print_success "Servicios del sistema configurados"

# ═══════════════════════════════════════════════════════════
# PASO 20: SERVICIOS SYSTEMD USER
# ═══════════════════════════════════════════════════════════
print_step "20/35: Servicios Systemd (User)"

echo
read -p "¿Habilitar servicios systemd de usuario? [S/n]: " enable_services

if [[ ! "$enable_services" =~ ^[Nn]$ ]]; then
  print_status "Habilitando servicios systemd de usuario..."

  # Gemini CLI
  if [[ -f ~/.config/systemd/user/gemini.service ]]; then
    print_package "Habilitando: gemini.service"
    systemctl --user enable gemini.service 2>/dev/null || print_warning "gemini.service no encontrado"
    systemctl --user start gemini.service 2>/dev/null || true
  fi

# Espanso
if [[ -f ~/.config/systemd/user/espanso.service ]]; then
  killall espanso 2>/dev/null || true
  print_package "Habilitando: espanso.service"
  
  # Registrar servicio si no está registrado
  espanso service register 2>/dev/null || true
  
  # Habilitar e iniciar via systemd (NO usar 'espanso start' directamente)
  systemctl --user enable espanso.service 2>/dev/null || print_warning "espanso.service no encontrado"
  systemctl --user start espanso.service 2>/dev/null || true
  
  # Esperar 2 segundos para que inicie
  sleep 2
  
  print_success "Espanso iniciado via systemd"
fi

  # Kanata
  if [[ -f ~/.config/systemd/user/kanata.service ]]; then
    print_package "Habilitando: kanata.service"
    systemctl --user enable kanata.service 2>/dev/null || print_warning "kanata.service no encontrado"
    systemctl --user start kanata.service 2>/dev/null || true
  fi

  # GDrive mount
  if [[ -f ~/.config/systemd/user/montar_gdrive.service ]]; then
    print_package "Habilitando: montar_gdrive.service"
    systemctl --user enable montar_gdrive.service 2>/dev/null || print_warning "montar_gdrive.service no encontrado"
    systemctl --user start montar_gdrive.service 2>/dev/null || true
  fi

  # GDrive música
  if [[ -f ~/.config/systemd/user/montar_gdmusica.service ]]; then
    print_package "Habilitando: montar_gdmusica.service"
    systemctl --user enable montar_gdmusica.service 2>/dev/null || print_warning "montar_gdmusica.service no encontrado"
    systemctl --user start montar_gdmusica.service 2>/dev/null || true
  fi

  # MPRIS cover update
  if [[ -f ~/.config/systemd/user/update-cover.loop.service ]]; then
    print_package "Habilitando: update-cover.loop.service"
    systemctl --user enable update-cover.loop.service 2>/dev/null || print_warning "update-cover.loop.service no encontrado"
    systemctl --user start update-cover.loop.service 2>/dev/null || true
  fi

  # ydotool
  if [[ -f ~/.config/systemd/user/ydotool.service ]]; then
    print_package "Habilitando: ydotool.service"
    systemctl --user enable ydotool.service 2>/dev/null || print_warning "ydotool.service no encontrado"
    systemctl --user start ydotool.service 2>/dev/null || true
  fi

  print_success "Servicios de usuario habilitados"
else
  print_warning "Servicios de usuario omitidos"
fi

# Input-remapper (system service) - CORREGIDO: nombre correcto del servicio
print_status "Habilitando input-remapper (system service)..."
if systemctl list-unit-files | grep -q "input-remapper"; then
  sudo systemctl enable --now input-remapper 2>/dev/null || sudo systemctl enable --now input-remapper.service 2>/dev/null
  print_success "input-remapper habilitado"
else
  print_warning "input-remapper no encontrado (instalar con: yay -S input-remapper-git)"
fi

# ═══════════════════════════════════════════════════════════
# PASO 21: WINE PREFIX
# ═══════════════════════════════════════════════════════════
print_step "21/35: Wine Prefix (Interactivo)"

echo
read -p "¿Configurar Wine prefix ahora? [S/n]: " setup_wine

if [[ ! "$setup_wine" =~ ^[Nn]$ ]]; then
  print_installing "Inicializando Wine prefix"
  export WINEPREFIX=~/.wine
  export WINEARCH=win64
  wineboot -u 2>/dev/null &
  sleep 5

  print_installing "Instalando componentes Wine con winetricks"
  winetricks -q corefonts dotnet40 dotnet48 dxvk d3dx9 vcrun2022 2>/dev/null || print_warning "Algunos winetricks fallaron"
  winetricks -q d3dcompiler_47 d3dx11_42 win10 vigem 2>/dev/null || print_warning "Algunos winetricks fallaron"

  #Redis Code Gaming
  print_installing "Instalando componentes de Redis C++ Code Gaming (Y dependencias para RE4)"
  WINEPREFIX=/home/diego/.wine winetricks -q vcrun2013 vcrun2022 vcrun2012 vcrun2010 vcrun2008 vcrun2005
  # 🚨 󰀦 Instala Media Foundation y codecs [para RE4]
  WINEPREFIX=/home/diego/.wine winetricks -q mf wmv9 quartz

  # Wine Dark Theme
  read -p "¿Aplicar Wine Dark Theme? [S/n]: " apply_dark
  if [[ ! "$apply_dark" =~ ^[Nn]$ ]]; then
    if [[ -f ~/dotfiles-dizzi/wine-breeze-dark.reg ]]; then
      print_installing "Aplicando Wine Dark Theme"
      wine regedit ~/dotfiles-dizzi/wine-breeze-dark.reg 2>/dev/null || true
      print_success "Wine Dark Theme aplicado"
    else
      print_warning "wine-breeze-dark.reg no encontrado"
    fi
  fi

  print_success "Wine configurado"
else
  print_warning "Wine prefix omitido"
fi

# ═══════════════════════════════════════════════════════════
# PASO 21.5: BOTTLES SETUP (DESPUÉS DE WINE PREFIX)
# ═══════════════════════════════════════════════════════════
print_step "21.5/35: Bottles Gaming Setup (Opcional)"

echo
echo -e "${BOLD}${YELLOW}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${YELLOW}║          🍷 BOTTLES GAMING SETUP 🍷                       ║${NC}"
echo -e "${BOLD}${YELLOW}╚═══════════════════════════════════════════════════════════╝${NC}"
echo
echo -e "${CYAN}Bottles es una alternativa moderna a Wine prefix tradicional:${NC}"
echo
echo -e "${GREEN}Ventajas:${NC}"
echo -e "  ${MAGENTA}•${NC} GUI intuitiva para gestionar juegos/apps"
echo -e "  ${MAGENTA}•${NC} Cambio fácil entre Wine-GE y Proton-GE"
echo -e "  ${MAGENTA}•${NC} Creación automática de .desktop files"
echo -e "  ${MAGENTA}•${NC} Mejor compatibilidad con juegos modernos"
echo -e "  ${MAGENTA}•${NC} Gestión de dependencias simplificada"
echo
echo -e "${YELLOW}Nota:${NC} La instalación de Bottles compila ~1 hora"
echo
read -p "¿Configurar Bottles para gaming? [s/N]: " setup_bottles

if [[ "$setup_bottles" =~ ^[Ss]$ ]]; then
  print_header "Configurando Bottles"
  
  # Verificar si install-bottles.sh existe
  BOTTLES_SCRIPT_PATHS=(
    ~/dotfiles-dizzi/home/install-bottles.sh
    ~/install-bottles.sh
    ~/Descargas/install-bottles.sh
  )
  
  BOTTLES_SCRIPT=""
  for path in "${BOTTLES_SCRIPT_PATHS[@]}"; do
    if [[ -f "$path" ]]; then
      BOTTLES_SCRIPT="$path"
      break
    fi
  done
  
  if [[ -z "$BOTTLES_SCRIPT" ]]; then
    print_warning "install-bottles.sh no encontrado"
    print_status "Descargando script desde repositorio..."
    
    wget -q https://raw.githubusercontent.com/dizzi1222/dotfiles-dizzi/main/home/install-bottles.sh \
      -O ~/install-bottles.sh 2>/dev/null || {
      print_error "Error descargando script"
      print_info "Instalación manual: yay -S bottles"
    }
    
    BOTTLES_SCRIPT=~/install-bottles.sh
  fi
  
  if [[ -f "$BOTTLES_SCRIPT" ]]; then
    chmod +x "$BOTTLES_SCRIPT"
    print_status "Ejecutando configuración de Bottles..."
    "$BOTTLES_SCRIPT"
    
    print_success "Bottles configurado"
  else
    print_error "No se pudo ejecutar install-bottles.sh"
  fi
  
else
  print_warning "Bottles omitido (puedes instalarlo después con: yay -S bottles)"
fi

# ═══════════════════════════════════════════════════════════
# PASO 22: SPOTIFY SPICETIFY
# ═══════════════════════════════════════════════════════════
print_step "22/35: Spicetify (Opcional)"
if command -v spotify &>/dev/null; then
  print_installing "Spicetify + Marketplace"
  curl -fsSL https://raw.githubusercontent.com/spicetify/cli/main/install.sh | sh 2>/dev/null || true
  sudo chown -R $USER:$USER /opt/spotify/ 2>/dev/null || true
  spicetify backup apply 2>/dev/null || true
  curl -fsSL https://raw.githubusercontent.com/spicetify/marketplace/main/resources/install.sh | sh 2>/dev/null || true
  print_success "Spicetify instalado"
else
  print_warning "Spotify no detectado"
fi

# ═════════════════════════════════════════════════════════════
# PASO 23: EXTRAS, CURSORES, PRESETS
# ═════════════════════════════════════════════════════════════
print_step "23/35: Extras (Cursor, Presets)"

echo
read -p "¿Instalar extras? [S/n]: " install_extras

if [[ ! "$install_extras" =~ ^[Nn]$ ]]; then

  # ═══════════════════════════════════════════════════════════
  # Kafka Cursor - CORREGIDO CON BÚSQUEDA MÚLTIPLE
  # ═══════════════════════════════════════════════════════════
  print_installing "Buscando Kafka cursor"

  # Buscar archivo Kafka.tar.gz en múltiples ubicaciones
  KAFKA_PATHS=(
    ~/dotfiles-dizzi/cursor/Kafka.tar.gz
    ~/dotfiles-dizzi/home/Kafka.tar.gz
    ~/dotfiles-dizzi/Kafka.tar.gz
    ~/Kafka.tar.gz
  )

  KAFKA_FOUND=false
  for path in "${KAFKA_PATHS[@]}"; do
    if [[ -f "$path" ]]; then
      print_status "Kafka encontrado en: $path"
      mkdir -p ~/.icons
      tar -xzf "$path" -C ~/.icons/ 2>/dev/null || {
        print_error "Error extrayendo Kafka desde $path"
        continue
      }

      # Configurar cursor
      if [[ -d ~/.icons/Kafka ]]; then
        # GNOME/GTK
        gsettings set org.gnome.desktop.interface cursor-theme 'Kafka' 2>/dev/null || true
        gsettings set org.gnome.desktop.interface cursor-size 24 2>/dev/null || true

        # Hyprland cursor config
        if [[ -f ~/.config/hypr/hyprland.conf ]]; then
          if ! grep -q "XCURSOR_THEME.*Kafka" ~/.config/hypr/hyprland.conf; then
            echo "" >>~/.config/hypr/hyprland.conf
            echo "# Kafka Cursor Theme" >>~/.config/hypr/hyprland.conf
            echo "env = XCURSOR_THEME,Kafka" >>~/.config/hypr/hyprland.conf
            echo "env = XCURSOR_SIZE,24" >>~/.config/hypr/hyprland.conf
          fi
        fi

        print_success "Kafka cursor instalado y configurado"
        KAFKA_FOUND=true
        break
      fi
    fi
  done

  if [[ "$KAFKA_FOUND" == false ]]; then
    print_warning "Kafka.tar.gz no encontrado en dotfiles"
    print_status "Rutas buscadas:"
    for path in "${KAFKA_PATHS[@]}"; do
      echo "  - $path"
    done
  fi

  # EasyEffects presets
  if [[ -d ~/dotfiles-dizzi/easyeffects ]]; then
    print_installing "Copiando presets de EasyEffects"
    mkdir -p ~/.config/easyeffects
    cp -r ~/dotfiles-dizzi/easyeffects/* ~/.config/easyeffects/ 2>/dev/null || true
    print_success "EasyEffects presets copiados"
  fi

  # Input Remapper presets
  if [[ -d ~/dotfiles-dizzi/input-remapper ]]; then
    print_installing "Copiando presets de Input Remapper"
    mkdir -p ~/.config/input-remapper-2
    cp -r ~/dotfiles-dizzi/input-remapper/* ~/.config/input-remapper-2/ 2>/dev/null || true
    print_success "Input Remapper presets copiados"
  fi

else
  print_warning "Extras omitidos"
fi

# ═══════════════════════════════════════════════════════════
# FUNCIÓN PARA CONFIGURAR PERMISOS DE INPUT (UNIVERSAL)
# ═══════════════════════════════════════════════════════════
function setup_input_permissions() {
  local TOOL_NAME=$1

  print_status "Configurando permisos de input para $TOOL_NAME..."

  # 1. Crear reglas udev si no existen
  if [[ ! -f /etc/udev/rules.d/99-input-automation.rules ]]; then
    sudo tee /etc/udev/rules.d/99-input-automation.rules >/dev/null <<'EOL'
# Reglas udev para herramientas de automatización
# PyMacroRecord, TheClicker, etc.
KERNEL=="uinput", MODE="0660", GROUP="input", OPTIONS+="static_node=uinput"
KERNEL=="event*", MODE="0660", GROUP="input"
SUBSYSTEM=="input", GROUP="input", MODE="0660"
SUBSYSTEM=="misc", KERNEL=="uinput", MODE="0660", GROUP="input"
EOL

    # Recargar reglas
    sudo udevadm control --reload-rules
    sudo udevadm trigger
    print_success "Reglas udev creadas para $TOOL_NAME"
  fi

  # 2. Agregar usuario a grupo input
  if ! groups | grep -q input; then
    sudo usermod -aG input $USER
    print_warning "Usuario agregado al grupo 'input' - debes cerrar sesión"
  fi

  # 3. Cargar módulo uinput
  if ! lsmod | grep -q uinput; then
    sudo modprobe uinput
    echo 'uinput' | sudo tee /etc/modules-load.d/uinput.conf >/dev/null
    print_success "Módulo uinput cargado"
  fi
}

# ═══════════════════════════════════════════════════════════
# PASO 24: PYMACRORECORD + AUTOCLICKERS + PREMID
# ═══════════════════════════════════════════════════════════
print_step "24/35: PyMacroRecord + AutoClickers + PreMiD"

echo
echo -e "${BOLD}${YELLOW}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${YELLOW}║          🎮 HERRAMIENTAS DE AUTOMATIZACIÓN 🎮            ║${NC}"
echo -e "${BOLD}${YELLOW}╚═══════════════════════════════════════════════════════════╝${NC}"
echo
read -p "¿Instalar PyMacroRecord? [S/n]: " install_pymacro
read -p "¿Instalar AutoClickers? [S/n]: " install_autoclickers
read -p "¿Instalar PreMiD (Discord Rich Presence)? [s/N]: " install_premid

# ═══════════════════════════════════════════════════════════
# PYMACRORECORD (CON PERMISOS INTEGRADOS)
# ═══════════════════════════════════════════════════════════
if [[ ! "$install_pymacro" =~ ^[Nn]$ ]]; then
  print_header "Instalando PyMacroRecord"

  # Instalar dependencias del sistema
  print_installing "Dependencias del sistema"
  sudo pacman -S --needed --noconfirm \
    python python-pip git tk \
    zlib libjpeg-turbo libtiff libwebp openjpeg2 \
    python-setuptools python-wheel python-pillow

  # Buscar PyMacroRecord
  PYMACRO_PATHS=(
    ~/dotfiles-dizzi/home/PyMacroRecord-1.4.2
    ~/dotfiles-dizzi/PyMacroRecord-1.4.2
    ~/Descargas/PyMacroRecord-1.4.2
    ~/"{Linux} Tinytask Alternativa - PyMacroRecord ~ [Instalacion] 1.4.2/PyMacroRecord-1.4.2"
    ~/{Linux} Tinytask Alternativa - PyMacroRecord ~ [Instalacion] 1.4.2/PyMacroRecord-1.4.2/
  )

  PYMACRO_FOUND=false
  PYMACRO_PATH=""

  for path in "${PYMACRO_PATHS[@]}"; do
    if [[ -d "$path" ]]; then
      PYMACRO_PATH="$path"
      PYMACRO_FOUND=true
      print_success "PyMacroRecord encontrado en: $path"
      break
    fi
  done

  if [[ "$PYMACRO_FOUND" == false ]]; then
    print_warning "PyMacroRecord no encontrado"
    echo
    echo -e "${CYAN}Descarga desde:${NC} ${YELLOW}https://www.pymacrorecord.com/download${NC}"
    echo -e "${CYAN}Extrae el ZIP en:${NC} ${YELLOW}~/Descargas/${NC}"
    echo
    read -p "Introduce ruta completa (o Enter para omitir): " custom_path

    if [[ -d "$custom_path" ]]; then
      PYMACRO_PATH="$custom_path"
      PYMACRO_FOUND=true
    fi
  fi

  if [[ "$PYMACRO_FOUND" == true ]]; then
    print_installing "Configurando PyMacroRecord"

    # Copiar a ubicación definitiva
    mkdir -p ~/.local/share
    rm -rf ~/.local/share/pymacro
    cp -r "$PYMACRO_PATH" ~/.local/share/pymacro
    cd ~/.local/share/pymacro

    # Eliminar venv viejo
    if [[ -d venv ]]; then
      print_status "Eliminando venv antiguo..."
      rm -rf venv
    fi

    # Crear venv con acceso a paquetes del sistema
    print_installing "Creando entorno virtual"
    python -m venv --system-site-packages venv
    source venv/bin/activate

    # Actualizar pip
    print_status "Actualizando pip..."
    pip install --upgrade pip setuptools wheel &>/dev/null

    # Limpiar requirements.txt
    if [[ -f requirements.txt ]]; then
      print_status "Limpiando requirements.txt..."
      sed -i '/win10toast/d' requirements.txt
      sed -i '/Pillow/d' requirements.txt
    fi

    # Instalar dependencias Python
    print_installing "Instalando dependencias Python"
    pip install pynput numpy keyboard pystray &>/dev/null

    deactivate

    # ═══════════════════════════════════════════════════════════
    # CONFIGURAR PERMISOS (CRÍTICO)
    # ═══════════════════════════════════════════════════════════
    setup_input_permissions "PyMacroRecord"

    # Crear launcher mejorado con verificación
    print_installing "Creando launcher"
    mkdir -p ~/.local/bin
    cat >~/.local/bin/pymacrorecord <<'EOL'
#!/bin/bash
# Launcher de PyMacroRecord con verificación de permisos

# Verificar permisos básicos
if [[ ! -r /dev/uinput ]]; then
  echo "⚠️  Advertencia: Sin permisos para /dev/uinput"
  echo "   Ejecutando con sudo..."
  cd ~/.local/share/pymacro
  source venv/bin/activate
  cd src
  sudo python main.py
  exit $?
fi

# Todo OK, ejecutar normalmente
cd ~/.local/share/pymacro
source venv/bin/activate
cd src
python main.py
EOL
    chmod +x ~/.local/bin/pymacrorecord

    # Desktop file
    mkdir -p ~/.local/share/applications
    cat >~/.local/share/applications/pymacrorecord.desktop <<'EOL'
[Desktop Entry]
Name=PyMacroRecord
Comment=Record and replay macros (TinyTask for Linux)
Exec=pymacrorecord
Icon=input-keyboard
Terminal=false
Type=Application
Categories=Utility;Accessibility;
Keywords=macro;automation;record;tinytask;
EOL

    # Actualizar base de datos
    update-desktop-database ~/.local/share/applications 2>/dev/null || true

    print_success "PyMacroRecord instalado con permisos configurados"

    # Verificar si necesita cerrar sesión
    if ! groups | grep -q input; then
      echo
      echo -e "${RED}${BOLD}⚠️  IMPORTANTE:${NC} ${YELLOW}Debes cerrar sesión y volver a entrar${NC}"
      echo -e "   (para aplicar permisos del grupo 'input')"
      echo
    else
      echo
      echo -e "${GREEN}✓ Permisos aplicados, puedes usar PyMacroRecord ahora${NC}"
      echo
    fi

    echo -e "${GREEN}${BOLD}✨ GUÍA DE USO - PYMACRORECORD ✨${NC}"
    echo
    echo -e "${CYAN}Ejecutar:${NC}"
    echo -e "  ${YELLOW}pymacrorecord${NC}  (terminal)"
    echo -e "  O busca 'PyMacroRecord' en Rofi/Wofi"
    echo
    echo -e "${CYAN}Uso (como TinyTask):${NC}"
    echo -e "  ${RED}●${NC} ${RED}Botón ROJO${NC} → Grabar"
    echo -e "  ${YELLOW}■${NC} ${YELLOW}Botón NEGRO${NC} → Detener grabación"
    echo -e "  ${GREEN}▶${NC} ${GREEN}Botón VERDE${NC} → Reproducir"
    echo -e "  ${YELLOW}F3${NC} → Detener reproducción"
    echo
    echo -e "${CYAN}Atajos:${NC}"
    echo -e "  ${YELLOW}Ctrl+S${NC} - Guardar macro (.pmr)"
    echo -e "  ${YELLOW}Ctrl+L${NC} - Cargar macro"
    echo -e "  ${YELLOW}Ctrl+N${NC} - Nueva (limpiar)"
    echo
  else
    print_error "PyMacroRecord no instalado"
  fi
fi

# ═══════════════════════════════════════════════════════════
# AUTOCLICKERS
# ═══════════════════════════════════════════════════════════
if [[ ! "$install_autoclickers" =~ ^[Nn]$ ]]; then
  print_header "Instalando AutoClickers"

  echo
  echo -e "${CYAN}Selecciona autoclicker(s):${NC}"
  echo -e "${BOLD}${GREEN}1. TheClicker${NC} (Rust, RECOMENDADO)"
  echo -e "${BOLD}${GREEN}2. ydotool${NC} (Universal)"
  echo -e "${BOLD}${GREEN}3. Flatpak Clicker${NC} (GUI)"
  echo -e "${BOLD}${GREEN}4. Xclicker${NC} (GUI)"
  echo
  read -p "¿Instalar TheClicker? [S/n]: " install_theclicker
  read -p "¿Instalar ydotool? [s/N]: " install_ydotool
  read -p "¿Instalar Flatpak Clicker? [s/N]: " install_flatpak
  read -p "¿Instalar Flatpak Clicker? [s/N]: " install_xclickerAUR

  # ═══════════════════════════════════════════════════════════
  # THECLICKER (CON PERMISOS INTEGRADOS)
  # ═══════════════════════════════════════════════════════════
  if [[ ! "$install_theclicker" =~ ^[Nn]$ ]]; then
    print_installing "TheClicker"

    # Instalar Rust si no está
    if ! command -v cargo &>/dev/null; then
      print_status "Instalando Rust..."
      curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
      source ~/.cargo/env
    fi

    # Agregar cargo al PATH si no está
    if ! grep -q 'cargo/bin' ~/.zshrc 2>/dev/null; then
      echo 'export PATH="$HOME/.cargo/bin:$PATH"' >>~/.zshrc
      export PATH="$HOME/.cargo/bin:$PATH"
    fi

    # Instalar TheClicker
    print_status "Compilando TheClicker..."
    if ! cargo install theclicker 2>/dev/null; then
      print_warning "Instalación por cargo falló, compilando desde source..."
      cd /tmp
      git clone --depth 1 https://github.com/konkitoman/autoclicker.git theclicker_build
      cd theclicker_build
      cargo build --release
      mkdir -p ~/.cargo/bin
      cp target/release/theclicker ~/.cargo/bin/
      cd ~
      rm -rf /tmp/theclicker_build
    fi

    # Configurar permisos (usa la función universal)
    setup_input_permissions "TheClicker"

    print_success "TheClicker instalado"

    echo
    echo -e "${GREEN}${BOLD}✨ THECLICKER - GUÍA ✨${NC}"
    echo -e "${CYAN}Ejecutar:${NC}"
    echo -e "  ${YELLOW}theclicker${NC}  → Modo interactivo"
    echo -e "  ${YELLOW}theclicker --interval 100${NC}  → 10 clicks/seg"
    echo
    echo -e "${CYAN}Teclas:${NC}"
    echo -e "  ${YELLOW}F6${NC} = Iniciar/Pausar"
    echo -e "  ${YELLOW}F7${NC} = Detener"
    echo
  fi

  # ═══════════════════════════════════════════════════════════
  # YDOTOOL (CON SERVICIO SYSTEMD)
  # ═══════════════════════════════════════════════════════════
  if [[ "$install_ydotool" =~ ^[Ss]$ ]]; then
    print_installing "ydotool"
    sudo pacman -S --needed --noconfirm ydotool

    # Crear servicio systemd
    mkdir -p ~/.config/systemd/user
    cat >~/.config/systemd/user/ydotool.service <<'EOL'
[Unit]
Description=ydotool daemon
After=default.target

[Service]
ExecStart=/usr/bin/ydotoold --socket-path=/tmp/.ydotool_socket
Restart=always
RestartSec=3

[Install]
WantedBy=default.target
EOL

    # Habilitar servicio
    systemctl --user daemon-reload
    systemctl --user enable --now ydotool.service

    # Agregar variable de entorno
    if ! grep -q 'YDOTOOL_SOCKET' ~/.zshrc 2>/dev/null; then
      echo 'export YDOTOOL_SOCKET=/tmp/.ydotool_socket' >>~/.zshrc
      export YDOTOOL_SOCKET=/tmp/.ydotool_socket
    fi

    print_success "ydotool instalado con servicio automático"

    echo
    echo -e "${GREEN}${BOLD}✨ YDOTOOL - GUÍA ✨${NC}"
    echo -e "${CYAN}Ejecutar:${NC}"
    echo -e "  ${YELLOW}ydotool click${NC}  → Click izquierdo"
    echo -e "  ${YELLOW}ydotool click 0xC1${NC}  → Click derecho"
    echo
    echo -e "${CYAN}Autoclicker:${NC}"
    echo -e "  ${YELLOW}while true; do ydotool click; sleep 0.1; done${NC}"
    echo
  fi

  # ═══════════════════════════════════════════════════════════
  # FLATPAK CLICKER (CON VERIFICACIÓN MEJORADA)
  # ═══════════════════════════════════════════════════════════
  if [[ "$install_flatpak" =~ ^[Ss]$ ]]; then
    print_installing "Flatpak Clicker"

    # Verificar si flatpak está instalado
    if ! command -v flatpak &>/dev/null; then
      print_status "Instalando flatpak..."
      sudo pacman -S --needed --noconfirm flatpak
    fi

    # Verificar si flathub está configurado
    if ! flatpak remotes | grep -q flathub; then
      print_status "Agregando repositorio flathub..."
      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    fi

    # Verificar si ya está instalado
    if flatpak list | grep -q "net.codelogistics.clicker"; then
      print_success "Flatpak Clicker ya está instalado"
    else
      print_status "Instalando desde flathub..."
      if flatpak install -y flathub net.codelogistics.clicker; then
        print_success "Flatpak Clicker instalado"
      else
        print_error "Error instalando Flatpak Clicker"
        print_warning "Intenta manualmente: flatpak install flathub net.codelogistics.clicker"
      fi
    fi

    echo
    echo -e "${GREEN}${BOLD}✨ FLATPAK CLICKER - GUÍA ✨${NC}"
    echo -e "${CYAN}Ejecutar:${NC}"
    echo -e "  ${YELLOW}flatpak run net.codelogistics.clicker${NC}"
    echo -e "  O busca 'Clicker' en tu launcher"
    echo
    echo -e "${YELLOW}⚠️  Nota:${NC} Requiere permisos de portal Wayland cada vez"
  fi
    # ═══════════════════════════════════════════════════════════
    # XCLICKER (GUI)
    # ═══════════════════════════════════════════════════════════
    if [[ "$install_xclickerAUR" =~ ^[Ss]$ ]]; then
      print_installing "Xclicker"
      sudo pacman -S --needed --noconfirm xclicker
      yay -S --needed --noconfirm --answerdiff=None --answerclean=None --removemake \
        xclicker 2>/dev/null || print_warning "Xclicker falló"

      print_success "Xclicker instalado"
    else
      print_warning "Xclicker omitido"
    fi
    echo -e "${GREEN}✅ Todos los clickers instalados${NC}"
fi

# ═════════════════════════════════════════════════════════════
# PASP 24.5: Omarchy Scripts Webpack, Arch Fzf Search
# ═════════════════════════════════════════════════════════════
print_step "24.5/35: Omarmy Scripts, Webpack, Arch Fzf Search"
if [[ "$install_omarchySripts" =~ ^[Ss]$ ]]; then
  # print_header "Instalando PreMiD"
  print_header "Instalando dependencias para Omarchy Scripts [Webpack, Arch Fzf Search]"

  if command -v yay &>/dev/null; then
    yay -S --needed --noconfirm --answerdiff=None --answerclean=None premid gum curl xdg-utils desktop-file-utils 2>/dev/null || print_warning "PreMiD instalación falló"
  else
    print_warning "yay no encontrado..."
    # cd /tmp
    # git clone --depth 1 https://aur.archlinux.org/premid.git
    # cd premid
    # makepkg -si --noconfirm
    # cd ~
    # rm -rf /tmp/premid
  fi
  #
  # if command -v premid &>/dev/null; then
  #   print_success "PreMiD instalado"
  #
  #   chmod +x ~/install-premid-presences.sh
  #
  #   echo
  #   echo -e "${CYAN}Para instalar presences:${NC}"
  #   echo -e "  Ejecuta: ${YELLOW}~/install-premid-presences.sh${NC}"
  #   # Script de presences mejorado
  #   ~/install-premid-presences.sh
  #
  #   echo
  # else
  #   print_error "PreMiD no se instaló correctamente"
  # fi
fi
# ELIMINADO PREMID PORQUE NO DEJA EXPORTAR...

# ═══════════════════════════════════════════════════════════
# RESUMEN FINAL
# ═══════════════════════════════════════════════════════════
print_header "✅ Instalación Completada"

echo -e "${GREEN}${BOLD}Herramientas instaladas:${NC}"
[[ -f ~/.local/bin/pymacrorecord ]] && echo -e "  ${GREEN}✓${NC} PyMacroRecord"
command -v theclicker &>/dev/null && echo -e "  ${GREEN}✓${NC} TheClicker"
command -v ydotool &>/dev/null && echo -e "  ${GREEN}✓${NC} ydotool"
flatpak list | grep -q clicker && echo -e "  ${GREEN}✓${NC} Flatpak Clicker"
command -v premid &>/dev/null && echo -e "  ${GREEN}✓${NC} PreMiD"

echo
if ! groups | grep -q input; then
  echo -e "${RED}${BOLD}⚠️  IMPORTANTE:${NC} ${YELLOW}Cierra sesión y vuelve a entrar${NC}"
  echo -e "   (para aplicar permisos de automatización)"
else
  echo -e "${GREEN}✓ Todo listo para usar${NC}"
fi

print_success "Automatización configurada"

# ═══════════════════════════════════════════════════════════
# PASO 25: GRUVBOX (CORREGIDO - Cierre de bloques)
# ═══════════════════════════════════════════════════════════
print_step "25/35: Gruvbox Ecosystem"

echo
read -p "¿Instalar Gruvbox Icon Pack? [S/n]: " install_gruvbox_icons
read -p "¿Instalar Gruvbox GTK Theme? [S/n]: " install_gruvbox_gtk

# Icons
if [[ ! "$install_gruvbox_icons" =~ ^[Nn]$ ]]; then
  print_header "Instalando Gruvbox Icons"

  yay -S --needed --noconfirm --answerdiff=None --answerclean=None --removemake \
    gruvbox-plus-icon-theme 2>/dev/null || print_warning "Gruvbox icons falló"

  gsettings set org.gnome.desktop.interface icon-theme 'gruvbox-plus-icon-pack' 2>/dev/null || true

  if [[ -f ~/.config/hypr/hyprland.conf ]]; then
    if ! grep -q "GTK_ICON_THEME.*gruvbox" ~/.config/hypr/hyprland.conf; then
      echo "env = GTK_ICON_THEME,gruvbox-plus-icon-pack" >>~/.config/hypr/hyprland.conf
    fi
  fi

  print_success "Gruvbox icons instalado"
fi

# GTK Theme
if [[ ! "$install_gruvbox_gtk" =~ ^[Nn]$ ]]; then
  print_header "Instalando Gruvbox GTK"

  yay -S --needed --noconfirm --answerdiff=None --answerclean=None --removemake \
    gruvbox-gtk-theme-git 2>/dev/null || print_warning "Gruvbox GTK falló"

  gsettings set org.gnome.desktop.interface gtk-theme 'Gruvbox-Dark' 2>/dev/null || true
  print_success "Gruvbox GTK instalado"
fi

# ═══════════════════════════════════════════════════════════
# PASO 25.5: GRUB (CORREGIDO - Faltaba fi)
# ═══════════════════════════════════════════════════════════
print_step "25.5/35: GRUB + Iconos"

echo
read -p "¿Instalar temas Minecraft para GRUB? [S/n]: " install_minecraft_grub

if [[ ! "$install_minecraft_grub" =~ ^[Nn]$ ]]; then
  print_header "Instalando Temas Minecraft"

  sudo mkdir -p /boot/grub/themes

  # World Selection
  if [[ ! -d /boot/grub/themes/minegrub-world-selection ]]; then
    git clone --depth 1 https://github.com/Lxtharia/minegrub-world-selection.git /tmp/minegrub-ws
    sudo cp -r /tmp/minegrub-ws/minegrub-world-selection /boot/grub/themes/
    rm -rf /tmp/minegrub-ws
    print_success "World Selection instalado"
  fi

  # Classic
  if [[ ! -d /boot/grub/themes/minegrub ]]; then
    git clone --depth 1 https://github.com/Lxtharia/minegrub-theme.git /tmp/minegrub-classic
    sudo cp -r /tmp/minegrub-classic/minegrub /boot/grub/themes/
    rm -rf /tmp/minegrub-classic
    print_success "Classic instalado"
  fi

  echo
  read -p "¿Reconfigurar GRUB? [S/n]: " reconfig_grub

  if [[ ! "$reconfig_grub" =~ ^[Nn]$ ]]; then
    if [[ -L /etc/default/grub ]]; then
      sudo grub-mkconfig -o /boot/grub/grub.cfg
      print_success "GRUB reconfigurado"
    else
      print_warning "Symlink GRUB no existe"
    fi
  fi
fi # 🔴 ESTE FI FALTABA

print_status "Actualizando cachés..."
update-desktop-database ~/.local/share/applications 2>/dev/null || true
gtk-update-icon-cache -f ~/.local/share/icons 2>/dev/null || true

# ═══════════════════════════════════════════════════════════
# PASO 26: PYTHON-PYWAL
# ═══════════════════════════════════════════════════════════
print_step " 5/35: Python-pywal (Temas Dinámicos)"
print_installing "python-pywal + imagemagick"
sudo pacman -S --needed --noconfirm python-pywal imagemagick

# Aplicar dotfiles de wal si existen
if [[ -d ~/dotfiles-dizzi/wal ]]; then
  cd ~/dotfiles-dizzi
  stow wal 2>/dev/null || print_warning "Stow wal falló"
  cd ~
fi

print_success "Pywal instalado"

# ═══════════════════════════════════════════════════════════
# PASO 27: OH-MY-POSH
# ═══════════════════════════════════════════════════════════
print_step "26/35: Oh-My-Posh (Prompt Moderno)"
print_installing "oh-my-posh desde AUR"
yay -S --needed --noconfirm --answerdiff=None --answerclean=None --removemake \
  oh-my-posh 2>/dev/null || print_warning "oh-my-posh falló"

print_success "Oh-My-Posh instalado"

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
