#!/bin/bash
# install-bottles.sh
# Script interactivo para Bottles + Wine-GE / Proton-GE
# Compatible con el setup de dizzi1222

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

function print_status() { echo -e "${BLUE}[⚡]${NC} $1"; }
function print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
function print_error() { echo -e "${RED}[✗]${NC} $1"; }
function print_warning() { echo -e "${YELLOW}[⚠]${NC} $1"; }
function print_info() { echo -e "${CYAN}[ℹ]${NC} $1"; }
function print_package() { echo -e "  ${MAGENTA}📦${NC} $1"; }

# ═══════════════════════════════════════════════════════════
# FUNCIÓN: APLICAR TEMA OSCURO A UN PREFIX
# ═══════════════════════════════════════════════════════════
# Uso: apply_wine_dark_theme <prefix> <etiqueta>
# Busca wine-breeze-dark.reg en ubicaciones conocidas, lo aplica
# con regedit y verifica que quedó en user.reg.
function apply_wine_dark_theme() {
  local prefix="$1"
  local label="$2"

  # Matar instancias del prefix antes de tocar el registro
  print_status "Matando instancias de Wine ($label)..."
  WINEPREFIX="$prefix" wineserver -k 2>/dev/null
  sleep 2

  DARK_THEME_PATHS=(
    ~/dotfiles-dizzi/wine-breeze-dark.reg
    ~/wine-breeze-dark.reg
    ~/.config/wine-breeze-dark.reg
  )

  local found=false
  for path in "${DARK_THEME_PATHS[@]}"; do
    if [[ -f "$path" ]]; then
      print_status "Aplicando tema oscuro ($label) desde: $path"
      WINEPREFIX="$prefix" wine regedit "$path" 2>/dev/null || true
      # Verificar que realmente se aplicó (color del theme, ej. ActiveBorder)
      if rg -q '"ActiveBorder"="49 54 58"' "$prefix/user.reg" 2>/dev/null; then
        print_success "Dark theme aplicado en $label (verificado en user.reg)"
      else
        print_warning "El dark theme NO se detectó en $prefix/user.reg — revisa el output de regedit."
      fi
      found=true
      break
    fi
  done

  if [[ "$found" == false ]]; then
    print_warning "wine-breeze-dark.reg no encontrado"
    print_info "Aplica manualmente: $label → Herramientas/Configuración → Escritorio → Theme: Dark"
  fi

  # Reiniciar wineserver para que el prefix quede limpio
  WINEPREFIX="$prefix" wineserver -k 2>/dev/null || true
}

# ═══════════════════════════════════════════════════════════
# DETECCIÓN DE DISTRO Y VARIABLES DE ENTORNO
# ═══════════════════════════════════════════════════════════
# Soporta Arch (nativo, yay/pacman) y NixOS (flatpak).
if [[ $EUID -eq 0 ]]; then
  print_error "NO ejecutar como root. Ejecuta como usuario normal."
  exit 1
fi

if command -v pacman &>/dev/null && command -v yay &>/dev/null; then
  IS_ARCH=true
  DISTRO_LABEL="Arch/CachyOS"
  DEPS_CMD_PREFIX=""
elif command -v flatpak &>/dev/null; then
  IS_ARCH=false
  DISTRO_LABEL="NixOS (flatpak)"
  DEPS_CMD_PREFIX=""
else
  print_error "No se detectó Arch (yay+pacman) ni NixOS (flatpak). Instálalos primero."
  exit 1
fi

print_info "Distribución detectada: ${DISTRO_LABEL}"

# ═══════════════════════════════════════════════════════════
# DETECCIÓN DE BOTTLES: INSTALACIÓN Y RUTA REAL
# ═══════════════════════════════════════════════════════════
# Bottles puede instalarse como:
#   - flatpak (sandboxed) → ~/.var/app/com.usebottles.bottles/data/bottles
#   - nativo/pacman       → ~/.local/share/bottles
# Se detecta la instalación REAL y su ruta. Se puede forzar
# con la variable de entorno BOTTLES_BASE.

BOTTLES_BASE="${BOTTLES_BASE:-}"

# Candidatas en orden de prioridad (flatpak primero si existe la app)
FLATPAK_BOTTLES_BASE="$HOME/.var/app/com.usebottles.bottles/data/bottles"
NATIVE_BOTTLES_BASE="$HOME/.local/share/bottles"

if [[ -n "$BOTTLES_BASE" ]]; then
  BOTTLES_METHOD="manual (override BOTTLES_BASE=$BOTTLES_BASE)"
  print_warning "Forzando ruta de Bottles: $BOTTLES_BASE"
