#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# TERMUX BÁSICO SETUP - Adaptado de fase2-HyprInstall-full.sh
# ═══════════════════════════════════════════════════════════════════════════════
# Autor: Diego Dizzi
# Fecha: 2026-02-01
# Descripción: Instalación de herramientas CLI básicas para Termux en Android
# Nota: Termux usa pkg (basado en APT/Debian), no pacman
# Probado en: Xiaomi (arm64)
# ═══════════════════════════════════════════════════════════════════════════════

set -e

# ═══════════════════════════════════════════════════════════
# COLORES
# ═══════════════════════════════════════════════════════════
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ═══════════════════════════════════════════════════════════
# FUNCIONES HELPER
# ═══════════════════════════════════════════════════════════
print_header() {
  echo
  echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════════${NC}"
  echo -e "${CYAN}${BOLD}  $1${NC}"
  echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════════${NC}"
  echo
}

print_step() {
  echo -e "\n${MAGENTA}${BOLD}▶ PASO $1${NC}"
}

print_installing() {
  echo -e "${BLUE}  📦 Instalando: ${YELLOW}$1${NC}"
}

print_success() {
  echo -e "${GREEN}  ✅ $1${NC}"
}

print_warning() {
  echo -e "${YELLOW}  ⚠️  $1${NC}"
}

print_error() {
  echo -e "${RED}  ❌ $1${NC}"
}

print_info() {
  echo -e "${CYAN}  ℹ️  $1${NC}"
}

# ═══════════════════════════════════════════════════════════
# VERIFICACIONES
# ═══════════════════════════════════════════════════════════
if [[ ! -d /data/data/com.termux ]]; then
  print_error "Este script debe ejecutarse en Termux"
  exit 1
fi

# ═══════════════════════════════════════════════════════════
# INICIO
# ═══════════════════════════════════════════════════════════
clear
cat <<'EOF'

  ████████╗███████╗██████╗ ███╗   ███╗██╗   ██╗██╗  ██╗
  ╚══██╔══╝██╔════╝██╔══██╗████╗ ████║██║   ██║╚██╗██╔╝
     ██║   █████╗  ██████╔╝██╔████╔██║██║   ██║ ╚███╔╝
     ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║██║   ██║ ██╔██╗
     ██║   ███████╗██║  ██║██║ ╚═╝ ██║╚██████╔╝██╔╝ ██╗
     ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝

╔══════════════════════════════════════════════════════════════════════╗
║           📱 TERMUX BÁSICO SETUP - Diego Dizzi Edition 📱           ║
╠══════════════════════════════════════════════════════════════════════╣
║  Herramientas CLI esenciales para Termux en Android (Xiaomi)         ║
║  Basado en: fase2-HyprInstall-full.sh (adaptado)                     ║
╚══════════════════════════════════════════════════════════════════════╝

EOF

echo -e "${YELLOW}${BOLD}[!] IMPORTANTE:${NC}"
echo -e "${CYAN}  • Termux usa 'pkg' (APT/Debian), no pacman${NC}"
echo -e "${CYAN}  • Muchos paquetes gráficos NO existen para Android${NC}"
echo -e "${CYAN}  • Este script instala SOLO herramientas CLI compatibles${NC}"
echo
read -p "Presiona Enter para continuar o Ctrl+C para cancelar..."

# ═══════════════════════════════════════════════════════════
# PASO 1: ACTUALIZAR REPOSITORIOS Y PERMISOS
# ═══════════════════════════════════════════════════════════
print_step "1/13: Actualizar Sistema"
print_installing "Actualizando repositorios"
pkg update -y && pkg upgrade -y
print_success "Sistema actualizado"

# Permisos de almacenamiento (importante para acceder a /sdcard)
print_info "Otorgando permisos de almacenamiento..."
termux-setup-storage 2>/dev/null || print_warning "Ejecuta 'termux-setup-storage' manualmente si falla"

# ═══════════════════════════════════════════════════════════
# PASO 2: HERRAMIENTAS BÁSICAS
# ═══════════════════════════════════════════════════════════
print_step "2/13: Herramientas Básicas"
print_installing "Git, curl, wget, openssh, coreutils"
pkg install -y \
  git curl wget openssh \
  coreutils findutils grep sed gawk \
  tar gzip bzip2 xz-utils unzip zip \
  procps less man \
  ncurses-utils termux-api

