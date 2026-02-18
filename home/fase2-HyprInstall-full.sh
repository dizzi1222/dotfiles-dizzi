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
  kitty ghostty konsole thunar nemo plasma-desktop \
  grim slurp wl-clipboard cliphist \
  brightnessctl playerctl pamixer \
  swaync hyprlock hypridle hyprpicker \
  wofi fuzzel polkit-kde-agent polkit-gnome udiskie \
  swww hyprpaper hyprshot \
  qt5-wayland qt6-wayland gtk-layer-shell

yay -S --needed --noconfirm zellij nix niri swaybg mpvpaper wl-color-picker wlsunset
print_success "Hyprland instalado"
print_success "Niri es otro Tiling Manager igual de bueno muy RECOMANDO
[Dependencias]: niri swaybg mpvpaper wl-color-picker wlsunset # mpv permite gifs y swaybg fondos .jpg*"

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
  tig git-filter-repo man-db fastfetch bluetui impala networkmanager-dmenu gedit hyprsunset rsync gnome-system-monitor

print_installing "Utilidades extra AUR (pokemon-colorscripts, cava, zoxide)"
print_installing "Interfaces: bluetui, impala. Para gestionar el Bluetooth y Wifi [mismos devs]"
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
    steam lutris wine-staging winetricks \
    gamemode lib32-gamemode

  print_installing "Geforce Experience"
  yay -S --needed --noconfirm --answerdiff=None --answerclean=None --removemake \
    gfn-electron geforce-infinity-bin bottles curseforge minecraft-launcher lucem-git # LUCEM = BLOXTRAP PARA JUGAR ROBLOX

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
  ds4drv xpadneo-dkms sixpair input-remapper espanso-wayland \
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
  libreoffice-fresh okular filezilla transmission-gtk \
  pavucontrol loupe \
  scrcpy android-file-transfer \
  gvfs gvfs-gphoto2 kio-extras libxfce4ui

yay -S  --needed --noconfirm --answerdiff=None --answerclean=None --removemake \
  open-fuse-iso
print_success "Aplicaciones de gestión de discos instaladas [ISO]"

# ═══════════════════════════════════════════════════════════
# Kdenlive - Selección interactiva
# ═══════════════════════════════════════════════════════════
echo
echo -e "${BOLD}${YELLOW}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${YELLOW}║          🎬 KDENLIVE (EDITOR DE VIDEO) 🎬                 ║${NC}"
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
print_installing "Aplicaciones extra y de Música/OCIO, Youtube Music [pear-desktop], Discord, Soundbound (solo binarios precompilados)"
yay -S --needed --noconfirm --answerdiff=None --answerclean=None --removemake \
  brave-bin zen-browser-bin spotify pear-desktop-bin soundbound-app-bin \
  vencord-bin telegram-desktop-bin bitwarden gyazo-bin discord-screenaudio-bin \
  2>/dev/null || print_warning "Algunas apps fallaron"
# Youtube Music cambió de nombre a Pear Desktop

# ═══════════════════════════════════════════════════════════
# Selección interactiva de editor de código
# ═══════════════════════════════════════════════════════════
echo
echo -e "${BOLD}${YELLOW}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${YELLOW}║          💻 SELECCIONAR EDITOR DE CÓDIGO 💻               ║${NC}"
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
  bash ~/dotfiles-dizzi/home/Antigravity\ Setup/install\ extensions/install-vscode-extensions.sh
  print_success "Extensiones de VSCode instaladas"
*)
  print_warning "Editor de código omitido"
  ;;
esac

# ═══════════════════════════════════════════════════════════
# Extras
# ═══════════════════════════════════════════════════════════
print_installing "Extras (SOLO -bin, sin compilar)"
print_installing "Las Mejores VPN (No esta Urban)"
sudo pacman -S proton-vpn-gtk-app --needed --noconfirm
yay -S --needed --noconfirm \ 
  stacer-bin bleachbit zip 7zip rar transmission-gtk windscribe-v2-bin jdownloader2 megasync \
  appimagelauncher music-presence-bin copyq pamac-aur \
  2>/dev/null || print_warning "Algunos extras fallaron"

print_success "Instalado apps basicas: zip, 7zip, rar, appimagelauncher"
print_success "Instalado Downloaders: megasync, jdownloader2, pamac-aur [Panel Control], transmission-gtk (Utorrent)"
print_success "Aplicaciones instaladas (solo binarios)"

# ═══════════════════════════════════════════════════════════
# PASO 13.2: WAYDROID + MAGISTV + ALTERNATIVAS TV (CORREGIDO)
# ═══════════════════════════════════════════════════════════
# INSERTAR DESPUÉS DE "PASO 13: APLICACIONES" Y ANTES DE "PASO 13.5: STREMIO"
# ═══════════════════════════════════════════════════════════

print_step "13.2/35: Waydroid + MagisTV + Alternativas TV"

echo
echo -e "${BOLD}${YELLOW}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${YELLOW}║        📱 WAYDROID + MAGISTV + ALTERNATIVAS TV 📱         ║${NC}"
echo -e "${BOLD}${YELLOW}╚═══════════════════════════════════════════════════════════╝${NC}"
echo
echo -e "${CYAN}Waydroid permite ejecutar Android en Linux (Wayland native).${NC}"
echo -e "${CYAN}Se incluye MagisTV con firma ya configurada.$NC}"
echo
echo -e "${BOLD}${GREEN}Requisitos:$NC}"
echo -e "  ${MAGENTA}•$NC} 5GB+ de espacio libre"
echo -e "  ${MAGENTA}•$NC} CPU con soporte para virtualización (KVM)"
echo -e "  ${MAGENTA}•$NC} RAM: 4GB+ recomendado"
echo
read -p "¿Instalar Waydroid + MagisTV? [S/n]: " install_waydroid

if [[ ! "$install_waydroid" =~ ^[Nn]$ ]]; then
  print_header "Instalando Waydroid + MagisTV"

  # ═══════════════════════════════════════════════════════════
  # PASO 1: Instalar Waydroid
  # ═══════════════════════════════════════════════════════════
  print_installing "Waydroid + Dependencias"
  sudo pacman -S --needed --noconfirm \
    waydroid python-pip git lzip

  # Habilitar KVM
  print_status "Habilitando KVM..."
  sudo usermod -aG kvm $USER
  print_package "Usuario agregado al grupo 'kvm'"

  # ═══════════════════════════════════════════════════════════
  # PASO 2: Inicializar con GApps
  # ═══════════════════════════════════════════════════════════
  print_header "Inicializando Waydroid con Google Apps (~1.2GB)"
  print_warning "IMPORTANTE: NO CANCELES LA DESCARGA"
  echo
  echo -e "${CYAN}Esto descargará:$NC}"
  echo -e "  ${MAGENTA}•$NC} Sistema Android 13"
  echo -e "  ${MAGENTA}•$NC} Google Apps (Play Store, Gmail, etc.)"
  echo -e "  ${MAGENTA}•$NC} Duración estimada: 10-20 minutos"
  echo
  read -p "Presiona Enter para iniciar (esto es IRREVERSIBLE)..."

  sudo waydroid init -s GAPPS -f

  if [[ $? -ne 0 ]]; then
    print_error "Error inicializando Waydroid"
    print_warning "Prueba: sudo rm -rf /var/lib/waydroid && sudo waydroid init -s GAPPS -f"
  else
    print_success "Waydroid inicializado"
  fi

  # ═══════════════════════════════════════════════════════════
  # PASO 3: Iniciar Waydroid por primera vez
  # ═══════════════════════════════════════════════════════════
  print_header "Iniciando servicios de Waydroid"

  print_status "Iniciando contenedor..."
  sudo systemctl start waydroid-container
  sleep 10

  print_status "Iniciando sesión..."
  waydroid session start
  sleep 5

  # Verificar estado
  WAYDROID_STATUS=$(waydroid status 2>&1)
  if echo "$WAYDROID_STATUS" | grep -q "Container:.*RUNNING"; then
    print_success "Waydroid corriendo correctamente"
  else
    print_error "Error: Waydroid no se inició correctamente"
    print_warning "Estado: $WAYDROID_STATUS"
  fi

  # ═══════════════════════════════════════════════════════════
  # PASO 4: Instalar libhoudini (ARM Translation) - CLAVE
  # ═══════════════════════════════════════════════════════════
  print_header "Instalando libhoudini (ARM Translation) - CRUCIAL"

  echo
  echo -e "${BOLD}${CYAN}¿Por qué necesitas libhoudini?$NC}"
  echo -e "  ${MAGENTA}•$NC} La mayoría de apps Android (incluida MagisTV) son ARM"
  echo -e "  ${MAGENTA}•$NC} Tu PC es x86_64 (Intel/AMD)"
  echo -e "  ${MAGENTA}•$NC} libhoudini traduce ARM → x86_64"
  echo -e "  ${MAGENTA}•$NC} Sin esto: error 'App not compatible'"
  echo -e "  ${MAGENTA}•$NC} Para más detalles ver: https://github.com/waydroid/waydroid/wiki/Installing-libhoudini O consulta la imagen abajo"
  # O en heredoc
