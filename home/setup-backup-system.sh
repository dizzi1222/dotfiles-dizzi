#!/bin/bash

# Script de Configuración del Sistema de Backup
# Soporta Timeshift (ext4) y Snapper (Btrfs)
# Límite de espacio: ~6-8GB (max 2 snapshots simultáneos)

set -euo pipefail

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info()    { echo -e "${BLUE}ℹ${NC} $*"; }
print_success() { echo -e "${GREEN}✓${NC} $*"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $*"; }
print_error()   { echo -e "${RED}✗${NC} $*"; }

run_sudo() {
  if sudo -v &>/dev/null; then
    sudo "$@"
  else
    print_error "Se requieren permisos de sudo"
    exit 1
  fi
}

detect_filesystem() {
  df -T / | tail -1 | awk '{print $2}'
}

command_exists() {
  command -v "$1" &>/dev/null
}

# ==================== ext4 - Timeshift ====================

configure_timeshift_limits() {
  print_info "Configurando límites reales (por cantidad de snapshots)..."
  print_warning "Timeshift NO limita por GB directamente, solo por cantidad."
  print_info "  2 snapshots × ~3-4GB c/u = ~6-8GB máximo real"

  local config_file="/etc/timeshift/timeshift.json"

  if [[ ! -f "$config_file" ]]; then
    print_error "timeshift.json no encontrado. Ejecuta primero: setup"
    return 1
  fi

  # FIX #1: Usar python3 para editar JSON correctamente
  # snapshot_count=2 es el límite REAL que respeta Timeshift
  run_sudo python3 -c "
import json
with open('$config_file', 'r') as f:
    cfg = json.load(f)
cfg['snapshot_count']       = 2      # Máximo 2 snapshots simultáneos
cfg['cron_weekly_enabled']  = False  # Sin cron extra (solo hook pacman)
cfg['cron_daily_enabled']   = False
cfg['cron_monthly_enabled'] = False
cfg['skip_grub']            = False  # Mantener integración GRUB
with open('$config_file', 'w') as f:
    json.dump(cfg, f, indent=2)
print('Config actualizada: snapshot_count=2')
"
  print_success "Límite aplicado: máximo 2 snapshots (~6-8GB total)"
  print_info "Para ajustar visualmente: sudo timeshift --ui → Settings → Snapshot Retention"
}

setup_timeshift_ext4() {
  print_info "Configurando Timeshift para ext4..."

  if ! command_exists timeshift; then
    print_info "Instalando Timeshift..."
    run_sudo pacman -S --noconfirm timeshift
  else
    print_success "Timeshift ya está instalado"
  fi

  if [ ! -d "/mnt/timeshift-snapshots" ]; then
    run_sudo mkdir -p /mnt/timeshift-snapshots
    run_sudo chown root:root /mnt/timeshift-snapshots
    run_sudo chmod 755 /mnt/timeshift-snapshots
  fi

  local config_dir="/etc/timeshift"
  local config_file="$config_dir/timeshift.json"

  [ ! -d "$config_dir" ] && run_sudo mkdir -p "$config_dir"

  # FIX #1 APLICADO: snapshot_count=2 (antes era 0 = sin límite)
  # snapshot_size=0 es correcto (Timeshift no lo usa para limitar)
  # El límite real está en snapshot_count
  cat << 'EOF' | run_sudo tee "$config_file" > /dev/null
{
  "backup_device_uuid": "",
  "parent_device_uuid": "",
  "snapshot_size": 0,
  "snapshot_count": 2,
  "snapshot_type": 1,
  "skip_grub": false,
  "skip_linux": false,
  "compression": "gzip",
  "cron_hourly_enabled": false,
  "cron_daily_enabled": false,
  "cron_weekly_enabled": false,
  "cron_monthly_enabled": false,
  "consecutive_failed_snapshots": 0,
  "consecutive_failed_snapshots_limit": 3,
  "app_version": "21.09.1",
  "btrfs_mode": false,
  "include_btrfs_home_for_backup": false,
  "include_btrfs_home_for_restore": false,
  "verbosity": 1,
  "schedule_monthly_day": 1,
  "tags": {
    "backup": true,
    "boot": false,
    "update": true
  },
  "exclude": [
    "/home",
    "/root",
    "/tmp",
    "/proc",
    "/sys",
    "/dev",
    "/run",
    "/var/run",
    "/var/cache",
    "/var/tmp",
    "/lost+found"
  ],
  "exclude_apps": []
}
EOF

  print_success "timeshift.json creado (snapshot_count=2, cron=off)"
  print_warning "⚠ IMPORTANTE: Selecciona el dispositivo de destino con: sudo timeshift --ui"

  [ ! -d "/etc/pacman.d/hooks" ] && run_sudo mkdir -p /etc/pacman.d/hooks

  # FIX #2 APLICADO: eliminado --tags O (argumento inválido en Timeshift)
  # --scripted es suficiente para ejecución no interactiva
  print_info "Creando hook de pacman para pre-actualización..."
  cat << 'EOF' | run_sudo tee /etc/pacman.d/hooks/timeshift-pre-update.hook > /dev/null
[Trigger]
Operation = Upgrade
Type = Package
Target = *

[Action]
Description = Timeshift: creando snapshot pre-actualización...
When = PreTransaction
Exec = /usr/bin/timeshift --create --comments "Pre-update snapshot" --scripted
Depends = timeshift
EOF

  print_success "Hook creado: /etc/pacman.d/hooks/timeshift-pre-update.hook"
  print_info "Se ejecutará automáticamente antes de cada pacman -Syu"
}

# ==================== Btrfs - Snapper ====================

setup_snapper_btrfs() {
  print_info "Configurando Snapper para Btrfs..."

  if ! command_exists snapper; then
    run_sudo pacman -S --noconfirm snapper
  else
    print_success "Snapper ya está instalado"
  fi

  if [ ! -d "/etc/snapper/configs/root" ]; then
    run_sudo snapper -c root create-config /
    print_success "Configuración de Snapper creada"
  else
    print_success "Configuración de Snapper ya existe"
  fi

  local snapper_config="/etc/snapper/configs/root"

  if [ -f "$snapper_config" ]; then
    run_sudo sed -i 's/^SPACE_LIMIT=.*/SPACE_LIMIT="0.2"/'         "$snapper_config"
    run_sudo sed -i 's/^NUMBER_LIMIT=.*/NUMBER_LIMIT="5"/'          "$snapper_config"
    run_sudo sed -i 's/^TIMELINE_LIMIT_HOURLY=.*/TIMELINE_LIMIT_HOURLY="10"/' "$snapper_config"
    run_sudo sed -i 's/^TIMELINE_LIMIT_DAILY=.*/TIMELINE_LIMIT_DAILY="3"/'   "$snapper_config"
    run_sudo sed -i 's/^TIMELINE_LIMIT_WEEKLY=.*/TIMELINE_LIMIT_WEEKLY="2"/' "$snapper_config"
    run_sudo sed -i 's/^TIMELINE_LIMIT_MONTHLY=.*/TIMELINE_LIMIT_MONTHLY="1"/' "$snapper_config"
    print_success "Límites configurados"
  fi

  [ ! -d "/etc/pacman.d/hooks" ] && run_sudo mkdir -p /etc/pacman.d/hooks

  cat << 'EOF' | run_sudo tee /etc/pacman.d/hooks/snapper-pre-update.hook > /dev/null
[Trigger]
Operation = Upgrade
Type = Package
Target = *

[Action]
Description = Snapper: creando snapshot pre-actualización...
When = PreTransaction
Exec = /usr/bin/snapper -c root create --description "Pre-update snapshot" --cleanup-algorithm number
Depends = snapper
EOF

  print_success "Hook Snapper creado"

  if command_exists systemctl; then
    run_sudo systemctl enable --now snapper-timeline.timer
    run_sudo systemctl enable --now snapper-cleanup.timer
    print_success "Timers de Snapper habilitados"
  fi
}

# ==================== Utilities ====================

# FIX #3 APLICADO: remove_old_snapshots reescrita completamente
# --json-output NO existe en timeshift; ahora parsea la salida real de --list
remove_old_snapshots() {
  print_info "Snapshots actuales:"
  sudo timeshift --list
  echo

  print_warning "Esto eliminará TODOS los snapshots excepto el más reciente"
  read -p "¿Continuar? [s/N]: " confirm
  [[ ! "$confirm" =~ ^[Ss]$ ]] && return

  # Parsear nombres reales del formato de timeshift --list
  # Formato de salida: "  1)  2025-02-09_22:39:45  ..."
  local snapshots
  snapshots=$(sudo timeshift --list 2>/dev/null \
    | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}:[0-9]{2}:[0-9]{2}')

  if [[ -z "$snapshots" ]]; then
    print_warning "No hay snapshots para remover"
    return
  fi

  local total
  total=$(echo "$snapshots" | wc -l)

  if [[ $total -le 1 ]]; then
    print_warning "Solo hay 1 snapshot, no se elimina nada"
    return
  fi

  local count=0
  while IFS= read -r snap; do
    count=$((count + 1))
    if [[ $count -lt $total ]]; then
      print_info "Eliminando: $snap"
      sudo timeshift --delete --snapshot "$snap" --scripted
      print_success "Eliminado: $snap"
    else
      print_success "Conservado (más reciente): $snap"
    fi
  done <<< "$snapshots"

  echo
  print_success "Limpieza completada. Snapshots restantes:"
  sudo timeshift --list
}

create_full_backup() {
  print_warning "Esto creará una imagen PESADA completa (puede ocupar 20GB+)"
  read -p "¿Continuar? (s/n): " confirm
  [[ "$confirm" != "s" && "$confirm" != "S" ]] && return

  local backup_dir="/mnt/backups/full-backup-$(date +%Y%m%d-%H%M%S)"
  run_sudo mkdir -p "$backup_dir"

  echo "1. Timeshift (recomendado, compresión automática)"
  echo "2. dd (imagen raw, SIN compresión — muy pesada)"
  echo "3. tar (portable, compresión gzip)"
  read -p "Selecciona opción (1-3): " option

  case "$option" in
    1)
      run_sudo timeshift --create --comments "Full-Backup-$(date +%Y%m%d)" --scripted
      print_success "Snapshot completo creado"
      ;;
    2)
      read -p "¿Confirmar imagen dd? (si/no): " confirm2
      if [ "$confirm2" = "si" ]; then
        local source_disk
        source_disk=$(df / | grep -oE '/dev/[a-z0-9]+' | head -1)
        run_sudo dd if="$source_disk" of="$backup_dir/full-image.img" bs=4M status=progress
        print_success "Imagen dd: $backup_dir/full-image.img"
      fi
      ;;
    3)
      run_sudo tar --exclude=/proc --exclude=/sys --exclude=/dev \
        --exclude=/run --exclude=/tmp --exclude=/mnt \
        -czf "$backup_dir/system-backup.tar.gz" /
      print_success "Backup tar: $backup_dir/system-backup.tar.gz"
      ;;
    *)
      print_error "Opción inválida"
      return 1
      ;;
  esac

  print_info "Ubicación: $backup_dir"
  ls -lh "$backup_dir"
}

