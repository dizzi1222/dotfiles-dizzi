#!/bin/bash
# HYPER-arch-INSTALL.sh
# EJECUTAR SOLO DENTRO DE arch-chroot /mnt

# ═══════════════════════════════════════════════════════════
# 🔮 FASE 1: CONFIGURACIÓN BASE ARCH LINUX 🔮
# ═══════════════════════════════════════════════════════════

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

function print_status() { echo -e "${BLUE}[⚡]${NC} $1"; }
function print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
function print_error() {
  echo -e "${RED}[✗]${NC} $1"
  exit 1
}
function print_warning() { echo -e "${YELLOW}[⚠]${NC} $1"; }

# ═══════════════════════════════════════════════════════════
# VERIFICACIÓN: SOLO ROOT EN CHROOT
# ═══════════════════════════════════════════════════════════
if [[ $EUID -ne 0 ]]; then
  print_error "Este script DEBE ejecutarse como root dentro de arch-chroot /mnt"
fi

if [[ ! -f /etc/arch-release ]]; then
  print_error "No estás en un sistema Arch Linux"
fi

clear
cat <<"EOF"

██╗███╗░░██╗░██████╗████████╗░█████╗░██╗░░░░░██╗░░░░░
██║████╗░██║██╔════╝╚══██╔══╝██╔══██╗██║░░░░░██║░░░░░
██║██╔██╗██║╚█████╗░░░░██║░░░███████║██║░░░░░██║░░░░░
██║██║╚████║░╚═══██╗░░░██║░░░██╔══██║██║░░░░░██║░░░░░
██║██║░╚███║██████╔╝░░░██║░░░██║░░██║███████╗███████╗
╚═╝╚═╝░░╚══╝╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝╚══════╝╚══════╝

██╗░░██╗██╗░░░██╗██████╗░██████╗░██╗░░░░░░█████╗░███╗░░██╗██████╗░
██║░░██║╚██╗░██╔╝██╔══██╗██╔══██╗██║░░░░░██╔══██╗████╗░██║██╔══██╗
███████║░╚████╔╝░██████╔╝██████╔╝██║░░░░░███████║██╔██╗██║██║░░██║
██╔══██║░░╚██╔╝░░██╔═══╝░██╔══██╗██║░░░░░██╔══██║██║╚████║██║░░██║
██║░░██║░░░██║░░░██║░░░░░██║░░██║███████╗██║░░██║██║░╚███║██████╔╝
╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░░░╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░

╔══════════════════════════════════════════════════════════════════════╗
║  🔮 FASE 1: CONFIGURACIÓN BASE ARCH LINUX 🔮                         ║
╠══════════════════════════════════════════════════════════════════════╣
║  EJECUTANDO EN: arch-chroot /mnt                                     ║
║  USUARIO: root                                                       ║
╚══════════════════════════════════════════════════════════════════════╝

EOF
sleep 2

# ═══════════════════════════════════════════════════════════
# 0. INSTALAR PAQUETES BASE CRÍTICOS PRIMERO
# ═══════════════════════════════════════════════════════════
print_status "Instalando paquetes base del sistema..."
pacman -Sy --noconfirm --needed \
  base base-devel \
  linux linux-firmware linux-headers \
  archlinux-keyring \
  efibootmgr \
  dhcpcd networkmanager iwd \
  nano vim \
  git curl wget \
  unzip zip \
  bash-completion \
  sudo \
  reflector man-db man-pages

print_success "Paquetes base críticos instalados"
echo

# ═══════════════════════════════════════════════════════════
# 1. TIMEZONE
# ═══════════════════════════════════════════════════════════
print_status "Configurando timezone..."
echo
echo -e "  ${CYAN}1)${NC} America/Santo_Domingo"
echo -e "  ${CYAN}2)${NC} America/New_York"
echo -e "  ${CYAN}3)${NC} Europe/Madrid"
echo
read -p "Selecciona timezone [1-3]: " tz_choice

case $tz_choice in
1) TIMEZONE="America/Santo_Domingo" ;;
2) TIMEZONE="America/New_York" ;;
3) TIMEZONE="Europe/Madrid" ;;
*) TIMEZONE="America/Santo_Domingo" ;;
esac
# 1. Configurar timezone correcto
ln -sf /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime
sudo timedatectl set-timezone "$TIMEZONE"
systemctl enable systemd-timesyncd
systemctl start systemd-timesyncd

# 2. Sincronizar hora con internet
sudo timedatectl set-ntp true
hwclock --systohc
print_success "Timezone configurado: $TIMEZONE"
echo