cat <<"EOF"
Instrucciones en: 
https://raw.githubusercontent.com/casualsnek/waydroid_script/main/assets/img/README/image-20230430013148814.png
EOF
  echo -e "  ${MAGENTA}•$NC} La imagen muestra otras dependencias aparte que te pueden servir. Y seleciona android 13 90% de ocasiones."
  echo
  read -p "¿Instalar libhoudini? [S/n]: " install_libhoudini

  if [[ ! "$install_libhoudini" =~ ^[Nn]$ ]]; then
    print_installing "waydroid_script (necesario para libhoudini)"

    # Clonar y configurar script
    if [[ ! -d ~/waydroid_script ]]; then
      cd ~
      git clone https://github.com/casualsnek/waydroid_script.git
      cd waydroid_script
    else
      cd ~/waydroid_script
      git pull
    fi

    # Setup Python venv
    python -m venv venv
    source venv/bin/activate
    pip install -q -r requirements.txt 2>/dev/null

    print_status "Instalando libhoudini (esto toma 5-10 minutos)..."
    echo
    echo -e "${CYAN}Sigue estos pasos en el menú interactivo:$NC}"
    echo -e "  ${MAGENTA}1.$NC} Versión: ${YELLOW}Android 13${NC}"
    echo -e "  ${MAGENTA}2.$NC} Acción: ${YELLOW}Install$NC}"
    echo -e "  ${MAGENTA}3.$NC} Marca ${YELLOW}libhoudini$NC} con ESPACIO"
    echo -e "  ${MAGENTA}4.$NC} Presiona ENTER"
    echo

    # Ejecutar script interactivo
    sudo venv/bin/python main.py

    deactivate

    # Reiniciar Waydroid
    print_status "Reiniciando Waydroid..."
    waydroid session stop
    sudo systemctl restart waydroid-container
    sleep 10
    waydroid session start

    print_success "libhoudini instalado y Waydroid reiniciado"
    print_warning "IMPORTANTE: Cierra sesión y vuelve a entrar para KVM"
  else
    print_warning "libhoudini omitido (MagisTV PROBABLEMENTE NO FUNCIONARÁ)"
  fi

  # ═══════════════════════════════════════════════════════════
  # PASO 5: Certificación de Google Play (OPCIONAL pero recomendado)
  # ═══════════════════════════════════════════════════════════
  print_header "Certificación de Google Play (Opcional)"

  echo
  echo -e "${BOLD}${CYAN}¿Por qué certificar?$NC}"
  echo -e "  ${MAGENTA}•$NC} Acceder a Play Store premium"
  echo -e "  ${MAGENTA}•$NC} Instalar apps que requieren certificación"
  echo -e "  ${MAGENTA}•$NC} NO es necesario para MagisTV (ya tiene firma)"
  echo
  read -p "¿Obtener Android ID para certificación? [s/N]: " get_device_id

  if [[ "$get_device_id" =~ ^[Ss]$ ]]; then
    echo
    echo -e "${YELLOW}Opción A (Automática - Recomendada):$NC}"
    echo -e "  cd ~/waydroid_script"
    echo -e "  source venv/bin/activate"
    echo -e "  sudo venv/bin/python main.py"
    echo -e "  → ${CYAN}Get Google Device ID to Get Certified$NC}"
    echo
    echo -e "${YELLOW}Opción B (Manual):$NC}"
    echo -e "  waydroid show-full-ui"
    echo -e "  Settings → About phone → Copia Android ID"
    echo
    read -p "¿Usar automática (A) o manual (B)? [A/b]: " id_method

    if [[ ! "$id_method" =~ ^[Bb]$ ]]; then
      print_status "Abriendo herramienta automática..."
      cd ~/waydroid_script 2>/dev/null && {
        source venv/bin/activate 2>/dev/null
        echo -e "${CYAN}Selecciona la opción de Device ID$NC}"
        sudo venv/bin/python main.py
        deactivate
      } || print_warning "waydroid_script no encontrado, usa método B"
    else
      print_status "Abriendo interfaz Android..."
      waydroid show-full-ui &
      sleep 3
    fi

    echo
    echo -e "${BOLD}${YELLOW}PASOS PARA CERTIFICAR:$NC}"
    echo -e "  ${MAGENTA}1.$NC} Obtén el Android ID (arriba)"
    echo -e "  ${MAGENTA}2.$NC} Abre: ${CYAN}https://www.google.com/android/uncertified/$NC}"
    echo -e "  ${MAGENTA}3.$NC} Pega el ID"
    echo -e "  ${MAGENTA}4.$NC} Registra"
    echo -e "  ${RED}5.$NC} ${RED}ESPERA 10-20 MINUTOS$NC} (a veces 1-2 horas)"
    echo -e "  ${MAGENTA}6.$NC} Verifica: Play Store → Tu perfil → Play Protection"
    echo -e "  ${MAGENTA}7.$NC} Debe decir: ${GREEN}Device is certified$NC}"
    echo

    read -p "¿Ya certificaste? [s/N]: " certified

    if [[ "$certified" =~ ^[Ss]$ ]]; then
      print_success "Dispositivo certificado"
    else
      print_warning "Certificación pendiente (espera 20+ minutos)"
    fi
  else
    print_warning "Certificación omitida (no es necesaria para MagisTV)"
  fi

  # ═══════════════════════════════════════════════════════════
  # PASO 6: Instalar MagisTV
  # ═══════════════════════════════════════════════════════════
  print_header "Instalando MagisTV"

  echo
  echo -e "${CYAN}MagisTV viene con firma ya configurada.$NC}"
  echo -e "${CYAN}Se instala directamente sin necesidad de setup adicional.$NC}"
  echo
  read -p "¿Instalar MagisTV ahora? [S/n]: " install_magistv_app

  if [[ ! "$install_magistv_app" =~ ^[Nn]$ ]]; then
    MAGISTV_APK=""

    # Buscar APK en múltiples ubicaciones
    if [[ -f ~/Descargas/MAGIS*.apk ]]; then
      MAGISTV_APK=$(ls ~/Descargas/MAGIS*.apk 2>/dev/null | head -1)
    elif [[ -f ~/MAGIS*.apk ]]; then
      MAGISTV_APK=$(ls ~/MAGIS*.apk 2>/dev/null | head -1)
    fi

    if [[ -z "$MAGISTV_APK" ]]; then
      print_warning "APK de MagisTV no encontrado"
      echo
      echo -e "${CYAN}Descargalo desde:$NC}"
      echo -e "  ${YELLOW}linktr.ee/MagisReddit$NC}"
      echo -e "  (Selecciona versión Android)"
      echo
      echo -e "${CYAN}Guarda como:$NC}"
      echo -e "  ${YELLOW}~/Descargas/MAGIS_6.4.2.apk$NC}"
      echo
      read -p "Presiona Enter cuando tengas el APK..."

      if [[ -f ~/Descargas/MAGIS*.apk ]]; then
        MAGISTV_APK=$(ls ~/Descargas/MAGIS*.apk | head -1)
      fi
    fi

    if [[ -n "$MAGISTV_APK" && -f "$MAGISTV_APK" ]]; then
      print_installing "Instalando $MAGISTV_APK"

      if waydroid app install "$MAGISTV_APK" 2>&1 | tee /tmp/magistv_install.log; then
        print_success "MagisTV instalado"

        # Obtener package name automáticamente
        MAGISTV_PACKAGE=$(waydroid app list 2>/dev/null | grep -iE "magis|iptv" | grep -v "google" | awk '{print $1}' | head -1)

        if [[ -z "$MAGISTV_PACKAGE" ]]; then
          # Fallback: obtener del instalador
          MAGISTV_PACKAGE=$(grep -oE "com\.gsetech\.[a-zA-Z0-9._]*" /tmp/magistv_install.log | head -1)
        fi

        if [[ -n "$MAGISTV_PACKAGE" ]]; then
          print_success "Package detectado: $MAGISTV_PACKAGE"

          # Crear launcher .desktop
          mkdir -p ~/.local/share/applications
          cat >~/.local/share/applications/magistv.desktop <<EOF
[Desktop Entry]
Name=MagisTV
Comment=IPTV Application
Exec=waydroid app launch $MAGISTV_PACKAGE
Icon=media-video-player
Terminal=false
Type=Application
Categories=AudioVideo;Video;
Keywords=iptv;tv;streaming;
StartupNotify=true
EOF

          update-desktop-database ~/.local/share/applications 2>/dev/null

          print_success "MagisTV disponible en launcher"
          print_status "Ejecuta: waydroid app launch $MAGISTV_PACKAGE"
        else
          print_warning "No se detectó automáticamente el package"
          print_status "Obtén manualmente: waydroid app list | grep -i magis"
        fi
      else
        print_error "Error instalando MagisTV"
        print_status "Verifica: libhoudini está instalado? ¿El APK es correcto?"
        print_warning "Error log guardado en: /tmp/magistv_install.log"
      fi
    else
      print_error "APK de MagisTV no encontrado y no se descargó"
    fi
  else
    print_warning "MagisTV no instalado"
    print_status "Puedes instalarlo después: waydroid app install ~/Descargas/MAGIS.apk"
  fi

  # ═══════════════════════════════════════════════════════════
  # PASO 7: Magisk Root (OPCIONAL)
  # ═══════════════════════════════════════════════════════════
  print_step "13.2.1/35: Magisk Root (Opcional)"

  echo
  read -p "¿Instalar Magisk para root en Waydroid? [s/N]: " install_magisk

  if [[ "$install_magisk" =~ ^[Ss]$ ]]; then
    print_header "Instalando Magisk"

    if [[ -d ~/waydroid_script ]]; then
      cd ~/waydroid_script
      source venv/bin/activate 2>/dev/null
      echo -e "${CYAN}Selecciona en el menú: Install → magisk$NC}"
      sudo venv/bin/python main.py
      deactivate
      cd ~

      waydroid session stop
      sudo systemctl restart waydroid-container
      sleep 10
      waydroid session start

      print_success "Magisk instalado"
    else
      print_error "waydroid_script no encontrado"
      print_status "Instala libhoudini primero (paso 4)"
    fi
  else
    print_warning "Magisk omitido"
  fi

  print_success "Waydroid + MagisTV configurado"

else
  print_warning "Waydroid omitido"
fi

# ═══════════════════════════════════════════════════════════
# PASO 13.3: ALTERNATIVAS TV (YUKI-IPTV, HYPNOTIX)
# ═══════════════════════════════════════════════════════════
print_step "13.3/35: Alternativas TV en Desktop"

