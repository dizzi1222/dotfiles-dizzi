#!/bin/bash
# instalar_juego.sh
# Instala juegos desde el disco externo (ISOs) en la botella de Bottles.
# El juego (los GB pesados) se instala EN EL DISCO EXTERNO para no llenar
# el SSD interno; solo el prefix de Wine (1-2GB) vive en el disco interno.
#
# Recomendación de partición con IA:
#   - Estima el tamaño instalado a partir del ISO.
#   - Consulta a OpenRouter con un modelo nemotron :free para recomendar
#     la mejor partición y optimización de espacio.
#   - Si no hay API key / red, cae a una heurística local (más espacio libre).
#
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

if [[ "$IS_NIXOS" == true ]]; then
  DISTRO_LABEL="NixOS"
else
  DISTRO_LABEL="Arch/CachyOS"
fi

# ── Configuración ────────────────────────────────────────────
# Botella de Bottles donde se instalan los juegos
BOTTLE_NAME="gaming"
# Partición del disco externo que contiene las ISOs
SRC_LABEL="game-Rudolf"
# Carpeta raíz donde buscar ISOs dentro de la partición
SRC_MOUNT="/media/diego/$SRC_LABEL"
# Particiones candidatas a instalar juegos (excluye la de ISOs)
# Particiones candidatas a instalar juegos (label|mount_root|destino)
CANDIDATES=(
  "0828-67C1|/media/diego/0828-67C1|/media/diego/0828-67C1/Juegos"
  "ext.Fp 1|/media/diego/ext.Fp 1|/media/diego/ext.Fp 1/Juegos"
  "game-Rudolf|/media/diego/game-Rudolf|/media/diego/game-Rudolf/Juegos"
)
# Modelo de OpenRouter gratis para la recomendación (fallback a heurística)
OPENROUTER_MODEL="${OPENROUTER_MODEL:-nvidia/nemotron-3-nano-30b-a3b:free}"
# Margen de seguridad sobre el tamaño estimado
SAFETY_MARGIN=1.25

# ── Cargar API key (OpenRouter) sin exponerla ────────────────
OPEN_ROUTER_API_KEY=""
if [[ -f ~/.api-keys.sh ]]; then
  # shellcheck disable=SC1090
  source ~/.api-keys.sh 2>/dev/null
fi

# ── Buscar el device real de una partición por label ──────────
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

# ── Montar una partición por label ────────────────────────────
mount_partition() {
  local label="$1"
  local mnt="$2"
  local dev=$(find_dev_by_label "$label")

  if mount | grep -qE "on $mnt "; then
    return 0
  fi
  if [[ -z "$dev" ]]; then
    print_error "Partición '$label' no detectada. ¿Está el disco conectado?"
    return 1
  fi
  sudo mkdir -p "$mnt"
  if sudo mount "/dev/$dev" "$mnt" 2>/dev/null; then
    print_success "'$label' montada en $mnt"
  else
    print_error "No se pudo montar '$label' en $mnt"
    return 1
  fi
}

# ── Formatear tamaño humano a GB numérico ────────────────────
human_to_gb() {
  local h="$1"
  if [[ "$h" =~ ^([0-9]+)([KMG]?)$ ]]; then
    local num="${BASH_REMATCH[1]}" unit="${BASH_REMATCH[2]}"
    case "$unit" in
      K) echo "scale=2; $num/1048576" | bc ;;
      M) echo "scale=2; $num/1024" | bc ;;
      G) echo "scale=2; $num" | bc ;;
      "") echo "scale=2; $num/1073741824" | bc ;;
    esac
  else
    echo "0"
  fi
}

# ── Obtener espacio libre (GB) de una partición ──────────────
# Usa el punto de montaje raíz (el label) porque la subcarpeta destino
# (/Juegos) puede no existir aún y df fallaría con "No such file".
free_gb() {
  local mnt="$1"
  df -BG "$mnt" 2>/dev/null | awk 'NR==2 {gsub(/G/,"",$4); print $4}'
}

# ── Estimación de tamaño instalado a partir del ISO ──────────
# Los repacks (elamigos, etc) suelen expandir a ~1.2-1.5x el ISO.
estimate_install_size_gb() {
  local iso_bytes="$1"
  local iso_gb
  iso_gb=$(awk -v b="$iso_bytes" 'BEGIN {printf "%.1f", b/1073741824}')
  awk -v g="$iso_gb" 'BEGIN {printf "%.1f", g*1.4}'
}