elif flatpak list --app 2>/dev/null | grep -qi "com.usebottles.bottles" && \
     [[ -d "$FLATPAK_BOTTLES_BASE/bottles" ]]; then
  BOTTLES_BASE="$FLATPAK_BOTTLES_BASE"
  BOTTLES_METHOD="flatpak"
elif [[ -d "$NATIVE_BOTTLES_BASE/bottles" ]]; then
  BOTTLES_BASE="$NATIVE_BOTTLES_BASE"
  BOTTLES_METHOD="nativo (pacman/AUR)"
else
  BOTTLES_METHOD="no detectado"
fi

print_info "Bottles instalado vía: ${BOTTLES_METHOD}"
print_info "Ruta de Bottles: ${BOTTLES_BASE:-NO ENCONTRADA}"

# Listar botellas existentes (si hay)
if [[ -d "$BOTTLES_BASE/bottles" ]] && [[ -n "$(ls -A "$BOTTLES_BASE/bottles" 2>/dev/null)" ]]; then
  print_info "Botellas encontradas: $(ls -1 "$BOTTLES_BASE/bottles" | tr '\n' ' ')"
else
  print_warning "No hay botellas aún en $BOTTLES_BASE/bottles"
fi

# ═══════════════════════════════════════════════════════════
# BANNER
# ═══════════════════════════════════════════════════════════
clear
cat <<"EOF"

██████╗░░█████╗░████████╗████████╗██╗░░░░░███████╗░██████╗
██╔══██╗██╔══██╗╚══██╔══╝╚══██╔══╝██║░░░░░██╔════╝██╔════╝
██████╦╝██║░░██║░░░██║░░░░░░██║░░░██║░░░░░█████╗░░╚█████╗░
██╔══██╗██║░░██║░░░██║░░░░░░██║░░░██║░░░░░██╔══╝░░░╚═══██╗
██████╦╝╚█████╔╝░░░██║░░░░░░██║░░░███████╗███████╗██████╔╝
╚═════╝░░╚════╝░░░░╚═╝░░░░░░╚═╝░░░╚══════╝╚══════╝╚═════╝░

╔══════════════════════════════════════════════════════════════════════╗
║        🍷 BOTTLES SETUP + WINE-GE / PROTON-GE SWITCHER 🍷           ║
║                    Setup optimizado por dizzi1222                    ║
╚══════════════════════════════════════════════════════════════════════╝

EOF

echo -e "${GREEN}${BOLD}Este script te permite:${NC}"
echo "  • Instalar Bottles (si no lo tienes)"
echo "  • Cambiar entre Wine-GE y Proton-GE fácilmente"
echo "  • Configurar runners optimizados para gaming"
echo "  • Aplicar configuraciones recomendadas"
echo
echo -e "${YELLOW}${BOLD}Información importante:${NC}"
echo -e "  ${MAGENTA}•${NC} Wine-GE 8: ${GREEN}Mejor para Steam, apps Windows generales${NC}"
echo -e "  ${MAGENTA}•${NC} Proton-GE 10: ${GREEN}Mejor para juegos (Sparking Zero, etc)${NC}"
echo -e "  ${MAGENTA}•${NC} Puedes cambiar el runner cuando quieras${NC}"
echo
read -p "¿Continuar? [S/n]: " confirm
[[ "$confirm" =~ ^[Nn]$ ]] && exit 0

# ═══════════════════════════════════════════════════════════
# PASO 1: VERIFICAR/INSTALAR BOTTLES
# ═══════════════════════════════════════════════════════════
print_header "PASO 1: Verificar instalación de Bottles"

if command -v bottles &>/dev/null || flatpak list --app 2>/dev/null | grep -qi "com.usebottles.bottles" || [[ -n "$BOTTLES_BASE" ]]; then
  print_success "Bottles ya está instalado (${BOTTLES_METHOD:-nativo})"
  BOTTLES_INSTALLED=true
else
  print_warning "Bottles no está instalado"
  echo
  read -p "¿Instalar Bottles ahora? [S/n]: " install_bottles

  if [[ ! "$install_bottles" =~ ^[Nn]$ ]]; then
    if [[ "$IS_ARCH" == true ]]; then
      print_status "Instalando Bottles desde AUR..."
      print_warning "Esto puede tardar 1+ hora. Ve por un café ☕"
      yay -S --needed --noconfirm --answerdiff=None --answerclean=None --removemake \
        bottles 2>/dev/null || {
        print_error "Error instalando Bottles"
        exit 1
      }
    else
      print_status "Instalando Bottles vía flatpak..."
      flatpak install -y --user flathub com.usebottles.bottles 2>/dev/null || {
        print_error "Error instalando Bottles (flatpak)"
        exit 1
      }
    fi
    print_success "Bottles instalado correctamente"
    BOTTLES_INSTALLED=true
  else
    print_error "Bottles es necesario para continuar"
    exit 1
  fi