echo
echo -e "${BOLD}${YELLOW}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${YELLOW}║          📺 ALTERNATIVAS TV PARA DESKTOP 📺               ║${NC}"
echo -e "${BOLD}${YELLOW}╚═══════════════════════════════════════════════════════════╝${NC}"
echo
echo -e "${CYAN}Alternativas nativas a MagisTV (sin necesidad de Waydroid):$NC}"
echo
echo -e "${BOLD}${GREEN}1. Yuki-IPTV$NC}"
echo -e "  ${MAGENTA}•$NC} Cliente IPTV con M3U support"
echo -e "  ${MAGENTA}•$NC} Interfaz GTK moderna"
echo -e "  ${MAGENTA}•$NC} Recomendado si tienes lista M3U"
echo
echo -e "${BOLD}${GREEN}2. Hypnotix$NC}"
echo -e "  ${MAGENTA}•$NC} Reproductor IPTV avanzado"
echo -e "  ${MAGENTA}•$NC} Compatible con XTREAM codes"
echo -e "  ${MAGENTA}•$NC} Requiere configuración de servidor"
echo
echo -e "${YELLOW}⚠️  IMPORTANTE - SEGURIDAD CON VPN:$NC}"
echo -e "  ${RED}•$NC} ${RED}NUNCA usar IPTV sin VPN$NC}"
echo -e "  ${RED}•$NC} ${RED}Se expone tu IP real al servidor IPTV$NC}"
echo -e "  ${RED}•$NC} ${RED}Algunos proveedores bloquean sin VPN$NC}"
echo -e "  ${GREEN}•$NC} ${GREEN}RECOMENDACIÓN: Activa VPN ANTES de usar$NC}"
echo
read -p "¿Instalar Yuki-IPTV? [s/N]: " install_yuki
read -p "¿Instalar Hypnotix? [s/N]: " install_hypnotix
read -p "¿Necesitas ayuda con VPN? [s/N]: " setup_vpn

# Yuki-IPTV
if [[ "$install_yuki" =~ ^[Ss]$ ]]; then
  print_installing "Yuki-IPTV"
  yay -S --needed --noconfirm --answerdiff=None --answerclean=None --removemake \
    yuki-iptv 2>/dev/null || print_warning "Yuki-IPTV falló"

  if command -v yuki-iptv &>/dev/null; then
    print_success "Yuki-IPTV instalado"
    print_status "Uso: yuki-iptv (o busca en launcher)"
    print_status "Configura tu lista M3U en: Settings → Playlists"
  else
    print_warning "Error instalando Yuki-IPTV"
  fi
fi

# Hypnotix
if [[ "$install_hypnotix" =~ ^[Ss]$ ]]; then
  print_installing "Hypnotix"
  sudo pacman -S --needed --noconfirm hypnotix 2>/dev/null || {
    yay -S --needed --noconfirm --answerdiff=None --answerclean=None --removemake \
      hypnotix 2>/dev/null || print_warning "Hypnotix falló"
  }

  if command -v hypnotix &>/dev/null; then
    print_success "Hypnotix instalado"
    print_status "Uso: hypnotix (o busca en launcher)"
    print_status "Configura servidor: File → Settings → XTREAM URL"
  else
    print_warning "Error instalando Hypnotix"
  fi
fi

# VPN Setup
if [[ "$setup_vpn" =~ ^[Ss]$ ]]; then
  print_header "Configuración de VPN"

  echo
  echo -e "${CYAN}¿Cuál es tu proveedor VPN?$NC}"
  echo -e "  ${MAGENTA}1.$NC} ProtonVPN (Recomendado + Gratuito)"
  echo -e "  ${MAGENTA}2.$NC} Windscribe"
  echo -e "  ${MAGENTA}3.$NC} Otro / No instalar"
  echo
  read -p "Selecciona [1-3]: " vpn_choice

  case "$vpn_choice" in
  1)
    print_installing "ProtonVPN"
    sudo pacman -S --needed --noconfirm proton-vpn-gtk-app

    # Script de conveniencia
    mkdir -p ~/.local/bin
    cat >~/.local/bin/yuki-with-vpn.sh <<'EOL'
#!/bin/bash
echo "🔒 Conectando a ProtonVPN..."
proton-vpn-gtk-app --connect rapid &
sleep 5
echo "▶️  Iniciando Yuki-IPTV..."
yuki-iptv
EOF
    chmod +x ~/.local/bin/yuki-with-vpn.sh

    print_success "ProtonVPN instalado"
    print_status "Usa: yuki-with-vpn.sh para conectar automáticamente"
    print_status "O abre ProtonVPN manualmente antes de Yuki"
    ;;
  2)
    print_installing "Windscribe"
    yay -S --needed --noconfirm windscribe-v2-bin 2>/dev/null || print_warning "Windscribe falló"
    ;;
  *)
    print_warning "VPN no configurada"
    echo -e "${YELLOW}Recuerda: SIEMPRE usa VPN antes de IPTV$NC}"
    ;;
  esac
fi

print_success "Alternativas TV configuradas"

# ═══════════════════════════════════════════════════════════
# PASO 13.4: ANDROID EMULATOR (SDK AVD - ÚLTIMO RECURSO)
# ═══════════════════════════════════════════════════════════
print_step "13.4/35: Android Emulator (SDK AVD - Último Recurso)"

echo
echo -e "${BOLD}${YELLOW}╔═══════════════════════════════════════════════════════════╗$NC}"
echo -e "${BOLD}${YELLOW}║       🤖 ANDROID EMULATOR (ÚLTIMO RECURSO) 🤖             ║$NC}"
echo -e "${BOLD}${YELLOW}╚═══════════════════════════════════════════════════════════╝$NC}"
echo
echo -e "${YELLOW}⚠️  NOTA:$NC} Usa ${RED}SOLO si Waydroid no funciona$NC}"
echo
echo -e "${CYAN}Características:$NC}"
echo -e "  ${MAGENTA}•$NC} ${RED}Mucho más lento$NC} que Waydroid (~5-10x)"
echo -e "  ${MAGENTA}•$NC} ${RED}Más pesado$NC} (consume más RAM/CPU)"
echo -e "  ${MAGENTA}•$NC} ${GREEN}Mejor compatibilidad$NC} en algunos casos raros"
echo
read -p "¿Instalar Android Emulator (SDK)? [s/N]: " install_android_studio

if [[ "$install_android_studio" =~ ^[Ss]$ ]]; then
  print_header "Instalando Android Studio + Emulator"

  print_installing "Android Studio (esto toma tiempo)"
  yay -S --needed --noconfirm --answerdiff=None --answerclean=None --removemake \
    android-studio 2>/dev/null || print_warning "Android Studio falló"

  if [[ -d /opt/android-studio ]]; then
    print_success "Android Studio instalado en /opt/android-studio"

    echo
    echo -e "${CYAN}Pasos para usar:$NC}"
    echo -e "  ${MAGENTA}1.$NC} Ejecuta: ${YELLOW}/opt/android-studio/bin/studio.sh$NC}"
    echo -e "  ${MAGENTA}2.$NC} Selecciona: ${YELLOW}AVD Manager$NC}"
    echo -e "  ${MAGENTA}3.$NC} Crea: ${YELLOW}Pixel 2$NC} (recomendado)"
    echo -e "  ${MAGENTA}4.$NC} Lanza y espera (${RED}LENTO$NC})"
    echo -e "  ${MAGENTA}5.$NC} Instala MagisTV desde APK"
    echo

    print_warning "${RED}Esto es MUCHO MÁS LENTO que Waydroid$NC}"
    print_status "Solo usa si Waydroid falla"
  else
    print_error "Android Studio no se instaló correctamente"
  fi
else
  print_warning "Android Emulator omitido"
fi

print_success "Alternativas de Android completadas"

# ═══════════════════════════════════════════════════════════
# COMANDOS ÚTILES PARA WAYDROID
# ═══════════════════════════════════════════════════════════

cat >~/.local/bin/waydroid-helpers.sh <<'EOL'
#!/bin/bash
# Comandos útiles para Waydroid

case "$1" in
  status)
    echo "📊 Estado de Waydroid:"
    waydroid status
    ;;
  restart)
    echo "🔄 Reiniciando Waydroid..."
    waydroid session stop
    sudo systemctl restart waydroid-container
    sleep 10
    waydroid session start
    echo "✅ Reiniciado"
    ;;
  open)
    if [[ -z "$2" ]]; then
      waydroid show-full-ui
    else
      waydroid app launch "$2"
    fi
    ;;
  logcat)
    waydroid logcat "$@"
    ;;
  adb)
    waydroid adb enable
    adb connect 192.168.240.112:5555
    ;;
  *)
    echo "Uso: waydroid-helpers.sh [status|restart|open|logcat|adb]"
    ;;
esac
EOL

chmod +x ~/.local/bin/waydroid-helpers.sh

print_success "Helpers de Waydroid creados: waydroid-helpers.sh"

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

  if yay -S --needed --noconfirm --answerdiff=None --answerclean=None --removemake stremio stremio-service-bin 2>/dev/null; then
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
  nodejs npm python python-pip python-gobject python-pipx pyenv \
  docker rust \
  llvm clang patchelf git github-cli tgpt glow expect  # expect: Para unbuffer, glow: para los colores 

yay -S --needed --noconfirm --answerdiff=None --answerclean=None --removemake \
  claude-code clawdbot gemini-cli-git aichat
print_success "Gemini, TGPT, Claude instaladas. Para Deepseek y modelos local usa: Ollama"

print_installing "Python LSP + Neovim support"
python -m pip install --user --break-system-packages pynvim 'python-lsp-server[all]' 2>/dev/null || true

print_installing "Node packages (neovim)"
npm install -g neovim 2>/dev/null || true

# ═══════════════════════════════════════════════════════════
# DOCKER SETUP (FUNCIONAL Y ROBUSTO)
# ═══════════════════════════════════════════════════════════
print_header "Configurando Docker"

# 1. Habilitar Docker service
print_status "Habilitando servicios de Docker..."
sudo systemctl daemon-reload
sudo systemctl enable docker.socket 2>/dev/null || true
sudo systemctl enable docker 2>/dev/null || true
sudo systemctl start docker.socket 2>/dev/null || true
sudo systemctl start docker 2>/dev/null || true

# 2. Agregar usuario a grupo docker
sudo usermod -aG docker $USER 2>/dev/null || true
print_success "Docker CLI configurado"

# 3. Verificar instalación básica
if command -v docker &>/dev/null; then
  print_success "Docker disponible: $(docker --version)"
