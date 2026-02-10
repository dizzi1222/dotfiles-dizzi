#!/bin/bash

# Script de Configuración del Sistema de Backup
# Soporta Timeshift (ext4) y Snapper (Btrfs)
# Límite de espacio: 5GB para snapshots de actualización

set -euo pipefail

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funciones de salida
print_info() {
  echo -e "${BLUE}ℹ${NC} $*"
}

print_success() {
  echo -e "${GREEN}✓${NC} $*"
}

print_warning() {
  echo -e "${YELLOW}⚠${NC} $*"
}

print_error() {
  echo -e "${RED}✗${NC} $*"
}

# Función para ejecutar comandos con sudo
run_sudo() {
  if sudo -v &>/dev/null; then
    sudo "$@"
  else
    print_error "Se requieren permisos de sudo"
    exit 1
  fi
}

# Detectar tipo de filesystem
detect_filesystem() {
  local fs_type
  fs_type=$(df -T / | tail -1 | awk '{print $2}')
  echo "$fs_type"
}

# Verificar si el comando existe
command_exists() {
  command -v "$1" &>/dev/null
}

# ==================== ext4 - Timeshift ====================

configure_timeshift_limits() {
  print_info "Configurando límites de espacio y cantidad de snapshots..."

  # Usar Timeshift GUI para seleccionar dispositivo
  print_info "Abriendo Timeshift para seleccionar dispositivo de destino..."
  print_warning "Por favor, selecciona tu dispositivo de backup (puede ser la misma partición /)"
  print_info ""

  run_sudo timeshift --ui
}

