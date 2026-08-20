#!/bin/bash
# ══════════════════════════════════════════════════════════════════════════════
# waydroid-bd2.sh — Lanza Waydroid + Phantom para Brown Dust 2
# Ubicación: ~/scripts/waydroid-bd2.sh (stow → dotfiles-dizzi/home/scripts/)
# ══════════════════════════════════════════════════════════════════════════════

PHANTOM_PROFILE="$HOME/.config/phantom/profiles/brown-dust-2.json"

# ─── Colores ─────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

echo -e "${CYAN}╔══════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║   🎮 Brown Dust 2 - Waydroid Launcher    ║${RESET}"
echo -e "${CYAN}╚══════════════════════════════════════════╝${RESET}"
echo ""

# ─── Verificar Waydroid ──────────────────────────────────────────────
echo -e "${CYAN}[1/3] Verificando Waydroid...${RESET}"
sudo waydroid status 2>/dev/null | grep -q "RUNNING"
if [ $? -ne 0 ]; then
  echo -e "${YELLOW}Waydroid no corriendo, iniciando...${RESET}"
  waydroid show-full-ui &
  sleep 12
fi
echo -e "${GREEN}✅ Waydroid listo${RESET}"

# ─── Phantom daemon ──────────────────────────────────────────────────
echo -e "${CYAN}[2/3] Arrancando Phantom daemon...${RESET}"
sudo pkill phantom 2>/dev/null
sudo phantom --daemon &
sleep 3

if [ -f "$PHANTOM_PROFILE" ]; then
  phantom load "$PHANTOM_PROFILE"
  phantom enter-capture 2>/dev/null
  echo -e "${GREEN}✅ Perfil cargado: brown-dust-2.json${RESET}"
else
  echo -e "${YELLOW}⚠️  Perfil no encontrado. Créalo con phantom-gui.${RESET}"
fi

echo -e "${GREEN}[3/3] ✅ Todo listo. Brown Dust 2 debería responder.${RESET}"
echo ""
echo -e "${CYAN}Controles:  F1=menú/apuntar  F8=captura  F10=overlay  F2=salir${RESET}"
echo -e "${YELLOW}Cierra esta terminal cuando termines de jugar.${RESET}"
echo ""
read -rp "Presiona Enter para salir y limpiar..."

# ─── Cleanup ─────────────────────────────────────────────────────────
echo -e "${CYAN}Limpiando...${RESET}"
phantom exit-capture 2>/dev/null
phantom shutdown 2>/dev/null
sudo pkill phantom 2>/dev/null
echo -e "${GREEN}✅ Hecho.${RESET}"