fi

# ═══════════════════════════════════════════════════════════
# PASO 1.5: SANDBOX FLATPAK — PERMISOS DE FILESYSTEM
# ═══════════════════════════════════════════════════════════
# En NixOS Bottles corre sandboxed (flatpak). Por defecto NO puede acceder
# a mounts de udisks2 (/run/media/diego/*) donde GNOME/KDE montan ISOs
# automáticamente. Sin esto, bottles-cli falla con:
#   "Executable file path does not exist or is not accessible by the Flatpak"
print_header "PASO 1.5: Permisos Flatpak (acceso a /run/media)"

if [[ "$IS_ARCH" == true ]]; then
  print_warning "Instalación nativa (Arch): sin sandbox, no hace falta override."
else
  print_status "Aplicando overrides de filesystem a com.usebottles.bottles..."
  # /mnt  → montajes loop manuales (ISO en /mnt/iso-N)
  # /media/diego → disco externo montado por montar_disco_externo.sh
  # /run/media/diego → ISOs autocontenidas por udisks2 (GNOME/KDE)
  flatpak override --user --filesystem=/mnt com.usebottles.bottles
  flatpak override --user --filesystem=/media/diego com.usebottles.bottles
  flatpak override --user --filesystem=/run/media/diego com.usebottles.bottles

  perms="$(flatpak info --show-permissions com.usebottles.bottles 2>/dev/null | grep -i filesystem || true)"
  if echo "$perms" | grep -qE "/run/media|/media/diego|/mnt"; then
    print_success "Bottles ya puede ver los mounts externos:"
    echo -e "  ${MAGENTA}•${NC} $perms"
  else
    print_warning "Override aplicado pero flatpak info no lo refleja aún (revisa manualmente)."
  fi
fi

# ═══════════════════════════════════════════════════════════
# PASO 1.6: KERNEL ASLR — FIX INSTALADORES 32-BIT (mmap)
# ═══════════════════════════════════════════════════════════
# En kernel 6.1+ vm.mmap_rnd_bits=32 rompe instaladores 32-bit bajo Wine
# (elamigos/Inno Setup) que explotan: bucle infinito de
#   "mmap() error Cannot allocate memory, range 0x90000000-..."
# El fix conocido es bajar la entropía a 28. Esto afecta a TODAS las distros.
print_header "PASO 1.6: Fix kernel ASLR (mmap_rnd_bits=28)"

current_bits="$(cat /proc/sys/vm/mmap_rnd_bits 2>/dev/null || echo '?')"
if [[ "$current_bits" == "28" ]]; then
  print_success "vm.mmap_rnd_bits ya está en 28 (instaladores 32-bit OK)"
elif [[ "$current_bits" == "32" ]]; then
  print_warning "vm.mmap_rnd_bits=32 detectado: instaladores 32-bit de Wine fallarán con mmap."
  echo
  read -p "¿Aplicar fix (sysctl 32→28) ahora? [S/n]: " fix_mmap
  if [[ ! "$fix_mmap" =~ ^[Nn]$ ]]; then
    if sudo sysctl -w vm.mmap_rnd_bits=28 2>/dev/null; then
      print_success "Aplicado (runtime). Persistiendo en /etc/sysctl.d/99-wine-mmap.conf..."
      echo "vm.mmap_rnd_bits=28" | sudo tee /etc/sysctl.d/99-wine-mmap.conf >/dev/null
      print_info "Nota NixOS: usa boot.kernel.sysctl.\"vm.mmap_rnd_bits\" = \"28\" en configuration.nix para que no se pierda al rebuild."
    else
      print_error "No se pudo aplicar (permisos). Hazlo manualmente:"
      echo -e "   ${YELLOW}sudo sysctl -w vm.mmap_rnd_bits=28${NC}"
    fi
  else
    print_warning "Fix omitido: instaladores 32-bit (elamigos/Inno) pueden fallar con mmap."
  fi
else
  print_info "valor actual: ${current_bits} (no requiere cambio)"
fi

# ═══════════════════════════════════════════════════════════
# PASO 2: VERIFICAR DEPENDENCIAS
# ═══════════════════════════════════════════════════════════
print_header "PASO 2: Verificar dependencias"