else
  print_warning "Docker CLI no disponible en PATH"
fi

# ═══════════════════════════════════════════════════════════
# DOCKER DESKTOP (OPCIONAL - FALLBACK INTELIGENTE)
# ═══════════════════════════════════════════════════════════
echo
echo -e "${CYAN}Opciones de Docker:${NC}"
echo -e "  ${MAGENTA}1.${NC} (OMITIR) Docker CLI (ya instalado - suficiente)"
echo -e "  ${MAGENTA}2.${NC} Docker Desktop (binarios estáticos+GUI - recomendado si necesitas GUI)"
echo -e "  ${MAGENTA}BTW.${NC} La realidad es que docker-compose entraba en conflicto con docker-desktop"
echo
read -p "Selecciona [1=(OMITIR) CLI solamente, 2=Agregar Desktop]: " docker_choice

if [[ "$docker_choice" == "2" ]]; then
  print_header "Instalando Docker Desktop (Binarios Estáticos)"
  
  # Crear directorio temporal
  DOCKER_TEMP="/tmp/docker-desktop-install-$$"
  mkdir -p "$DOCKER_TEMP"
  cd "$DOCKER_TEMP"
  
  # DESCARGA CORRECTA
  print_status "Descargando Docker binarios estáticos v29.1.4..."
  if wget -q --show-progress https://download.docker.com/linux/static/stable/x86_64/docker-29.1.4.tgz 2>/dev/null; then
    wget -q --show-progress https://desktop.docker.com/linux/main/amd64/214940/docker-desktop-x86_64.pkg.tar.zst
    sudo pacman -U ./docker-desktop-x86_64.pkg.tar.zst
    print_success "GUI => Descarga completada [Pacman -U para instalaciones Locales] + Binario Estático"
    
    # EXTRACCIÓN CORRECTA (sin errores de sintaxis)
    print_status "Extrayendo archivos..."
    if tar -xzf docker-29.1.4.tgz 2>/dev/null; then
      print_success "Extracción completada"
      
      # INSTALACIÓN CORRECTA
      print_installing "Instalando binarios en /usr/local/bin/"
      if sudo cp -rp docker/* /usr/local/bin/ && rm -rf docker; then
        print_success "Binarios instalados"
        
        # CREAR SERVICIO SYSTEMD (para docker daemon)
        print_status "Creando servicio Docker daemon..."
        sudo tee /etc/systemd/system/docker.service >/dev/null <<'DOCKERSVC'
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target docker.socket
Wants=network-online.target

[Service]
Type=notify
ExecStart=/usr/local/bin/dockerd -H fd://
ExecReload=/bin/kill -s HUP $MAINPID
RestartSec=5
Restart=on-failure

[Install]
WantedBy=multi-user.target
DOCKERSVC

        # Habilitar servicios
        sudo systemctl daemon-reload
        sudo systemctl enable docker docker.socket 2>/dev/null || true
        sudo systemctl restart docker 2>/dev/null || true
        
        print_success "Docker daemon configurado"
        
        # Verificación
        sleep 2
        if docker --version &>/dev/null; then
          print_success "✅ Docker funcional: $(docker --version)"
          
          # Prueba rápida (sin descargar imagen)
          print_status "Verificando conectividad..."
          if docker ps &>/dev/null; then
            print_success "✅ Docker listo para usar"
          fi
        else
          print_warning "⚠️  Docker instalado pero no disponible en PATH"
          print_status "Intenta: /usr/local/bin/docker --version"
        fi
      else
        print_error "❌ Error al copiar binarios"
      fi
    else
      print_error "❌ Error al extraer archivo tar"
    fi
  else
    print_error "❌ Error descargando Docker (sin internet o servidor caído)"
    print_status "Descarga manual: https://download.docker.com/linux/static/stable/x86_64/docker-29.1.4.tgz"
  fi
  
  # Limpiar
  cd ~
  rm -rf "$DOCKER_TEMP"
  
elif [[ "$docker_choice" == "1" ]]; then
  print_success "Usando Docker CLI (suficiente para la mayoría)"
else
  print_warning "Docker Desktop omitido"
fi

print_success "Docker configurado"

# ═══════════════════════════════════════════════════════════
# PYTHON + NODE SUPPORT
# ═══════════════════════════════════════════════════════════
print_installing "Python LSP + Neovim support"
python -m pip install --user --break-system-packages pynvim 'python-lsp-server[all]' 2>/dev/null || true

print_installing "Node packages (neovim)"
npm install -g neovim 2>/dev/null || true

# ═══════════════════════════════════════════════════════════
# GEMINI CLI (OPCIONAL)
# ═══════════════════════════════════════════════════════════

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

  rm -rf ~/.oh-my-zsh
  rm -rf ~/dotfiles-dizzi/zsh/.oh-my-zsh
  #  0. Limpiar/Reinstalar Oh My Zsh si existe
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

  for pkg in niri kdenlive-compressor-editor pipewire sattyScreenshots Antigravity networkmanager-fuzzel nwg-gtk-3.0 nwg-gtk-4.0 qt5ct qt6ct thunar ibus Raycast-vicinae fuzzel-glyphs-rofimoji autostart dunst easyeffects swaync espanso eww fastfetch font ghostty home hypr kew kitty local nvim rofi systemd themes wal wallpapers waybar wireplumber wofi yazi zsh input-remapper quickshell caelestia icons vscode cursor manual-ln htop neofetch tmux polybar bottom starship qtile; do
    if [[ -d $pkg ]]; then
      print_package "Stow: $pkg"
      stow $pkg 2>/dev/null || print_warning "Stow falló para $pkg"
    fi
  done

print_status "Aplicando Submodulos [NVIM]    ."

echo "${BOLD}${CYAN}Paso 1: Clonando repositorios...${RESET}"
# Verificar submodules
git submodule update --init --recursive
rm -rf nvim

# Recuperar cada submódulo
git submodule update --init --recursive nvim

echo "${BOLD}${CYAN}Paso 2: Corrigiendo el branch main...${RESET}"
cd  nvim/.config/nvim  && git checkout main
cd  ../../../

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

  # Config de Sudoers POWER para systemctl reboot --force --force
  if [[ -f ~/dotfiles-dizzi/etc/sudoers.d/power ]]; then
    print_package "Symlink: Sudoers POWER"
    sudo ln -sf ~/dotfiles-dizzi/etc/sudoers.d/power /etc/sudoers.d/
    # sudo cp ~/dotfiles-dizzi/etc/sudoers.d/power /etc/sudoers.d/power && sudo chmod 440 etc/sudoers.d/power && sudo visudo -c
  fi

  # TIMESHIFT Snapshots config
  if [[ -f ~/dotfiles-dizzi/etc/timeshift/timeshift.json ]]; then
    print_package "Symlink: Timeshift Snapshots"
    sudo ln -sf ~/dotfiles-dizzi/etc/timeshift/timeshift.json /etc/timeshift/timeshift.json
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

  # Para reparar problemas con WIFI
  if [[ -f ~/dotfiles-dizzi/etc/modprobe.d/iwlwifi.conf ]]; then
    print_package "Symlink: WIFI reparar problemas"
    sudo ln -sf ~/dotfiles-dizzi/etc/modprobe.d/iwlwifi.conf /etc/modprobe.d/iwlwifi.conf
    # sudo modprobe -r iwlwifi
    sudo modprobe iwlwifi 11n_disable=1 swcrypto=1
    # sudo modprobe -r iwlwifi
    sudo modprobe iwlwifi power_save=0
    # print_status "Recuerda usar:
    ip link show
    nmcli device status
    sudo dmesg | grep iwlwifi

    # Esto comprueba si hay problemas con el WIFI o las BIOS
  fi

  # Para solucionar Suspender al cerrar la laptop, viceversa
  if [[ -f ~/dotfiles-dizzi/etc/systemd/logind.conf ]]; then
    print_package "Symlink: Suspender al cerrar la laptop, viceversa"
    sudo ln -sf ~/dotfiles-dizzi/etc/systemd/logind.conf /etc/systemd/logind.conf
    # sudo systemctl restart systemd-logind
    print_status "Recuerda usar:
    sudo systemctl restart systemd-logind   O reiniciar el sistema
    systemctl status systemd-logind   para ver si se ejecuto"
  fi

  # Para solucionar initramfs-linux [/etc/mkinitcpio.conf] Tambien puedes consultar el historial root para guiarte con:
  if [[ -f ~/dotfiles-dizzi/etc/mkinitcpio.conf ]]; then
    print_package "Symlink: FIX initramfs-linux"
    sudo ln -sf ~/dotfiles-dizzi/etc/mkinitcpio.conf /etc/mkinitcpio.conf
    print_status "Tambien puedes consultar el historial ARRIBA root para guiarte. Por si vuelve a dar ese pantallazo azul con el 🐧  
    [Y Recuerda Usar:
    nano /etc/mkinitcpio.conf

    # EDITAR: HOOKS=(base udev autodetect keyboard keymap modconf block encrypt lvm2 filesystems fsck) # o elige systemd
    sudo mkinitcpio -P -v]

     󰁃 ¿Diferencias entre usar udev y systemd?
        󱞩 - systemd: resulta en una .img: 8.6/16mb
          - udev: resulta en una .img: 206mb

    # EDITAR: HOOKS=(base udev autodetect keyboard keymap modconf block encrypt lvm2 filesystems fsck) # o elige systemd"
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

  # NetworkManager y bluetooth
  if [[ -f ~/home/ ]]; then
    print_package "Habilitando: NetworkManager"
    systemctl --user enable NetworkManager
    systemctl --user start NetworkManager
  fi

  # bluetooth
  if [[ -f ~/home/ ]]; then
    print_package "Habilitando: bluetooth"
    systemctl --user enable bluetooth
    systemctl --user start bluetooth
  fi

  print_success "Servicios de usuario habilitados"
  print_success "bluetooth y Wifi habilitados"
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
  print_success "Better-Local-Files instalado" || true
  sh <(curl -s https://raw.githubusercontent.com/Pithaya/spicetify-apps/main/custom-apps/better-local-files/src/install.sh)
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
echo -e "${BOLD}${YELLOW}║          🎮 HERRAMIENTAS DE AUTOMATIZACIÓN 🎮             ║${NC}"
echo -e "${BOLD}${YELLOW}╚═══════════════════════════════════════════════════════════╝${NC}"
echo
read -p "¿Instalar PyMacroRecord? [S/n]: " install_pymacro
read -p "¿Instalar AutoClickers? [S/n]: " install_autoclickers
# read -p "¿Instalar PreMiD (Discord Rich Presence)? [s/N]: " install_premid

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

  # Buscar PyMacroRecord (CORREGIDO)
  PYMACRO_PATHS=(
    ~/dotfiles-dizzi/home/LinuxPyMacroRecord/PyMacroRecord-1.4.2
    ~/dotfiles-dizzi/home/LinuxPyMacroRecord/PyMacroRecord-1.4.1
    ~/LinuxPyMacroRecord/PyMacroRecord-1.4.2
    ~/LinuxPyMacroRecord/PyMacroRecord-1.4.1
    ~/Descargas/PyMacroRecord-1.4.2
    ~/Descargas/PyMacroRecord-1.4.1
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
    echo -e "${CYAN}O tienes las carpetas en:${NC}"
    echo "  • ~/LinuxPyMacroRecord/PyMacroRecord-1.4.2"
    echo "  • ~/LinuxPyMacroRecord/PyMacroRecord-1.4.1"
    echo
    read -p "Introduce ruta completa (o Enter para omitir): " custom_path

    if [[ -d "$custom_path" ]]; then
      PYMACRO_PATH="$custom_path"
      PYMACRO_FOUND=true
    fi
  fi

  if [[ "$PYMACRO_FOUND" == true ]]; then
    print_installing "Configurando PyMacroRecord"

    # CRÍTICO: Copiar SOLO la carpeta de PyMacroRecord, NO todo ~
    mkdir -p ~/.local/share

    # Eliminar instalación anterior
    if [[ -d ~/.local/share/pymacro ]]; then
      print_status "Eliminando instalación anterior..."
      rm -rf ~/.local/share/pymacro
    fi

    # Copiar CORRECTAMENTE
    cp -r "$PYMACRO_PATH" ~/.local/share/pymacro
    cd ~/.local/share/pymacro

    # Eliminar venv viejo si existe
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

    # Configurar permisos
    setup_input_permissions "PyMacroRecord"

    # Crear launcher con XWayland wrapper
    print_installing "Creando launcher XWayland"
    mkdir -p ~/.local/bin

    cat >~/.local/bin/pymacrorecord <<'EOL'
#!/bin/bash
# Wrapper DEFINITIVO para PyMacroRecord en Hyprland/Wayland

PYMACRO_DIR=~/.local/share/pymacro

# Verificar instalación
if [[ ! -d "$PYMACRO_DIR" ]]; then
    echo "❌ PyMacroRecord no encontrado en $PYMACRO_DIR"
    exit 1
fi

# Encontrar display de XWayland
find_xwayland_display() {
    local display=$(ps aux | grep -i xwayland | grep -oE ':[0-9]+' | head -1)
    if [[ -z "$display" ]]; then
        display=$(ls /tmp/.X11-unix/ 2>/dev/null | grep -oE 'X[0-9]+' | head -1 | sed 's/X/:/')
    fi
    if [[ -z "$display" ]]; then
        display=":0"
    fi
    echo "$display"
}

XWAYLAND_DISPLAY=$(find_xwayland_display)

# Configurar variables de entorno para XWayland
export DISPLAY="$XWAYLAND_DISPLAY"
export GDK_BACKEND=x11
export QT_QPA_PLATFORM=xcb
export XAUTHORITY="$HOME/.Xauthority"

# Verificar conexión a XWayland
xhost +si:localuser:$USER 2>/dev/null

# Activar entorno virtual
cd "$PYMACRO_DIR"

if [[ ! -d "venv" ]]; then
    echo "❌ Entorno virtual no encontrado"
    exit 1
fi

source venv/bin/activate

# Ejecutar PyMacroRecord en XWayland
cd src
exec python main.py
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

    print_success "PyMacroRecord instalado con wrapper XWayland"

    # Verificar si necesita cerrar sesión
    if ! groups | grep -q input; then
      echo
      echo -e "${RED}${BOLD}⚠️  IMPORTANTE:${NC} ${YELLOW}Debes cerrar sesión y volver a entrar${NC}"
      echo -e "   (para aplicar permisos del grupo 'input')"
      echo
    fi

    echo
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
  echo -e "${BOLD}${GREEN}2. ydotool [like Wtype, dtool, xdtool]${NC} (Universal)"
  echo -e "${BOLD}${GREEN}3. Flatpak Clicker & BiggerTask ${NC} (GUI)"
  echo -e "${BOLD}${GREEN}4. Xclicker & atbswp [Tinytask?] ${NC} (GUI)"
  echo -e "${BOLD}${GREEN}5. Clonar Macro-Tool [Tinytask?] ${NC} (GUI)"
  echo
  read -p "¿Instalar TheClicker? [S/n]: " install_theclicker
  read -p "¿Instalar ydotool? [s/N]: " install_ydotool
  read -p "¿Instalar Flatpak Clicker? [s/N]: " install_flatpak
  read -p "¿Instalar xClicker? (yay) [s/N]: " install_xclickerAUR
  read -p "¿Instalar Macro-Tool? [s/N]: " install_macrotool

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

  # ══════════════════════════════════════════════════════════════════
  # FLATPAK CLICKER+Tinytask [BiggerTask] (CON VERIFICACIÓN MEJORADA)
  # ══════════════════════════════════════════════════════════════════
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
        flatpak install -y io.github.taboulet.BiggerTask
        print_success "Flatpak BiggerTask instalado (Tinytask)"
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
  # XCLICKER, & atbswp [Tinytask?] (GUI)
  # ═══════════════════════════════════════════════════════════
  if [[ "$install_xclickerAUR" =~ ^[Ss]$ ]]; then
    print_installing "Xclicker"
    yay -S --needed --noconfirm --answerdiff=None --answerclean=None --removemake \
      xclicker atbswp 2>/dev/null || print_warning "Xclicker falló"

    print_success "Xclicker instalado"
  else
    print_warning "Xclicker omitido"
  fi

  # ═══════════════════════════════════════════════════════════
  # MACRO-TOOL - INSTALACIÓN SIMPLE Y DIRECTA
  # ═══════════════════════════════════════════════════════════
  if [[ "$install_macrotool" =~ ^[Ss]$ ]]; then
    print_header "Instalando Macro-Tool"

    # Dependencias del sistema
    print_installing "Dependencias del sistema"
    sudo pacman -S --needed --noconfirm python python-pip git tk xdotool wmctrl

    # Directorio de instalación
    MACROTOOL_DIR=~/.local/share/macro-tool
    [[ -d "$MACROTOOL_DIR" ]] && rm -rf "$MACROTOOL_DIR"

    # Clonar repositorio
    print_installing "Clonando Macro-Tool desde GitHub"
    git clone --depth 1 https://github.com/YatoVoid/Macro-Tool.git "$MACROTOOL_DIR"
    cd "$MACROTOOL_DIR"

    # Setup automático (crea venv e instala dependencias)
    print_installing "Configurando entorno virtual"
    python3 run_macro.py &
    SETUP_PID=$!
    sleep 5
    kill $SETUP_PID 2>/dev/null || pkill -f "python3 run_macro.py"

    # Launcher
    print_installing "Creando launcher"
    mkdir -p ~/.local/bin
    cat >~/.local/bin/macro-tool <<'EOF'
#!/bin/bash
cd ~/.local/share/macro-tool
source venv/bin/activate
python3 AutoClicker.py
EOF
    chmod +x ~/.local/bin/macro-tool

    # Desktop entry
    mkdir -p ~/.local/share/applications
    cat >~/.local/share/applications/macro-tool.desktop <<'EOF'
[Desktop Entry]
Name=Macro-Tool AutoClicker
Exec=macro-tool
Icon=input-mouse
Terminal=false
Type=Application
Categories=Utility;
EOF

    update-desktop-database ~/.local/share/applications 2>/dev/null

    print_success "Macro-Tool instalado → Ejecuta: macro-tool"

    echo
    echo -e "${CYAN}Ubicación:${NC}"
    echo -e "  ${YELLOW}~/.local/share/macro-tool/${NC}"
    echo
  else
    print_warning "Macro-Tool omitido"
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
[[ -f ~/.local/bin/macro-tool ]] && echo -e "  ${GREEN}✓${NC} Macro-Tool"
# command -v premid &>/dev/null && echo -e "  ${GREEN}✓${NC} PreMiD"

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
read -p " [💀DURA 1H☠️] ¿Instalar Gruvbox GTK Theme? [S/n]: " install_gruvbox_gtk

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
  sudo pacman -S --needed --noconfirm ollama # open-webui: Interfaz gráfica para Ollama
  sudo systemctl enable --now ollama

  print_installing "Descargando modelo qwen2.5:0.5b (más ligero y rápido)"
  ollama pull qwen2.5:0.5b
  # Modelos Onlines
  ollama pull qwen3-coder:480b-cloud
  ollama pull gpt-oss:120b-cloud
  ollama pull gemma3:27b-cloud
  ollama pull deepseek-v3.1:671b-cloud

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

# ═══════════════════════════════════════════════════════════
# PASO 28.5: OPEN-WEBUI (CON FALLBACK A DOCKER)
# ═══════════════════════════════════════════════════════════
print_step "28.5/35: Open-WebUI (Interfaz para Ollama)"

echo
echo -e "${CYAN}Opciones para acceder a Ollama:${NC}"
echo -e "  ${MAGENTA}1.${NC} Open-WebUI (interfaz completa + historial)"
echo -e "  ${MAGENTA}2.${NC} Omitir (usar solo CLI de Ollama)"
echo -e "  ${MAGENTA}BTW.${NC} La realidad es que open-webui es más FACIL de instalar en DOCKER-desktop EXTENSIONS [No HUB]"
echo -e "  ${MAGENTA}BUSCALO COMO:${NC} rw4lll/openwebui-docker-extension"
echo
read -p "¿Instalar Open-WebUI? [S/n]: " install_webui

if [[ ! "$install_webui" =~ ^[Nn]$ ]]; then
  print_header "Instalando Open-WebUI"

  # Intento 1: Compilar desde AUR
  print_status "Intentando instalación desde AUR..."
  if yay -S --needed --noconfirm --answerdiff=None --answerclean=None --removemake \
    open-webui 2>/dev/null; then
    print_success "Open-WebUI instalado desde AUR"
    print_status "Accede a: http://localhost:8080"
  else
    # Fallback: Docker
    print_warning "Compilación AUR falló, usando Docker..."
    
    if ! command -v docker &>/dev/null; then
      print_status "Instalando Docker..."
      sudo pacman -S --needed --noconfirm docker
      sudo systemctl enable --now docker
      sudo systemctl start docker.service
      sudo systemctl enable docker.service
      sudo usermod -aG docker $USER
      docker run hello-world
    fi

    print_installing "Open-WebUI via Docker"
    # EXTRAIDO DE: 
    # https://www.jeremymorgan.com/blog/generative-ai/how-to-install-ollama-web-ui-arch-linux/ 

    # I’m going to choose the option to install Open WebUI with Bundled Ollama Support and select the container that utilizes a GPU:
    # if [[ -f /etc/arch-release ]]; then # esto esta MAL, usa:
      if command -v nvidia-smi &> /dev/null; then
      print_status "Detectado Arch Linux"
      print_installing "Open-WebUI via Docker (GPU)"
      docker run -d -p 3000:8080 --gpus=all -v ollama:/root/.ollama -v open-webui:/app/backend/data --name open-webui --restart always ghcr.io/open-webui/open-webui:ollama  2>/dev/null
    else
      print_status "Detectado Debian/Ubuntu"
      print_installing "Open-WebUI via Docker (CPU)"
      # If you’re not using a GPU, use this command:
      docker run -d -p 3000:8080 -v ollama:/root/.ollama -v open-webui:/app/backend/data --name open-webui --restart always ghcr.io/open-webui/open-webui:ollama 2>/dev/null
    fi

    if [[ $? -eq 0 ]]; then
      print_success "Open-WebUI iniciado en Docker"
      print_status "Accede a: http://localhost:3000"
      print_status "Primer inicio toma ~30 segundos"
    else
      print_error "Docker falló, instálalo manualmente después:"
      echo -e "${YELLOW}docker run -d --name open-webui -p 3000:8080 --add-host=host.docker.internal:host-gateway -v open-webui:/app/backend/data ghcr.io/open-webui/open-webui:main${NC}"
    fi
  fi
else
  print_warning "Open-WebUI omitido"
fi

# ═════════════════════════════════════════════════════════════════
# PASO 29: GLYPHS, ICONOS Y EMOJIS (RAYCAST-LIKE): Vicinae + Fuzzel
# ═════════════════════════════════════════════════════════════════
print_step "28/35: Glyphs, Iconos y Emojis"

echo
echo -e "${BOLD}${YELLOW}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${YELLOW}║          🎨 ICONOS, GLYPHS Y EMOJIS 🎨                    ║${NC}"
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

    wget -q --show-progress "$MUSIC_PRESENCE_URL" -O musicpresence.tar.gz
    {
      print_error "Error descargando Music Presence"
      cd ~
      return
    }

    if [[ -f musicpresence.tar.gz ]]; then
      # Extraer
      tar -xzf musicpresence.tar.gz
      rm musicpresence.tar.gz

      chmod +x musicpresence-*/usr/bin/musicpresence 2>/dev/null || true
    fi

    cd ~
  fi

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
# PASO 31.5: RCLONE GOOGLE DRIVE (OPCIONAL)
# ═══════════════════════════════════════════════════════════
print_step "31.5/35: Rclone Google Drive (Opcional)"

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
# PASO 32: CONFIGURACIÓN AUTOMÁTICA DE TEMAS QT/GTK
# ═══════════════════════════════════════════════════════════
print_step "32/35: Configuración Automática de Temas"

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
# PASO 32.5: DESACTIVAR GESTOR DE LOGIN ACTUAL
# ═══════════════════════════════════════════════════════════
print_step "32.5/35: Desactivar Display Manager Actual"

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
# PASO 33: CONFIGURAR SWAP DE +16GB RAM ( O LOS QUE TENGA )
# ═══════════════════════════════════════════════════════════