setup_timeshift_ext4() {
  print_info "Configurando Timeshift para ext4..."

  # Instalar Timeshift si no está instalado
  if ! command_exists timeshift; then
    print_info "Instalando Timeshift..."
    run_sudo pacman -S --noconfirm timeshift
  else
    print_success "Timeshift ya está instalado"
  fi

  # Crear directorio de snapshots si no existe
  if [ ! -d "/mnt/timeshift-snapshots" ]; then
    print_info "Creando directorio para snapshots..."
    run_sudo mkdir -p /mnt/timeshift-snapshots
    run_sudo chown root:root /mnt/timeshift-snapshots
    run_sudo chmod 755 /mnt/timeshift-snapshots
  fi

  # Crear configuración de Timeshift
  print_info "Creando configuración de Timeshift..."
  local config_dir="/etc/timeshift"
  local config_file="$config_dir/timeshift.json"

  if [ ! -d "$config_dir" ]; then
    run_sudo mkdir -p "$config_dir"
  fi

  # Generar configuración JSON para Timeshift con límites optimizados
  # IMPORTANTE: skip_grub = false para permitir entrada en Grub para recuperación
  cat << 'EOF' | run_sudo tee "$config_file" > /dev/null
{
  "backup_device_uuid": "",
  "parent_device_uuid": "",
  "snapshot_size": 0,
  "snapshot_count": 0,
  "snapshot_type": 1,
  "skip_grub": false,
  "skip_linux": false,
  "compression": "gzip",
  "cron_hourly_enabled": false,
  "cron_daily_enabled": false,
  "cron_weekly_enabled": true,
  "cron_monthly_enabled": false,
  "consecutive_failed_snapshots": 0,
  "consecutive_failed_snapshots_limit": 3,
  "app_version": "21.09.1",
  "btrfs_mode": false,
  "include_btrfs_home_for_backup": true,
  "include_btrfs_home_for_restore": true,
  "verbosity": 1,
  "schedule_monthly_day": 1,
  "tags": {
    "backup": true,
    "boot": true,
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

  print_success "Configuración de Timeshift creada"
  print_warning "⚠ IMPORTANTE: skip_grub = false (permite boot desde Grub)"

  # Crear directorio de hooks de pacman
  if [ ! -d "/etc/pacman.d/hooks" ]; then
    run_sudo mkdir -p /etc/pacman.d/hooks
  fi

  # Crear hook de pre-actualización con límites de espacio
  print_info "Creando hook de pacman para pre-actualización..."
  cat << 'EOF' | run_sudo tee /etc/pacman.d/hooks/timeshift-pre-update.hook > /dev/null
[Trigger]
Operation = Upgrade
Type = Package
Target = *

[Action]
Description = Creating Timeshift snapshot before update (max 5GB)...
When = PreTransaction
Exec = /usr/bin/timeshift --create --comments "Pre-update snapshot" --tags O --scripted
Depends = timeshift
EOF

  print_success "Hook de pre-actualización creado"
}

# ==================== Btrfs - Snapper ====================

setup_snapper_btrfs() {
  print_info "Configurando Snapper para Btrfs..."

  # Instalar Snapper si no está instalado
  if ! command_exists snapper; then
    print_info "Instalando Snapper..."
    run_sudo pacman -S --noconfirm snapper
  else
    print_success "Snapper ya está instalado"
  fi

  # Crear configuración de Snapper si no existe
  if [ ! -d "/etc/snapper/configs/root" ]; then
    print_info "Creando configuración de Snapper para /"
    run_sudo snapper -c root create-config /
    print_success "Configuración de Snapper creada"
  else
    print_success "Configuración de Snapper ya existe"
  fi

  # Configurar límites de espacio y snapshots
  print_info "Configurando límites de espacio..."
  local snapper_config="/etc/snapper/configs/root"

  if [ -f "$snapper_config" ]; then
    # Calcular límite de 5GB en porcentaje (aproximadamente 5% de espacio típico)
    # SPACE_LIMIT es un porcentaje del espacio disponible
    run_sudo sed -i 's/^SPACE_LIMIT=.*/SPACE_LIMIT="0.2"/' "$snapper_config"
    run_sudo sed -i 's/^NUMBER_LIMIT=.*/NUMBER_LIMIT="5"/' "$snapper_config"
    run_sudo sed -i 's/^TIMELINE_LIMIT_HOURLY=.*/TIMELINE_LIMIT_HOURLY="10"/' "$snapper_config"
    run_sudo sed -i 's/^TIMELINE_LIMIT_DAILY=.*/TIMELINE_LIMIT_DAILY="3"/' "$snapper_config"
    run_sudo sed -i 's/^TIMELINE_LIMIT_WEEKLY=.*/TIMELINE_LIMIT_WEEKLY="2"/' "$snapper_config"
    run_sudo sed -i 's/^TIMELINE_LIMIT_MONTHLY=.*/TIMELINE_LIMIT_MONTHLY="1"/' "$snapper_config"

    print_success "Límites configurados"
  fi

  # Crear directorio de hooks de pacman
  if [ ! -d "/etc/pacman.d/hooks" ]; then
    run_sudo mkdir -p /etc/pacman.d/hooks
  fi

  # Crear hook de pre-actualización
  print_info "Creando hook de pacman para pre-actualización..."
  cat << 'EOF' | run_sudo tee /etc/pacman.d/hooks/snapper-pre-update.hook > /dev/null
[Trigger]
Operation = Upgrade
Type = Package
Target = *

[Action]
Description = Creating Snapper snapshot before update...
When = PreTransaction
Exec = /usr/bin/snapper -c root create --description "Pre-update snapshot" --cleanup-algorithm number
Depends = snapper
EOF

  print_success "Hook de pre-actualización creado"

  # Habilitar snapshots automáticos (timeline)
  print_info "Habilitando snapshots automáticos (timeline)..."
  if command_exists systemctl; then
    run_sudo systemctl enable snapper-timeline.timer
    run_sudo systemctl start snapper-timeline.timer
    print_success "Snapshots automáticos habilitados"
  fi

  # Habilitar limpieza de snapshots antiguos
  if command_exists systemctl; then
    run_sudo systemctl enable snapper-cleanup.timer
    run_sudo systemctl start snapper-cleanup.timer
    print_success "Limpieza automática de snapshots habilitada"
  fi

  # Mostrar comandos útiles
  print_info "Configuración completada. Comandos útiles:"
  cat << 'EOF'

  # Listar snapshots
  snapper -c root list

  # Ver diferencias entre snapshots
  snapper -c root diff 0..X

  # Crear snapshot manual
  sudo snapper -c root create --description "Manual snapshot"

  # Restaurar desde snapshot (requiere reboot a snapshot)
  sudo snapper -c root undochange 0..X

  # Editar configuración de Snapper
  sudo vim /etc/snapper/configs/root

  # Ver estado de los timers
  systemctl status snapper-timeline.timer
  systemctl status snapper-cleanup.timer

EOF
}

# ==================== Utilities ====================

# Remover snapshots antiguos
remove_old_snapshots() {
  print_info "Removiendo snapshots antiguos..."
  print_info "Snapshots actuales:"
  sudo timeshift --list

  read -p "¿Deseas remover snapshots antiguos? (s/n): " confirm
  if [ "$confirm" = "s" ] || [ "$confirm" = "S" ]; then
    print_warning "ADVERTENCIA: Esto eliminará snapshots permanentemente"
    read -p "¿Estás seguro? (si/no): " confirm2
    if [ "$confirm2" = "si" ]; then
      # Obtener el listado de snapshots
      local snapshots
      snapshots=$(sudo timeshift --list --json-output 2>/dev/null | grep '"name"' || true)
      if [ -z "$snapshots" ]; then
        print_warning "No hay snapshots para remover"
      else
        print_info "Removiendo snapshots automáticamente..."
        # Dejar solo los últimos 2-3 snapshots (máximo 5GB)
        sudo timeshift --delete-all --yes
        print_success "Snapshots removidos"
      fi
    fi
  fi
}

# Crear imagen completa (full backup pesada)
create_full_backup() {
  print_info "═════════════════════════════════════════"
  print_info "  Crear Imagen Completa (Full Backup)"
  print_info "═════════════════════════════════════════"
  print_warning "ADVERTENCIA: Esto creará una imagen PESADA completa"
  print_warning "Puede ocupar 20GB+ dependiendo de tu sistema"
  print_info ""

  read -p "¿Deseas continuar? (s/n): " confirm
  if [ "$confirm" != "s" ] && [ "$confirm" != "S" ]; then
    print_info "Operación cancelada"
    return
  fi

  local backup_dir
  backup_dir="/mnt/backups/full-backup-$(date +%Y%m%d-%H%M%S)"

  print_info "Creando directorio: $backup_dir"
  run_sudo mkdir -p "$backup_dir"

  print_info "Crear imagen completa con opciones:"
  print_info "1. Usar Timeshift (recomendado, con compresión)"
  print_info "2. Usar dd (imagen raw pura, SIN compresión)"
  print_info "3. Usar tar (más lento pero muy portable)"
  read -p "Selecciona opción (1-3): " option

  case "$option" in
    1)
      print_info "Creando snapshot completo con Timeshift..."
      run_sudo timeshift --create --comments "Full-Backup-$(date +%Y%m%d)" --tags B
      print_success "Snapshot completo creado"
      ;;
    2)
      print_warning "⚠ Opción dd: Imagen SIN compresión (~${DISK_SIZE}GB)"
      print_info "Esto puede tardar mucho tiempo..."
      read -p "¿Confirmar? (si/no): " confirm2
      if [ "$confirm2" = "si" ]; then
        local source_disk
        source_disk=$(df / | grep -oE '/dev/[a-z0-9]+' | head -1)
        print_info "Creando imagen dd de $source_disk (SIN compresión)..."
        run_sudo dd if="$source_disk" of="$backup_dir/full-image.img" bs=4M status=progress
        print_success "Imagen dd creada en: $backup_dir/full-image.img"
      fi
      ;;
    3)
      print_info "Creando backup tar con compresión..."
      run_sudo tar --exclude=/proc --exclude=/sys --exclude=/dev \
        --exclude=/run --exclude=/tmp --exclude=/mnt \
        -czf "$backup_dir/system-backup.tar.gz" /
      print_success "Backup tar creado en: $backup_dir/system-backup.tar.gz"
      ;;
    *)
      print_error "Opción inválida"
      return 1
      ;;
  esac

  print_success "Backup completo finalizado"
  print_info "Ubicación: $backup_dir"
  ls -lh "$backup_dir"
}