if [[ "$IS_ARCH" == true ]]; then
  print_status "Instalando dependencias base (Arch)..."
  sudo pacman -S --needed --noconfirm \
    wine-staging winetricks gamemode lib32-gamemode \
    vkd3d lib32-vkd3d vulkan-icd-loader lib32-vulkan-icd-loader
else
  print_status "Verificando runtime de Wine (NixOS/flatpak)..."
  # En NixOS los runners (wine) se instalan dentro de Bottles GUI; winetricks
  # está disponible vía el paquete del sistema o flatpak. Solo avisamos.
  if ! command -v winetricks &>/dev/null; then
    print_warning "winetricks no está en PATH. Instálelo: nix-shell -p winetricks (o flatpak)."
  fi
fi

print_success "Dependencias listas"

# ═══════════════════════════════════════════════════════════
# PASO 2.5: WINE PREFIX (~/.wine) — Cross-platform
# ═══════════════════════════════════════════════════════════
print_header "PASO 2.5: Configurar Wine prefix (~/.wine)"

echo
read -p "¿Configurar Wine prefix ahora? [S/n]: " setup_wine

if [[ ! "$setup_wine" =~ ^[Nn]$ ]]; then
  if ! command -v wine &>/dev/null || ! command -v winetricks &>/dev/null; then
    print_warning "wine/winetricks no están en PATH. En NixOS usa: nix-shell -p wine winetricks"
    print_warning "Omitiendo Wine prefix (Bottles usa sus propios runners)."
  else
    export WINEPREFIX="$HOME/.wine"
    # Solo forzar win64 cuando se va a recrear limpio; un prefix win32 con
    # WINEARCH=win64 hace que winetricks/wine/funcionen mal (arch desalineada).
    if [[ -f "$WINEPREFIX/system.reg" ]] && rg -qi '^#arch=win32' "$WINEPREFIX/system.reg"; then
      export WINEARCH=win32
      print_warning "Prefix detectado como $WINEARCH; usando WINEARCH=$WINEARCH (no win64)"
    else
      export WINEARCH=win64
    fi

    # ── Pre-config: detectar prefix existente con arch distinta a win64 ──
    # Si ~/.wine ya existe como win32 (o sin #arch) pero queremos win64,
    # winetricks/wine fallan ("WINEARCH set to win64 but ... is a 32-bit
    # installation"). Se respalda el prefix y se recrea limpio como win64.
    if [ -f ~/.wine/system.reg ] || [ -d ~/.wine/drive_c ]; then
      current_arch=$(rg -m1 -i '^#arch=' ~/.wine/system.reg 2>/dev/null | sed 's/#arch=//i' || true)
      echo
      echo -e "${YELLOW}⚠  Detectado prefix existente en ~/.wine (arch: ${current_arch:-desconocida}).${NC}"
      if [[ "$current_arch" != "win64" ]]; then
        read -p "  No es win64. ¿Respaldo y recreo como win64 (se borra el actual)? [S/n]: " recreate_wine
        if [[ ! "$recreate_wine" =~ ^[Nn]$ ]]; then
          backup_wine=~/.wine.bak.$(date +%Y%m%d-%H%M%S)
          print_status "Respaldando ~/.wine -> $backup_wine"
          mv ~/.wine "$backup_wine" 2>/dev/null || true
          print_warning "Prefix anterior respaldado en $backup_wine"
        else
          print_warning "Omitiendo recreación: winetricks puede fallar por arch distinta."
        fi
      fi
    fi

    print_status "Inicializando Wine prefix"
    wineboot -u 2>/dev/null &
    sleep 5

    print_status "Instalando componentes Wine con winetricks"
    wt_fail=0
    for wt_args in \
      "corefonts dotnet40 dotnet48 dxvk d3dx9 vcrun2022" \
      "d3dcompiler_47 d3dx11_42 win10" \
      "vcrun2013 vcrun2012 vcrun2010 vcrun2008 vcrun2005" \
      "mf quartz"
    do
      print_status "winetricks $wt_args"
      winetricks $wt_args 2>&1 || wt_fail=1
    done
    if [[ "$wt_fail" -ne 0 ]]; then
      print_warning "Algunos componentes winetricks reportaron error (revisa el output de arriba)."
    else
      print_success "Componentes winetricks instalados."
    fi

    # Wine Dark Theme
    read -p "¿Aplicar Wine Dark Theme? [S/n]: " apply_dark
    if [[ ! "$apply_dark" =~ ^[Nn]$ ]]; then
      apply_wine_dark_theme "$WINEPREFIX" "Wine (~/.wine)"
    fi

    print_success "Wine configurado"
  fi
else
  print_warning "Wine prefix omitido"
fi