function configure_swap() {
  print_step "33/35: Configurar Swap Automático"

  echo
  echo -e "${BOLD}${YELLOW}╔═══════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${YELLOW}║          💾 CONFIGURACIÓN AUTOMÁTICA DE SWAP 💾           ║${NC}"
  echo -e "${BOLD}${YELLOW}╚═══════════════════════════════════════════════════════════╝${NC}"
  echo

  # Detectar RAM total del sistema
  local TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
  local TOTAL_RAM_GB=$((TOTAL_RAM_KB / 1024 / 1024))
  local CURRENT_SWAP_KB=$(grep SwapTotal /proc/meminfo | awk '{print $2}')
  local CURRENT_SWAP_GB=$((CURRENT_SWAP_KB / 1024 / 1024))

  echo -e "${CYAN}Sistema detectado:${NC}"
  echo -e "  ${MAGENTA}•${NC} RAM total: ${BOLD}${TOTAL_RAM_GB}GB${NC}"
  echo -e "  ${MAGENTA}•${NC} Swap actual: ${BOLD}${CURRENT_SWAP_GB}GB${NC}"

  # Calcular swap recomendado
  local RECOMMENDED_SWAP
  if [[ $TOTAL_RAM_GB -le 8 ]]; then
    RECOMMENDED_SWAP=$((TOTAL_RAM_GB * 2))  # 2x RAM si ≤8GB
  elif [[ $TOTAL_RAM_GB -le 16 ]]; then
    RECOMMENDED_SWAP=$TOTAL_RAM_GB          # 1x RAM si ≤16GB
  else
    RECOMMENDED_SWAP=16                     # Máximo 16GB si >16GB RAM
  fi

  echo -e "  ${MAGENTA}•${NC} Swap recomendado: ${BOLD}${RECOMMENDED_SWAP}GB${NC}"

  # Verificar espacio libre en disco
  local FREE_SPACE_KB=$(df / | tail -1 | awk '{print $4}')
  local FREE_SPACE_GB=$((FREE_SPACE_KB / 1024 / 1024))
  echo -e "  ${MAGENTA}•${NC} Espacio libre en /: ${BOLD}${FREE_SPACE_GB}GB${NC}"

  # Verificar si ya hay suficiente swap
  if [[ $CURRENT_SWAP_GB -ge $RECOMMENDED_SWAP ]]; then
    echo
    echo -e "${GREEN}✓ Swap actual (${CURRENT_SWAP_GB}GB) es suficiente${NC}"
    read -p "¿Configurar swap adicional de todos modos? [s/N]: " force_swap
    if [[ ! "$force_swap" =~ ^[Ss]$ ]]; then
      print_warning "Configuración de swap omitida"
      return
    fi
  fi

  # Verificar espacio suficiente
  local REQUIRED_SPACE=$((RECOMMENDED_SWAP + 2))  # +2GB de margen
  if [[ $FREE_SPACE_GB -lt $REQUIRED_SPACE ]]; then
    echo
    echo -e "${RED}⚠️  Espacio insuficiente:${NC}"
    echo -e "  Requerido: ${RED}${REQUIRED_SPACE}GB${NC}"
    echo -e "  Disponible: ${YELLOW}${FREE_SPACE_GB}GB${NC}"
    echo
    read -p "¿Crear swap más pequeño de ${FREE_SPACE_GB}GB? [s/N]: " create_smaller
    if [[ "$create_smaller" =~ ^[Ss]$ ]]; then
      RECOMMENDED_SWAP=$((FREE_SPACE_GB - 1))
    else
      print_warning "Configuración de swap omitida por falta de espacio"
      return
    fi
  fi

echo
echo -e "${CYAN}Opciones de swap:${NC}"
echo -e "  ${MAGENTA}1.${NC} Swapfile (${RECOMMENDED_SWAP}GB) - ${GREEN}Recomendado${NC}"
echo -e "  ${MAGENTA}2.${NC} Zswap (compresión en RAM) - ${YELLOW}Experimental${NC}"
echo -e "  ${MAGENTA}3.${NC} Ambos (Swapfile + Zswap) - ${CYAN}Máximo rendimiento${NC}"
echo -e "  ${MAGENTA}4.${NC} Eliminar swap completamente - ${RED}Desactiva hibernation${NC}"
echo -e "  ${MAGENTA}5.${NC} Omitir configuración"
echo
read -p "Seleccionar opción [1-5]: " swap_choice

case "$swap_choice" in
  4)
    print_header "Eliminando Swap Completamente"

    echo
    print_warning "⚠️  ADVERTENCIA: Esto desactivará hibernation"
    read -p "¿Estás seguro? [s/N]: " confirm_delete

    if [[ "$confirm_delete" =~ ^[Ss]$ ]]; then
      # Desactivar swap
      print_status "Desactivando swap..."
      sudo swapoff -a 2>/dev/null || true
      print_success "Swap desactivado"

      # Eliminar swapfile
      if [[ -f /swapfile ]]; then
        print_status "Eliminando /swapfile..."
        sudo rm -f /swapfile
        print_success "Swapfile eliminado"
      fi

      # Limpiar /etc/fstab
      if grep -q "/swapfile" /etc/fstab 2>/dev/null; then
        print_status "Removiendo entrada de fstab..."
        sudo sed -i '/\/swapfile/d' /etc/fstab
        print_success "Línea removida de /etc/fstab"
      fi

      # Limpiar parámetros de hibernation en GRUB
      if [[ -f /etc/default/grub ]]; then
        if grep -q "resume=" /etc/default/grub; then
          print_status "Removiendo parámetros de hibernation de GRUB..."
          sudo cp /etc/default/grub /etc/default/grub.backup.$(date +%s)
          sudo sed -i 's/ resume=[^ ]*//' /etc/default/grub
          sudo sed -i 's/ resume_offset=[^ ]*//' /etc/default/grub
          sudo grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null
          print_success "GRUB actualizado"
        fi
      fi

      # Mostrar espacio recuperado
      echo
      FREE_SPACE=$(df -h / | tail -1 | awk '{print $4}')
      echo -e "${GREEN}✓ Swap eliminado completamente${NC}"
      echo -e "${CYAN}Espacio libre ahora: ${BOLD}$FREE_SPACE${NC}"
      echo

      # Marcar para saltar hibernation
      SKIP_HIBERNATION=true
    else
      print_warning "Eliminación cancelada"
    fi
    ;;
  1|3)
    print_header "Configurando Swapfile de ${RECOMMENDED_SWAP}GB"
    
    # Verificar si ya existe swapfile
    if [[ -f /swapfile ]]; then
      print_warning "Ya existe /swapfile"
      sudo swapoff /swapfile 2>/dev/null || true
      sudo rm -f /swapfile
      print_status "Swapfile anterior eliminado"
    fi
    
    # Crear swapfile con fallocate (más rápido que dd)
    print_installing "Creando swapfile de ${RECOMMENDED_SWAP}GB"
    if sudo fallocate -l ${RECOMMENDED_SWAP}G /swapfile 2>/dev/null; then
      print_success "Swapfile creado con fallocate"
    else
      print_status "fallocate falló, usando dd..."
      sudo dd if=/dev/zero of=/swapfile bs=1M count=$((RECOMMENDED_SWAP * 1024)) status=progress
    fi
    
    # Configurar permisos y formato
    print_status "Configurando swapfile..."
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    
    # Agregar a /etc/fstab si no existe
    if ! grep -q "/swapfile" /etc/fstab; then
      echo '/swapfile none swap defaults 0 0' | sudo tee -a /etc/fstab
      print_success "Swapfile agregado a /etc/fstab"
    fi
    
    print_success "Swapfile de ${RECOMMENDED_SWAP}GB configurado"
    ;;
