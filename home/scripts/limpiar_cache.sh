#
# Script interactivo para limpiar caché y dependencias
# Soporta: NixOS (nix-collect-garbage / nix store) y Arch/CachyOS (pacman/yay)

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

# ── Funciones NixOS ──────────────────────────────────────────
df_disk() {
  local _ total usado libre pct
  read -r _ total usado libre pct _ < <(df -h / | tail -1)
  echo -e "${CYAN}💾 Disco: ${usado} usados de ${total} · libres ${libre} (${pct})${RESET}"
}

# La MÁS agresiva: borra TODAS las generaciones viejas de todos los perfiles
# (solo queda la actual -> sin rollback) y luego GC del store completo.
nixos_gc() {
  echo -e "\n${RED}${BOLD}⚡ MODO AGRESIVO: borra TODAS las generaciones viejas (pierdes rollback) + basura del store.${RESET}"
  read -rp "$(echo -e ${YELLOW}➜${RESET}) ¿Continuar? [y/N]: " conf
  [[ "$conf" =~ ^[yY]$ ]] || { echo -e "${DIM}Cancelado.${RESET}"; return; }
  sudo nix-collect-garbage -d
  echo -e "${GREEN}✔ GC completado.${RESET}"
  df_disk
}

# Intermedio: GC completo pero solo borra generaciones más viejas que N días.
# Conserva los rollbacks recientes (lo usado hoy tras un rebuild fallido).
nixos_gc_older() {
  local dias="$1"
  echo -e "\n${YELLOW}⚡ GC moderado: borra generaciones de +${dias} días y toda la basura huérfana del store.${RESET}"
  sudo nix-collect-garbage --delete-older-than "${dias}d"
  echo -e "${GREEN}✔ GC completado.${RESET}"
  df_disk
}

nixos_optimise() {
  echo -e "\n${YELLOW}⚡ Optimizando el store (deduplicación de hardlinks)...${RESET}"
  sudo nix store optimise
  echo -e "${GREEN}✔ Optimización completada.${RESET}"
  df_disk
}

nixos_dryrun() {
  echo -e "\n${YELLOW}⚡ ¿Cuánto liberaría el GC? (dry-run, no borra nada)...${RESET}"
  sudo nix-store --gc --print-dead 2>/dev/null | tail -1 | sed 's/^/   📦 /'
}

