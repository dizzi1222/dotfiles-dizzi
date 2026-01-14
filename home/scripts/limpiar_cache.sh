#!/bin/bash
# Script interactivo para limpiar caché y dependencias en Arch Linux + yay

# Colores y formato
RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
CYAN='\033[96m'
GREEN='\033[92m'
YELLOW='\033[93m'
RED='\033[91m'
BLUE='\033[94m'
MAGENTA='\033[95m'

while true; do
  clear
  echo -e "${CYAN}${BOLD}"
  echo "╔════════════════════════════════════════════════════════════╗"
  echo "║        ⚙️  Limpiar caché y dependencias - MENÚ             ║"
  echo "╚════════════════════════════════════════════════════════════╝"
  echo -e "${RESET}"
  echo -e "${BLUE}  1)${RESET} Limpiar caché de pacman ${BOLD}󰮯${RESET} ${DIM}(sudo)${RESET}"
  echo -e "${BLUE}  2)${RESET} Eliminar dependencias huérfanas de pacman ${BOLD}󰮯${RESET} ${DIM}(sudo)${RESET}"
  echo -e "${BLUE}  3)${RESET} Limpiar caché y dependencias huérfanas de yay ${BOLD}${RESET}"
  echo -e "${BLUE}  4)${RESET} Limpiar caches de npm/yarn/pnpm ${BOLD}󰎙${RESET}"
  echo -e "${BLUE}  5)${RESET} Limpiar ~/.cache completo ${BOLD}󰃨${RESET}"
  echo -e "${BLUE}  6)${RESET} Limpiar caché de neovim ${BOLD}${RESET}"
  echo -e "${BLUE}  7)${RESET} ${RED}${BOLD}󰀧[PELIGRO!!!]󰀦${RESET} Reinstalar Plugins de Neovim ${BOLD}♻️${RESET} ${DIM}(depurar/downgrade)${RESET}"
  echo -e "${BLUE}  8)${RESET} Salir ${BOLD}󰩈${RESET}"
  echo ""
  echo -e "${DIM}────────────────────────────────────────────────────────────${RESET}"
  read -rp "$(echo -e ${GREEN}${BOLD}➜${RESET}) Selecciona una opción: " opcion

  case $opcion in
  1)
    echo -e "\n${YELLOW}⚡ Limpiando caché de pacman...${RESET}"
    sudo pacman -Scc
    notify-send "🗑️ PACMAN Cache" 'Recuerda reaplicar fondos y ajustar QT5/QT6, lxa y nwglook  🎨'
    ;;
  2)
    echo -e "\n${YELLOW}⚡ Eliminando dependencias huérfanas de pacman...${RESET}"
    sudo pacman -Rns $(pacman -Qdtq)
    notify-send "🗑️ Pacman Huérfanas" 'Recuerda reaplicar fondos y ajustar QT5/QT6, lxa y nwglook  🎨'
    ;;
  3)
    echo -e "\n${YELLOW}⚡ Eliminando dependencias huérfanas y caché de yay...${RESET}"
    yay -Scc
    rm -rf ~/.cache/yay
    yay -Rns $(yay -Qdtq)
    notify-send "🗑️ YAY Cache" 'Recuerda reaplicar fondos y ajustar QT5/QT6, lxa y nwglook  🎨'
    ;;
  4)
    echo -e "\n${YELLOW}⚡ Limpiando pnpm, npm y yarn...${RESET}"
    pnpm store prune
    npm cache clean --force
    yarn cache clean
    notify-send "🗑️ NPM Cache" 'Recuerda reaplicar fondos y ajustar QT5/QT6, lxa y nwglook  🎨'
    ;;
  5)
    echo -e "\n${YELLOW}⚡ Limpiando ~/.cache completo...${RESET}"
    rm -rf ~/.cache/*
    flatpak uninstall --unused
    rm -rf ~/.var/app/*/cache/*
    sudo journalctl --vacuum-size=50M
    notify-send "🗑️ CACHE COMPLETO" 'Recuerda reaplicar fondos y ajustar QT5/QT6, lxa y nwglook  🎨'
    ;;
  6)
    echo -e "\n${YELLOW}⚡ Limpiando caché de neovim...${RESET}"
    rm -rf ~/.local/share/nvim/backup
    rm -rf ~/.local/share/nvim/swap
    rm -rf ~/.local/share/nvim/undo
    notify-send "🗑️ Neovim Cache" 'Recuerda reaplicar fondos y ajustar QT5/QT6, lxa y nwglook  🎨'
    ;;
  7)
    echo -e "\n${RED}${BOLD}⚠️  Reinstalando todos los plugins de Neovim...${RESET}"
    echo -e "${DIM}Esto fuerza la descarga de repositorios: útil para depurar updates, cambiar nombres de repo (como Supermaven) o forzar un downgrade.${RESET}"
    # Elimina el directorio de plugins y caché de Lazy/Packer
    rm -rf ~/.local/share/nvim/{lazy,packer,site,lspconfig,log} # limpieza selectiva
    # rm -rf ~/.local/share/nvim                                  # limpieza total
    echo -e "${MAGENTA}Directorio de plugins borrado. Los plugins se reinstalarán al abrir Neovim.${RESET}"
    notify-send "🔄 Plugins Neovim Eliminados" \
      'Abre NVIM y ejecuta :Lazy sync o :PackerSync para reinstalar todos los plugins.'
    # nvim & # <--- Se ejecuta en background, el script continúa inmediatamente
    ;;
  8)
    echo -e "\n${CYAN}👋 Saliendo...${RESET}"
    exit 0
    ;;
  *)
    echo -e "\n${RED}❌ Opción no válida.${RESET}"
    ;;
  esac

  echo -e "\n${GREEN}${BOLD}✅ Operación completada.${RESET}"
  read -rp "$(echo -e ${DIM})Presiona Enter para volver al menú...$(echo -e ${RESET})"
done