show_grub_info() {
  print_info "═════════════════════════════════════════"
  print_info "  Información de Grub y Snapshots"
  print_info "═════════════════════════════════════════"

  if [ -f "/boot/grub/grub.cfg" ]; then
    print_success "Grub instalado en /boot/grub/grub.cfg"
    print_info "Entradas de snapshot en Grub:"
    sudo grep -i "timeshift\|snapshot" /boot/grub/grub.cfg | head -5 \
      || print_warning "No hay entradas de snapshot aún (normal en primera instalación)"
  else
    print_error "Grub no encontrado en /boot/grub/grub.cfg"
    return 1
  fi

  print_info ""
  print_info "Snapshots disponibles:"
  sudo timeshift --list 2>/dev/null | tail -10 || print_warning "Aún no hay snapshots"
}

show_menu() {
  while true; do
    echo ""
    print_info "═════════════════════════════════════════"
    print_info "  Menú de Gestión de Backups"
    print_info "═════════════════════════════════════════"
    echo "1. Ver snapshots actuales"
    echo "2. Crear snapshot manual"
    echo "3. Crear imagen completa (full backup)"
    echo "4. Remover snapshots antiguos (conserva el más reciente)"
    echo "5. Información de Grub y snapshots"
    echo "6. Configurar límites de almacenamiento"
    echo "7. Salir"
    echo ""
    read -p "Selecciona opción (1-7): " menu_option

    case "$menu_option" in
      1) sudo timeshift --list ;;
      2)
        read -p "Descripción (enter = 'Manual snapshot'): " description
        [[ -z "$description" ]] && description="Manual snapshot"
        sudo timeshift --create --comments "$description" --scripted
        ;;
      3) create_full_backup ;;
      4) remove_old_snapshots ;;
      5) show_grub_info ;;
      6) configure_timeshift_limits ;;
      7) print_success "¡Hasta luego!"; exit 0 ;;
      *) print_error "Opción inválida" ;;
    esac
  done
}