# ═══════════════════════════════════════════════════════════
# PASO 3: CONFIGURACIÓN DE BOTELLA
# ═══════════════════════════════════════════════════════════
print_header "PASO 3: Configuración de Botella"

BOTTLES_DIR="$BOTTLES_BASE/bottles"

echo
echo -e "${CYAN}¿Qué quieres hacer?${NC}"
echo
echo -e "${BOLD}${GREEN}1.${NC} Crear nueva botella Gaming"
echo -e "${BOLD}${GREEN}2.${NC} Usar botella existente"
echo -e "${BOLD}${GREEN}3.${NC} Omitir (solo instalar runners)"
echo
read -p "Selecciona opción [1/2/3]: " bottle_choice

BOTTLE_NAME=""

case "$bottle_choice" in
1)
  print_status "Creando nueva botella..."
  echo
  read -p "Nombre de la botella (ej: bottles-dbz, gaming, etc): " BOTTLE_NAME

  if [[ -z "$BOTTLE_NAME" ]]; then
    BOTTLE_NAME="gaming-$(date +%s)"
    print_warning "Usando nombre por defecto: $BOTTLE_NAME"
  fi

  print_info "Abre Bottles GUI y crea la botella '$BOTTLE_NAME' manualmente"
  print_info "Presiona Enter cuando hayas terminado..."
  read
  ;;

2)
  print_status "Botellas existentes:"
  if [[ -d "$BOTTLES_DIR" ]]; then
    ls -1 "$BOTTLES_DIR" 2>/dev/null || print_warning "No hay botellas"
  fi
  echo
  read -p "Nombre de la botella a configurar: " BOTTLE_NAME

  if [[ ! -d "$BOTTLES_DIR/$BOTTLE_NAME" ]]; then
    print_error "Botella '$BOTTLE_NAME' no encontrada"
    exit 1
  fi
  ;;

3)
  print_warning "Configuración de botella omitida"
  BOTTLE_NAME=""
  ;;

*)
  print_error "Opción inválida"
  exit 1
  ;;
esac

# ═══════════════════════════════════════════════════════════
# PASO 4: INSTALAR/CAMBIAR RUNNERS
# ═══════════════════════════════════════════════════════════
print_header "PASO 4: Gestión de Runners"

echo
echo -e "${BOLD}${YELLOW}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${YELLOW}║          🎮 SELECCIONAR RUNNER 🎮                         ║${NC}"
echo -e "${BOLD}${YELLOW}╚═══════════════════════════════════════════════════════════╝${NC}"
echo
echo -e "${CYAN}Opciones disponibles:${NC}"
echo
echo -e "${BOLD}${GREEN}1. Wine-GE Custom${NC}"
echo -e "  ${MAGENTA}•${NC} Mejor para: ${GREEN}Steam, apps Windows, juegos generales${NC}"
echo -e "  ${MAGENTA}•${NC} Versión recomendada: ${YELLOW}ge-proton11-3${NC}"
echo -e "  ${MAGENTA}•${NC} Compatibilidad: ${GREEN}Excelente${NC}"
echo -e "  ${MAGENTA}•${NC} ${RED}Evita wine-ge-proton8-26:${NC} bucle 'mmap() Cannot allocate memory' en instaladores 32-bit (elamigos/Inno) con kernel 6.x"
echo
echo -e "${BOLD}${GREEN}2. Proton-GE Custom${NC}"
echo -e "  ${MAGENTA}•${NC} Mejor para: ${GREEN}Sparking Zero, juegos AAA recientes${NC}"
echo -e "  ${MAGENTA}•${NC} Versión recomendada: ${YELLOW}GE-Proton9-20${NC}"
echo -e "  ${MAGENTA}•${NC} Compatibilidad: ${GREEN}Juegos modernos${NC}"
echo
echo -e "${BOLD}${GREEN}3. Instalar AMBOS${NC} (recomendado)"
echo -e "  ${MAGENTA}•${NC} Podrás cambiar entre ellos cuando quieras"
echo
echo -e "${BOLD}${GREEN}4. Omitir${NC}"
echo
read -p "Seleccionar opción [1/2/3/4]: " runner_choice

case "$runner_choice" in
1)
  print_header "Instalando Wine-GE Custom"
  if [[ "$IS_ARCH" == true ]]; then
    yay -S --needed --noconfirm --answerdiff=None --answerclean=None --removemake \
      wine-ge-custom 2>/dev/null || print_warning "wine-ge-custom falló (puede que ya esté)"
  else
    print_info "En NixOS, descarga el runner desde Bottles GUI:"
    print_info "  Preferencias → Ejecutores → Wine (Wine-GE xxx)"
  fi
  print_success "Wine-GE listo"
  SELECTED_RUNNER="wine-ge"
  ;;