print_success "Herramientas básicas instaladas"

# ═══════════════════════════════════════════════════════════
# PASO 3: DESARROLLO (Esenciales para Neovim)
# ═══════════════════════════════════════════════════════════
print_step "3/13: Herramientas de Desarrollo (Esenciales para Neovim)"
print_installing "Python, pip, Node.js, Rust, Go, Clang (para LSP/Mason)"

pkg install -y \
  clang make cmake \
  python python-pip \
  nodejs-lts \
  rust \
  golang

# Instalar paquetes pip útiles para Neovim
print_installing "pynvim (requerido por Neovim)"
pip install pynvim 2>/dev/null || print_warning "pynvim falló, intenta: pip install pynvim"

# Runtime de sweep.nvim (proxy llama-cpp-python en :5555). Nix Only en NixOS;
# en termux se instala por pip.
print_installing "sweep.nvim runtime (llama-cpp-python)"
pip install llama-cpp-python fastapi uvicorn 2>/dev/null || print_warning "sweep runtime falló, intenta: pip install llama-cpp-python fastapi uvicorn"

# Instalar neovim npm provider
print_installing "neovim npm provider"
npm install -g neovim 2>/dev/null || print_warning "neovim npm falló"

print_success "Herramientas de desarrollo instaladas"
print_info "  • Python + pip → providers Neovim"
print_info "  • Node.js     → Mason, Copilot, LSPs"
print_info "  • Rust        → ripgrep, fd, stylua, etc."
print_info "  • Go          → gopls, gofumpt"

# ═══════════════════════════════════════════════════════════
# PASO 4: EDITORES DE TEXTO
# ═══════════════════════════════════════════════════════════
print_step "4/13: Editores de Texto"
print_installing "Neovim, Vim, Nano, Micro"

pkg install -y \
  neovim vim nano micro

print_success "Editores instalados"
print_info "Tip: Usa 'nvim' para Neovim moderno"

# ═══════════════════════════════════════════════════════════
# PASO 5: UTILIDADES CLI MODERNAS
# ═══════════════════════════════════════════════════════════
print_step "5/13: Utilidades CLI Modernas"
print_installing "bat, eza, fd, ripgrep, fzf, zoxide, jq"

pkg install -y \
  bat eza fd ripgrep fzf \
  jq tree htop \
  ncdu duf dust

# zoxide (si disponible)
pkg install -y zoxide 2>/dev/null || print_warning "zoxide no disponible, omitiendo..."

print_success "Utilidades modernas instaladas"
print_info "  • bat = cat mejorado con syntax highlighting"
print_info "  • eza = ls mejorado con íconos"
print_info "  • fd = find rápido"
print_info "  • ripgrep (rg) = grep ultrarrápido"
print_info "  • fzf = fuzzy finder"

# ═══════════════════════════════════════════════════════════
# PASO 6: ZSH + OH-MY-ZSH (Configuración completa)
# ═══════════════════════════════════════════════════════════
print_step "6/13: Zsh + Oh-My-Zsh (Completo)"

echo
read -p "¿Instalar Zsh + Oh-My-Zsh + Plugins completos? [S/n]: " install_zsh