# ═══════════════════════════════════════════════════════════
# 2. LOCALE
# ═══════════════════════════════════════════════════════════
print_status "Configurando locale..."
sed -i 's/^#es_ES.UTF-8 UTF-8/es_ES.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen

echo 'LANG=es_ES.UTF-8' >/etc/locale.conf
echo 'LC_COLLATE=C' >>/etc/locale.conf
print_success "Locale configurado"
echo

# ═══════════════════════════════════════════════════════════
# 3. HOSTNAME
# ═══════════════════════════════════════════════════════════
print_status "Configurando hostname..."
read -p "Nombre del PC (hostname, ej: diego-pc): " HOSTNAME
HOSTNAME=${HOSTNAME:-archlinux}

echo "$HOSTNAME" >/etc/hostname
cat >/etc/hosts <<EOFHOSTS
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${HOSTNAME}.localdomain ${HOSTNAME}
EOFHOSTS
print_success "Hostname: $HOSTNAME"
echo

# ═══════════════════════════════════════════════════════════
# 4. PASSWORD ROOT
# ═══════════════════════════════════════════════════════════
print_status "Configurando password de root..."
echo -e "${YELLOW}IMPORTANTE: Esta será la password del superusuario root${NC}"
while true; do
  read -s -p "Password para root: " ROOTPASS
  echo
  read -s -p "Confirmar password: " ROOTPASS2
  echo

  if [[ "$ROOTPASS" == "$ROOTPASS2" ]] && [[ -n "$ROOTPASS" ]]; then
    echo "root:$ROOTPASS" | chpasswd
    print_success "Password de root configurado"
    break
  else
    print_warning "Las contraseñas no coinciden o están vacías. Intenta de nuevo."
  fi
done
echo

# ═══════════════════════════════════════════════════════════
# 5. CREAR USUARIO (VERSIÓN MEJORADA)
# ═══════════════════════════════════════════════════════════
print_status "Configuración de usuario principal..."

# Selección de shell
echo
echo -e "  ${CYAN}Selecciona el shell predeterminado:${NC}"
echo -e "  ${CYAN}1)${NC} zsh (recomendado - moderno y personalizable)"
echo -e "  ${CYAN}2)${NC} bash (clásico - ya instalado)"
echo
read -p "Shell [1-2] (default: zsh): " shell_choice

case $shell_choice in
2)
  USER_SHELL="/bin/bash"
  print_status "Shell seleccionado: bash"
  ;;
*)
  USER_SHELL="/bin/zsh"
  print_status "Shell seleccionado: zsh"
  # Instalar zsh si no está
  pacman -S --needed --noconfirm zsh
  ;;
esac
echo

# Solicitar nombre de usuario
echo -e "${YELLOW}Este será tu usuario diario (NO uses 'root' como nombre)${NC}"
read -p "Nombre de usuario (ej: diego): " USERNAME
USERNAME=${USERNAME:-diego}

# Validar que no sea root
if [[ "$USERNAME" == "root" ]]; then
  print_error "No puedes usar 'root' como nombre de usuario. Usa tu nombre real."
fi

# Verificar si el usuario ya existe
if id "$USERNAME" &>/dev/null; then
  print_warning "⚠️  Usuario '$USERNAME' ya existe"
  echo
  echo -e "  ${CYAN}Opciones disponibles:${NC}"
  echo -e "  ${CYAN}1)${NC} Reconfigurar usuario existente (cambiar shell y password)"
  echo -e "  ${CYAN}2)${NC} Eliminar y recrear usuario"
  echo -e "  ${CYAN}3)${NC} Cancelar (mantener usuario como está)"
  echo
  read -p "Selecciona opción [1-3]: " user_action

  case $user_action in
  1)
    print_status "Reconfigurando usuario '$USERNAME'..."
    usermod -s "$USER_SHELL" "$USERNAME"
    usermod -aG wheel,audio,video,storage,input,power "$USERNAME"
    print_success "Usuario '$USERNAME' actualizado"
    ;;
  2)
    print_warning "Eliminando usuario '$USERNAME' (sin borrar /home)..."
    userdel "$USERNAME" 2>/dev/null || true
    print_status "Recreando usuario '$USERNAME'..."
    useradd -m -g users -G wheel,audio,video,storage,input,power -s "$USER_SHELL" "$USERNAME"
    print_success "Usuario '$USERNAME' recreado"
    ;;
  3)
    print_status "Manteniendo usuario existente..."
    ;;
  *)
    print_warning "Opción inválida. Reconfigurando usuario..."
    usermod -s "$USER_SHELL" "$USERNAME"
    usermod -aG wheel,audio,video,storage,input,power "$USERNAME"
    ;;
  esac