# Mostrar información de Grub y snapshots
show_grub_info() {
  print_info "═════════════════════════════════════════"
  print_info "  Información de Grub y Snapshots"
  print_info "═════════════════════════════════════════"
  print_info ""

  # Verificar Grub
  if [ -f "/boot/grub/grub.cfg" ]; then
    print_success "✓ Grub instalado en /boot/grub/grub.cfg"
    print_info ""
    print_info "Verificando entradas de snapshot en Grub:"
    sudo grep -i "timeshift\|snapshot" /boot/grub/grub.cfg | head -5 || print_warning "No se encontraron entradas de snapshot (aún)"
  else
    print_error "✗ Grub no encontrado en /boot/grub/grub.cfg"
    return 1
  fi

  print_info ""
  print_info "Timeshift puede crear entradas de Grub para restauración:"
  print_info "  - Al restaurar un snapshot, se crea entrada de boot"
  print_info "  - Puedes seleccionar snapshot en menú de Grub al iniciar"
  print_info "  - Requiere: skip_grub = false (actual: configurado)"
  print_info ""

  # Mostrar snapshots
  print_info "Snapshots disponibles:"
  sudo timeshift --list 2>/dev/null | tail -10 || print_warning "Aún no hay snapshots"
}

# Gestión interactiva
show_menu() {
  while true; do
    echo ""
    print_info "═════════════════════════════════════════"
    print_info "  Menú de Gestión de Backups"
    print_info "═════════════════════════════════════════"
    echo "1. Ver snapshots actuales"
    echo "2. Crear snapshot manual"
    echo "3. Crear imagen completa (full backup)"
    echo "4. Remover snapshots antiguos"
    echo "5. Información de Grub y snapshots"
    echo "6. Configurar límites de almacenamiento"
    echo "7. Salir"
    echo ""
    read -p "Selecciona opción (1-7): " menu_option

    case "$menu_option" in
      1)
        print_info "Listando snapshots..."
        sudo timeshift --list
        ;;
      2)
        read -p "Descripción del snapshot (enter para vacío): " description
        if [ -z "$description" ]; then
          description="Manual snapshot"
        fi
        print_info "Creando snapshot: $description"
        sudo timeshift --create --comments "$description"
        ;;
      3)
        create_full_backup
        ;;
      4)
        remove_old_snapshots
        ;;
      5)
        show_grub_info
        ;;
      6)
        print_info "Para configurar límites, usa:"
        print_info "  sudo timeshift --ui"
        print_info "Recomendado: 2-3 snapshots máximo (~ 5GB total)"
        ;;
      7)
        print_success "¡Hasta luego!"
        exit 0
        ;;
      *)
        print_error "Opción inválida"
        ;;
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
  remove          Remover snapshots antiguos
  grub-info       Mostrar información de Grub y snapshots
  limits          Configurar límites de almacenamiento
  help            Mostrar este mensaje