if [[ ! "$install_zsh" =~ ^[Nn]$ ]]; then
  print_installing "Zsh"
  pkg install -y zsh

  # Limpiar plugins antiguos del sistema
  print_status "Limpiando plugins antiguos..."
  rm -rf ~/.oh-my-zsh/custom/plugins/zsh-* 2>/dev/null || true
  rm -rf ~/.zsh/zsh-autocomplete 2>/dev/null || true
  rm -rf ~/.zsh/fzf-tab 2>/dev/null || true

  # Instalar Oh My Zsh
  print_installing "Oh-My-Zsh"
  if [[ ! -d ~/.oh-my-zsh ]]; then
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    print_success "Oh-My-Zsh instalado"
  else
    print_warning "Oh-My-Zsh ya instalado"
  fi

  ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  # Instalar Powerlevel10k theme
  print_installing "Powerlevel10k theme"
  if [[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
      "$ZSH_CUSTOM/themes/powerlevel10k"
    print_success "Powerlevel10k instalado"
  else
    print_warning "Powerlevel10k ya instalado"
  fi

  # Plugins Oh My Zsh Custom
  print_installing "Plugins: zsh-syntax-highlighting"
  if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
    git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git \
      "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  fi

  print_installing "Plugins: zsh-autosuggestions"
  if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
    git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions.git \
      "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  fi

  print_installing "Plugins: zsh-completions"
  if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-completions" ]]; then
    git clone --depth 1 https://github.com/zsh-users/zsh-completions.git \
      "$ZSH_CUSTOM/plugins/zsh-completions"
  fi

  print_installing "Plugins: zsh-history-substring-search"
  if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-history-substring-search" ]]; then
    git clone --depth 1 https://github.com/zsh-users/zsh-history-substring-search.git \
      "$ZSH_CUSTOM/plugins/zsh-history-substring-search"
  fi

  # Plugins externos en ~/.zsh
  mkdir -p ~/.zsh

  print_installing "Plugins: zsh-autocomplete"
  if [[ ! -d ~/.zsh/zsh-autocomplete ]]; then
    git clone --depth 1 https://github.com/marlonrichert/zsh-autocomplete.git \
      ~/.zsh/zsh-autocomplete
  fi

  print_installing "Plugins: fzf-tab"
  if [[ ! -d ~/.zsh/fzf-tab ]]; then
    git clone --depth 1 https://github.com/Aloxaf/fzf-tab.git \
      ~/.zsh/fzf-tab
  fi

  # Backup .zshrc existente si no es symlink
  if [[ -f ~/.zshrc ]] && [[ ! -L ~/.zshrc ]]; then
    mv ~/.zshrc ~/.zshrc.bak
    print_info "Backup de .zshrc en ~/.zshrc.bak"
  fi

  # Configurar .zshrc con todos los plugins
  print_status "Configurando .zshrc con plugins..."
  cat > ~/.zshrc <<'ZSHRC'
# ═══════════════════════════════════════════════════════════
# Termux Zsh Config - Diego Dizzi
# ═══════════════════════════════════════════════════════════

# Path to oh-my-zsh
export ZSH="$HOME/.oh-my-zsh"

# Theme: Powerlevel10k
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins (oh-my-zsh)
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-completions
  zsh-history-substring-search
  fzf
  extract
  colored-man-pages
)

# Cargar Oh My Zsh
source $ZSH/oh-my-zsh.sh

# ═══════════════════════════════════════════════════════════
# Plugins externos
# ═══════════════════════════════════════════════════════════

# zsh-autocomplete
[[ -f ~/.zsh/zsh-autocomplete/zsh-autocomplete.plugin.zsh ]] && \
  source ~/.zsh/zsh-autocomplete/zsh-autocomplete.plugin.zsh

# fzf-tab (debe ir después de compinit)
[[ -f ~/.zsh/fzf-tab/fzf-tab.plugin.zsh ]] && \
  source ~/.zsh/fzf-tab/fzf-tab.plugin.zsh

# ═══════════════════════════════════════════════════════════
# Aliases y configuración extra
# ═══════════════════════════════════════════════════════════

# Cargar aliases personalizados
[[ -f ~/.termux_aliases ]] && source ~/.termux_aliases

# Starship prompt (si está instalado, sobreescribe p10k)
# Descomenta si prefieres starship sobre powerlevel10k:
# eval "$(starship init zsh)"

# Zoxide (cd inteligente)
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

# History config
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_DUPS
setopt SHARE_HISTORY

# Powerlevel10k instant prompt
[[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]] && \
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"

# Cargar config de Powerlevel10k si existe
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
ZSHRC

  # Cambiar shell por defecto
  chsh -s zsh

  print_success "Zsh + Oh-My-Zsh + Plugins configurado"
  print_info "Plugins instalados:"
  print_info "  • zsh-autosuggestions, zsh-syntax-highlighting"
  print_info "  • zsh-completions, zsh-history-substring-search"
  print_info "  • zsh-autocomplete, fzf-tab"
  print_info "  • Powerlevel10k theme"
  print_warning "Ejecuta 'p10k configure' para configurar Powerlevel10k"
else
  print_warning "Zsh omitido"
fi

# ═══════════════════════════════════════════════════════════
# PASO 7: STARSHIP PROMPT (OPCIONAL)
# ═══════════════════════════════════════════════════════════
print_step "7/13: Starship Prompt (Opcional)"

echo
read -p "¿Instalar Starship (prompt moderno)? [S/n]: " install_starship

if [[ ! "$install_starship" =~ ^[Nn]$ ]]; then
  pkg install -y starship

  # Configurar en .zshrc si existe
  if [[ -f ~/.zshrc ]] && ! grep -q "starship init" ~/.zshrc; then
    echo 'eval "$(starship init zsh)"' >> ~/.zshrc
  fi

  # Configurar en .bashrc también
  if [[ -f ~/.bashrc ]] && ! grep -q "starship init" ~/.bashrc; then
    echo 'eval "$(starship init bash)"' >> ~/.bashrc
  fi

  print_success "Starship instalado. Reinicia la terminal para ver los cambios."
else
  print_warning "Starship omitido"
fi

# ═══════════════════════════════════════════════════════════
# PASO 8: TMUX + CONFIGURACIÓN
# ═══════════════════════════════════════════════════════════
print_step "8/13: Tmux (Terminal Multiplexer)"

pkg install -y tmux

# Configuración básica de tmux
if [[ ! -f ~/.tmux.conf ]]; then
  cat > ~/.tmux.conf <<'TMUXCONF'
# Termux Tmux Config
set -g mouse on
set -g default-terminal "screen-256color"
set -g history-limit 10000

# Prefix más cómodo (Ctrl+a en vez de Ctrl+b)
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# Dividir paneles con | y -
bind | split-window -h
bind - split-window -v

# Navegar entre paneles con Alt+flechas
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D

# Recargar config con r
bind r source-file ~/.tmux.conf \; display "Tmux reconfigurado!"
TMUXCONF
  print_success "Tmux configurado (~/.tmux.conf)"
else
  print_warning "~/.tmux.conf ya existe, no se sobreescribió"
fi

# ═══════════════════════════════════════════════════════════
# PASO 9: YAZI (FILE MANAGER CLI)
# ═══════════════════════════════════════════════════════════
print_step "9/13: Yazi (File Manager CLI)"

# Yazi puede no estar disponible directamente, intentar instalarlo
if pkg list-installed 2>/dev/null | grep -q "^yazi"; then
  print_warning "Yazi ya instalado"
else
  pkg install -y yazi 2>/dev/null || {
    print_warning "Yazi no disponible en repos oficiales"
    print_info "Alternativa: pkg install ranger (file manager clásico)"
    pkg install -y ranger 2>/dev/null || true
  }
fi

print_success "File manager CLI instalado"

# ═══════════════════════════════════════════════════════════
# PASO 10: FASTFETCH / NEOFETCH
# ═══════════════════════════════════════════════════════════
print_step "10/13: Fastfetch / Neofetch"

pkg install -y fastfetch 2>/dev/null || pkg install -y neofetch 2>/dev/null || {
  print_warning "Ni fastfetch ni neofetch disponibles"
}

print_success "System info instalado (fastfetch/neofetch)"

# ═══════════════════════════════════════════════════════════
# PASO 11: TERMUX-API (Funciones del teléfono)
# ═══════════════════════════════════════════════════════════
print_step "11/13: Termux-API (Funciones del teléfono)"

pkg install -y termux-api

print_success "termux-api instalado"
print_info "Comandos útiles:"
print_info "  • termux-battery-status    - Estado de batería"
print_info "  • termux-brightness 255    - Ajustar brillo"
print_info "  • termux-camera-photo      - Tomar foto"
print_info "  • termux-clipboard-get     - Leer portapapeles"
print_info "  • termux-clipboard-set     - Escribir al portapapeles"
print_info "  • termux-notification      - Enviar notificación"
print_info "  • termux-open-url          - Abrir URL en navegador"
print_info "  • termux-share             - Compartir archivo"
print_info "  • termux-toast             - Mostrar toast"
print_info "  • termux-vibrate           - Vibrar teléfono"
print_info "  • termux-wifi-connectioninfo - Info WiFi"
print_warning "IMPORTANTE: Instala también la app 'Termux:API' desde F-Droid"

# ═══════════════════════════════════════════════════════════
# PASO 12: CONFIGURACIONES EXTRA + ALIASES
# ═══════════════════════════════════════════════════════════
print_step "12/13: Configuraciones Extra"

# Crear aliases útiles
ALIAS_FILE="$HOME/.termux_aliases"
cat > "$ALIAS_FILE" <<'ALIASES'
# ═══════════════════════════════════════════════════════════
# Aliases para Termux - Diego Dizzi
# ═══════════════════════════════════════════════════════════

# Navegación
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias sd='cd /sdcard'
alias dl='cd /sdcard/Download'

# Listado moderno (usa eza si disponible)
if command -v eza &> /dev/null; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -la --icons --group-directories-first'
  alias la='eza -a --icons --group-directories-first'
  alias lt='eza -T --icons --level=2'
else
  alias ll='ls -la'
  alias la='ls -a'
fi

# Cat moderno
if command -v bat &> /dev/null; then
  alias cat='bat --style=plain'
  alias catn='bat'
fi

# Grep coloreado
alias grep='grep --color=auto'

# Git shortcuts
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline -10'
alias gd='git diff'

# Editores
alias v='nvim'
alias vi='nvim'
alias vim='nvim'

# Utilidades
alias c='clear'
alias q='exit'
alias h='history'
alias reload='source ~/.zshrc 2>/dev/null || source ~/.bashrc'

# Termux específico
alias update='pkg update && pkg upgrade -y'
alias install='pkg install'
alias remove='pkg uninstall'
alias search='pkg search'
alias battery='termux-battery-status | jq'
alias wifi='termux-wifi-connectioninfo | jq'

# Python
alias py='python'
alias pip='pip3'

# Node
alias n='node'
alias np='npm'
alias nr='npm run'

# Fastfetch / Neofetch
if command -v fastfetch &> /dev/null; then
  alias ff='fastfetch'
elif command -v neofetch &> /dev/null; then
  alias ff='neofetch'
fi

# Yazi / Ranger
if command -v yazi &> /dev/null; then
  alias fm='yazi'
elif command -v ranger &> /dev/null; then
  alias fm='ranger'
fi
ALIASES

# Agregar source a los shells
for RC in ~/.bashrc ~/.zshrc; do
  if [[ -f "$RC" ]] && ! grep -q "termux_aliases" "$RC"; then
    echo "" >> "$RC"
    echo "# Aliases personalizados Termux" >> "$RC"
    echo "[ -f ~/.termux_aliases ] && source ~/.termux_aliases" >> "$RC"
  fi
done

print_success "Aliases configurados (~/.termux_aliases)"

# ═══════════════════════════════════════════════════════════
# PASO 13: STOW + DOTFILES
# ═══════════════════════════════════════════════════════════
print_step "13/13: Stow + Dotfiles"

echo
echo -e "${BOLD}${YELLOW}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${YELLOW}║          📁 DOTFILES CON STOW 📁                          ║${NC}"
echo -e "${BOLD}${YELLOW}╚═══════════════════════════════════════════════════════════╝${NC}"
echo
echo -e "${CYAN}Solo se aplicarán dotfiles COMPATIBLES con Termux:${NC}"
echo -e "  ${GREEN}•${NC} nvim, zsh, starship, tmux, yazi"
echo -e "  ${GREEN}•${NC} fastfetch, htop, bottom, neofetch"
echo
echo -e "${RED}Dotfiles INCOMPATIBLES (omitidos):${NC}"
echo -e "  ${RED}•${NC} hypr, waybar, rofi, dunst, eww, swaync, wofi, fuzzel"
echo -e "  ${RED}•${NC} kitty, ghostty, polybar, qtile, niri, quickshell"
echo -e "  ${RED}•${NC} pipewire, wireplumber, easyeffects, qt5ct/qt6ct"
echo

read -p "¿Configurar dotfiles con stow? [S/n]: " setup_dotfiles

if [[ ! "$setup_dotfiles" =~ ^[Nn]$ ]]; then
  # Instalar stow
  print_installing "GNU Stow"
  pkg install -y stow

  # Definir directorio de dotfiles
  DOTFILES_DIR="$HOME/dotfiles-termux"

  echo
  echo -e "${CYAN}Opciones de dotfiles:${NC}"
  echo -e "  ${GREEN}1.${NC} Clonar desde GitHub (nuevo)"
  echo -e "  ${GREEN}2.${NC} Usar directorio existente"
  echo -e "  ${GREEN}3.${NC} Crear estructura vacía para personalizar"
  echo
  read -p "Selecciona opción [1-3]: " dotfiles_option

  case "$dotfiles_option" in
    1)
      echo
      read -p "URL del repositorio (ej: https://github.com/usuario/dotfiles): " repo_url
      if [[ -n "$repo_url" ]]; then
        print_installing "Clonando dotfiles"
        git clone "$repo_url" "$DOTFILES_DIR" 2>/dev/null || {
          print_warning "Error clonando, ¿ya existe el directorio?"
          DOTFILES_DIR="$HOME/dotfiles-termux"
        }
      fi
      ;;
    2)
      read -p "Ruta al directorio de dotfiles (default: ~/dotfiles-termux): " custom_dir
      DOTFILES_DIR="${custom_dir:-$HOME/dotfiles-termux}"
      ;;
    3)
      print_status "Creando estructura de dotfiles..."
      mkdir -p "$DOTFILES_DIR"
      ;;
  esac

  # Asegurarse de que el directorio existe
  if [[ ! -d "$DOTFILES_DIR" ]]; then
    print_warning "Directorio no encontrado, creando: $DOTFILES_DIR"
    mkdir -p "$DOTFILES_DIR"
  fi

  cd "$DOTFILES_DIR"

  # Lista de dotfiles COMPATIBLES con Termux
  TERMUX_COMPATIBLE_DOTFILES=(
    "nvim"
    "zsh"
    "starship"
    "tmux"
    "yazi"
    "fastfetch"
    "htop"
    "bottom"
    "neofetch"
    "home"
  )

  # Lista de dotfiles INCOMPATIBLES (para referencia)
  TERMUX_INCOMPATIBLE_DOTFILES=(
    "hypr" "waybar" "rofi" "dunst" "eww" "swaync" "wofi" "fuzzel"
    "kitty" "ghostty" "polybar" "qtile" "niri" "quickshell" "caelestia"
    "pipewire" "wireplumber" "easyeffects" "qt5ct" "qt6ct"
    "thunar" "nemo" "firefox" "vscode" "cursor" "kdenlive-compressor-editor"
    "autostart" "systemd" "ibus" "input-remapper" "themes" "icons"
    "nwg-gtk-3.0" "nwg-gtk-4.0" "local" "wal" "wallpapers"
    "espanso" "sattyScreenshots" "Raycast-vicinae" "fuzzel-glyphs-rofimoji"
    "kew" "mcphub" "Antigravity" "opencode" "manual-ln"
  )

  echo
  echo -e "${CYAN}Aplicando dotfiles compatibles con Termux...${NC}"

  # Contar aplicados
  applied_count=0
  skipped_count=0

  for dotfile in "${TERMUX_COMPATIBLE_DOTFILES[@]}"; do
    if [[ -d "$DOTFILES_DIR/$dotfile" ]]; then
      print_installing "$dotfile"
      stow "$dotfile" --adopt 2>/dev/null && {
        print_success "$dotfile aplicado"
        ((applied_count++))
      } || print_warning "$dotfile falló"
    else
      print_info "$dotfile no encontrado en dotfiles, omitiendo..."
      ((skipped_count++))
    fi
  done

  echo
  print_success "Dotfiles aplicados: $applied_count"
  if [[ $skipped_count -gt 0 ]]; then
    print_info "Dotfiles omitidos (no encontrados): $skipped_count"
  fi

  echo
  echo -e "${YELLOW}${BOLD}Comandos útiles de stow:${NC}"
  echo -e "  ${CYAN}•${NC} Aplicar todos:     ${YELLOW}cd $DOTFILES_DIR && stow */--adopt${NC}"
  echo -e "  ${CYAN}•${NC} Quitar todos:      ${YELLOW}cd $DOTFILES_DIR && stow -D */${NC}"
  echo -e "  ${CYAN}•${NC} Aplicar específico: ${YELLOW}cd $DOTFILES_DIR && stow nvim zsh --adopt${NC}"
  echo -e "  ${CYAN}•${NC} Ver conflictos:    ${YELLOW}stow -n -v nvim${NC} (dry-run)"
  echo

  cd ~