# ==================== Main ====================

show_help() {
  cat << 'EOF'
╔════════════════════════════════════════════════════════════════════╗
║     Script de Gestión de Backup del Sistema (Timeshift/Snapper)   ║
╚════════════════════════════════════════════════════════════════════╝

USO:
  sudo bash setup-backup-system.sh [OPCIÓN]

OPCIONES:
  setup           Configurar el sistema de backup (inicial)
  menu            Abrir menú interactivo de gestión
  list            Listar snapshots actuales
  create          Crear snapshot manual
  full-backup     Crear imagen completa (full backup)
  remove          Remover snapshots antiguos (conserva el más reciente)
  grub-info       Mostrar información de Grub y snapshots
  limits          Configurar límites (máx 2 snapshots ~ 6-8GB)
  help            Mostrar este mensaje

CARACTERÍSTICAS:
  ✓ snapshot_count=2 (límite REAL de Timeshift, ~6-8GB)
  ✓ Hook pacman corregido (sin --tags O inválido)
  ✓ Remove snapshots funcional (parsea --list correctamente)
  ✓ Snapshots automáticos pre-actualización (pacman -Syu)
  ✓ Integración con Grub para boot desde snapshots
  ✓ Soporta ext4 (Timeshift) y Btrfs (Snapper)

FIXES APLICADOS vs versión anterior:
  FIX #1  snapshot_count=2 en JSON (antes 0 = sin límite)
  FIX #2  Hook sin --tags O (argumento inexistente en Timeshift)
  FIX #3  remove_old_snapshots sin --json-output (no existe en Timeshift)

EOF
}