esac

case "$swap_choice" in
  2|3)
    print_header "Configurando Zswap (Compresión en RAM)"
    
    # Verificar soporte del kernel
    if [[ ! -f /sys/module/zswap/parameters/enabled ]]; then
      print_warning "Zswap no soportado por el kernel actual"
    else
      # Habilitar zswap
      print_installing "Habilitando zswap"
      echo 1 | sudo tee /sys/module/zswap/parameters/enabled
      
      # Configurar algoritmo de compresión (lz4 es más rápido)
      echo lz4 | sudo tee /sys/module/zswap/parameters/compressor 2>/dev/null || true
      echo zbud | sudo tee /sys/module/zswap/parameters/zpool 2>/dev/null || true
      
      # Configurar porcentaje de RAM para zswap (20% por defecto)
      echo 20 | sudo tee /sys/module/zswap/parameters/max_pool_percent
      
      # Hacer permanente agregando a kernel parameters
      if [[ -f /etc/default/grub ]]; then
        if ! grep -q "zswap.enabled=1" /etc/default/grub; then
          sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="zswap.enabled=1 zswap.compressor=lz4 zswap.max_pool_percent=20 /' /etc/default/grub
          print_status "Parámetros zswap agregados a GRUB"
          print_warning "Ejecuta 'sudo grub-mkconfig -o /boot/grub/grub.cfg' después del reinicio"
        fi
      fi
      
      print_success "Zswap configurado (20% RAM, compresión lz4)"
    fi
    ;;