else
  print_warning "Dotfiles omitido"
fi

# ═══════════════════════════════════════════════════════════
# RESUMEN FINAL
# ═══════════════════════════════════════════════════════════
clear
cat <<'EOF'

╔══════════════════════════════════════════════════════════════════════╗
║          🎉 TERMUX BÁSICO SETUP COMPLETADO 🎉                        ║
╠══════════════════════════════════════════════════════════════════════╣
║  ✅ Herramientas básicas (git, curl, wget, ssh)                      ║
║  ✅ Desarrollo (clang, python, nodejs, go)                           ║
║  ✅ Editores (neovim, vim, nano, micro)                              ║
║  ✅ CLI modernas (bat, eza, fd, ripgrep, fzf)                        ║
║  ✅ Zsh + Oh-My-Zsh + Plugins                                        ║
║  ✅ Starship Prompt                                                  ║
║  ✅ Tmux configurado                                                 ║
║  ✅ File manager (yazi/ranger)                                       ║
║  ✅ Fastfetch/Neofetch                                               ║
║  ✅ Termux-API                                                       ║
║  ✅ Aliases personalizados                                           ║
║  ✅ Stow + Dotfiles (nvim, zsh, starship, tmux, yazi...)             ║
╚══════════════════════════════════════════════════════════════════════╝

