#!/bin/bash
# /029   - [13] Regenerar Escritorio+Apps {Nemo Desktop}.sh
# Regenerar Escritorio + Apps {Nemo Desktop} - VERSIÓN MEJORADA
# =================================================================================
# FUNCIONALIDAD:
# 1. Crea enlaces simbólicos de aplicaciones .desktop en el Escritorio
# 2. Crea symlink de carpeta CustomRP_Icons para Wine
# 3. Copia archivos .crp SUELTOS al Desktop de Wine (para CustomRP)
# =================================================================================
/home/diego/scripts/crear_escritorio-CustomRP.sh
/home/diego/add-icons-to-desktop.sh
# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directorios principales
ORIGEN="/home/diego/.local/share/applications"
ESCRITORIO="/home/diego/Escritorio"
WINE_DESKTOP="/home/diego/.wine/drive_c/users/diego/Desktop"
GDRIVE_ICONS="/home/diego/mi_gdrive/Mi unidad/[Documentos]/[Iconos - Status personalizados DISCORD CustomRP]"
WINE_CUSTOMRP="/home/diego/.wine/drive_c/CustomRP_Icons"

# =================================================================================
# LISTAS DE APLICACIONES
# =================================================================================

# Archivos del subdirectorio [APPS]+scripts/
declare -a APPS_SCRIPTS_FILES=(
  # "Bluetooth-restart.desktop"
  # "fzf+nvim🔍.desktop"
  # "scrcpy-movil.desktop"
  # "MAC-theme🫟🔴🔵🟢.theme.desktop"
  "kew.desktop"
  # "notepad.desktop"
  "limpiar_cache.desktop"
  # "comfy-ui editor.desktop"
  # "SDDM Astronaut Theme Installer.desktop"
  "input-remapper-gtk.desktop"
  # "Regenerar Escritorio Nemo.desktop"
  # "mi_gdrive_iconos.desktop"
  # "hypridle STOP [for juegos WINE].desktop"
  # "hypridle START.desktop"
)

# Archivos de la raíz de applications/
declare -a ROOT_FILES=(
  # "Among Us.desktop"
  # "Project Zomboid.desktop"
  # "Terraria.desktop"
  # "Undertale.desktop"
  # WINE Y LUTRIS APPS (SIN CustomRP_Icons/ - lo manejamos aparte)
  # "Wine-Manager.desktop"
  # "bottles-dbz--Resident Evil 4 2023--1763458955.444143.desktop"
  # "Legcord-wine.desktop"
  "CustomRP-wine.desktop"
  "Discord.desktop"
  # "uTorrent µ-wine.desktop"
  # "bottles-dbz--Geometry Dash--1761703337.881545.desktop"
  # "Wine11 Manager [Uninstaller-Installer].desktop"
  # "Wine11 Commands-Comandos.desktop"
  # "net.lutris.dead-cells-46.desktop"
  # "net.lutris.hollow-knight-47.desktop"
  # "nemo-windows.desktop"
  # "kill-nemo-windows.desktop"
  # "bottles-dbz--Dragon Ball Sparking ZERO--1761704150.630538.desktop"
  # "net.lutris.pro-evolution-soccer-2010-115.desktop"
  # "net.lutris.pokemon-scarlet-110.desktop"
  # "net.lutris.pokemon-sword-111.desktop"
  # "net.lutris.pokemon-legends-z-a-120.desktop"
  "net.lutris.firefox-72.desktop"
  "net.lutris.brave-browser-55.desktop"
  # "bottles-dbz--Hades--1761703565.061601.desktop"
  "net.lutris.handbrake-51.desktop"
  # "bottles-dbz--Hollow Knight Silksong--1761704399.656596.desktop"
  # "net.lutris.jdownloader-57.desktop"
  # "net.lutris.krita-66.desktop"
  # "net.lutris.lxappearance-themes-56.desktop"
  "net.lutris.lutris-48.desktop"
  # "bottles-dbz--NARUTO SHIPPUDEN: Ultimate Ninja STORM 4--1761704496.291657.desktop"
  # "net.lutris.nwg-look-themes-54.desktop"
  # "net.lutris.obs-studio-67.desktop"
  # "PokeOne-wine.desktop"
  # "bottles-dbz--PokeMMO--1761703189.638156.desktop"
  # "net.lutris.sekiro-shadows-die-twice-76.desktop"
  # "bottles-dbz--Silent Hill 2--1761704592.309507.desktop"
  # # "net.lutris.stacer-ccleaner-limpieza-50.desktop"
  # "steam-wine.desktop"
  # "bottles-dbz--steam--1761701610.473356.desktop"
  "steam-native.desktop"
  # "net.lutris.winetricks-121.desktop"
  # "net.lutris.yazi-search-68.desktop"
  "net.lutris.youtube-music-69.desktop"
  "net.lutris.spotify-client-127.desktop"
  # "net.lutris.cursor-64.desktop"
  # "net.lutris.visual-studio-code-122.desktop"
  "net.lutris.antigravity-vscodevim-129.desktop"
  "net.lutris.neovim-124.desktop"
  # "net.lutris.bottles-wine-ge-10-123.desktop"
  # "net.lutris.musicpreence-58.desktop"
  # "net.lutris.protonvpn-app-62.desktop"
  # "net.lutris.usrbinqt5ct-53.desktop"
  # "net.lutris.qt6ct-themes-52.desktop"
  # "net.lutris.warp-terminal-63.desktop"
  # "µTorrent.desktop"
  # "net.lutris.pamac-aur-panel-de-control-49.desktop"
  # "net.lutris.mp3tag-80.desktop"
  "net.lutris.ghostty-81.desktop"
  # "net.lutris.mega-sync-70.desktop"
  "net.lutris.geforce-now-86.desktop"
  "net.lutris.geforce-infinity-125.desktop"
  # "net.lutris.blasphemous-85.desktop"
  # "tModLoader.desktop"
  # "WinRAR-wine.desktop"
  # "PCXS2 Emulador PS2.desktop"
  # "Citra Emulador 3DS.desktop"
  # "RyujinX Emulador Switch.desktop"
  # "YUZU Emulador Switch.desktop"
  # "net.lutris.davinci-resolve-87.desktop"
  # "net.lutris.dragon-ball-z-budokai-tenkaichi-3-93.desktop"
  "net.lutris.monitor-del-sistema-94.desktop"
  # "net.lutris.usrbingnome-disks-97.desktop"
  "net.lutris.btop-monitor-kill-t-96.desktop"
  # "net.lutris.calculadora-gnome-95.desktop"
  # "7-Zip File Manager-wine.desktop"
)

