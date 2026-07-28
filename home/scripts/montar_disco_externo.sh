#!/bin/bash
# montar_disco_externo.sh
# Gestiona el disco externo USB Seagate 500GB (enclosure JMicron JMS561).
# Detecta las 3 particiones y permite montar/desmontar cualquiera de ellas.
# Soporta: NixOS y Arch/CachyOS.

# ── Colores y formato ─────────────────────────────────────────
RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
RED='\033[91m'
GREEN='\033[92m'
YELLOW='\033[93m'
BLUE='\033[94m'
MAGENTA='\033[95m'
CYAN='\033[96m'

print_header() {
  echo
  echo -e "${BOLD}${CYAN}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${CYAN}║ $1${NC}"
  echo -e "${BOLD}${CYAN}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
  echo
}
print_status()   { echo -e "${BLUE}[⚡]${NC} $1"; }
print_success()  { echo -e "${GREEN}[✓]${NC} $1"; }
print_error()    { echo -e "${RED}[✗]${NC} $1"; }
print_warning()  { echo -e "${YELLOW}[⚠]${NC} $1"; }
print_info()     { echo -e "${CYAN}[ℹ]${NC} $1"; }

# ── Detección de distribución ────────────────────────────────
IS_NIXOS=false
IS_ARCH=false
if [ -e /etc/nixos ] || command -v nixos-rebuild &>/dev/null || command -v nix-collect-garbage &>/dev/null; then
  IS_NIXOS=true
fi
if command -v pacman &>/dev/null || command -v yay &>/dev/null; then
  IS_ARCH=true
fi
if [[ "$IS_NIXOS" == false && "$IS_ARCH" == false ]]; then
  echo -e "${RED}❌ No se detectó NixOS ni Arch/CachyOS.${RESET}"
  exit 1
fi

# Label único de distro (si ambos se detectan, priorizar NixOS)
if [[ "$IS_NIXOS" == true ]]; then
  DISTRO_LABEL="NixOS"
else
  DISTRO_LABEL="Arch/CachyOS"
fi

# ── Definición de particiones (por LABEL, más robusto que sda/sdb) ──
# El disco puede aparecer como sda o sdb según el estado del bus USB.
declare -A PART_LABEL=(
  [1]="0828-67C1"
  [2]="game-Rudolf"
  [3]="ext.Fp 1"
)
declare -A PART_SIZE=(
  [1]="171.9G"
  [2]="60.5G"
  [3]="233.3G"
)
MOUNT_BASE="/media/diego"

# ── Buscar el device real de una partición por label ──────────
# Usa lsblk en modo raw (-r). OJO: los labels con espacios salen
# escapados como \x20 (ej. "ext.Fp\x201"); se decodifican con printf %b.
# Bug resuelto: la partición 1 (0828-67C1) NO tiene label — ese valor es su
# UUID. Por eso buscamos por LABEL o, si no hay match, por UUID.
find_dev_by_label() {
  local label="$1"
  local result=""
  result=$(lsblk -rno NAME,LABEL,UUID 2>/dev/null | while read -r dev lbl uuid; do
    local decoded
    decoded=$(printf '%b' "$lbl" 2>/dev/null)
    if [[ "$decoded" == "$label" || "$uuid" == "$label" ]]; then
      echo "$dev"
      break
    fi
  done)
  echo "$result"
  [[ -n "$result" ]]
}

# ── Buscar UUID de una partición por label (o por label como UUID) ──
find_uuid_by_label() {
  local label="$1"
  lsblk -rno UUID,LABEL 2>/dev/null | while read -r uuid lbl; do
    local decoded
    decoded=$(printf '%b' "$lbl" 2>/dev/null)
    if [[ "$decoded" == "$label" ]]; then
      echo "$uuid"
      return 0
    fi
  done
  # Fallback: si el propio término ES el uuid (caso 0828-67C1)
  echo "$label"
}

# ── Verificar que el disco JMicron está conectado ────────────
disk_present() {
  if lsusb 2>/dev/null | grep -qi "152d:9561"; then
    return 0
  fi
  # Fallback: detectar por las particiones aunque no salga en lsusb
  for i in 1 2 3; do
    [[ -n "$(find_dev_by_label "${PART_LABEL[$i]}")" ]] && return 0
  done
  return 1
}

