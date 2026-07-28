#!/bin/bash
# Script Integrado para instalar extensiones en Antigravity/VSCode en Linux
# Modificado para permitir extensiones propietarias usando MS Marketplace

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Instalador de Extensiones VSCode/Antigravity (Integrado)${NC}"
echo ""

# Detectar editor disponible
EDITOR=""
if command -v antigravity &>/dev/null; then
  EDITOR="antigravity"
  echo -e "${GREEN}✅ Detectado: Antigravity${NC}"
elif command -v cursor &>/dev/null; then
  EDITOR="cursor"
  echo -e "${GREEN}✅ Detectado: Cursor${NC}"
elif command -v code &>/dev/null; then
  EDITOR="code"
  echo -e "${GREEN}✅ Detectado: VSCode${NC}"
elif command -v codium &>/dev/null; then
  EDITOR="codium"
  echo -e "${GREEN}✅ Detectado: VSCodium${NC}"
else
  echo -e "${RED}❌ Error: No se encontró ningún editor compatible${NC}"
  exit 1
fi

# Archivo de extensiones (localizado en el mismo directorio del script)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
EXTENSIONS_FILE="$SCRIPT_DIR/extensions.txt"

if [ ! -f "$EXTENSIONS_FILE" ]; then
  # Fallback: intentar buscarlo en el directorio actual si se ejecuta desde allí
  if [ -f "extensions.txt" ]; then
    EXTENSIONS_FILE="extensions.txt"
  else
    echo -e "${RED}❌ No se encontró el archivo: extensions.txt en $SCRIPT_DIR${NC}"
    exit 1
  fi
fi

# Contadores
TOTAL=0
SUCCESS=0
FAILED=0

echo ""
echo -e "${BLUE}📦 Instalando extensiones (Total sin filtros)...${NC}"
echo "----------------------------------------"

# Crear archivo de fallos
FAILED_FILE="failed-extensions-integrated.txt"
>"$FAILED_FILE"

while IFS= read -r extension; do
  # Saltar líneas vacías
  if [ -z "$extension" ]; then
    continue
  fi

  TOTAL=$((TOTAL + 1))
  echo -e "${BLUE}[$TOTAL] Instalando: $extension${NC}"

  # Intentamos instalar TODAS las extensiones, confiando en settings.json
  if $EDITOR --install-extension "$extension" --force 2>&1 | tee /tmp/install-output.txt | grep -q "successfully installed\|already installed"; then
    echo -e "  ${GREEN}✅ OK${NC}"
    SUCCESS=$((SUCCESS + 1))
  else
    echo -e "  ${RED}❌ ERROR${NC}"
    echo "$extension" >>"$FAILED_FILE"
    FAILED=$((FAILED + 1))
  fi
  echo ""

done <"$EXTENSIONS_FILE"

# Resumen
echo "=========================================="
echo -e "${BLUE}📊 RESUMEN DE INSTALACIÓN${NC}"
echo "=========================================="
echo -e "Total de extensiones procesadas: ${BLUE}$TOTAL${NC}"
echo -e "✅ Instaladas exitosamente: ${GREEN}$SUCCESS${NC}"
echo -e "❌ Fallidas: ${RED}$FAILED${NC}"
echo ""

if [ $FAILED -gt 0 ]; then
  echo -e "${YELLOW}⚠️  Extensiones que fallaron:${NC}"
  cat "$FAILED_FILE"
fi

echo ""
echo -e "${GREEN}✨ Instalación completada!${NC}"
echo "Reinicia $EDITOR para ver los cambios"