# =================================================================================
# FUNCIONES
# =================================================================================

print_header() {
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}$1${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_step() {
  echo -e "\n${YELLOW}► $1${NC}"
}

print_success() {
  echo -e "${GREEN}✓${NC} $1"
}

print_error() {
  echo -e "${RED}✗${NC} $1"
}

# =================================================================================
# PASO 1: LIMPIEZA INICIAL
# =================================================================================

print_header "PASO 1: LIMPIEZA INICIAL"

print_step "Eliminando enlaces simbólicos antiguos del Escritorio..."
ALL_FILES=("${APPS_SCRIPTS_FILES[@]}" "${ROOT_FILES[@]}")
REMOVED_COUNT=0

for FILENAME in "${ALL_FILES[@]}"; do
  if [ -L "$ESCRITORIO/$FILENAME" ]; then
    rm -v "$ESCRITORIO/$FILENAME" && ((REMOVED_COUNT++))
  fi
done

# Limpiar symlink de carpeta CustomRP_Icons si existe
if [ -L "$ESCRITORIO/CustomRP_Icons" ]; then
  rm -v "$ESCRITORIO/CustomRP_Icons" && ((REMOVED_COUNT++))
fi

if [ $REMOVED_COUNT -gt 0 ]; then
  print_success "Eliminados $REMOVED_COUNT enlaces antiguos"
else
  echo "  (No había enlaces antiguos para eliminar)"
fi

# =================================================================================
# PASO 2: CREAR ENLACES SIMBÓLICOS DE APLICACIONES
# =================================================================================

print_header "PASO 2: CREAR ENLACES SIMBÓLICOS DE APLICACIONES"

print_step "Creando enlaces desde subdirectorio [APPS]+scripts/..."
SUCCESS_COUNT=0
ERROR_COUNT=0

for FILENAME in "${APPS_SCRIPTS_FILES[@]}"; do
  SOURCE_PATH="$ORIGEN/[APPS]+scripts/$FILENAME"
  DEST_PATH="$ESCRITORIO/$FILENAME"

  if [ -f "$SOURCE_PATH" ]; then
    if ln -s "$SOURCE_PATH" "$DEST_PATH" 2>/dev/null && chmod +x "$DEST_PATH" 2>/dev/null; then
      print_success "$FILENAME"
      ((SUCCESS_COUNT++))
    else
      print_error "No se pudo crear enlace: $FILENAME"
      ((ERROR_COUNT++))
    fi
  else
    print_error "Archivo no existe: $FILENAME"
    ((ERROR_COUNT++))
  fi
done

print_step "Creando enlaces desde directorio raíz..."

for FILENAME in "${ROOT_FILES[@]}"; do
  SOURCE_PATH="$ORIGEN/$FILENAME"
  DEST_PATH="$ESCRITORIO/$FILENAME"

  if [ -f "$SOURCE_PATH" ]; then
    if ln -s "$SOURCE_PATH" "$DEST_PATH" 2>/dev/null && chmod +x "$DEST_PATH" 2>/dev/null; then
      print_success "$FILENAME"
      ((SUCCESS_COUNT++))
    else
      print_error "No se pudo crear enlace: $FILENAME"
      ((ERROR_COUNT++))
    fi
  else
    print_error "Archivo no existe: $FILENAME"
    ((ERROR_COUNT++))
  fi
done

echo ""
print_success "Enlaces creados: $SUCCESS_COUNT"
[ $ERROR_COUNT -gt 0 ] && print_error "Errores: $ERROR_COUNT"

# =================================================================================
# PASO 3: CONFIGURAR CustomRP_Icons PARA WINE
# =================================================================================

print_header "PASO 3: CONFIGURAR CustomRP_Icons PARA WINE"

if [ ! -d "$GDRIVE_ICONS" ]; then
  print_error "Google Drive no montado o carpeta no existe: $GDRIVE_ICONS"
  exit 1
fi

# 3.1: Symlink en el Escritorio (acceso rápido en Nemo)
print_step "Creando symlink en Escritorio..."
if [ -L "$ESCRITORIO/CustomRP_Icons" ] || [ -e "$ESCRITORIO/CustomRP_Icons" ]; then
  rm -rf "$ESCRITORIO/CustomRP_Icons"
fi

if ln -s "$GDRIVE_ICONS" "$ESCRITORIO/CustomRP_Icons" 2>/dev/null; then
  print_success "Symlink creado: ~/Escritorio/CustomRP_Icons"
else
  print_error "No se pudo crear symlink en Escritorio"
fi

# 3.2: Symlink en Wine drive_c (CRÍTICO para CustomRP)
print_step "Creando symlink en Wine C:\\ ..."
if [ -L "$WINE_CUSTOMRP" ] || [ -e "$WINE_CUSTOMRP" ]; then
  rm -rf "$WINE_CUSTOMRP"
fi

if ln -s "$GDRIVE_ICONS" "$WINE_CUSTOMRP" 2>/dev/null; then
  print_success "Symlink creado: C:\\CustomRP_Icons"
  echo -e "  ${BLUE}→${NC} En CustomRP usa: ${GREEN}C:\\CustomRP_Icons\\tuicono.png${NC}"
else
  print_error "No se pudo crear symlink en Wine"
fi

# =================================================================================
# PASO 4: COPIAR ARCHIVOS .crp AL DESKTOP DE WINE
# =================================================================================

print_header "PASO 4: COPIAR ARCHIVOS .crp AL DESKTOP DE WINE"

print_step "Limpiando archivos .crp antiguos..."
rm -f "$WINE_DESKTOP"/*.crp 2>/dev/null
echo "  (Desktop de Wine limpiado)"

print_step "Copiando archivos .crp a Wine Desktop..."
if [ -d "$GDRIVE_ICONS" ]; then
  CRP_COUNT=0
  # Buscar y copiar TODOS los archivos .crp
  while IFS= read -r -d '' crp_file; do
    if cp "$crp_file" "$WINE_DESKTOP/" 2>/dev/null; then
      print_success "$(basename "$crp_file")"
      ((CRP_COUNT++))
    fi
  done < <(find "$GDRIVE_ICONS" -type f -name "*.crp" -print0)

  if [ $CRP_COUNT -gt 0 ]; then
    echo ""
    print_success "Total de archivos .crp copiados: $CRP_COUNT"
    echo -e "  ${BLUE}→${NC} Ubicación: ${GREEN}$WINE_DESKTOP${NC}"
  else
    print_error "No se encontraron archivos .crp en $GDRIVE_ICONS"
  fi
else
  print_error "Carpeta de iconos no accesible"
fi

# =================================================================================
# PASO 5: ACTUALIZAR BASE DE DATOS
# =================================================================================

print_header "PASO 5: ACTUALIZAR BASE DE DATOS"

print_step "Actualizando desktop database..."
update-desktop-database "$ORIGEN" 2>/dev/null
update-desktop-database /home/diego/.local/share/applications 2>/dev/null
print_success "Base de datos actualizada"

# =================================================================================
# RESUMEN FINAL
# =================================================================================

print_header "✅ PROCESO COMPLETADO"

echo ""
echo -e "${GREEN}Archivos en Escritorio:${NC}"
DESKTOP_COUNT=$(find "$ESCRITORIO" -maxdepth 1 -type l -name "*.desktop" 2>/dev/null | wc -l)
echo -e "  • Aplicaciones (.desktop): ${GREEN}$DESKTOP_COUNT${NC}"

if [ -L "$ESCRITORIO/CustomRP_Icons" ]; then
  echo -e "  • CustomRP_Icons: ${GREEN}✓ Enlazado${NC}"
fi

echo ""
echo -e "${GREEN}Archivos en Wine:${NC}"
CRP_TOTAL=$(find "$WINE_DESKTOP" -maxdepth 1 -type f -name "*.crp" 2>/dev/null | wc -l)
echo -e "  • Archivos .crp en Desktop: ${GREEN}$CRP_TOTAL${NC}"

if [ -L "$WINE_CUSTOMRP" ]; then
  ICON_COUNT=$(find "$WINE_CUSTOMRP" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) 2>/dev/null | wc -l)
  echo -e "  • Iconos en C:\\CustomRP_Icons: ${GREEN}$ICON_COUNT${NC}"
fi

echo ""
echo -e "${BLUE}📍 Rutas importantes:${NC}"
echo -e "  • Escritorio Linux: ${GREEN}~/Escritorio/${NC}"
echo -e "  • Wine Desktop: ${GREEN}~/.wine/drive_c/users/diego/Desktop/${NC}"
echo -e "  • CustomRP Icons: ${GREEN}C:\\CustomRP_Icons\\${NC}"

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
