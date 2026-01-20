#
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
    echo -e "\n${YELLOW}⚡ Limpiando ~/.cache completo [& journalctl, docker, electron]...${RESET}"
    # -- Lo mas pesado
    rm -rf ~/.cache/*
    rm -rf ~/.bun/install/cache/
    $HOME/.docker/desktop/vms/
    # Brave
    rm -rf ~/.config/BraveSoftware/Brave-Browser/Default/Cache
    rm -rf ~/.cache/BraveSoftware

    # Python & NPM
    rm -rf $HOME/.pyenv/versions/3.11.9/lib/python3.11/test/__pycache__/
    rm -rf $HOME/.npm/_cacache/

    # Firefox
    rm -rf ~/.mozilla/firefox/*.default*/cache2
    flatpak uninstall --unused
    rm -rf ~/.var/app/*/cache/*
    sudo journalctl --vacuum-size=50M
    rm -rf ~/.config/{Cursor,discord,Slack}/{Cache,Code\ Cache,GPUCache}/
    $HOME/.local/share/Trash/files/
    sudo rm -rf /tmp/
    docker system prune -af
    docker builder prune

    notify-send "🗑️ CACHE COMPLETO" 'Recuerda reaplicar fondos [Windows + B] 󰸉  y ajustar QT5/QT6, lxa y nwglook  🎨'
    ;;
  6)
    echo -e "\n${YELLOW}⚡ Limpiando caché de neovim...${RESET}"
    rm -rf ~/.local/share/nvim/backup
    rm -rf ~/.local/share/nvim/swap
    rm -rf ~/.local/share/nvim/undo

    notify-send "🗑️ Neovim Cache" 'Clean  🎨'
    ;;
  7)
    echo -e "\n${RED}${BOLD}⚠️  Reinstalando todos los plugins de Neovim...${RESET}"
    echo -e "${DIM}Esto fuerza la descarga de repositorios: útil para depurar updates, cambiar nombres de repo (como Supermaven) o forzar un downgrade.${RESET}"
    # Elimina el directorio de plugins y caché de Lazy/Packer
    rm -rf ~/.local/share/nvim/{lazy,packer,site,lspconfig,log} # limpieza selectiva

    # En WSL/Linux
    rm -rf ~/.local/share/nvim/mason
    rm -rf ~/.local/state/nvim/mason.log

    # Detectar qué gestor de paquetes está disponible e instalar tree-sitter-cli
    if command -v npm >/dev/null 2>&1; then
      echo -e "${YELLOW}📦 Instalando tree-sitter-cli con npm...${RESET}"
      npm install -g tree-sitter-cli
    elif command -v cargo >/dev/null 2>&1; then
      echo -e "${YELLOW}📦 Instalando tree-sitter-cli con cargo...${RESET}"
      cargo install tree-sitter-cli
    elif command -v yarn >/dev/null 2>&1; then
      echo -e "${YELLOW}📦 Instalando tree-sitter-cli con yarn...${RESET}"
      yarn global add tree-sitter-cli
    elif command -v pipx >/dev/null 2>&1; then
      echo -e "${YELLOW}📦 Instalando tree-sitter-cli con pipx...${RESET}"
      pipx install tree-sitter-cli
    else
      echo -e "${RED}⚠️  No se encontró npm, cargo, yarn ni pipx.${RESET}"
      echo -e "${YELLOW}Por favor, instala tree-sitter-cli manualmente.${RESET}"
    fi
    echo -e "${MAGENTA}Directorio de plugins borrado. Los plugins se reinstalarán al abrir Neovim.${RESET}"
    notify-send "🔄 Plugins Neovim Eliminados" \
      'Abre NVIM y ejecuta :Lazy sync o :PackerSync para reinstalar todos los plugins.'
    echo -e "${MAGENTA}  :MasonInstall lua-language-server typescript-language-server json-lsp eslint-lsp angular-language-server marksman${RESET}"

    # nvim & # <--- Se ejecuta en background, el script continúa inmediatamente
    # CASO EXTREMO NO RECOMENDADO! Solo si falla continuamente Mason
    # rm -rf ~/.local/share/nvim                                  # limpieza total
    # rm -rf ~/.local/share/nvim/lazy
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
