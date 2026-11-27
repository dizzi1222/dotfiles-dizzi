#!/bin/bash

# --- COLORES ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# --- FUNCIONES ---
print_step() { echo -e "${BLUE}>>> $1${NC}"; }
print_ok()   { echo -e "${GREEN}✓ $1${NC}"; }
print_warn() { echo -e "${YELLOW}⚠ $1${NC}"; }
print_err()  { echo -e "${RED}✗ $1${NC}"; }

# --- ROOT CHECK ---
if [[ $EUID -ne 0 ]]; then
  print_err "Ejecutar con sudo: sudo bash $0"
  exit 1
fi

REAL_USER="${SUDO_USER:-$(ls /home | head -n1)}"
HOME_DIR="/home/$REAL_USER"

print_step "Instalando btrfs-progs (~7 MB)..."
pacman -Sy --needed --noconfirm btrfs-progs
print_ok "btrfs-progs listo"

# Detectar partición Kimtigo (SATA, 128 GB, GPT, tipo Btrfs)
KIMTIGO_DEV=$(lsblk -dpno NAME,TYPE,SIZE,MODEL,FSTYPE | awk '$3 ~ /119/ && $5 == "btrfs" {print $1; exit}')
if [[ -z "$KIMTIGO_DEV" ]]; then
  print_warn "No se detectó auto; usando /dev/sdb1 (ajusta si difiere)"
  KIMTIGO_DEV="/dev/sdb1"
fi
print_ok "Dispositivo: $KIMTIGO_DEV"

MOUNT_POINT="/mnt/kimtigo"
print_step "Creando punto de montaje: $MOUNT_POINT"
mkdir -p "$MOUNT_POINT"

print_step "Montando $KIMTIGO_DEV → $MOUNT_POINT"
if mount -t btrfs -o noatime,compress=zstd "$KIMTIGO_DEV" "$MOUNT_POINT"; then
  print_ok "Montado OK"
else
  print_err "Fallo al montar; revisa 'dmesg -T | tail'"
  exit 1
fi

print_step "Añadiendo a /etc/fstab (persistente)"
FSTAB_LINE="$KIMTIGO_DEV $MOUNT_POINT btrfs defaults,noatime,compress=zstd 0 0"
if ! grep -qs "$KIMTIGO_DEV" /etc/fstab; then
  echo "$FSTAB_LINE" >> /etc/fstab
  print_ok "fstab actualizado"
else
  print_warn "Ya existe en fstab; saltando"
fi

# Permisos para tu usuario
chown -R "$REAL_USER:$(id -gn $REAL_USER)" "$MOUNT_POINT"
print_ok "Permisos ajustados a $REAL_USER"

echo ""
echo -e "${GREEN}=== LISTO ===${NC}"
echo "Desde Windows: \\\\wsl\$\\Arch\\mnt\\kimtigo"
echo "O mapea letra (PowerShell admin):"
echo "  net use K: \\\\wsl\$\\Arch\\mnt\\kimtigo /persistent:yes"