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
# PASO 18: SYMLINKS A /etc
# ═══════════════════════════════════════════════════════════
print_step "18/35: Symlinks a /etc (udev/polkit/bluetooth/pam.d) para Gnome Keyring y mas"

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
    # sudo ln -sf ~/dotfiles-dizzi/etc/sudoers.d/power /etc/sudoers.d/
    # como root ejecuta: su - # &
    # sudo cp ~/dotfiles-dizzi/etc/sudoers.d/power /etc/sudoers.d/power && sudo chmod 440 etc/sudoers.d/power && sudo visudo -c
  fi

  # TIMESHIFT Snapshots config
  if [[ -f ~/dotfiles-dizzi/etc/timeshift/timeshift.json ]]; then
    print_package "Symlink: Timeshift Snapshots"
    sudo mkdir -p /etc/timeshift
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
  # Para SDDM THEME
  [[ -f ~/dotfiles-dizzi/etc/sddm.conf ]] && {
    print_package "Symlink: SDDM Theme de Jake"
    sudo pacman -S sddm --needed --noconfirm
    sudo ln -sf ~/dotfiles-dizzi/etc/sddm.conf /etc/sddm.conf
  }

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
    RECOMMENDED_SWAP=$((TOTAL_RAM_GB * 2)) # 2x RAM si ≤8GB
  elif [[ $TOTAL_RAM_GB -le 16 ]]; then
    RECOMMENDED_SWAP=$TOTAL_RAM_GB # 1x RAM si ≤16GB
  else
    RECOMMENDED_SWAP=16 # Máximo 16GB si >16GB RAM
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
  local REQUIRED_SPACE=$((RECOMMENDED_SWAP + 2)) # +2GB de margen
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
  1 | 3)
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
  2 | 3)
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
      SWAPPINESS=10 # Menos agresivo con mucha RAM
    elif [[ $TOTAL_RAM_GB -ge 8 ]]; then
      SWAPPINESS=20 # Moderado con RAM media
    else
      SWAPPINESS=60 # Más agresivo con poca RAM
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
echo
echo -e "${BOLD}${GREEN}2. SDDM + Astronaut Theme (MEJORADO)${NC}"
echo -e "  ${MAGENTA}•${NC} 10 temas visuales pre-hechos"
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
  # Fix 1 - graphical target
  sudo systemctl set-default graphical.target
  sudo reboot
  # Fix 2 - restaurar desktop files
  sudo pacman -S hyprland # reinstalación restauró hyprland.desktop
  sudo chmod 644 /usr/share/wayland-sessions/hyprland.desktop
  #  Fix 3 - restaurar sddm.service
  sudo ln -sf /usr/lib/systemd/system/gdm.service /etc/systemd/system/display-manager.service
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
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo
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
  sudo systemctl set-default graphical.target
  sudo reboot
  sudo pacman -S hyprland # reinstalación restauró hyprland.desktop
  sudo chmod 644 /usr/share/wayland-sessions/hyprland.desktop
  #  Fix 4 - restaurar gdm.service
  sudo ln -sf /usr/lib/systemd/system/gdm.service /etc/systemd/system/display-manager.service
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
║  ✅ Apps, DevOps (Docker), Ollama + opencommit (si seleccionado)     ║
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
echo -e "  ${CYAN}•${NC} Pywal: ${YELLOW}wal -i ~/wallpapers/tu-imagen.jpg${NC}"
echo -e "  ${CYAN}•${NC} Music Presence: ${YELLOW}source ~/.zshrc && musicpresence${NC}"
echo -e "  ${CYAN}•${NC} Rclone: ${YELLOW}~/montar_gdrive.sh${NC} (si configuraste)"
echo
echo -e "${YELLOW}${BOLD}Hibernation y Snapshots:${NC}"
echo -e "  ${CYAN}•${NC} Dormir a disco: ${YELLOW}systemctl hibernate${NC}"
echo -e "  ${CYAN}•${NC} Espacio snapshots: ${YELLOW}~10-20GB${NC} para 50 snapshots (con compresión)"
echo
echo -e "${CYAN}💡 TIPS:${NC}"
echo -e "  ${CYAN}•${NC}   PROBLEMAS CON LA CPU al 100%? # Ver CPU de otros procesos
  htop # --> Usa F6 para ordenar por CPU
  # ...
  Btw ya parche y mejore los intervalos de waybar, eww, hypr, scripts etc.
  ps aux --sort=-%cpu | grep -E "eww | hypr | waybar | dunst | swaync | swww | caelestia" | head -20.${NC}"
echo
echo -e "${GREEN}¡Disfruta tu setup Hyprland perfeccionado con SDDM Astronaut! 🚀${NC}"