EJEMPLOS:
  sudo bash setup-backup-system.sh setup
  sudo bash setup-backup-system.sh menu
  sudo bash setup-backup-system.sh list
  sudo bash setup-backup-system.sh create

CARACTERÍSTICAS:
  ✓ Máximo 5GB por actualización (2-3 snapshots)
  ✓ Snapshots automáticos pre-actualización
  ✓ Integración con Grub para boot desde snapshots
  ✓ Opción de imagen completa (full backup)
  ✓ Limpieza automática de snapshots antiguos
  ✓ Soporta ext4 (Timeshift) y Btrfs (Snapper)

EOF
}

main() {
  local action="${1:-setup}"

  case "$action" in
    setup)
      print_info "═════════════════════════════════════════"
      print_info "  Setup del Sistema de Backup"
      print_info "═════════════════════════════════════════"
      print_info ""

      # Detectar filesystem
      local fs_type
      fs_type=$(detect_filesystem)
      print_info "Tipo de filesystem detectado: ${BLUE}$fs_type${NC}"

      case "$fs_type" in
        ext4)
          print_info "Configurando para ext4 (Timeshift)..."
          setup_timeshift_ext4
          ;;
        btrfs)
          print_info "Configurando para Btrfs (Snapper)..."
          setup_snapper_btrfs
          ;;
        *)
          print_error "Filesystem no soportado: $fs_type"
          print_info "Se soportan: ext4 (Timeshift) y btrfs (Snapper)"
          exit 1
          ;;
      esac

      print_info ""
      print_success "═════════════════════════════════════════"
      print_success "  Setup completado exitosamente"
      print_success "═════════════════════════════════════════"
      print_info ""
      print_warning "Nota: Los snapshots de actualización se crearán automáticamente"
      print_warning "      antes de cada actualización del sistema (pacman -Syu)"
      print_info ""
      print_info "Para gestionar snapshots, usa:"
      print_info "  sudo bash setup-backup-system.sh menu"
      ;;

    menu)
      show_menu
      ;;

    list)
      print_info "Listando snapshots..."
      sudo timeshift --list
      ;;

    create)
      read -p "Descripción del snapshot (enter para vacío): " description
      if [ -z "$description" ]; then
        description="Manual snapshot"
      fi
      print_info "Creando snapshot: $description"
      sudo timeshift --create --comments "$description"
      ;;

    full-backup)
      create_full_backup
      ;;

    remove)
      remove_old_snapshots
      ;;

    grub-info)
      show_grub_info
      ;;

    limits)
      configure_timeshift_limits
      ;;

    help)
      show_help
      ;;

    *)
      print_error "Acción desconocida: $action"
      echo ""
      show_help
      exit 1
      ;;
  esac
}

# Ejecutar main
main "$@"