esac

if [[ "$swap_choice" == "5" ]]; then
  print_warning "Configuración de swap omitida"
else
  # Configurar swappiness (agresividad del swap)
  print_status "Configurando swappiness..."
  
  # Swappiness recomendado según RAM
  if [[ $TOTAL_RAM_GB -ge 16 ]]; then
    SWAPPINESS=10  # Menos agresivo con mucha RAM
  elif [[ $TOTAL_RAM_GB -ge 8 ]]; then
    SWAPPINESS=20  # Moderado con RAM media
  else
    SWAPPINESS=60  # Más agresivo con poca RAM
  fi
  
  echo "vm.swappiness=$SWAPPINESS" | sudo tee /etc/sysctl.d/99-swappiness.conf
  sudo sysctl vm.swappiness=$SWAPPINESS
  
  print_success "Swappiness configurado a $SWAPPINESS"
  
  # Mostrar estado final
  echo
  echo -e "${GREEN}${BOLD}✨ CONFIGURACIÓN DE SWAP COMPLETADA ✨${NC}"
  echo
  NEW_SWAP_KB=$(grep SwapTotal /proc/meminfo | awk '{print $2}')
  NEW_SWAP_GB=$((NEW_SWAP_KB / 1024 / 1024))
  echo -e "${CYAN}Estado actual:${NC}"
  echo -e "  ${MAGENTA}•${NC} RAM: ${BOLD}${TOTAL_RAM_GB}GB${NC}"
  echo -e "  ${MAGENTA}•${NC} Swap total: ${BOLD}${NEW_SWAP_GB}GB${NC}"
  echo -e "  ${MAGENTA}•${NC} Swappiness: ${BOLD}$SWAPPINESS${NC}"
  
  if [[ "$swap_choice" == "2" || "$swap_choice" == "3" ]]; then
    ZSWAP_STATUS=$(cat /sys/module/zswap/parameters/enabled 2>/dev/null || echo "N")
    echo -e "  ${MAGENTA}•${NC} Zswap: ${BOLD}$([[ "$ZSWAP_STATUS" == "Y" ]] && echo "Habilitado" || echo "Deshabilitado")${NC}"
  fi
  
  echo
  echo -e "${YELLOW}Comandos útiles:${NC}"
  echo -e "  ${CYAN}•${NC} Ver uso de swap: ${YELLOW}swapon --show${NC}"
  echo -e "  ${CYAN}•${NC} Ver memoria: ${YELLOW}free -h${NC}"
  echo -e "  ${CYAN}•${NC} Estado zswap: ${YELLOW}grep -r . /sys/module/zswap/parameters/${NC}"
  echo
  fi
}

# Llamar la función de swap
configure_swap