while true; do
  clear
  echo -e "${CYAN}${BOLD}"
  echo "╔════════════════════════════════════════════════════════════╗"
  echo "║        ⚙️  Limpiar caché y dependencias - MENÚ             ║"
  echo "╚════════════════════════════════════════════════════════════╝"
  echo -e "${RESET}"
  echo -e "${DIM}Distro: ${GREEN}${IS_NIXOS:+NixOS}${IS_ARCH:+Arch/CachyOS}${RESET}"
  echo ""
  if [[ "$IS_NIXOS" == true ]]; then
    echo -e "${BLUE}  0)${RESET} [NixOS] ${RED}${BOLD}󰀧 GC TOTAL${RESET} ${BOLD}nix-collect-garbage -d${RESET} ${DIM}(sudo · borra TODAS las generaciones viejas)${RESET}"
    echo -e "${BLUE}  b)${RESET} [NixOS] ${BOLD}GC +1 día${RESET} ${DIM}(--delete-older-than 1d · conserva rollback de hoy)${RESET}"
    echo -e "${BLUE}  c)${RESET} [NixOS] ${BOLD}GC +7 días${RESET} ${DIM}(--delete-older-than 7d)${RESET}"
    echo -e "${BLUE}  9)${RESET} [NixOS] ${BOLD}nix store optimise${RESET} ${DIM}(sudo · deduplica hardlinks)${RESET}"
    echo -e "${BLUE}  a)${RESET} [NixOS] ${DIM}dry-run: cuánto liberaría el GC${RESET}"
  fi
  if [[ "$IS_ARCH" == true ]]; then
    echo -e "${BLUE}  1)${RESET} Limpiar caché de pacman ${BOLD}󰮯${RESET} ${DIM}(sudo)${RESET}"
    echo -e "${BLUE}  2)${RESET} Eliminar dependencias huérfanas de pacman ${BOLD}󰮯${RESET} ${DIM}(sudo)${RESET}"
    echo -e "${BLUE}  3)${RESET} Limpiar caché y dependencias huérfanas de yay ${BOLD}${RESET}"
  fi
  echo -e "${BLUE}  4)${RESET} Limpiar caches de npm/yarn/pnpm ${BOLD}󰎙${RESET}"
  echo -e "${BLUE}  5)${RESET} Limpiar ~/.cache completo ${BOLD}󰃨${RESET}"
  echo -e "${BLUE}  6)${RESET} Limpiar caché de neovim ${BOLD}${RESET}"
  echo -e "${BLUE}  7)${RESET} ${RED}${BOLD}󰀧[PELIGRO!!!]󰀦${RESET} Reinstalar Plugins de Neovim ${BOLD}♻️${RESET} ${DIM}(depurar/downgrade)${RESET}"
  echo -e "${BLUE}  8)${RESET} Salir ${BOLD}󰩈${RESET}"
  echo ""
  echo -e "${DIM}────────────────────────────────────────────────────────────${RESET}"
  read -rp "$(echo -e ${GREEN}${BOLD}➜${RESET}) Selecciona una opción: " opcion

  case $opcion in
  0)
    nixos_gc
    notify-send "🗑️ NIX GC" 'nix-collect-garbage -d completado  🎨'
    ;;
  9)
    nixos_optimise
    notify-send "🗑️ NIX Optimise" 'nix store optimise completado  🎨'
    ;;
  a)
    nixos_dryrun
    ;;
  b)
    nixos_gc_older 1
    notify-send "🗑️ NIX GC (+1d)" 'Generaciones >1 día eliminadas, rollbacks de hoy intactos  🎨'
    ;;
  c)
    nixos_gc_older 7
    notify-send "🗑️ NIX GC (+7d)" 'Generaciones >7 días eliminadas  🎨'
    ;;
  1)
    echo -e "\n${YELLOW}⚡ Limpiando caché de pacman...${RESET}"
    sudo rm -rf /var/cache/pacman/pkg/download-* 2>/dev/null || true
    sudo pacman -Scc
    notify-send "🗑️ PACMAN Cache" 'Recuerda reaplicar fondos y ajustar QT5/QT6, lxa y nwglook  🎨'
    ;;
  2)
    echo -e "\n${YELLOW}⚡ Eliminando dependencias huérfanas de pacman...${RESET}"
    orphans=$(pacman -Qdtq 2>/dev/null)
    if [ -n "$orphans" ]; then
      sudo pacman -Rns $orphans
    else
      echo -e "${DIM}✔ No hay dependencias huérfanas de pacman.${RESET}"
    fi
    notify-send "🗑️ Pacman Huérfanas" 'Recuerda reaplicar fondos y ajustar QT5/QT6, lxa y nwglook  🎨'
    ;;
  3)
    echo -e "\n${YELLOW}⚡ Eliminando dependencias huérfanas y caché de yay...${RESET}"
    sudo rm -rf /var/cache/pacman/pkg/download-* 2>/dev/null || true
    yay -Scc
    rm -rf ~/.cache/yay
    orphans=$(yay -Qdtq 2>/dev/null)
    if [ -n "$orphans" ]; then
      yay -Rns $orphans
    else
      echo -e "${DIM}✔ No hay dependencias huérfanas de yay.${RESET}"
    fi
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
    sudo rm -rf ~/.cache/waydroid-script/ 2>/dev/null || true
    rm -rf ~/.cache/*
    rm -rf ~/assets/
    rm -rf ~/.bun/install/cache/
    rm -rf $HOME/.docker/desktop/vms/ 2>/dev/null || true # ✅
    # Brave
    rm -rf ~/.config/BraveSoftware/Brave-Browser/Default/Cache
    rm -rf ~/.cache/BraveSoftware

    # Python & NPM
    rm -rf $HOME/.pyenv/versions/3.11.9/lib/python3.11/test/__pycache__/
    rm -rf $HOME/.npm/_cacache/

    # Firefox
    find ~/.mozilla/firefox/*.default*/cache2 -type f -delete 2>/dev/null || true
    rm -rf ~/.mozilla/firefox/*.default*/cache2 2>/dev/null || true
    flatpak uninstall --unused
    rm -rf ~/.var/app/*/cache/*
    sudo journalctl --vacuum-size=50M
    rm -rf ~/.config/{Cursor,discord,Slack}/{Cache,Code\ Cache,GPUCache}/
    rm -rf $HOME/.local/share/Trash/files/* 2>/dev/null || true # ✅ Solo contenido
    # sudo rm -rf /tmp/
    if docker info >/dev/null 2>&1; then
      docker system prune -af
      docker builder prune
    else
      echo -e "${DIM}⚠️  Docker no está corriendo, omitiendo limpieza de docker.${RESET}"
    fi

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
    # rm -rf ~/.local/share/nvim/mason
    # rm -rf ~/.local/state/nvim/mason.log
    # REINSTALAR AVANTE
    if [ -d ~/.local/share/nvim/lazy/avante.nvim ] 2>/dev/null; then
      cd ~/.local/share/nvim/lazy/avante.nvim
      make 2>/dev/null || true
      echo -e "${GREEN}✅ Plantillas Restauradas..${RESET}"
    fi

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