else
  # Crear nuevo usuario con grupos correctos
  print_status "Creando usuario '$USERNAME'..."
  useradd -m -g users -G wheel,audio,video,storage,input,power -s "$USER_SHELL" "$USERNAME"
  print_success "Usuario '$USERNAME' creado correctamente"
fi

# Configurar password del usuario
echo
echo -e "${YELLOW}Configura la password para $USERNAME (esta es la que usarás diario)${NC}"
while true; do
  read -s -p "Password para $USERNAME: " USERPASS
  echo
  read -s -p "Confirmar password: " USERPASS2
  echo

  if [[ "$USERPASS" == "$USERPASS2" ]] && [[ -n "$USERPASS" ]]; then
    echo "$USERNAME:$USERPASS" | chpasswd
    print_success "Password de '$USERNAME' configurado"
    break
  else
    print_warning "Las contraseñas no coinciden o están vacías. Intenta de nuevo."
  fi
done

# Verificar y corregir permisos del home
print_status "Verificando permisos de /home/$USERNAME..."
if [[ -d "/home/$USERNAME" ]]; then
  chown -R "$USERNAME:users" "/home/$USERNAME"
  chmod 755 "/home/$USERNAME"
  print_success "Permisos de /home/$USERNAME corregidos"
else
  print_warning "Directorio /home/$USERNAME no existe. Creando..."
  mkdir -p "/home/$USERNAME"
  chown -R "$USERNAME:users" "/home/$USERNAME"
  chmod 755 "/home/$USERNAME"
  print_success "Directorio /home/$USERNAME creado con permisos correctos"
fi

# Verificar configuración final
ACTUAL_SHELL=$(getent passwd "$USERNAME" | cut -d: -f7)
ACTUAL_GROUPS=$(groups "$USERNAME" 2>/dev/null | cut -d: -f2)
print_success "Shell configurado: $ACTUAL_SHELL"
print_success "Grupos del usuario: $ACTUAL_GROUPS"
echo

# ═══════════════════════════════════════════════════════════
# 6. SUDO
# ═══════════════════════════════════════════════════════════
print_status "Configurando sudo..."

# Habilitar wheel en sudoers (ya está instalado en paso 0)
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Verificar que el usuario está en wheel
if groups "$USERNAME" | grep -q wheel; then
  print_success "Usuario '$USERNAME' tiene permisos sudo (grupo wheel)"
else
  print_warning "Agregando '$USERNAME' al grupo wheel..."
  usermod -aG wheel "$USERNAME"
  print_success "Usuario '$USERNAME' agregado a wheel"
fi
echo

# ═══════════════════════════════════════════════════════════
# 7. NETWORKMANAGER
# ═══════════════════════════════════════════════════════════
print_status "Configurando NetworkManager..."

# Paquetes de red ya instalados en paso 0
pacman -S --noconfirm --needed \
  wpa_supplicant wireless_tools net-tools inetutils

systemctl enable NetworkManager
systemctl enable dhcpcd
print_success "NetworkManager habilitado"
echo

# ═══════════════════════════════════════════════════════════
# 8. GRUB (DUALBOOT READY)
# ═══════════════════════════════════════════════════════════
print_status "Instalando GRUB..."
pacman -S --noconfirm --needed grub os-prober intel-ucode amd-ucode

echo
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS
echo
print_warning "IDENTIFICA LA PARTICIÓN EFI (generalmente /dev/sda1 o /dev/nvme0n1p1)"
echo -e "${YELLOW}Debe ser tipo 'vfat' o 'EFI System'${NC}"
read -p "Partición EFI (ej: /dev/sda1): " EFI_PART

# Validar que la partición existe
if [[ ! -b "$EFI_PART" ]]; then
  print_error "La partición $EFI_PART no existe"
fi

# Montar EFI
mkdir -p /boot/efi
if ! mountpoint -q /boot/efi; then
  mount "$EFI_PART" /boot/efi || print_error "Error montando $EFI_PART"
  print_success "Partición EFI montada en /boot/efi"
fi

# Instalar GRUB
print_status "Instalando GRUB en UEFI..."
grub-install --target=x86_64-efi \
  --efi-directory=/boot/efi \
  --bootloader-id=GRUB \
  --recheck

# Habilitar os-prober para detectar Windows
sed -i 's/^#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub

# Generar config
print_status "Generando configuración de GRUB..."
grub-mkconfig -o /boot/grub/grub.cfg
print_success "GRUB instalado y configurado para dualboot"
echo