# PASO 33.5: CONFIGURAR HIBERNATION (SLEEP TO DISK)
function configure_hibernation() {
  # Verificar si se saltó por eliminación de swap
  if [[ "$SKIP_HIBERNATION" == "true" ]]; then
    print_warning "Hibernation omitido (swap eliminado)"
    return 0
  fi

  print_step "33.5/35: Configurar Hibernation (Sleep to Disk)"

  echo
  echo -e "${BOLD}${YELLOW}╔═══════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${YELLOW}║          💤 CONFIGURACIÓN DE HIBERNATION 💤               ║${NC}"
  echo -e "${BOLD}${YELLOW}╚═══════════════════════════════════════════════════════════╝${NC}"
  echo

  # Verificar si systemctl soporta hibernation
  if ! systemctl hibernate --dry-run &>/dev/null; then
    print_warning "Hibernation NO soportado en este kernel"
    print_warning "Saltando configuración de hibernation"
    return
  fi

  read -p "¿Configurar Hibernation? [S/n]: " setup_hibernation
  [[ "$setup_hibernation" =~ ^[Nn]$ ]] && return

  # ───────────────────────────────────────────────────────────
  # PASO 1: Obtener offset del swapfile
  # ───────────────────────────────────────────────────────────
  print_header "Calculando OFFSET del swapfile"

  if [[ ! -f /swapfile ]]; then
    print_error "No existe /swapfile. Hibernation requiere swap configurado."
    return
  fi

  SWAP_OFFSET=$(sudo filefrag -v /swapfile 2>/dev/null | grep "0:" | awk '{print $4}' | cut -d. -f1)

  if [[ -z "$SWAP_OFFSET" ]]; then
    print_error "No se pudo calcular el offset. Saltando hibernation."
    return
  fi

  print_success "Offset calculado: $SWAP_OFFSET"
  echo -e "${CYAN}Guardando en ${YELLOW}/root/.hibernation_offset${NC}"
  echo "$SWAP_OFFSET" | sudo tee /root/.hibernation_offset >/dev/null

  # ───────────────────────────────────────────────────────────
  # PASO 2: Detectar bootloader
  # ───────────────────────────────────────────────────────────
  print_status "Detectando bootloader..."

  BOOTLOADER="none"
  if [[ -f /etc/default/grub ]]; then
    BOOTLOADER="grub"
    print_success "GRUB detectado"
  elif [[ -d /boot/loader/entries ]]; then
    BOOTLOADER="systemd-boot"
    print_warning "systemd-boot detectado (hibernation manual)"
  fi

  if [[ "$BOOTLOADER" == "none" ]]; then
    print_warning "No se detectó bootloader conocido"
    return
  fi

  # ───────────────────────────────────────────────────────────
  # PASO 3: Configurar GRUB (si aplica)
  # ───────────────────────────────────────────────────────────
  if [[ "$BOOTLOADER" == "grub" ]]; then
    print_header "Configurando GRUB para Hibernation"

    echo
    echo -e "${YELLOW}Opciones:${NC}"
    echo -e "  ${MAGENTA}1.${NC} ${GREEN}Automático${NC} (editar GRUB automáticamente)"
    echo -e "  ${MAGENTA}2.${NC} ${YELLOW}Manual${NC} (mostrar instrucciones)"
    echo -e "  ${MAGENTA}3.${NC} ${RED}Omitir${NC}"
    echo
    read -p "Seleccionar [1-3]: " grub_choice

    case "$grub_choice" in
    1)
      print_status "Editando /etc/default/grub..."

      # Hacer backup
      sudo cp /etc/default/grub /etc/default/grub.backup.$(date +%s)
      print_success "Backup creado"

      # Buscar la línea GRUB_CMDLINE_LINUX_DEFAULT
      if grep -q "GRUB_CMDLINE_LINUX_DEFAULT=" /etc/default/grub; then
        # Remover parámetros resume antiguos (si existen)
        sudo sed -i 's/ resume=[^ ]*//' /etc/default/grub
        sudo sed -i 's/ resume_offset=[^ ]*//' /etc/default/grub

        # Agregar parámetros nuevos
        sudo sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"/GRUB_CMDLINE_LINUX_DEFAULT=\"resume=\/swapfile resume_offset=$SWAP_OFFSET /" /etc/default/grub

        print_success "Parámetros agregados a GRUB"
      else
        print_warning "No se encontró GRUB_CMDLINE_LINUX_DEFAULT"
        echo "resume=/swapfile resume_offset=$SWAP_OFFSET" | sudo tee -a /etc/default/grub
      fi

      # Mostrar configuración
      echo
      echo -e "${CYAN}Nueva configuración:${NC}"
      grep "GRUB_CMDLINE_LINUX_DEFAULT" /etc/default/grub
      echo

      # Actualizar GRUB
      print_status "Actualizando GRUB..."
      sudo grub-mkconfig -o /boot/grub/grub.cfg

      if [[ $? -eq 0 ]]; then
        print_success "GRUB actualizado exitosamente"
      else
        print_error "Error actualizando GRUB"
        print_warning "Restaurar backup: sudo cp /etc/default/grub.backup.* /etc/default/grub"
      fi
      ;;
    2)
      echo
      echo -e "${YELLOW}${BOLD}CONFIGURACIÓN MANUAL DE GRUB${NC}"
      echo
      echo -e "  ${CYAN}1. Abre el archivo con:${NC}"
      echo -e "     ${YELLOW}sudo nano /etc/default/grub${NC}"
      echo
      echo -e "  ${CYAN}2. Busca la línea:${NC}"
      echo -e "     ${YELLOW}GRUB_CMDLINE_LINUX_DEFAULT=\"...\"${NC}"
      echo
      echo -e "  ${CYAN}3. Agrega al final (antes del cierre \"):${NC}"
      echo -e "     ${GREEN}resume=/swapfile resume_offset=$SWAP_OFFSET${NC}"
      echo
      echo -e "  ${CYAN}Ejemplo:${NC}"
      echo -e "     ${YELLOW}GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet resume=/swapfile resume_offset=$SWAP_OFFSET\"${NC}"
      echo
      echo -e "  ${CYAN}4. Guarda (Ctrl+O, Enter, Ctrl+X)"
      echo
      echo -e "  ${CYAN}5. Actualiza GRUB:${NC}"
      echo -e "     ${YELLOW}sudo grub-mkconfig -o /boot/grub/grub.cfg${NC}"
      echo
      read -p "Presiona Enter cuando hayas completado los pasos..."
      ;;
    3)
      print_warning "GRUB no configurado"
      ;;
    esac
  fi

  if [[ "$BOOTLOADER" == "systemd-boot" ]]; then
    echo
    echo -e "${YELLOW}${BOLD}systemd-boot detectado${NC}"
    echo -e "${CYAN}Para hibernation en systemd-boot:${NC}"
    echo
    echo -e "  ${MAGENTA}1.${NC} Edita ${YELLOW}/boot/loader/entries/arch.conf${NC}:"
    echo -e "     Agrega: ${GREEN}options resume=/swapfile resume_offset=$SWAP_OFFSET${NC}"
    echo
    echo -e "  ${MAGENTA}2.${NC} O usa ${YELLOW}bootctl edit arch${NC} (más seguro)"
    echo
    read -p "Presiona Enter cuando completes..."
  fi

  # ───────────────────────────────────────────────────────────
  # PASO 4: Configurar systemd-sleep (duraciones)
  # ───────────────────────────────────────────────────────────
  print_header "Configurando systemd-sleep"

  print_status "Permitir hibernation sin sudo (opcional)..."

  read -p "¿Crear permisos sudo para systemctl hibernate? [S/n]: " setup_sudo
  if [[ ! "$setup_sudo" =~ ^[Nn]$ ]]; then
    echo "%wheel ALL=(ALL) NOPASSWD: /usr/bin/systemctl hibernate" | sudo tee -a /etc/sudoers.d/hibernation >/dev/null
    echo "%wheel ALL=(ALL) NOPASSWD: /usr/bin/systemctl suspend" | sudo tee -a /etc/sudoers.d/hibernation >/dev/null
    print_success "Permisos configurados en /etc/sudoers.d/hibernation"
  fi

  # ───────────────────────────────────────────────────────────
  # PASO 5: Mostrar resumen
  # ───────────────────────────────────────────────────────────
  echo
  echo -e "${GREEN}${BOLD}✨ HIBERNATION CONFIGURADO ✨${NC}"
  echo
  echo -e "${CYAN}Comandos para usar:${NC}"
  echo -e "  ${YELLOW}systemctl hibernate${NC}      # Dormir a disco"
  echo -e "  ${YELLOW}systemctl suspend${NC}        # Dormir en RAM"
  echo -e "  ${YELLOW}systemctl suspend-then-hibernate${NC}  # RAM→Disco (timeout)"
  echo
  echo -e "${CYAN}Variables guardadas:${NC}"
  echo -e "  ${MAGENTA}•${NC} Offset: ${BOLD}$SWAP_OFFSET${NC}"
  echo -e "  ${MAGENTA}•${NC} Swapfile: ${BOLD}/swapfile${NC}"
  echo -e "  ${MAGENTA}•${NC} Bootloader: ${BOLD}$BOOTLOADER${NC}"
  echo
  echo -e "${YELLOW}${BOLD}⚠️  IMPORTANTE:${NC}"
  echo -e "  ${CYAN}•${NC} ${YELLOW}Reinicia el sistema${NC} para que los cambios tomen efecto"
  echo -e "  ${CYAN}•${NC} Si GRUB se corrompe, usa: ${YELLOW}sudo grub-mkconfig -o /boot/grub/grub.cfg${NC}"
  echo
}

# Llamar la función de hibernation
configure_hibernation

# ═══════════════════════════════════════════════════════════
# PASO 34: SISTEMA UNIFICADO DE BACKUPS (TIMESHIFT/SNAPPER)
# ═══════════════════════════════════════════════════════════
print_step "34/35: Sistema Unificado de Backups (Snapshots)"

echo
echo -e "${BOLD}${YELLOW}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${YELLOW}║      🔄 SISTEMA UNIFICADO DE SNAPSHOTS/BACKUPS 🔄         ║${NC}"
echo -e "${BOLD}${YELLOW}╚═══════════════════════════════════════════════════════════╝${NC}"
echo
echo -e "${CYAN}Sistema modular y completo de backups/snapshots:${NC}"
echo -e "  ${MAGENTA}•${NC} Detección automática de filesystem (ext4/Btrfs)"
echo -e "  ${MAGENTA}•${NC} Timeshift para ext4 (rsync incremental)"
echo -e "  ${MAGENTA}•${NC} Snapper para Btrfs (snapshots nativos)"
echo -e "  ${MAGENTA}•${NC} Límite de 5GB máximo para ahorro de espacio"
echo -e "  ${MAGENTA}•${NC} Snapshots automáticos antes de actualizaciones"
echo -e "  ${MAGENTA}•${NC} Opción de desinstalación/reversión completa"
echo

# Ejecutar script de configuración de backups
if [[ -f ~/dotfiles-dizzi/setup-backup-system.sh ]]; then
  bash ~/dotfiles-dizzi/setup-backup-system.sh
else
  print_error "Script de configuración no encontrado: ~/dotfiles-dizzi/setup-backup-system.sh"
  read -p "¿Continuar sin configurar backups? [S/n]: " skip_backups

  if [[ "$skip_backups" =~ ^[Nn]$ ]]; then
    print_error "Backup system setup abortado"
  fi
fi

echo
print_success "Configuración de backups completada"

# ═══════════════════════════════════════════════════════════
# PASO 34.5: DISPLAY MANAGER (GDM O SDDM) - MEJORADO
# ═══════════════════════════════════════════════════════════
print_step "34.5/35: Display Manager (GDM o SDDM)"

echo
echo -e "${BOLD}${YELLOW}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${YELLOW}║          🖥️  SELECCIONAR DISPLAY MANAGER 🖥️               ║${NC}"
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
    echo -e "${CYAN}║  • Uno de los 10 temas visuales disponibles           ║${NC}"
    echo -e "${CYAN}║  • Personalizar colores y apariencia                  ║${NC}"
    echo -e "${CYAN}║  • Configurar wallpaper                               ║${NC}"
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
hyprctl reload # o niri reload

# Reiniciar Waybar desacoplado de la terminal
print_status "Reiniciando Waybar..."
killall waybar 2>/dev/null || true
nohup waybar >/dev/null 2>&1 & # NOHUP LA SOLUCION PARA QUE NO SE CIERRE AL CERRAR TERMINAL
sleep 1

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
echo -e "${YELLOW}${BOLD}Hibernation y Snapshots:${NC}"
echo -e "  ${CYAN}•${NC} Dormir a disco: ${YELLOW}systemctl hibernate${NC}"
echo -e "  ${CYAN}•${NC} Ver snapshots: ${YELLOW}snapper list${NC} o ${YELLOW}snls${NC} (alias)"
echo -e "  ${CYAN}•${NC} Crear snapshot: ${YELLOW}snapper create -d 'Mi snapshot'${NC}"
echo -e "  ${CYAN}•${NC} Snapshots automáticos: ${YELLOW}Antes de pacman -Syu${NC} (snap-pac)"
echo -e "  ${CYAN}•${NC} Espacio snapshots: ${YELLOW}~10-20GB${NC} para 50 snapshots (con compresión)"
echo
echo -e "${CYAN}💡 TIPS:${NC}"
echo -e "  ${MAGENTA}•${NC} Hibernation: Verifica con ${YELLOW}systemctl hibernate --dry-run${NC}"
echo -e "  ${MAGENTA}•${NC} Snapshots: Rollback desde GRUB en 'Arch Linux snapshots'"
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