2)
  print_header "Instalando Proton-GE Custom"
  if [[ "$IS_ARCH" == true ]]; then
    yay -S --needed --noconfirm --answerdiff=None --answerclean=None --removemake \
      proton-ge-custom-bin 2>/dev/null || print_warning "proton-ge falló (puede que ya esté)"
  else
    print_info "En NixOS, descarga el runner en Bottles GUI:"
    print_info "  Preferencias → Ejecutores → Prootn-GE xxx"
  fi
  print_success "Proton-GE listo"
  SELECTED_RUNNER="proton-ge"
  ;;

3)
  print_header "Instalando Wine-GE + Proton-GE"
  if [[ "$IS_ARCH" == true ]]; then
    yay -S --needed --noconfirm --answerdiff=None --answerclean=None --removemake \
      wine-ge-custom proton-ge-custom-bin 2>/dev/null || print_warning "Algunos falló (pueden estar instalados)"
  else
    print_info "En NixOS, descarga ambos runners en: Bottles GUI → Preferencias → Ejecutores"
  fi
  print_success "Ambos runners listos"
  SELECTED_RUNNER="ambos"
  ;;

4)
  print_warning "Instalación de runners omitida"
  SELECTED_RUNNER="ninguno"
  ;;

*)
  print_error "Opción inválida"
  exit 1
  ;;
esac

# ═══════════════════════════════════════════════════════════
# PASO 5: CONFIGURAR BOTELLA CON RUNNER
# ═══════════════════════════════════════════════════════════
if [[ -n "$BOTTLE_NAME" ]] && [[ "$SELECTED_RUNNER" != "ninguno" ]]; then
  print_header "PASO 5: Configurar Runner en Botella"

  echo
  echo -e "${YELLOW}${BOLD}INSTRUCCIONES PARA CONFIGURAR EN BOTTLES GUI:${NC}"
  echo
  echo -e "${CYAN}1.${NC} Abre ${YELLOW}Bottles${NC}"
  echo -e "${CYAN}2.${NC} Selecciona tu botella: ${GREEN}$BOTTLE_NAME${NC}"
  echo -e "${CYAN}3.${NC} Ve a: ${YELLOW}⚙️ Preferencias → Ejecutores (Runners)${NC}"
  echo -e "${CYAN}4.${NC} Busca e instala:"

  if [[ "$SELECTED_RUNNER" == "wine-ge" ]] || [[ "$SELECTED_RUNNER" == "ambos" ]]; then
    echo -e "     ${MAGENTA}•${NC} ${GREEN}Wine GE-Proton8-25${NC} (o más reciente)"
  fi

  if [[ "$SELECTED_RUNNER" == "proton-ge" ]] || [[ "$SELECTED_RUNNER" == "ambos" ]]; then
    echo -e "     ${MAGENTA}•${NC} ${GREEN}Proton GE-Proton9-20${NC} (o más reciente)"
  fi

  echo
  echo -e "${CYAN}5.${NC} Vuelve a tu botella → ${YELLOW}⚙️ Opciones${NC}"
  echo -e "${CYAN}6.${NC} En ${YELLOW}Runner${NC}, selecciona el runner instalado"
  echo -e "${CYAN}7.${NC} ${RED}CRÍTICO:${NC} ${BOLD}Desactiva 'Steam Runtime'${NC} (causa problemas)"
  echo

  if [[ "$SELECTED_RUNNER" == "ambos" ]]; then
    echo -e "${YELLOW}${BOLD}CUÁNDO USAR CADA RUNNER:${NC}"
    echo -e "  ${GREEN}Wine-GE:${NC} Steam, apps Windows, juegos viejos/medios"
    echo -e "  ${GREEN}Proton-GE:${NC} Sparking Zero, juegos AAA modernos, online fixes"
    echo
  fi

  read -p "Presiona Enter cuando hayas configurado el runner..."

  print_success "Configuración de runner completada"
fi

