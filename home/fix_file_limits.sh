#!/bin/bash
# Fix: Too many open files - Script mejorado

# Colores ANSI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Icono para notificación
ICON="📁"

echo -e "${CYAN}${BOLD}╔════════════════════════════════════════╗${NC}"
echo -e "${CYAN}${BOLD}║  FIX: Too Many Open Files              ║${NC}"
echo -e "${CYAN}${BOLD}╚════════════════════════════════════════╝${NC}"
echo ""

# 1. Configurar límites del sistema
echo -e "${YELLOW}[1/5]${NC} Configurando límites del sistema..."
sudo tee /etc/sysctl.d/99-file-limits.conf >/dev/null <<EOF
fs.file-max = 2097152
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 512
EOF
echo -e "${GREEN}✓${NC} Archivo creado: ${BLUE}/etc/sysctl.d/99-file-limits.conf${NC}"

# 2. Configurar límites de usuario
echo -e "${YELLOW}[2/5]${NC} Configurando límites de usuario..."
sudo tee /etc/security/limits.d/99-nofile.conf >/dev/null <<EOF
*    soft nofile 524288
*    hard nofile 524288
root soft nofile 524288
root hard nofile 524288
EOF
echo -e "${GREEN}✓${NC} Archivo creado: ${BLUE}/etc/security/limits.d/99-nofile.conf${NC}"

# 3. Configurar systemd user
echo -e "${YELLOW}[3/5]${NC} Configurando systemd user..."
sudo mkdir -p /etc/systemd/user.conf.d/
sudo tee /etc/systemd/user.conf.d/limits.conf >/dev/null <<EOF
[Manager]
DefaultLimitNOFILE=524288
EOF
echo -e "${GREEN}✓${NC} Archivo creado: ${BLUE}/etc/systemd/user.conf.d/limits.conf${NC}"

# 4. Configurar systemd system
echo -e "${YELLOW}[4/5]${NC} Configurando systemd system..."
sudo mkdir -p /etc/systemd/system.conf.d/
sudo tee /etc/systemd/system.conf.d/limits.conf >/dev/null <<EOF
[Manager]
DefaultLimitNOFILE=524288
EOF
echo -e "${GREEN}✓${NC} Archivo creado: ${BLUE}/etc/systemd/system.conf.d/limits.conf${NC}"

# 5. Aplicar cambios
echo -e "${YELLOW}[5/5]${NC} Aplicando cambios al kernel..."
sudo sysctl -p /etc/sysctl.d/99-file-limits.conf >/dev/null
echo -e "${GREEN}✓${NC} Cambios aplicados"

echo ""
echo -e "${GREEN}${BOLD}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}  ✓ CONFIGURACIÓN COMPLETADA EXITOSAMENTE${NC}"
echo -e "${GREEN}${BOLD}═══════════════════════════════════════════${NC}"
echo ""
echo -e "${PURPLE}Límite anterior:${NC} ${RED}1024${NC}"
echo -e "${PURPLE}Límite nuevo:${NC}    ${GREEN}524288${NC} ${BOLD}(512K)${NC}"
echo ""
echo -e "${YELLOW}⚠  IMPORTANTE:${NC} ${BOLD}Debes reiniciar el sistema${NC} para aplicar todos los cambios"
echo ""
echo -e "${CYAN}Después del reinicio, verifica con:${NC}"
echo -e "  ${BLUE}ulimit -n${NC}  ${PURPLE}# Debe mostrar 524288${NC}"

# Notificación
notify-send -u critical -i system-file-manager \
  "$ICON File Limits Fixed" \
  "Límites aumentados: 1024 → 524288\n⚠ Reinicia para aplicar cambios"

# Echo final con color
echo ""
echo -e "${CYAN}${ICON} ${GREEN}${BOLD}Limites de Archivo aumentados de: ${RED}1024${NC} ${GREEN}${BOLD}→${NC} ${GREEN}${BOLD}524288${NC} ${GREEN}[fixed]${NC} 󰄭"