# ═══════════════════════════════════════════════════════════
# 9. CREAR DIRECTORIO SCRIPTS Y PREPARAR FASE 2
# ═══════════════════════════════════════════════════════════
print_status "Creando estructura de directorios..."
mkdir -p "/home/$USERNAME/scripts"
chown -R "$USERNAME:users" "/home/$USERNAME/scripts"
chmod 755 "/home/$USERNAME/scripts"
print_success "Directorio /home/$USERNAME/scripts creado"
echo

print_status "Guardando placeholder del script Fase 2..."

# Crear el script fase 2 placeholder en /home/scripts/
cat >"/home/$USERNAME/scripts/fase2-HyprInstall-full.sh" <<'EOFSCRIPT2'
#!/bin/bash
# fase2-HyprInstall-full.sh
# EJECUTAR DESPUÉS DEL REBOOT COMO USUARIO NORMAL

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚠️  PLACEHOLDER DEL SCRIPT FASE 2"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Este es solo un marcador temporal."
echo "Debes descargar el script COMPLETO desde GitHub:"
echo ""
echo "  cd ~"
echo "  curl -O https://raw.githubusercontent.com/dizzi1222/dotfiles-dizzi/main/scripts/fase2-HyprInstall-full.sh"
echo "  chmod +x fase2-HyprInstall-full.sh"
echo "  bash fase2-HyprInstall-full.sh"
echo ""
echo "El script Fase 2 instalará Hyprland, AUR helper, dotfiles y más. Se encuentra en: /home/$USERNAME/dotfiles-dizzi/home/fase2-HyprInstall-full.sh"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
EOFSCRIPT2

# Permisos
chown "$USERNAME:users" "/home/$USERNAME/dotfiles-dizzi/home/fase2-HyprInstall-full.sh"
chown "$USERNAME:users" "/home/$USERNAME/dotfiles-dizzi/home/fase2-HyprInstall-full.sh"
chmod +x "/home/$USERNAME/dotfiles-dizzi/home/fase2-HyprInstall-full.sh"

print_success "Placeholder del script Fase 2 guardado"
echo

# ═══════════════════════════════════════════════════════════
# RESUMEN FINAL
# ═══════════════════════════════════════════════════════════
clear
cat <<EOFFINAL

╔══════════════════════════════════════════════════════════════════════╗
║                  ✅ FASE 1 COMPLETADA ✅                              ║
╠══════════════════════════════════════════════════════════════════════╣
║  ✓ Paquetes base: instalados (base, linux, firmware, etc)          ║
║  ✓ Timezone: $TIMEZONE
║  ✓ Hostname: $HOSTNAME
║  ✓ Usuario: $USERNAME (con sudo y permisos correctos)
║  ✓ Shell: $ACTUAL_SHELL
║  ✓ Grupos:$ACTUAL_GROUPS
║  ✓ Password de root: configurado
║  ✓ Password de $USERNAME: configurado
║  ✓ Permisos /home/$USERNAME: corregidos
║  ✓ NetworkManager: habilitado
║  ✓ GRUB: instalado (dualboot ready)
╚══════════════════════════════════════════════════════════════════════╝

🎯 PRÓXIMOS PASOS:

  1. Sal del chroot:
     exit

  2. Desmonta particiones:
     umount -R /mnt

  3. Reinicia el sistema:
     reboot

  4. Inicia sesión como: $USERNAME

  5. Descarga y ejecuta el script Fase 2 COMPLETO:
     cd ~
     curl -O https://raw.githubusercontent.com/dizzi1222/dotfiles-dizzi/main/scripts/fase2-HyprInstall-full.sh
     chmod +x fase2-HyprInstall-full.sh
     bash fase2-HyprInstall-full.sh

⚠️  IMPORTANTE:
  • No olvides 'umount -R /mnt' antes de reboot
  • El usuario es: $USERNAME (NO "root")
  • Shell configurado: $ACTUAL_SHELL
  • Permisos verificados: chown -R $USERNAME:users /home/$USERNAME

📁 Scripts guardados en:
  • /home/$USERNAME/dotfiles-dizzi/home/fase2-HyprInstall-full.sh

💡 El script Fase 2 instalará:
  • Hyprland + Waybar + Rofi
  • AUR helper (yay)
  • Tus dotfiles personalizados
  • Temas, fuentes e iconos
  • Aplicaciones esenciales
  • DEVTOOLS (Ollama + Git + Vim + NPM etc)

EOFFINAL

read -p "Presiona ENTER para salir..."