# ═══════════════════════════════════════════════════════════
# PASO 6: DEPENDENCIAS WINE EN BOTELLA
# ═══════════════════════════════════════════════════════════
if [[ -n "$BOTTLE_NAME" ]]; then
  print_header "PASO 6: Instalar dependencias Wine"

  echo
  read -p "¿Instalar dependencias recomendadas en '$BOTTLE_NAME'? [S/n]: " install_deps

  if [[ ! "$install_deps" =~ ^[Nn]$ ]]; then
    BOTTLE_PREFIX="$BOTTLES_DIR/$BOTTLE_NAME"

    if [[ ! -d "$BOTTLE_PREFIX" ]]; then
      print_error "Botella no encontrada en: $BOTTLE_PREFIX"
    else
      print_status "Instalando dependencias en: $BOTTLE_NAME"

      dep_fail=0
      for wt_args in \
        "dxvk d3dcompiler_47 d3dx9 d3dx11_42" \
        "vcrun2013 vcrun2015 vcrun2022" \
        "dotnet40 dotnet48" \
        "corefonts"
      do
        print_package "winetricks $wt_args"
        WINEPREFIX="$BOTTLE_PREFIX" winetricks $wt_args 2>&1 || dep_fail=1
      done

      # Para juegos que necesitan media (RE4, etc)
      echo
      read -p "¿Juego necesita codecs media (RE4, etc)? [s/N]: " install_media
      if [[ "$install_media" =~ ^[Ss]$ ]]; then
        print_package "Media Foundation + Codecs"
        WINEPREFIX="$BOTTLE_PREFIX" winetricks mf quartz 2>&1 || dep_fail=1
      fi

      if [[ "$dep_fail" -ne 0 ]]; then
        print_warning "Algunos componentes reportaron error (revisa el output de arriba)."
      else
        print_success "Dependencias instaladas"
      fi
    fi
  else
    print_warning "Dependencias omitidas"
  fi
fi

# ═══════════════════════════════════════════════════════════
# PASO 7: CREAR SCRIPT HELPER
# ═══════════════════════════════════════════════════════════
print_header "PASO 7: Crear scripts auxiliares"

# Script para cambiar runners fácilmente
cat >~/bottles-switch-runner.sh <<'EOFSCRIPT'
#!/bin/bash
# bottles-switch-runner.sh
# Script rápido para cambiar runners en Bottles

echo "🍷 BOTTLES RUNNER SWITCHER"
echo

if [[ $# -eq 0 ]]; then
  echo "Uso: $0 <nombre-botella>"
  echo
  echo "Botellas disponibles:"
  ls -1 ~/.local/share/bottles/bottles/ 2>/dev/null
  exit 1
fi

BOTTLE="$1"
BOTTLE_PATH="$HOME/.local/share/bottles/bottles/$BOTTLE"

if [[ ! -d "$BOTTLE_PATH" ]]; then
  echo "❌ Botella '$BOTTLE' no encontrada"
  exit 1
fi

echo "Botella: $BOTTLE"
echo
echo "Selecciona runner:"
echo "  1. Wine-GE (Steam, apps generales)"
echo "  2. Proton-GE (juegos modernos)"
echo
read -p "Opción [1/2]: " choice

case "$choice" in
  1)
    echo "📝 Configurando Wine-GE..."
    echo "Abre Bottles → $BOTTLE → Opciones → Runner → Wine GE"
    ;;
  2)
    echo "📝 Configurando Proton-GE..."
    echo "Abre Bottles → $BOTTLE → Opciones → Runner → Proton GE"
    ;;
  *)
    echo "❌ Opción inválida"
    exit 1
    ;;
esac

echo
echo "✅ Recuerda DESACTIVAR Steam Runtime"
EOFSCRIPT

chmod +x ~/bottles-switch-runner.sh

print_success "Script creado: ~/bottles-switch-runner.sh"

# ═══════════════════════════════════════════════════════════
# PASO 8: TEMA OSCURO — WINE Y/O BOTTLES
# ═══════════════════════════════════════════════════════════
print_header "PASO 8: Tema oscuro en Wine y Bottles"

echo
echo -e "${CYAN}¿A dónde quieres aplicar el tema oscuro?${NC}"
echo
echo -e "${BOLD}${GREEN}1.${NC} Wine (~/.wine)"
echo -e "${BOLD}${GREEN}2.${NC} Botella Bottles"
echo -e "${BOLD}${GREEN}3.${NC} Ambos"
echo -e "${BOLD}${GREEN}4.${NC} Omitir"
echo
read -p "Selecciona opción [1/2/3/4]: " dark_choice

case "$dark_choice" in
1)
  apply_wine_dark_theme "$HOME/.wine" "Wine (~/.wine)"
  ;;
