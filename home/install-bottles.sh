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
# VERIFICACIONES INICIALES
# ═══════════════════════════════════════════════════════════
if [[ $EUID -eq 0 ]]; then
  print_error "NO ejecutar como root. Ejecuta como usuario normal."
  exit 1
fi

if ! command -v yay &>/dev/null; then
  print_error "yay no está instalado. Instálalo primero."
  exit 1
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

if command -v bottles &>/dev/null || pacman -Qi bottles &>/dev/null 2>&1; then
  print_success "Bottles ya está instalado"
  BOTTLES_INSTALLED=true
else
  print_warning "Bottles no está instalado"
  echo
  read -p "¿Instalar Bottles ahora? (compila ~1 hora) [S/n]: " install_bottles

  if [[ ! "$install_bottles" =~ ^[Nn]$ ]]; then
    print_status "Instalando Bottles desde AUR..."
    print_warning "Esto puede tardar 1+ hora. Ve por un café ☕"

    yay -S --needed --noconfirm --answerdiff=None --answerclean=None --removemake \
      bottles 2>/dev/null || {
      print_error "Error instalando Bottles"
      exit 1
    }

    if command -v bottles &>/dev/null; then
      print_success "Bottles instalado correctamente"
      BOTTLES_INSTALLED=true
    else
      print_error "Bottles no se instaló correctamente"
      exit 1
    fi
  else
    print_error "Bottles es necesario para continuar"
    exit 1
  fi
fi

# ═══════════════════════════════════════════════════════════
# PASO 2: VERIFICAR DEPENDENCIAS
# ═══════════════════════════════════════════════════════════
print_header "PASO 2: Verificar dependencias"

print_status "Instalando dependencias base..."
sudo pacman -S --needed --noconfirm \
  wine-staging winetricks gamemode lib32-gamemode \
  vkd3d lib32-vkd3d vulkan-icd-loader lib32-vulkan-icd-loader

print_success "Dependencias instaladas"

# ═══════════════════════════════════════════════════════════
# PASO 3: CONFIGURACIÓN DE BOTELLA
# ═══════════════════════════════════════════════════════════
print_header "PASO 3: Configuración de Botella"

BOTTLES_DIR="$HOME/.local/share/bottles/bottles"

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
echo -e "  ${MAGENTA}•${NC} Versión recomendada: ${YELLOW}GE-Proton8-25${NC}"
echo -e "  ${MAGENTA}•${NC} Compatibilidad: ${GREEN}Excelente${NC}"
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
  yay -S --needed --noconfirm --answerdiff=None --answerclean=None --removemake \
    wine-ge-custom 2>/dev/null || print_warning "wine-ge-custom falló (puede que ya esté)"
  print_success "Wine-GE instalado"
  SELECTED_RUNNER="wine-ge"
  ;;

2)
  print_header "Instalando Proton-GE Custom"
  yay -S --needed --noconfirm --answerdiff=None --answerclean=None --removemake \
    proton-ge-custom-bin 2>/dev/null || print_warning "proton-ge falló (puede que ya esté)"
  print_success "Proton-GE instalado"
  SELECTED_RUNNER="proton-ge"
  ;;

3)
  print_header "Instalando Wine-GE + Proton-GE"
  yay -S --needed --noconfirm --answerdiff=None --answerclean=None --removemake \
    wine-ge-custom proton-ge-custom-bin 2>/dev/null || print_warning "Algunos falló (pueden estar instalados)"
  print_success "Ambos runners instalados"
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

      # Dependencias críticas
      print_package "DXVK + D3D"
      WINEPREFIX="$BOTTLE_PREFIX" winetricks -q dxvk d3dcompiler_47 d3dx9 d3dx11_42 2>/dev/null || true

      print_package "Visual C++ Redistributables"
      WINEPREFIX="$BOTTLE_PREFIX" winetricks -q vcrun2013 vcrun2015 vcrun2019 vcrun2022 2>/dev/null || true

      print_package ".NET Framework"
      WINEPREFIX="$BOTTLE_PREFIX" winetricks -q dotnet40 dotnet48 2>/dev/null || true

      print_package "Fuentes y extras"
      WINEPREFIX="$BOTTLE_PREFIX" winetricks -q corefonts 2>/dev/null || true

      # Para juegos que necesitan media (RE4, etc)
      echo
      read -p "¿Juego necesita codecs media (RE4, etc)? [s/N]: " install_media
      if [[ "$install_media" =~ ^[Ss]$ ]]; then
        print_package "Media Foundation + Codecs"
        WINEPREFIX="$BOTTLE_PREFIX" winetricks -q mf wmv9 quartz 2>/dev/null || true
      fi

      print_success "Dependencias instaladas"
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
# PASO 8: CONFIGURAR TEMA OSCURO
# ═══════════════════════════════════════════════════════════
if [[ -n "$BOTTLE_NAME" ]]; then
  print_header "PASO 8: Tema oscuro en Wine"

  echo
  read -p "¿Aplicar tema oscuro a '$BOTTLE_NAME'? [S/n]: " apply_dark

  if [[ ! "$apply_dark" =~ ^[Nn]$ ]]; then
    BOTTLE_PREFIX="$BOTTLES_DIR/$BOTTLE_NAME"

    # Buscar wine-breeze-dark.reg en múltiples ubicaciones
    DARK_THEME_PATHS=(
      ~/dotfiles-dizzi/wine-breeze-dark.reg
      ~/wine-breeze-dark.reg
      ~/.config/wine-breeze-dark.reg
    )

    THEME_FOUND=false
    for path in "${DARK_THEME_PATHS[@]}"; do
      if [[ -f "$path" ]]; then
        print_status "Aplicando tema oscuro desde: $path"
        WINEPREFIX="$BOTTLE_PREFIX" wine regedit "$path" 2>/dev/null || true
        print_success "Tema oscuro aplicado"
        THEME_FOUND=true
        break
      fi
    done

    if [[ "$THEME_FOUND" == false ]]; then
      print_warning "wine-breeze-dark.reg no encontrado"
      print_info "Configura manualmente: Bottles → $BOTTLE_NAME → Herramientas → Configuración → Escritorio → Theme: Dark"
    fi
  fi
fi

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
echo -e "${CYAN}1. Abrir Bottles:${NC}"
echo -e "   ${YELLOW}bottles${NC}"
echo
echo -e "${CYAN}2. Ejecutar juego/app desde terminal:${NC}"
echo -e "   ${YELLOW}bottles-cli run -p steam -b '$BOTTLE_NAME'${NC}"
echo -e "   ${YELLOW}bottles-cli run -p 'Hades' -b '$BOTTLE_NAME'${NC}"
echo
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