EOF

echo -e "${GREEN}${BOLD}Siguiente paso:${NC}"
echo -e "  ${CYAN}1.${NC} Reinicia Termux: ${YELLOW}exit${NC} y volver a abrir"
echo -e "  ${CYAN}2.${NC} Ejecuta: ${YELLOW}fastfetch${NC} o ${YELLOW}ff${NC}"
echo
echo -e "${YELLOW}${BOLD}Apps complementarias (F-Droid):${NC}"
echo -e "  ${CYAN}•${NC} Termux:API      - Para comandos termux-*"
echo -e "  ${CYAN}•${NC} Termux:Styling  - Temas y fuentes"
echo -e "  ${CYAN}•${NC} Termux:Widget   - Widgets en home"
echo -e "  ${CYAN}•${NC} Termux:Boot     - Scripts al iniciar"
echo
echo -e "${YELLOW}${BOLD}Dotfiles:${NC}"
echo -e "  ${CYAN}•${NC} Aplicar todos:      ${YELLOW}cd ~/dotfiles-termux && stow */ --adopt${NC}"
echo -e "  ${CYAN}•${NC} Quitar todos:       ${YELLOW}cd ~/dotfiles-termux && stow -D */${NC}"
echo -e "  ${CYAN}•${NC} Aplicar específico: ${YELLOW}cd ~/dotfiles-termux && stow nvim zsh --adopt${NC}"
echo
echo -e "${YELLOW}${BOLD}Paquetes NO compatibles con Android (omitidos):${NC}"
echo -e "  ${RED}•${NC} Hyprland, Waybar, Rofi, Dunst (requieren Wayland/X11)"
echo -e "  ${RED}•${NC} Steam, Lutris, Wine (solo x86/x64)"
echo -e "  ${RED}•${NC} SDDM, GDM (display managers)"
echo -e "  ${RED}•${NC} PipeWire, Bluetooth stack completo"
echo -e "  ${RED}•${NC} Drivers gráficos (mesa, vulkan)"
echo
echo -e "${CYAN}${BOLD}Tip:${NC} Para GUI en Android, considera:"
echo -e "  ${CYAN}•${NC} Termux:X11 + proot-distro (Ubuntu/Debian en Termux)"
echo -e "  ${CYAN}•${NC} VNC server para apps gráficas"
echo
echo -e "${GREEN}¡Disfruta tu terminal potenciado en Android! 📱${NC}"
echo