# ── Montar una partición ──────────────────────────────────────
mount_part() {
  local n="$1"
  local label="${PART_LABEL[$n]}"
  local mnt="$MOUNT_BASE/$label"

  local dev=$(find_dev_by_label "$label")
  local uuid=$(find_uuid_by_label "$label")

  if [[ -z "$dev" && -z "$uuid" ]]; then
    print_error "Partición '$label' no detectada. ¿Está el disco conectado?"
    return 1
  fi

  # Si ya está montada (en cualquier punto), avisar
  if mount | grep -qE "on $mnt |on /run/media/.*/$label "; then
    print_warning "'$label' ya está montada."
    return 0
  fi

  print_status "Montando '$label' → $mnt"
  sudo mkdir -p "$mnt"

  # Preferir UUID; si no hay UUID usar el device
  local target="${uuid:-$dev}"
  if [[ -b "$target" ]] || [[ -n "$uuid" ]]; then
    if sudo mount "/dev/disk/by-uuid/$uuid" "$mnt" 2>/dev/null || sudo mount "/dev/$dev" "$mnt" 2>/dev/null; then
      print_success "'$label' montada en $mnt"
      echo
      print_info "Contenido:"
      ls -la "$mnt" 2>/dev/null | head -15
      return 0
    fi
  fi

  # Fallback: udisks2 (monta en /run/media/$USER/<label>)
  print_warning "mount directo falló — intentando udisks2..."
  if command -v udisksctl &>/dev/null; then
    if [[ -n "$dev" ]]; then
      sudo udisksctl mount -b "/dev/$dev" 2>&1
      return $?
    fi
  fi
  print_error "No se pudo montar '$label'."
  return 1
}

# ── Desmontar una partición ───────────────────────────────────
umount_part() {
  local n="$1"
  local label="${PART_LABEL[$n]}"
  local mnt="$MOUNT_BASE/$label"

  print_status "Desmontando '$label'..."
  # Buscar dónde está montada realmente
  local real_mnt=$(mount | grep -E "on ($mnt|/run/media/.*/$label) " | awk '{print $3}' | head -1)
  if [[ -n "$real_mnt" ]]; then
    sudo umount "$real_mnt" && print_success "'$label' desmontada ($real_mnt)" || print_error "No se pudo desmontar '$label'."
  else
    print_warning "'$label' no está montada."
  fi
}

# ── Mostrar estado ────────────────────────────────────────────
show_status() {
  echo -e "${BOLD}${CYAN}┌────────────────────────────────────────────────────────────────────┐${NC}"
  echo -e "${BOLD}${CYAN}│ ESTADO DEL DISCO EXTERNO (Seagate 500GB / JMicron JMS561)         │${NC}"
  echo -e "${BOLD}${CYAN}└────────────────────────────────────────────────────────────────────┘${NC}"
  echo
  for i in 1 2 3; do
    local label="${PART_LABEL[$i]}"
    local dev=$(find_dev_by_label "$label")
    local mnt=$(mount | grep -E "on ($MOUNT_BASE/$label|/run/media/.*/$label) " | awk '{print $3}' | head -1)
    printf "  ${BOLD}%s${NC}  %s  ${DIM}(%s)${NC}  " "$i)" "$label" "${PART_SIZE[$i]}"
    if [[ -z "$dev" && -z "$mnt" ]]; then
      echo -e "${RED}NO DETECTADA${NC}"
    elif [[ -n "$mnt" ]]; then
      echo -e "${GREEN}MONTADA → $mnt${NC}"
    else
      echo -e "${YELLOW}PRESENTE (no montada)${NC}"
    fi
  done
  echo
}

# ── Banner ────────────────────────────────────────────────────
clear
print_header "💾 DISCO EXTERNO — MONTAR / DESMONTAR"

if ! disk_present; then
  print_error "No se detecta el disco externo (JMicron 152d:9561)."
  print_info "Conéctalos y vuelve a ejecutar el script."
  exit 1
fi

print_info "Distro: ${GREEN}${DISTRO_LABEL}${NC}"

show_status

echo
echo -e "${CYAN}¿Qué partición quieres montar/desmontar?${NC}"
echo
echo -e "  ${BOLD}${GREEN}1.${NC} ${PART_LABEL[1]}  ${DIM}(${PART_SIZE[1]})${NC}"
echo -e "  ${BOLD}${GREEN}2.${NC} ${PART_LABEL[2]}  ${DIM}(${PART_SIZE[2]})${NC}"
echo -e "  ${BOLD}${GREEN}3.${NC} ${PART_LABEL[3]}  ${DIM}(${PART_SIZE[3]})${NC}"
echo -e "  ${BOLD}${GREEN}4.${NC} ${MAGENTA}Todas${NC}"
echo -e "  ${BOLD}${RED}9.${NC} Desmontar (elegir cuál)"
echo -e "  ${BOLD}${RED}0.${NC} Salir"
echo
read -rp "Selecciona opción: " choice

case "$choice" in
  1|2|3)
    mount_part "$choice"
    ;;
  4)
    for i in 1 2 3; do
      mount_part "$i" || true
    done
    ;;
  9)
    echo
    echo -e "${CYAN}¿Cuál quieres desmontar?${NC}"
    echo
    for i in 1 2 3; do
      echo -e "  ${BOLD}${GREEN}$i.${NC} ${PART_LABEL[$i]}"
    done
    read -rp "Opción: " u
    case "$u" in
      1|2|3) umount_part "$u" ;;
      *) print_warning "Opción inválida." ;;
    esac
    ;;
  0|"")
    print_info "Saliendo."
    exit 0
    ;;
  *)
    print_error "Opción inválida."
    exit 1
    ;;
esac

echo
show_status