2)
  if [[ -n "$BOTTLE_NAME" ]]; then
    apply_wine_dark_theme "$BOTTLES_DIR/$BOTTLE_NAME" "Bottles ($BOTTLE_NAME)"
  else
    if [[ -d "$BOTTLES_DIR" ]]; then
      echo
      print_info "Botellas disponibles:"
      ls -1 "$BOTTLES_DIR"
      echo
      read -p "Nombre de la botella (para dark theme): " EXTRA_BOTTLE
      if [[ -n "$EXTRA_BOTTLE" ]] && [[ -d "$BOTTLES_DIR/$EXTRA_BOTTLE" ]]; then
        apply_wine_dark_theme "$BOTTLES_DIR/$EXTRA_BOTTLE" "Bottles ($EXTRA_BOTTLE)"
      else
        print_error "Botella '$EXTRA_BOTTLE' no encontrada en $BOTTLES_DIR"
      fi
    else
      print_warning "No hay botellas de Bottles (BOTTLES_DIR no existe: $BOTTLES_DIR)"
      print_info "Crea una botella primero (PASO 3 o desde la GUI de Bottles)."
    fi
  fi
  ;;
3)
  apply_wine_dark_theme "$HOME/.wine" "Wine (~/.wine)"
  if [[ -n "$BOTTLE_NAME" ]]; then
    apply_wine_dark_theme "$BOTTLES_DIR/$BOTTLE_NAME" "Bottles ($BOTTLE_NAME)"
  else
    print_warning "Sin botella seleccionada en este run — aplica a Bottles manualmente:"
    print_info "Bottles → botella → Herramientas de Wine → Configuración → Escritorio → Theme: Dark"
  fi
  ;;
4)
  print_warning "Tema oscuro omitido"
  ;;
*)
  print_error "Opción inválida"
  ;;
esac

# ═══════════════════════════════════════════════════════════
# RESUMEN FINAL
# ═══════════════════════════════════════════════════════════
print_header "✅ CONFIGURACIÓN COMPLETADA"

echo -e "${GREEN}${BOLD}Instalación finalizada:${NC}"
echo
[[ "$BOTTLES_INSTALLED" == true ]] && echo -e "  ${GREEN}✓${NC} Bottles instalado"
[[ "$SELECTED_RUNNER" != "ninguno" ]] && echo -e "  ${GREEN}✓${NC} Runners instalados: $SELECTED_RUNNER"
[[ -n "$BOTTLE_NAME" ]] && echo -e "  ${GREEN}✓${NC} Botella configurada: $BOTTLE_NAME"
echo

echo -e "${YELLOW}${BOLD}GUÍA DE USO RÁPIDO:${NC}"
echo

if [[ "$IS_ARCH" == true ]]; then
  echo -e "${CYAN}1. Abrir Bottles:${NC}"
  echo -e "   ${YELLOW}bottles${NC}"
  echo
  echo -e "${CYAN}2. Ejecutar juego/app desde terminal:${NC}"
  echo -e "   ${YELLOW}bottles-cli run -p steam -b '$BOTTLE_NAME'${NC}"
  echo -e "   ${YELLOW}bottles-cli run -p 'Hades' -b '$BOTTLE_NAME'${NC}"
  echo
else
  echo -e "${CYAN}1. Abrir Bottles (flatpak):${NC}"
  echo -e "   ${YELLOW}flatpak run com.usebottles.bottles${NC}"
  echo
  echo -e "${CYAN}2. Ejecutar juego/app (flatpak):${NC}"
  echo -e "   ${YELLOW}flatpak run com.usebottles.bottles --run -p Steam -b '$BOTTLE_NAME'${NC}"
  echo
fi

echo -e "${CYAN}3. Cambiar runner rápidamente:${NC}"
echo -e "   ${YELLOW}~/bottles-switch-runner.sh $BOTTLE_NAME${NC}"
echo
echo -e "${CYAN}4. Instalar programa en botella:${NC}"
echo -e "   ${YELLOW}Bottles → $BOTTLE_NAME → Ejecutar ejecutable → selecciona .exe${NC}"
echo
echo -e "${CYAN}5. Ubicación de la botella:${NC}"
echo -e "   ${YELLOW}$BOTTLES_DIR/$BOTTLE_NAME${NC}"
echo

echo -e "${RED}${BOLD}IMPORTANTE:${NC}"
echo -e "  ${MAGENTA}•${NC} Wine-GE: Mejor para Steam y apps generales"
echo -e "  ${MAGENTA}•${NC} Proton-GE: Mejor para juegos modernos (Sparking Zero)"
echo -e "  ${MAGENTA}•${NC} ${BOLD}SIEMPRE desactiva Steam Runtime${NC}"
echo -e "  ${MAGENTA}•${NC} Los .desktop deben usar: ${YELLOW}bottles-cli run -p NOMBRE -b 'BOTELLA'${NC}"
echo

echo -e "${GREEN}🎮 ¡Disfruta tu setup Gaming optimizado! 🎮${NC}"
echo