main() {
  local action="${1:-setup}"

  case "$action" in
    setup)
      print_info "═════════════════════════════════════════"
      print_info "  Setup del Sistema de Backup"
      print_info "═════════════════════════════════════════"

      local fs_type
      fs_type=$(detect_filesystem)
      print_info "Filesystem detectado: ${BLUE}$fs_type${NC}"

      case "$fs_type" in
        ext4)  setup_timeshift_ext4  ;;
        btrfs) setup_snapper_btrfs   ;;
        *)
          print_error "Filesystem no soportado: $fs_type"
          print_info "Se soportan: ext4 (Timeshift) y btrfs (Snapper)"
          exit 1
          ;;
      esac

      echo
      print_success "Setup completado"
      print_warning "Paso obligatorio: sudo timeshift --ui → selecciona dispositivo destino"
      print_info "Gestión: sudo bash setup-backup-system.sh menu"
      ;;

    menu)        show_menu ;;
    list)        sudo timeshift --list ;;
    create)
      read -p "Descripción (enter = 'Manual snapshot'): " description
      [[ -z "$description" ]] && description="Manual snapshot"
      sudo timeshift --create --comments "$description" --scripted
      ;;
    full-backup) create_full_backup ;;
    remove)      remove_old_snapshots ;;
    grub-info)   show_grub_info ;;
    limits)      configure_timeshift_limits ;;
    help)        show_help ;;
    *)
      print_error "Acción desconocida: $action"
      show_help
      exit 1
      ;;
  esac
}

main "$@"