# ── Recomendación heurística local (fallback) ───────────────
recommend_local() {
  local needed="$1"
  shift
  local best_label="" best_free="-1"
  local entry label mnt free
  for entry in "$@"; do
    label="${entry%%|*}"
    mnt=$(echo "$entry" | cut -d'|' -f2)
    free=$(free_gb "$mnt")
    if [[ -z "$free" ]] || ! [[ "$free" =~ ^[0-9]+$ ]]; then continue; fi
    if awk -v f="$free" -v n="$needed" 'BEGIN {exit !(f >= n)}' && \
       awk -v f="$free" -v b="$best_free" 'BEGIN {exit !(f > b)}'; then
      best_free="$free"
      best_label="$label"
    fi
  done
  echo "$best_label"
}

# ── Recomendación con IA (OpenRouter nemotron free) ─────────
# Devuelve: "label|ruta|razón"  (o "heuristic|...")
recommend_with_ai() {
  local needed="$1" iso_name="$2"
  shift 2
  if [[ -z "$OPEN_ROUTER_API_KEY" ]]; then
    echo "NO_LLM"
    return
  fi

  # Construir lista de particiones con espacio real
  local parts=""
  local label mnt entry free
  for entry in "$@"; do
    label="${entry%%|*}"
    mnt=$(echo "$entry" | cut -d'|' -f2)
    free=$(free_gb "$mnt")
    [[ -z "$free" ]] && free="0"
    parts+="${label}: ${free}GB libres (montada en ${mnt})\n"
  done

  local prompt
  prompt="Soy un script bash que instala juegos de Windows (vía Wine/Bottles) en un disco externo con 3 particiones exfat. El juego a instalar es '${iso_name}', que ocupa aproximadamente ${needed}GB instalado. Espacio libre actual:\n${parts}\nElige la mejor partición para optimizar el espacio disponible a largo plazo (la que tenga más margen) y termina tu respuesta con UNA línea exactamente así: FINAL: <label de la partición>. No uses comillas."

  local resp
  resp=$(curl -s --max-time 30 \
    -H "Authorization: Bearer $OPEN_ROUTER_API_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"model\":\"$OPENROUTER_MODEL\",\"temperature\":0.2,\"messages\":[{\"role\":\"user\",\"content\":\"$prompt\"}],\"max_tokens\":400}" \
    https://openrouter.ai/api/v1/chat/completions 2>/dev/null)

  local content
  content=$(echo "$resp" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    print(d['choices'][0]['message']['content'])
except Exception:
    print('')
" 2>/dev/null)

  if [[ -z "$content" ]]; then
    echo "NO_LLM"
    return
  fi

  # 1) Buscar la línea FINAL: <label> explícita
  local final_line
  final_line=$(echo "$content" | grep -oE "FINAL:[[:space:]]*[A-Za-z0-9 _.-]+" | tail -1)
  if [[ -n "$final_line" ]]; then
    local final_candidate
    final_candidate=$(echo "$final_line" | sed 's/FINAL:[[:space:]]*//')
    local entry label
    for entry in "$@"; do
      label="${entry%%|*}"
      if [[ "$final_candidate" == *"$label"* ]]; then
        echo "$label"
        return
      fi
    done
  fi

  # 2) Fallback: última mención de cualquier label en el contenido
  local last_match=""
  local entry label
  for entry in "$@"; do
    label="${entry%%|*}"
    if echo "$content" | grep -q "$label"; then
      last_match="$label"
    fi
  done
  if [[ -n "$last_match" ]]; then
    echo "$last_match"
    return
  fi

  echo "NO_LLM"
}

# ── Elegir destino con IA + fallback heurístico ──────────────
choose_destination() {
  local iso_bytes="$1" iso_name="$2"
  local needed
  needed=$(estimate_install_size_gb "$iso_bytes")

  echo
  print_header "📦 RECOMENDACIÓN DE PARTICIPÓN (espacio)"
  print_info "Aprox. tamaño instalado estimado: ${BOLD}${needed}GB${NC} (margen ${SAFETY_MARGIN}x)"

  # Candidatas: label|mount_root|destino
  local candidates=()
  local entry label mnt dest
  for entry in "${CANDIDATES[@]}"; do
    candidates+=("$entry")
  done

  echo
  echo -e "  ${DIM}Espacio libre por partición:${NC}"
  local free
  for entry in "${candidates[@]}"; do
    label="${entry%%|*}"
    mnt=$(echo "$entry" | cut -d'|' -f2)
    free=$(free_gb "$mnt")
    printf "    ${BOLD}%s${NC}: ${free:-0}G libres${NC}\n" "$label"
  done

  # Necesidad con margen
  local needed_margin
  needed_margin=$(awk -v n="$needed" -v m="$SAFETY_MARGIN" 'BEGIN {printf "%.1f", n*m}')

  echo
  print_status "Consultando IA (${OPENROUTER_MODEL}) para recomendar partición..."
  local picked
  picked=$(recommend_with_ai "$needed_margin" "$iso_name" "${candidates[@]}")
  echo -e "  ${DIM}Respuesta IA: ${picked:-sin respuesta}${NC}"

  # Validar que la partición elegida por IA realmente tenga espacio
  if [[ -n "$picked" ]] && [[ "$picked" != "NO_LLM" ]]; then
    local picked_mnt picked_free
    for entry in "${candidates[@]}"; do
      if [[ "${entry%%|*}" == "$picked" ]]; then
        picked_mnt=$(echo "$entry" | cut -d'|' -f2)
        break
      fi
    done
    picked_free=$(free_gb "$picked_mnt")
    if ! awk -v f="${picked_free:-0}" -v n="$needed_margin" 'BEGIN {exit !(f >= n)}'; then
      print_warning "IA eligió '$picked' (${picked_free:-0}G) pero NO alcanza para ${needed_margin}GB — usando heurística."
      picked=""
    fi
  fi

  if [[ -z "$picked" ]] || [[ "$picked" == "NO_LLM" ]]; then
    print_warning "IA no disponible o inválida — usando heurística local (partición con más espacio que alcance)."
    picked=$(recommend_local "$needed_margin" "${candidates[@]}")
  fi

  if [[ -z "$picked" ]]; then
    print_error "Ninguna partición tiene suficientes GB para ${needed_margin}GB."
    print_info "El juego NO se puede instalar en el disco externo sin liberar espacio."
    return 1
  fi

  local dest_dir=""
  for entry in "${candidates[@]}"; do
    if [[ "${entry%%|*}" == "$picked" ]]; then
      dest_dir=$(echo "$entry" | cut -d'|' -f3)
      break
    fi
  done
  echo
  print_success "Partición recomendada: ${BOLD}${CYAN}${picked}${NC}"
  echo -e "  Destino sugerido: ${BOLD}${GREEN}${dest_dir}/$(basename "$iso_name" .iso)${NC}"
  echo
  DEST_PICKED="$picked"
  DEST_DIR="$dest_dir"
}

# ── Banner ────────────────────────────────────────────────────
clear
print_header "🎮 INSTALAR JUEGO (Bottles) DESDE DISCO EXTERNO"

print_info "Distro: ${GREEN}${DISTRO_LABEL}${NC}"

# ── Verificar Bottles ────────────────────────────────────────
if ! flatpak list --app 2>/dev/null | grep -qi "com.usebottles.bottles"; then
  print_error "Bottles no está instalado."
  exit 1
fi
print_success "Bottles detectado (botella: ${BOLD}${BOTTLE_NAME}${NC})"

# ── Asegurar acceso de Bottles (flatpak sandbox) al disco y a /mnt ──
flatpak override --user --filesystem=/media/diego com.usebottles.bottles 2>/dev/null
flatpak override --user --filesystem=/mnt com.usebottles.bottles 2>/dev/null

# ── Verificar disco y montar partición de ISOs ───────────────
echo
print_status "Verificando disco externo..."
mount_partition "$SRC_LABEL" "$SRC_MOUNT" || exit 1

# ── Listar ISOs disponibles ──────────────────────────────────
echo
print_header "ISOs disponibles en $SRC_MOUNT"

mapfile -t ISOS < <(find "$SRC_MOUNT" -maxdepth 2 -iname "*.iso" 2>/dev/null | sort)
if [[ ${#ISOS[@]} -eq 0 ]]; then
  print_error "No se encontraron ISOs en $SRC_MOUNT"
  exit 1
fi

for i in "${!ISOS[@]}"; do
  name=$(basename "${ISOS[$i]}")
  size=$(du -h "${ISOS[$i]}" 2>/dev/null | awk '{print $1}')
  printf "  ${BOLD}${GREEN}%d.${NC} ${CYAN}%s${NC}  ${DIM}(%s)${NC}\n" "$((i+1))" "$name" "$size"
done

echo
read -rp "Selecciona el número de la ISO: " iso_choice

if [[ ! "$iso_choice" =~ ^[0-9]+$ ]] || [[ "$iso_choice" -lt 1 ]] || [[ "$iso_choice" -gt ${#ISOS[@]} ]]; then
  print_error "Opción inválida."
  exit 1
fi

ISO_PATH="${ISOS[$((iso_choice-1))]}"
ISO_NAME=$(basename "$ISO_PATH")
echo
print_status "ISO seleccionada: ${CYAN}$ISO_NAME${NC}"

# ── Recomendar partición de instalación (IA + heurística) ───
ISO_BYTES=$(stat -c%s "$ISO_PATH" 2>/dev/null)
if ! choose_destination "$ISO_BYTES" "$ISO_NAME"; then
  exit 1
fi

# ── Montar la ISO ────────────────────────────────────────────
ISO_MNT="/mnt/iso-${iso_choice}"

# Si quedó un montaje residual de una corrida anterior en la misma ruta
# (ej. la sesión se cortó), desmontarlo antes de intentar montar de nuevo.
if mount | grep -q " on $ISO_MNT "; then
  print_warning "Montaje previo en $ISO_MNT — desmontándolo..."
  sudo umount -l "$ISO_MNT" 2>/dev/null
  sudo losetup -d /dev/loop* 2>/dev/null
  print_success "Residuo eliminado."
fi

print_status "Montando ISO (solo lectura)..."
sudo mkdir -p "$ISO_MNT"
if ! sudo mount -o loop "$ISO_PATH" "$ISO_MNT" 2>/dev/null; then
  # Reintentar una vez con montaje directo del device loop
  print_warning "Reintentando con loop device explícito..."
  if ! sudo mount -o loop,ro "$ISO_PATH" "$ISO_MNT" 2>/dev/null; then
    print_error "No se pudo montar la ISO (¿falló el bus USB?). Reintenta."
    exit 1
  fi
fi
print_success "ISO montada en $ISO_MNT"

# ── Encontrar el setup.exe ───────────────────────────────────
SETUP_EXE=$(find "$ISO_MNT" -maxdepth 2 -iname "setup*.exe" 2>/dev/null | head -1)
if [[ -z "$SETUP_EXE" ]]; then
  SETUP_EXE=$(find "$ISO_MNT" -maxdepth 2 -iname "*.exe" 2>/dev/null | head -1)
fi

if [[ -z "$SETUP_EXE" ]]; then
  print_error "No se encontró setup.exe en la ISO."
  print_info "Contenido de la ISO:"
  ls -la "$ISO_MNT" 2>/dev/null | head -20
  sudo umount "$ISO_MNT" 2>/dev/null
  exit 1
fi
print_success "Instalador encontrado: ${CYAN}$SETUP_EXE${NC}"

# ── Aviso de espacio ─────────────────────────────────────────
echo
print_warning "El juego se instalará en el DISCO EXTERNO (no en el SSD)."
print_info "Cuando el instalador pregunte la ruta, usa:"
echo
echo -e "  ${BOLD}${GREEN}${DEST_DIR}/<nombre-juego>${NC}"
echo
echo -e "  Ejemplo: ${DIM}${DEST_DIR}/Blasphemous${NC}"
echo
print_info "Solo el prefix de Wine (~1-2GB) queda en el disco interno."

read -rp "Presiona Enter para abrir el instalador en Bottles..."

# ── Lanzar instalador en Bottles ─────────────────────────────
echo
print_status "Lanzando '$SETUP_EXE' en la botella '${BOTTLE_NAME}'..."
print_info "CIERRA la ventana del instalador cuando termines."

flatpak run --command=bottles-cli com.usebottles.bottles run \
  -b "$BOTTLE_NAME" -e "$SETUP_EXE"

echo
print_status "Desmontando ISO..."
sudo umount "$ISO_MNT" 2>/dev/null && print_success "ISO desmontada."

echo
print_success "Proceso terminado. Si instalaste en $DEST_DIR, el juego ya vive en el disco externo."
print_info "Para jugarlo: Bottles → botella '$BOTTLE_NAME' → Ejecutar programa → el .exe del juego."