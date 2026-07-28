#!/bin/bash
# fix-ydotool.sh
# Arregla el problema del socket de ydotool

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🔧 ARREGLANDO YDOTOOL SOCKET 🔧               ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════╝${NC}"
echo

# ═══════════════════════════════════════════════════════════
# 1. DETENER SERVICIOS EXISTENTES
# ═══════════════════════════════════════════════════════════
echo -e "${YELLOW}[1/5]${NC} Deteniendo servicios existentes..."
systemctl --user stop ydotool.service 2>/dev/null || true
pkill ydotoold 2>/dev/null || true
sleep 1

# ═══════════════════════════════════════════════════════════
# 2. LIMPIAR SOCKETS VIEJOS
# ═══════════════════════════════════════════════════════════
echo -e "${YELLOW}[2/5]${NC} Limpiando sockets viejos..."
rm -f /tmp/.ydotool_socket
rm -f /run/user/1000/.ydotool_socket
rm -f ~/.ydotool_socket

# ═══════════════════════════════════════════════════════════
# 3. CREAR SERVICIO SYSTEMD CORRECTO
# ═══════════════════════════════════════════════════════════
echo -e "${YELLOW}[3/5]${NC} Creando servicio systemd correcto..."
mkdir -p ~/.config/systemd/user

cat >~/.config/systemd/user/ydotool.service <<'EOF'
[Unit]
Description=ydotool daemon
After=default.target

[Service]
Type=simple
ExecStart=/usr/bin/ydotoold --socket-path=/tmp/.ydotool_socket --socket-perm=0600
Restart=always
RestartSec=3

[Install]
WantedBy=default.target
EOF

# ═══════════════════════════════════════════════════════════
# 4. CONFIGURAR VARIABLE DE ENTORNO
# ═══════════════════════════════════════════════════════════
echo -e "${YELLOW}[4/5]${NC} Configurando variable de entorno..."

# Eliminar entradas viejas
sed -i '/YDOTOOL_SOCKET/d' ~/.zshrc 2>/dev/null || true
sed -i '/YDOTOOL_SOCKET/d' ~/.bashrc 2>/dev/null || true

# Agregar nueva entrada
echo 'export YDOTOOL_SOCKET=/tmp/.ydotool_socket' >> ~/.zshrc
echo 'export YDOTOOL_SOCKET=/tmp/.ydotool_socket' >> ~/.bashrc

# Aplicar ahora
export YDOTOOL_SOCKET=/tmp/.ydotool_socket

# ═══════════════════════════════════════════════════════════
# 5. INICIAR SERVICIO
# ═══════════════════════════════════════════════════════════
echo -e "${YELLOW}[5/5]${NC} Iniciando servicio ydotool..."
systemctl --user daemon-reload
systemctl --user enable ydotool.service
systemctl --user start ydotool.service

# Esperar a que se cree el socket
echo -e "${CYAN}Esperando socket...${NC}"
for i in {1..10}; do
  if [[ -S /tmp/.ydotool_socket ]]; then
    echo -e "${GREEN}✅ Socket creado correctamente${NC}"
    break
  fi
  sleep 1
done

# ═══════════════════════════════════════════════════════════
# VERIFICACIÓN
# ═══════════════════════════════════════════════════════════
echo
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo -e "${CYAN}VERIFICACIÓN:${NC}"
echo

# Verificar servicio
if systemctl --user is-active --quiet ydotool.service; then
  echo -e "${GREEN}✅ Servicio ydotool: ${BOLD}ACTIVO${NC}"
else
  echo -e "${RED}❌ Servicio ydotool: ${BOLD}INACTIVO${NC}"
fi

# Verificar socket
if [[ -S /tmp/.ydotool_socket ]]; then
  echo -e "${GREEN}✅ Socket: ${BOLD}/tmp/.ydotool_socket${NC}"
else
  echo -e "${RED}❌ Socket no encontrado${NC}"
fi

# Verificar variable de entorno
if [[ "$YDOTOOL_SOCKET" == "/tmp/.ydotool_socket" ]]; then
  echo -e "${GREEN}✅ Variable YDOTOOL_SOCKET: ${BOLD}$YDOTOOL_SOCKET${NC}"
else
  echo -e "${YELLOW}⚠️  Variable YDOTOOL_SOCKET no configurada${NC}"
  echo -e "${CYAN}   Ejecuta: ${YELLOW}source ~/.zshrc${NC}"
fi

# Test básico
echo
echo -e "${CYAN}Test de funcionamiento:${NC}"
if YDOTOOL_SOCKET=/tmp/.ydotool_socket ydotool key 29:1 29:0 2>/dev/null; then
  echo -e "${GREEN}✅ ydotool funciona correctamente${NC}"
else
  echo -e "${RED}❌ ydotool no responde${NC}"
  echo -e "${YELLOW}Logs del servicio:${NC}"
  journalctl --user -u ydotool.service -n 20 --no-pager
fi

echo
echo -e "${GREEN}${BOLD}✨ ARREGLO COMPLETADO ✨${NC}"
echo
echo -e "${CYAN}Próximos pasos:${NC}"
echo -e "  1. ${YELLOW}source ~/.zshrc${NC}  (aplicar variables de entorno)"
echo -e "  2. ${YELLOW}autoclicker${NC}      (probar autoclicker)"
echo -e "  3. ${YELLOW}autopress${NC}        (probar autopress)"
echo
