#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# TERMUX SETUP COMPLETO - Versión Final con Git Config
# ═══════════════════════════════════════════════════════════════════════════════

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

print_step() { echo -e "\n${MAGENTA}${BOLD}▶ PASO $1${NC}"; }
print_installing() { echo -e "${BLUE}  📦 $1${NC}"; }
print_success() { echo -e "${GREEN}  ✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}  ⚠️  $1${NC}"; }
print_info() { echo -e "${CYAN}  ℹ️  $1${NC}"; }

[[ ! -d /data/data/com.termux ]] && echo "❌ Ejecutar en Termux" && exit 1

clear
cat <<'BANNER'
  ████████╗███████╗██████╗ ███╗   ███╗██╗   ██╗██╗  ██╗
  ╚══██╔══╝██╔════╝██╔══██╗████╗ ████║██║   ██║╚██╗██╔╝
     ██║   █████╗  ██████╔╝██╔████╔██║██║   ██║ ╚███╔╝
     ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║██║   ██║ ██╔██╗
     ██║   ███████╗██║  ██║██║ ╚═╝ ██║╚██████╔╝██╔╝ ██╗
     ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝

╔══════════════════════════════════════════════════════════╗
║   📱 SETUP FINAL - Con Git Auto Push 🚀                 ║
╚══════════════════════════════════════════════════════════╝
BANNER

read -p "Presiona Enter..."

# ═══════════════════════════════════════════════════════════
# MODO REINSTALAR: --reinstall / -r regenera configs desde cero
# ═══════════════════════════════════════════════════════════
REINSTALL=0
[[ "$1" == "--reinstall" || "$1" == "-r" ]] && REINSTALL=1
if [[ "$REINSTALL" == "1" ]]; then
  print_warning "Modo REINSTALAR: se regenerarán .zshrc/.termux_aliases y configs de dotfiles"
  read -p "¿Continuar? [S/n]: " re_ok
  if [[ "$re_ok" =~ ^[Nn]$ ]]; then
    exit 0
  fi
  rm -f ~/.zshrc ~/.termux_aliases
  rm -rf ~/.oh-my-zsh ~/.zsh
  print_info "Configs viejas limpiadas"
fi

# Genera un .zshrc funcional para Termux (si no existe).
# Incluye OMZ, plugins, history, PATH, aliases, prompt y fastfetch.
ensure_zshrc() {
  [[ -f ~/.zshrc ]] && return 0
  cat >~/.zshrc <<'ZSH'
# Termux .zshrc generado por termux-basic-setup.sh
# --- Historial ANTES de los plugins: zsh-autosuggestions lee HISTFILE al cargar ---
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY SHARE_HISTORY
setopt INC_APPEND_HISTORY HIST_IGNORE_ALL_DUPS HIST_SAVE_NO_DUPS

export ZSH="$HOME/.oh-my-zsh"
export ZSH_CUSTOM="$ZSH/custom"
plugins=(git zsh-syntax-highlighting zsh-autosuggestions zsh-completions zsh-history-substring-search)
[[ -f "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"
# Predictivo: lo da zsh-autosuggestions (ya en plugins OMZ). NO cargar
# zsh-autocomplete (marlonrichert): compite con autosuggestions y anula las
# sugerencias grises. Receta basada en core-termux (DevCoreXOfficial).
[[ -d ~/.zsh/fzf-tab ]] && source ~/.zsh/fzf-tab/fzf-tab.plugin.zsh

export PATH="$HOME/.local/bin:$HOME/go/bin:$HOME/.opencode/bin:$PATH"
[[ -f ~/.termux_aliases ]] && source ~/.termux_aliases

# El prompt se configura en el PASO 9 para que solo quede activo un renderer.

command -v fastfetch >/dev/null 2>&1 && { [[ -f ~/.config/fastfetch/config.jsonc ]] && fastfetch --config ~/.config/fastfetch/config.jsonc || fastfetch; }
ZSH
  print_success ".zshrc generado"
}

# Versión forzada: respalda y regenera el .zshrc SIEMPRE (útil cuando el heredado
# del laptop lo rompe: oh-my-posh con URL remota, powerlevel10k, etc.)
ensure_zshrc_force() {
  [[ -f ~/.zshrc ]] && cp ~/.zshrc ~/.zshrc.backup-$(date +%s)
  rm -f ~/.zshrc
  ensure_zshrc
}

# ═══════════════════════════════════════════════════════════
# PASO 1: Sistema
# ═══════════════════════════════════════════════════════════
print_step "1/23: Sistema"
pkg update -y >/dev/null 2>&1 && pkg upgrade -y >/dev/null 2>&1
print_success "Sistema actualizado"

# ═══════════════════════════════════════════════════════════
# PASO 2: Básicos
# ═══════════════════════════════════════════════════════════
print_step "2/23: Básicos"
pkg install -y git curl wget openssh coreutils findutils grep sed gawk \
  tar gzip bzip2 xz-utils unzip zip procps less man ncurses-utils termux-api >/dev/null 2>&1
print_success "Herramientas básicas"

# ═══════════════════════════════════════════════════════════
# PASO 3: Git Config (AUTO PUSH)
# ═══════════════════════════════════════════════════════════
print_step "3/23: Git Configuración"
print_installing "Configurando git..."

# Auto-setup remote branches (FIX del git push --set-upstream)
git config --global push.autoSetupRemote true
git config --global init.defaultBranch main
git config --global pull.rebase false

# User config (si no existe)
if [[ -z "$(git config --global user.name)" ]]; then
  read -p "Git username: " git_name
  git config --global user.name "$git_name"
fi

if [[ -z "$(git config --global user.email)" ]]; then
  read -p "Git email: " git_email
  git config --global user.email "$git_email"
fi

print_success "Git configurado"
print_info "Auto-push habilitado (no más --set-upstream)"

# ═══════════════════════════════════════════════════════════
# PASO 4: Desarrollo
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
# PASO 5: Editores
# ═══════════════════════════════════════════════════════════
print_step "5/23: Editores"
pkg install -y neovim vim nano micro >/dev/null 2>&1
# lazygit [Leader +gg]
pkg install -y lazygit >/dev/null 2>&1
mkdir -p ~/bin
cat >~/bin/termux-file-editor <<'EDITOR'
#!/bin/bash
nvim "$@"
EDITOR
chmod +x ~/bin/termux-file-editor
grep -q "EDITOR=nvim" ~/.bashrc 2>/dev/null || echo 'export EDITOR=nvim' >>~/.bashrc
print_success "Editores instalados"

# ═══════════════════════════════════════════════════════════
# PASO 6: CLI Modernas
# ═══════════════════════════════════════════════════════════
print_step "6/23: CLI Modernas"
pkg install -y bat eza fd ripgrep fzf jq tree htop ncdu duf dust zoxide >/dev/null 2>&1
print_success "CLI modernas"

# btop: no está en los repos de Termux → instala el binario musl estático (aarch64)
# desde GitHub Releases (aristocratos/btop). Binario fully-static, no necesita glibc.
print_installing "btop (monitor interactivo - GitHub Releases)..."
BTOP_VER=$(curl -s https://api.github.com/repos/aristocratos/btop/releases/latest \
  | grep -o '"tag_name": *"[^"]*"' | head -1 | cut -d'"' -f4)
[[ -z "$BTOP_VER" ]] && BTOP_VER="v1.4.8"
BTOP_TMP=$(mktemp -d)
if curl -fsSL --retry 3 -o "$BTOP_TMP/btop.tar.gz" \
  "https://github.com/aristocratos/btop/releases/download/$BTOP_VER/btop-aarch64-unknown-linux-musl.tar.gz" \
  && tar -xzf "$BTOP_TMP/btop.tar.gz" -C "$BTOP_TMP" \
  && install -m 755 "$BTOP_TMP/btop/bin/btop" "$PREFIX/bin/btop"; then
  print_success "btop $BTOP_VER instalado (\$PREFIX/bin/btop)"
else
  print_warning "btop: descarga falló (revisa red)"
fi
rm -rf "$BTOP_TMP"

# ═══════════════════════════════════════════════════════════
# PASO 7: GitHub CLI
# ═══════════════════════════════════════════════════════════
print_step "7/23: GitHub CLI"
pkg install -y gh >/dev/null 2>&1
gh extension install meiji163/gh-notify >/dev/null 2>&1 || true
print_success "gh instalado"
print_info "Autenticar: gh auth login"

# ═══════════════════════════════════════════════════════════
# PASO 8: Zsh Plugins
# ═══════════════════════════════════════════════════════════
print_step "8/23: Zsh + Plugins"
read -p "¿Instalar Zsh+Plugins? [S/n]: " zsh_install

if [[ ! "$zsh_install" =~ ^[Nn]$ ]]; then
  pkg install -y zsh >/dev/null 2>&1

  # Zsh como shell por defecto de Termux (fix: sin esto arranca bash)
  if [[ "$(basename "${SHELL:-}")" != "zsh" ]]; then
    chsh -s zsh && print_success "zsh es ahora tu shell por defecto (reabrí Termux)" ||
      print_warning "chsh falló — corré manualmente: chsh -s zsh"
  fi

  if [[ ! -d ~/.oh-my-zsh ]]; then
    print_installing "Oh-My-Zsh..."
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" >/dev/null 2>&1
  fi

  ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  # git-flow (AVH Edition) → comando `git flow` (tu config ya define gitflow())
  pkg install -y gitflow-avh >/dev/null 2>&1 || true

  # IMPORTANTE: los plugins se configuran con `core install shell` (instala en
  # ~/.zsh-plugins + Oh-My-Zsh + persistent session). Reemplaza el clonado
  # manual de plugins. DESPUÉS se enlaza tu .zshrc de dotfiles (PASO 18).
  print_installing "core install shell (plugins)..."
  if command -v core >/dev/null 2>&1; then
    bash -c "core install shell" >/dev/null 2>&1 || true
  else
    print_warning "core no está en PATH — los plugins quedan pendientes (corré: core install shell)"
  fi

  # Tu .zshrc (dotfiles) sourcea estos desde ~/.zsh/ → asegurarlos:
  mkdir -p ~/.zsh
  [[ ! -d ~/.zsh/zsh-autocomplete ]] &&
    git clone --depth 1 -q https://github.com/marlonrichert/zsh-autocomplete.git ~/.zsh/zsh-autocomplete 2>/dev/null || true
  [[ ! -d ~/.zsh/fzf-tab ]] &&
    git clone --depth 1 -q https://github.com/Aloxaf/fzf-tab.git ~/.zsh/fzf-tab 2>/dev/null || true

  print_success "Plugins instalados"
  ensure_zshrc
fi

# ═══════════════════════════════════════════════════════════
# PASO 9: Prompts
# ═══════════════════════════════════════════════════════════
print_step "9/23: Prompts"
echo "Elige tu prompt:"
echo "  1) Powerlevel10k (tema de dotfiles, recomendado)"
echo "  2) Starship (ligero)"
echo "  3) Oh-My-Posh (más features)"
echo "  4) Ninguno"
read -p "Opción [1-4, Enter=1]: " prompt_choice
prompt_choice="${prompt_choice:-1}"

remove_prompt_initializers() {
  [[ -f ~/.zshrc ]] || touch ~/.zshrc
  sed -i \
    -e '/starship init zsh/d' \
    -e '/oh-my-posh init zsh/d' \
    -e '/# Termux Powerlevel10k prompt/d' \
    -e '/powerlevel10k.zsh-theme/d' \
    -e '/source .*p10k.zsh/d' \
    -e '/POWERLEVEL9K_DISABLE_GITSTATUS=true/d' \
    -e '/POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true/d' \
    -e '/POWERLEVEL9K_INSTANT_PROMPT=off/d' \
    ~/.zshrc
}

disable_omz_theme() {
  sed -i 's/^[[:space:]]*ZSH_THEME=.*/ZSH_THEME=""/' ~/.zshrc
}

case "$prompt_choice" in
1)
  mkdir -p ~/.zsh-plugins
  if [[ ! -f ~/.zsh-plugins/powerlevel10k/powerlevel10k.zsh-theme ]]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
      ~/.zsh-plugins/powerlevel10k >/dev/null 2>&1 ||
      print_warning "Powerlevel10k no pudo clonarse"
  fi
  for p10k_config in "$HOME/dotfiles-dizzi/zsh/.p10k.zsh" \
    "$HOME/dotfiles-termux/zsh/.p10k.zsh" "$HOME/dotfiles/zsh/.p10k.zsh"; do
    if [[ -f "$p10k_config" ]]; then
      ln -sfn "$p10k_config" "$HOME/.p10k.zsh"
      break
    fi
  done
  if [[ -f ~/.zsh-plugins/powerlevel10k/powerlevel10k.zsh-theme ]]; then
    remove_prompt_initializers
    disable_omz_theme
    cat >>~/.zshrc <<'P10K'
# Termux Powerlevel10k prompt
typeset -g POWERLEVEL9K_DISABLE_GITSTATUS=true
[[ -r "$HOME/.zsh-plugins/powerlevel10k/powerlevel10k.zsh-theme" ]] && source "$HOME/.zsh-plugins/powerlevel10k/powerlevel10k.zsh-theme"
[[ -r "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"
# Set after sourcing .p10k.zsh because the dotfiles config unsets POWERLEVEL9K_* options.
typeset -g POWERLEVEL9K_DISABLE_GITSTATUS=true
typeset -g POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
typeset -g POWERLEVEL9K_INSTANT_PROMPT=off
P10K
    print_success "Powerlevel10k instalado y configurado"
  else
    print_warning "Powerlevel10k no está disponible; revisa la conexión e instala: core install shell"
  fi
  ;;
2)
  pkg install -y starship >/dev/null 2>&1
  mkdir -p ~/.config
  if [[ ! -f ~/.config/starship/starship.toml && ! -f ~/.config/starship.toml ]]; then
    starship preset nerd-font-symbols -o ~/.config/starship.toml 2>/dev/null || true
  fi
  remove_prompt_initializers
  disable_omz_theme
  if [[ -f ~/.config/starship/starship.toml ]]; then
    echo 'export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"' >>~/.zshrc
  fi
  echo 'command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"' >>~/.zshrc
  print_success "Starship instalado"
  ;;
3)
  OMP_CONFIG="$HOME/.config/oh-my-posh/1_shell.omp.json"
  if ! command -v oh-my-posh >/dev/null 2>&1; then
    pkg install -y oh-my-posh >/dev/null 2>&1 || true
  fi
  if ! command -v oh-my-posh >/dev/null 2>&1; then
    print_warning "Oh-My-Posh no se instaló; no cambié el prompt actual"
  else
    mkdir -p "$(dirname "$OMP_CONFIG")"
    if [[ ! -s "$OMP_CONFIG" ]] || ! jq -e 'type == "object" and (.blocks | type == "array")' "$OMP_CONFIG" >/dev/null 2>&1; then
      if curl -fsSL --retry 3 -o "$OMP_CONFIG.tmp" \
        "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/1_shell.omp.json" &&
        jq -e 'type == "object" and (.blocks | type == "array")' "$OMP_CONFIG.tmp" >/dev/null 2>&1; then
        mv -f "$OMP_CONFIG.tmp" "$OMP_CONFIG"
      else
        rm -f "$OMP_CONFIG.tmp"
        print_warning "No se pudo descargar un tema válido de Oh-My-Posh; no cambié el prompt actual"
      fi
    fi
    if jq -e 'type == "object" and (.blocks | type == "array")' "$OMP_CONFIG" >/dev/null 2>&1; then
      remove_prompt_initializers
      disable_omz_theme
      echo 'command -v oh-my-posh >/dev/null 2>&1 && eval "$(oh-my-posh init zsh --config "$HOME/.config/oh-my-posh/1_shell.omp.json")"' >>~/.zshrc
      print_success "Oh-My-Posh configurado con tema local y sin prompts en conflicto"
    else
      print_warning "El tema local de Oh-My-Posh no es válido; no cambié el prompt actual"
    fi
  fi
  ;;
4)
  remove_prompt_initializers
  print_success "Prompts externos desactivados"
  ;;
*)
  print_warning "Opción inválida; no se modificó el prompt"
  ;;
esac

# ═══════════════════════════════════════════════════════════
# PASO 10: Pokemon (CON FIX)
# ═══════════════════════════════════════════════════════════
print_step "10/23: Pokemon-colorscripts"
read -p "¿Instalar pokemon? [S/n]: " pokemon_install
if [[ ! "$pokemon_install" =~ ^[Nn]$ ]]; then
  if ! command -v pokemon-colorscripts &>/dev/null; then
    if timeout 30 git clone --depth 1 https://gitlab.com/phoneybadger/pokemon-colorscripts.git /tmp/pokemon 2>/dev/null; then
      cd /tmp/pokemon
      timeout 30 ./install.sh >/dev/null 2>&1 && print_success "Pokemon OK" || {
        mkdir -p ~/.local/bin
        cat >~/.local/bin/pokemon-colorscripts <<'POKE'
#!/bin/bash
POKEMONS=("⚡ Pikachu" "🔥 Charizard" "🌱 Bulbasaur")
echo "${POKEMONS[$RANDOM % ${#POKEMONS[@]}]}"
POKE
        chmod +x ~/.local/bin/pokemon-colorscripts
        print_warning "Pokemon simple"
      }
      cd ~
      rm -rf /tmp/pokemon
    fi
  fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# PASO 11: Tmux + TPM + tmux-yank (portapapeles real en Termux)
# ─────────────────────────────────────────────────────────────────────────────
# Estrategia de clipboard en Termux (sin X11, sin Wayland):
#   1. OSC52  — el terminal interpreta la secuencia y escribe al portapapeles
#              del SO. Funciona en Termux nativo y la mayoría de emuladores.
#              Requiere: tmux set-clipboard on + allow-passthrough all.
#   2. termux-clipboard-set — API Android directa. Requiere la app Termux:API
#              (com.termux.api). Si no está, el comando se cuelga → usar timeout.
#   Los dos métodos se complementan: OSC52 cubre opencode/agy, termux-clipboard
#   cubre copiar con y en copy-mode-vi cuando hay Termux:API instalada.
# ─────────────────────────────────────────────────────────────────────────────
print_step "11/23: Tmux + Clipboard"
pkg install -y tmux >/dev/null 2>&1

# ~/.tmux.conf mínimo (solo si no existe ni el de dotfiles lo crea vía stow)
[[ ! -f ~/.tmux.conf ]] && cat >~/.tmux.conf <<'TMUXMIN'
set -g mouse on
set -g base-index 1
set -g set-clipboard on
set -g allow-passthrough all
TMUXMIN

# Garantizar las dos opciones críticas de clipboard en el .tmux.conf activo
grep -q "set-clipboard" ~/.tmux.conf 2>/dev/null || echo 'set -g set-clipboard on' >>~/.tmux.conf
grep -q "allow-passthrough" ~/.tmux.conf 2>/dev/null || echo 'set -g allow-passthrough all' >>~/.tmux.conf

# ── TPM (Tmux Plugin Manager) ──────────────────────────────────────────────
TPM_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/tmux/plugins/tpm"
if [[ ! -d "$TPM_DIR/.git" ]]; then
  print_installing "TPM (Tmux Plugin Manager)..."
  git clone --depth 1 -q https://github.com/tmux-plugins/tpm.git "$TPM_DIR" 2>/dev/null &&
    print_success "TPM clonado → $TPM_DIR" ||
    print_warning "TPM: clone falló (revisa red)"
fi

# ── Instalar plugins vía TPM headless ─────────────────────────────────────
# Solo si tmux-yank todavía no está instalado (evita reinstalar cada setup).
YANK_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/tmux/plugins/tmux-yank"
if [[ -d "$TPM_DIR" && ! -d "$YANK_DIR" ]]; then
  print_installing "Instalando plugins TPM (tmux-yank, tmux-sensible, etc.)..."
  # TPM necesita una sesión tmux; arrancamos una detached temporal.
  tmux new-session -d -s tpm_install 2>/dev/null || true
  TMUX_PLUGIN_MANAGER_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/tmux/plugins/" \
    bash "$TPM_DIR/bin/install_plugins" >/dev/null 2>&1 || true
  tmux kill-session -t tpm_install 2>/dev/null || true
  [[ -d "$YANK_DIR" ]] &&
    print_success "tmux-yank instalado" ||
    print_warning "tmux-yank: install TPM falló (abrí tmux y pulsá Prefix+I)"
fi

# ── Wrapper termux-clipboard-set con timeout ──────────────────────────────
# Si la app Termux:API no está, termux-clipboard-set se cuelga para siempre.
# El wrapper aplica timeout 3s para que no bloquee opencode/agy/tmux-yank.
mkdir -p ~/.local/bin
cat >~/.local/bin/tc-set <<'TCSET'
#!/data/data/com.termux/files/usr/bin/bash
# Wrapper de termux-clipboard-set con timeout de seguridad.
# Termux:API ausente → el comando nativo se cuelga; timeout 3s lo mata limpio.
exec timeout 3 termux-clipboard-set "$@" 2>/dev/null || true
TCSET
chmod +x ~/.local/bin/tc-set

print_success "Tmux + portapapeles configurado (OSC52 + termux-clipboard)"
print_info "  • OSC52      → opencode/agy pueden copiar sin Termux:API"
print_info "  • tmux-yank  → 'y' en copy-mode copia al portapapeles Android"
print_info "  • tc-set     → wrapper seguro (timeout 3s si falta la app)"
print_info "  Instala Termux:API para copiar/pegar nativo: https://f-droid.org/packages/com.termux.api/"

print_step "12/23: Yazi"
pkg install -y yazi >/dev/null 2>&1
print_success "Yazi"

print_step "13/23: Fastfetch"
pkg install -y fastfetch 2>/dev/null || pkg install -y neofetch 2>/dev/null
# Lanzar fastfetch portable al abrir cada shell (config del repo si stow la aplicó)
grep -q "fastfetch --config" ~/.zshrc 2>/dev/null ||
  echo 'command -v fastfetch >/dev/null 2>&1 && { [[ -f ~/.config/fastfetch/config.jsonc ]] && fastfetch --config ~/.config/fastfetch/config.jsonc || fastfetch; }' >>~/.zshrc
print_success "System info"

print_step "14/23: Portapapeles (Termux-API)"
pkg install -y termux-api >/dev/null 2>&1
# OJO: el paquete termux-api NO alcanza. Sin la app Termux:API (com.termux.api)
# termux-clipboard-get/set se cuelgan para siempre y opencode/agy quedan sin
# portapapeles (agy prueba termux-clipboard-get ANTES que xclip/wl-copy).
if pm list packages 2>/dev/null | grep -q "com.termux.api"; then
  print_success "termux-api + app Termux:API (portapapeles operativo)"
else
  print_warning "termux-api instalado, pero falta la app Termux:API"
  print_info "Sin la app, copiar/pegar se cuelga y opencode/agy no copian nada."
  print_info "F-Droid: https://f-droid.org/packages/com.termux.api/"
  read -p "  ¿Abrir la descarga ahora? [S/n]: " api_open
  if [[ ! "$api_open" =~ ^[Nn]$ ]]; then
    termux-open-url "https://f-droid.org/packages/com.termux.api/" >/dev/null 2>&1 ||
      print_warning "No se pudo abrir el navegador; instalá Termux:API a mano"
  fi
fi
# xclip solo funciona con X11 (Termux:X11) y wl-clipboard no está empaquetado
# en Termux, así que no se instalan por defecto: no resuelven el caso nativo.
if [[ -n "${DISPLAY:-}" ]] && ! command -v xclip >/dev/null 2>&1; then
  pkg install -y xclip >/dev/null 2>&1 && print_success "xclip (X11 detectado)"
fi

print_step "15/23: Aliases"
[[ ! -f ~/.termux_aliases ]] && cat >~/.termux_aliases <<'ALIASES'
alias ai='tgpt'; alias ask='tgpt -i'
alias g='git'; alias gs='git status'
alias dot='cd ~/dotfiles-dizzi'
alias ddot='cd ~/dotfiles-dizzi'
ALIASES
# Cargar aliases en shells (bash y zsh)
grep -q "termux_aliases" ~/.bashrc 2>/dev/null || echo 'source ~/.termux_aliases' >>~/.bashrc
grep -q "termux_aliases" ~/.zshrc 2>/dev/null || echo 'source ~/.termux_aliases' >>~/.zshrc
print_success "Aliases"

print_step "16/23: IA Tools"
read -p "¿Instalar IA Tools? [S/n]: " ia_install
if [[ ! "$ia_install" =~ ^[Nn]$ ]]; then
  # tgpt: los binarios de GitHub releases NO son PIE => error e_type: 2 en Android.
  # Compilar con Go produce binario Bionic/PIE válido. Fallback: paquete de Termux.
  if ! command -v tgpt &>/dev/null; then
    print_installing "tgpt via go install (PIE-safe)..."
    if go install github.com/aandrew-me/tgpt/v2@latest &>/dev/null && [[ -x ~/go/bin/tgpt ]]; then
      ln -sf ~/go/bin/tgpt "$PREFIX/bin/tgpt"
      print_success "tgpt (go build)"
    elif pkg install -y tgpt &>/dev/null; then
      print_success "tgpt (pkg)"
    else
      print_warning "tgpt no pudo instalarse"
    fi
  fi

  # opencode: npm NO funciona en Termux (postinstall busca opencode-android-arm64,
  # que no existe; el binario linux-arm64 es glibc no-PIE => e_type: 2).
  # Se usa el build nativo comunitario (guysoft/opencode-termux).
  # OJO: las URLs del README (releases/latest/download/opencode-aarch64.deb) están
  # STALE — los assets son versionados => resolver vía API.
  # Layout esperado (README Opción 1): wrapper->$PREFIX/bin, bin->$PREFIX/libexec/opencode,
  # libs->$PREFIX/lib. Si el bin cae en modo Bun pelado (--version=1.2.13, la versión
  # de Bun pineada), el artefacto está roto => fallback al ZIP con ese layout.
  read -p "¿Instalar opencode (build nativo Termux)? [S/n]: " oc_install
  if [[ ! "$oc_install" =~ ^[Nn]$ ]]; then
    print_installing "opencode (guysoft/opencode-termux)..."
    pkg install -y ripgrep unzip >/dev/null 2>&1

    oc_ok() { # 0 si opencode responde como OpenCode (no como Bun sin module graph, ni roto e_type:2)
      command -v opencode &>/dev/null || return 1
      local v
      v="$(opencode --version 2>&1)" || return 1 # binario roto (e_type:2) no puede ni ejecutarse
      [[ "$v" == "1.2.13" ]] && return 1
      echo "$v" | grep -qi '^Bun ' && return 1
      return 0
    }
    oc_libs_fix() { # el wrapper busca libs en ../lib, $PREFIX/lib y $dir (no en libexec)
      mkdir -p "$PREFIX/lib"
      for l in libtagfix.so libc++_shared.so libopentui.so; do
        [[ -f "$PREFIX/lib/$l" ]] || cp "$PREFIX/libexec/opencode/$l" "$PREFIX/lib/" 2>/dev/null
      done
    }

    GH_API=https://api.github.com/repos/guysoft/opencode-termux/releases/latest
    DEB_URL=$(curl -s "$GH_API" | grep -o '"browser_download_url": *"[^"]*aarch64\.deb"' | head -1 | cut -d'"' -f4)
    ZIP_URL=$(curl -s "$GH_API" | grep -o '"browser_download_url": *"[^"]*android-aarch64\.zip"' | head -1 | cut -d'"' -f4)

    if [[ -n "$DEB_URL" ]] && curl -fsSL --retry 3 --retry-all-errors -C - -o ~/opencode.deb "$DEB_URL"; then
      dpkg -i ~/opencode.deb >/dev/null 2>&1 || apt-get install -f -y >/dev/null 2>&1
      rm -f ~/opencode.deb
      oc_libs_fix
    fi

    if ! oc_ok; then
      print_warning ".deb roto (cae en modo Bun); probando ZIP (Opción 1 del README)..."
      if [[ -n "$ZIP_URL" ]] && curl -fsSL --retry 3 --retry-all-errors -C - -o ~/opencode.zip "$ZIP_URL"; then
        rm -rf ~/oc-zip && mkdir ~/oc-zip && unzip -q ~/opencode.zip -d ~/oc-zip
        # soportar tanto layout plano como anidado
        if [[ ! -f ~/oc-zip/opencode ]]; then
          SUB=$(dirname "$(find ~/oc-zip -type f -name opencode.bin 2>/dev/null | head -1)" 2>/dev/null)
          [[ -n "$SUB" && -d "$SUB" ]] && mv "$SUB"/* ~/oc-zip/
        fi
        if [[ -f ~/oc-zip/opencode && -f ~/oc-zip/opencode.bin ]]; then
          mkdir -p "$PREFIX/bin" "$PREFIX/libexec/opencode" "$PREFIX/lib"
          install -m 755 ~/oc-zip/opencode "$PREFIX/bin/opencode"
          install -m 755 ~/oc-zip/opencode.bin "$PREFIX/libexec/opencode/opencode.bin"
          install -m 644 ~/oc-zip/libtagfix.so ~/oc-zip/libc++_shared.so ~/oc-zip/libopentui.so "$PREFIX/lib/" 2>/dev/null
          oc_libs_fix
        else
          print_warning "ZIP con layout inesperado"
        fi
        rm -rf ~/oc-zip ~/opencode.zip
      fi
    fi

    if oc_ok; then
      print_success "opencode $(opencode --version 2>/dev/null) instalado"
    else
      print_warning "Artefactos de guysoft rotos (Bun pelado)."
      print_info "Fallback: Ruta A (bun-termux + binario oficial) ejecutándose..."
      # Ruta A — se ejecuta aquí, no solo se imprime
      # Dependencias reales de bun-termux (gue README oficial).
      # OJO: el paquete glibc-repo NO existe en espejos como termux.net → se agrega el repo
      # glibc a mano; sin esto, ni pkg ni el manager encuentran glibc-runner.
      mkdir -p $PREFIX/etc/apt/sources.list.d
      grep -q termux-glibc $PREFIX/etc/apt/sources.list.d/glibc.list 2>/dev/null ||
        echo "deb [trusted=yes] https://packages-cf.termux.dev/apt/termux-glibc glibc stable" \
          >$PREFIX/etc/apt/sources.list.d/glibc.list
      pkg update >/dev/null 2>&1 || true
      pkg install -y git curl clang make >/dev/null 2>&1 || true
      pkg install -y glibc glibc-runner >/dev/null 2>&1 || true
      # 1) Clonar bun-termux (necesario para helper_scripts/replace_runtime.py)
      [[ ! -d ~/bun-termux/.git ]] &&
        git clone --depth 1 https://github.com/Happ1ness-dev/bun-termux.git ~/bun-termux >/dev/null 2>&1 || true
      # 2) Instalar Bun + wrapper (vía manual ya probada en el campo; el manager
      #    busca el paquete glibc-repo y aborta aunque el repo manual ya esté).
      if [[ ! -x ~/.bun/bin/bun ]]; then
        print_installing "bun-termux (loader sin proot)..."
        touch ~/.bashrc
        curl -fsSL https://bun.sh/install | bash >/dev/null 2>&1
        if [[ -x ~/.bun/bin/bun ]]; then
          (cd ~/bun-termux && make >/dev/null 2>&1 && make install >/dev/null 2>&1)
        fi
        [[ -x ~/.bun/bin/bun ]] || print_warning "bun-termux falló (revisa manual)"
      fi
      # 3) Binario oficial de opencode (arm64) → ~/.opencode/bin
      if [[ ! -x ~/.opencode/bin/opencode ]]; then
        print_installing "opencode oficial (arm64)..."
        mkdir -p ~/.opencode/bin
        curl -fL --retry 3 --retry-all-errors -C - \
          -o ~/opencode-linux-arm64.tar.gz \
          https://github.com/anomalyco/opencode/releases/latest/download/opencode-linux-arm64.tar.gz &&
          tar -xzf ~/opencode-linux-arm64.tar.gz -C ~/.opencode/bin/ opencode &&
          rm -f ~/opencode-linux-arm64.tar.gz ||
          print_warning "descarga opencode falló"
      fi
      # 4) Parchar el binario para usar el wrapper (sin esto: e_type: 2 al ejecutar)
      if [[ -f ~/bun-termux/helper_scripts/replace_runtime.py && -x ~/.opencode/bin/opencode ]]; then
        print_installing "Parcheando opencode (replace_runtime.py)..."
        # Usar output explícito: si la primera vez quedó un .bak (modo default crea backup),
        # el script aborta con "Backup already exists". Con output a .patched nunca bloquea.
        python ~/bun-termux/helper_scripts/replace_runtime.py \
          ~/.opencode/bin/opencode ~/.opencode/bin/opencode.patched >/dev/null 2>&1 &&
          mv -f ~/.opencode/bin/opencode ~/.opencode/bin/opencode.unpatched &&
          mv -f ~/.opencode/bin/opencode.patched ~/.opencode/bin/opencode ||
          print_warning "replace_runtime.py no aplicó (revisa manual)"
      fi
      # 5) PATH estable (en .zshrc y en la sesión actual)
      grep -q '.opencode/bin' ~/.zshrc 2>/dev/null ||
        echo 'export PATH="$HOME/.opencode/bin:$PATH"' >>~/.zshrc
      export PATH="$HOME/.opencode/bin:$PATH"
      if oc_ok; then
        print_success "opencode vía Ruta A: $(opencode --version 2>/dev/null)"
      elif ~/.opencode/bin/opencode --version &>/dev/null; then
        print_success "opencode vía Ruta A (ruta explícita): $(~/.opencode/bin/opencode --version 2>/dev/null)"
      else
        print_warning "Ruta A no quedó funcional — seguí la guía manual (AGENT.MD, OpenCode Termux)"
      fi
    fi
  fi

  npm install -g opencommit 2>/dev/null
  pip install pywal --break-system-packages 2>/dev/null
  pkg install -y proot-distro imagemagick >/dev/null 2>&1
  print_success "IA Tools"
fi
print_info "Claude Code/Gemini CLI: solo vía proot-distro (Ubuntu/Debian)"

# ─── Engram (memoria persistente MCP) ─────────────────────────────────────
read -p "¿Configurar Engram (memoria MCP)? [S/n]: " engram_install
if [[ ! "$engram_install" =~ ^[Nn]$ ]]; then
  ENGRAM_VER=$(curl -s https://api.github.com/repos/Gentleman-Programming/engram/releases/latest | grep -o '"tag_name": *"[^"]*"' | head -1 | cut -d'"' -f4)
  [[ -z "$ENGRAM_VER" ]] && ENGRAM_VER="v1.20.0"
  ARCH="$(uname -m)"
  if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
    ENGRAM_TGZ="engram_${ENGRAM_VER#v}_linux_arm64.tar.gz"
  elif [[ "$ARCH" == "x86_64" || "$ARCH" == "amd64" ]]; then
    ENGRAM_TGZ="engram_${ENGRAM_VER#v}_linux_amd64.tar.gz"
  else print_warning "engram: arch no soportado ($ARCH)"; fi
  if [[ -n "$ENGRAM_TGZ" ]]; then
    mkdir -p ~/.local/bin
    TMPD=$(mktemp -d)
    curl -fsSL --retry 3 --retry-all-errors -C - \
      -o "$TMPD/engram.tar.gz" \
      "https://github.com/Gentleman-Programming/engram/releases/download/$ENGRAM_VER/$ENGRAM_TGZ" &&
      tar -xzf "$TMPD/engram.tar.gz" -C "$TMPD" engram &&
      install -m 755 "$TMPD/engram" ~/.local/bin/engram &&
      print_success "engram $ENGRAM_VER instalado (~/.local/bin/engram)" ||
      print_warning "descarga de engram falló"
    rm -rf "$TMPD"
    # MCP + plugin para OpenCode (escribe ~/.config/opencode/)
    if command -v opencode >/dev/null 2>&1 || [[ -d ~/.config/opencode ]]; then
      ~/.local/bin/engram setup opencode >/dev/null 2>&1 &&
        print_success "engram conectado a OpenCode (MCP + plugin)" ||
        print_warning "engram setup opencode no completó — reiniciá opencode"
    fi
  fi
fi

print_step "17/23: Fira Code"
read -p "¿Instalar Fira Code? [S/n]: " font_install
if [[ ! "$font_install" =~ ^[Nn]$ ]] && [[ ! -f ~/.termux/font.ttf ]]; then
  pkg install -y wget unzip >/dev/null 2>&1
  mkdir -p ~/.termux/fonts
  cd ~/.termux/fonts
  wget -q https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/FiraCode.zip &&
    unzip -q FiraCode.zip && rm FiraCode.zip
  # Termux solo lee ~/.termux/font.ttf (singular) — sin esto no hay íconos nerd
  cp FiraCodeNerdFont-Regular.ttf ~/.termux/font.ttf && print_success "Fira Code Nerd activada (~/.termux/font.ttf)"
  cd ~
fi

print_step "18/23: Stow + Dotfiles"
read -p "¿Configurar dotfiles? [S/n]: " stow_install
if [[ ! "$stow_install" =~ ^[Nn]$ ]]; then
  pkg install -y stow >/dev/null 2>&1

  DOTFILES=""
  for dir in ~/dotfiles-dizzi ~/dotfiles-termux ~/dotfiles; do
    [[ -d "$dir/.git" ]] && DOTFILES="$dir" && break
  done

  # Si no existe el repo, clonarlo CON submodules (sin esto nvim queda vacío)
  if [[ -z "$DOTFILES" ]]; then
    print_installing "Clonando dotfiles-dizzi (con submodules)..."
    if git clone --recurse-submodules https://github.com/dizzi1222/dotfiles-dizzi.git ~/dotfiles-dizzi; then
      DOTFILES=~/dotfiles-dizzi
    else
      print_warning "Clone falló, revisa conexión/auth"
    fi
  fi

  if [[ -n "$DOTFILES" ]]; then
    cd "$DOTFILES"
    git checkout termux 2>/dev/null || true
    # CRÍTICO: sincronizar submodules (nvim) — fix "submodule initialized but empty"
    git submodule update --init --recursive
    # El checkout estándar de submodule queda detached; usar la rama Termux real.
    NVIM_SUBMODULE="$DOTFILES/nvim/.config/nvim"
    if [[ -e "$NVIM_SUBMODULE/.git" ]]; then
      if git -C "$NVIM_SUBMODULE" fetch origin +refs/heads/termux:refs/remotes/origin/termux; then
        if git -C "$NVIM_SUBMODULE" checkout -B termux origin/termux; then
          git -C "$NVIM_SUBMODULE" branch --set-upstream-to=origin/termux termux >/dev/null
          print_success "Neovim quedó en la rama termux"
        else
          print_warning "No se pudo cambiar Neovim a termux; se conservaron los cambios locales"
        fi
      else
        print_warning "No se pudo actualizar origin/termux para Neovim"
      fi
    fi
    # Compartir la configuración Powerlevel10k del repo con el entorno Termux.
    [[ -f "$DOTFILES/zsh/.p10k.zsh" ]] && ln -sfn "$DOTFILES/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
    # Stow desde la raíz: cada paquete del repo tiene estructura .config/.
    # No enlazar zsh/.zshrc: Termux mantiene su propio archivo y el PASO 9
    # selecciona un solo prompt; solo se comparte la configuración .p10k.zsh.
    for pkg in nvim nixconf assets home Antigravity codex starship tmux opencode fastfetch bottom htop neofetch yazi zellij kew fish font fonts icons local mcphub etc; do
      [[ -d "$pkg" ]] && stow "$pkg" --adopt 2>/dev/null | grep -v "BUG" || true
    done
    [[ -f "zsh/.zshenv" ]] && ln -sfn "$DOTFILES/zsh/.zshenv" ~/.zshenv
    cd ~
    print_success "Dotfiles ($DOTFILES)"
  fi
fi

# ═══════════════════════════════════════════════════════════
# PASO 19: Parchar .zshrc
# ═══════════════════════════════════════════════════════════
print_step "19/23: Silenciar Avisos"
read -p "¿Reparar .zshrc? [S/n]: " patch_zshrc
if [[ ! "$patch_zshrc" =~ ^[Nn]$ ]] && [[ -f ~/.zshrc ]]; then
  # Si ~/.zshrc es el symlink mantenido del repo (rama termux, p10k adaptado)
  # se parchea normal; solo se regenera cuando el archivo es un .zshrc real de
  # laptop (oh-my-posh con URL remota, swww, prompt de Arch) que rompe Termux.
  LAPTOP_MARKS=("oh-my-posh init zsh --config 'http" "wallpaper-prompt-fastfetch" "ARCH LINUX" "bspwm" "swww")
  is_laptop=""
  if [[ ! -L ~/.zshrc ]]; then
    for mark in "${LAPTOP_MARKS[@]}"; do
      if grep -qF "$mark" ~/.zshrc; then
        is_laptop=1
        break
      fi
    done
  fi

  if [[ -n "$is_laptop" ]]; then
    print_warning "Detecté .zshrc del laptop → genero uno limpio para Termux."
    ensure_zshrc_force
  else
    cp ~/.zshrc ~/.zshrc.backup-$(date +%s)
    ! grep -q "HISTFILE=" ~/.zshrc && cat >>~/.zshrc <<'HIST'
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY SHARE_HISTORY
HIST
    ! grep -q "go/bin" ~/.zshrc && echo 'export PATH=$PATH:~/go/bin:~/.local/bin' >>~/.zshrc
    print_success ".zshrc parchado"
  fi
fi

# ═══════════════════════════════════════════════════════════
# PASO 20: Crear .gitignore Seguro
# ═══════════════════════════════════════════════════════════
print_step "20/23: .gitignore Seguro"
for dir in ~/dotfiles-dizzi ~/dotfiles-termux ~/dotfiles; do
  if [[ -d "$dir" ]]; then
    cd "$dir"
    if [[ -f .gitignore ]]; then
      if ! grep -q "\.opencommit" .gitignore; then
        cat >>.gitignore <<'IGNORE'

# Archivos sensibles (NO commitear)
**/.opencommit
*api-keys*
*.env
.env.*
*secret*
IGNORE
        print_success ".gitignore actualizado"
      fi
    fi
    cd ~
    break
  fi
done

# ═══════════════════════════════════════════════════════════
# PASO 21: Workspace + Discord RPC
# ═══════════════════════════════════════════════════════════
print_step "21/23: Workspace + Discord RPC"
read -p "¿Clonar workspace e instalar discord-rpc? [S/n]: " ws_install
if [[ ! "$ws_install" =~ ^[Nn]$ ]]; then
  if [[ ! -d ~/workspace/.git ]]; then
    print_installing "Clonando workspace (con submodules)..."
    if git clone --recurse-submodules https://github.com/dhardi007/workspace.git ~/workspace 2>/dev/null; then
      print_success "workspace clonado"
    else
      git -C ~/workspace submodule update --init --recursive >/dev/null 2>&1
    fi
  fi

  # Repos independientes PTD-Talento (CIC): origin=CIC, dizzi1222=fork personal
  for repo in ptd-talento-back ptd-talento-front; do
    if [[ ! -d ~/workspace/$repo/.git ]]; then
      print_installing "Clonando $repo (CIC + fork dizzi1222)..."
      if git clone https://github.com/dhardi007/$repo.git ~/workspace/$repo 2>/dev/null; then
        git -C ~/workspace/$repo remote add dizzi1222 https://github.com/dizzi1222/$repo.git
        print_success "$repo con remote dizzi1222"
      else
        print_warning "$repo: clone falló"
      fi
    fi
  done
  if [[ -d ~/workspace/opencode-discord-rpc ]]; then
    print_installing "Compilando opencode-discord-rpc..."
    (cd ~/workspace/opencode-discord-rpc && npm install --silent && npm run build --silent) &&
      print_success "discord-rpc compilado" || print_warning "build falló, revisa npm"
    # Registrar plugin en la config global de opencode (si falta)
    OC_JSON=~/.config/opencode/opencode.json
    if [[ -f "$OC_JSON" ]] && ! grep -q "opencode-discord-rpc" "$OC_JSON"; then
      sed -i 's|"\$schema": "https://opencode.ai/config.json",|"$schema": "https://opencode.ai/config.json",\n  "plugin": ["/data/data/com.termux/files/home/workspace/opencode-discord-rpc"],|' "$OC_JSON"
      print_success "Plugin registrado en opencode.json"
    fi
    print_info "Rich Presence activo al abrir opencode (requiere Discord)"
  fi
fi

# ═══════════════════════════════════════════════════════════
# PASO 22: Core-Termux (Modular Dev Env) + OpenCode + Antigravity + Claude Code
# ───────────────────────────────────────────────────────────
# Android 16+ ignora el PT_INTERP glibc y fuerza linker64 (bionic)
# → "Could not find a PHDR: broken executable?" (fallan los loaders
#   glibc: helper C nativo, bun-termux, ld-linux directo).
# Vías que esquivan el kernel (proot hace su propio ELF loading):
#   Nivel 1: core install ai --opencode → "glibc + proot" (ligero)
#   Nivel 2: core install ai --opencode → proot-distro ubuntu
# ═══════════════════════════════════════════════════════════
print_step "22/23: Core-Termux"
read -p "¿Instalar Core-Termux (DevCoreXOfficial)? [S/n]: " ct_install
if [[ ! "$ct_install" =~ ^[Nn]$ ]]; then
  print_installing "Instalando Core-Termux..."
  if curl -fsSL https://raw.githubusercontent.com/DevCoreXOfficial/core-termux/main/install.sh | bash; then
    print_success "Core-Termux instalado (comando: core)"
    print_info "Módulos: lang | db | ai | editor | dev | npm | shell | ui | auto"
  else
    print_warning "Core-Termux: instalación falló (revisa red/git)"
  fi

  read -p "¿Instalar OpenCode vía core? [S/n]: " oc_install
  if [[ ! "$oc_install" =~ ^[Nn]$ ]] && command -v core >/dev/null 2>&1; then
    rm -f $PREFIX/bin/opencode # quitar helper roto (PHDR) para que core no diga "ya instalado"
    print_warning "Elige en el selector: 'glibc + proot (bad system call)' — evita el linker64 del kernel"
    print_installing "core install ai --opencode"
    core install ai --opencode || print_warning "Falló; reintenta eligiendo 'proot-distro (ubuntu)'"
  fi

  read -p "¿Instalar Antigravity CLI vía core? [S/n]: " agy_install
  if [[ ! "$agy_install" =~ ^[Nn]$ ]] && command -v core >/dev/null 2>&1; then
    print_warning "Elige en el selector: 'glibc (recommended)' — el binario pesa ~250 MB"
    print_installing "core install ai --antigravity-cli"
    if core install ai --antigravity-cli; then
      print_success "Antigravity CLI instalado"
      # Enlazar dotfiles de Antigravity si están disponibles
      for dir in ~/dotfiles-dizzi ~/dotfiles-termux ~/dotfiles; do
        if [[ -d "$dir/Antigravity" ]] && command -v stow >/dev/null 2>&1; then
          (cd "$dir" && stow Antigravity --adopt 2>/dev/null || true)
          print_success "Dotfiles de Antigravity enlazados con stow"
          break
        fi
      done
    else
      print_warning "Falló; revisá red o espacio libre"
    fi
  fi

  read -p "¿Instalar Claude Code vía core? [S/n]: " cc_install
  if [[ ! "$cc_install" =~ ^[Nn]$ ]] && command -v core >/dev/null 2>&1; then
    print_warning "Elige en el selector: 'glibc (recommended)' o 'glibc + proot (bad system call)'"
    print_installing "core install ai --claude-code"
    core install ai --claude-code || print_warning "Falló; reintenta con 'proot-distro (ubuntu)'"
  fi
fi

# ═══════════════════════════════════════════════════════════
# PASO 22b: Módulos Core (complemento)
# ───────────────────────────────────────────────────────────
# Instala los módulos restantes del framework. Editor se omite (se usa nvim).
print_step "22b/23: Módulos Core"
read -p "¿Instalar módulos de core (lang, db, ai, dev, npm, shell, ui, auto)? [S/n]: " core_mods
if [[ ! "$core_mods" =~ ^[Nn]$ ]]; then
  for m in lang db ai dev npm shell ui auto; do
    print_installing "core install $m..."
    if timeout 120 bash -c "core install $m"; then
      print_success "$m instalado"
    else
      print_warning "$m falló o se saltó"
    fi
  done
fi

# ═══════════════════════════════════════════════════════════
# PASO 22c: Atajos de Termux:Widget (OpenCode, Neovim, Antigravity, Codex,
# Claude Code y OpenClaw)
# ───────────────────────────────────────────────────────────
# Termux:Widget lee los atajos dinámicos de ~/.termux/widget/dynamic_shortcuts.
# En Android 10+ el permiso "Mostrar sobre otras apps" va en TERMUX (no en
# Termux:Widget): sin él, el widget no puede abrir la terminal en foreground.
# En MIUI/HyperOS se llama "Mostrar ventanas emergentes mientras se ejecuta
# en segundo plano" y está en Ajustes → Apps → Termux → Otros permisos.
# ═══════════════════════════════════════════════════════════
print_step "22c/23: Atajos de Termux:Widget"
read -p "¿Crear los atajos de OpenCode, Neovim, Antigravity, Codex, Claude Code y OpenClaw? [S/n]: " widget_ok
if [[ ! "$widget_ok" =~ ^[Nn]$ ]]; then
  WIDGET_DIR="$HOME/.termux/widget/dynamic_shortcuts"
  ICONS_DIR="$HOME/.shortcuts/icons"
  mkdir -p "$WIDGET_DIR" "$ICONS_DIR"

  # Copia las versiones guardadas en dotfiles; si faltan, genera los comandos.
  WIDGET_SRC=""
  for dir in ~/dotfiles-dizzi ~/dotfiles-termux ~/dotfiles; do
    if [[ -f "$dir/home/termux/dynamic_shortcuts/opencode" ]]; then
      WIDGET_SRC="$dir/home/termux/dynamic_shortcuts/opencode"
      break
    fi
  done
  for entry in opencode:opencode nvim:nvim agy:agy codex:codex claude-code:claude openclaw:openclaw; do
    shortcut="${entry%%:*}"
    command="${entry#*:}"
    if [[ -n "$WIDGET_SRC" && -f "$(dirname "$WIDGET_SRC")/$shortcut" ]]; then
      cp "$(dirname "$WIDGET_SRC")/$shortcut" "$WIDGET_DIR/$shortcut"
    else
      printf '#!/data/data/com.termux/files/usr/bin/bash\n%s\n' "$command" >"$WIDGET_DIR/$shortcut"
    fi
    chmod +x "$WIDGET_DIR/$shortcut"
    print_success "Atajo creado: $WIDGET_DIR/$shortcut"
  done

  # El helper de core-termux ejecuta el loader glibc directo y opencode intenta
  # spawnear "serve" con process.execPath = ld-linux -> error 127. El launcher
  # proot hace que process.execPath sea el binario real y el spawn funcione.
  LAUNCHER="$HOME/.local/bin/opencode"
  mkdir -p "$HOME/.local/bin"
  if [[ -f "$LAUNCHER" ]]; then
    grep -q 'PROOT_NO_SECCOMP' "$LAUNCHER" || \
      sed -i '/^export SSL_CERT_FILE/a export PROOT_NO_SECCOMP=1' "$LAUNCHER"
  elif [[ -n "$WIDGET_SRC" && -f "$(dirname "$WIDGET_SRC")/../opencode-launcher.sh" ]]; then
    cp "$(dirname "$WIDGET_SRC")/../opencode-launcher.sh" "$LAUNCHER"
    chmod +x "$LAUNCHER"
  fi
  if [[ -f "$PREFIX/bin/opencode" && ! -L "$PREFIX/bin/opencode" ]]; then
    mv "$PREFIX/bin/opencode" "$PREFIX/bin/opencode.core-termux.bak"
  fi
  ln -sf "$LAUNCHER" "$PREFIX/bin/opencode"
  print_success "Launcher proot enlazado en \$PREFIX/bin/opencode"

  # npm deja el shebang /usr/bin/env en openclaw.mjs, que no existe en Termux.
  # El wrapper ejecuta node directamente para que `openclaw` funcione.
  OPENCLAW_LAUNCHER="$HOME/.local/bin/openclaw"
  if [[ -f "$PREFIX/lib/node_modules/openclaw/openclaw.mjs" ]]; then
    printf '#!/data/data/com.termux/files/usr/bin/bash\nexec node "$PREFIX/lib/node_modules/openclaw/openclaw.mjs" "$@"\n' \
      >"$OPENCLAW_LAUNCHER"
    chmod +x "$OPENCLAW_LAUNCHER"
    ln -sf "$OPENCLAW_LAUNCHER" "$PREFIX/bin/openclaw"
    print_success "Launcher de OpenClaw enlazado en \$PREFIX/bin/openclaw"
  fi

  # OJO: el ícono se busca SIEMPRE en ~/.shortcuts/icons/<script>.png,
  # no en ~/.termux/widget/dynamic_shortcuts/icons.
  for shortcut in opencode nvim agy codex claude-code openclaw; do
    if [[ -n "$WIDGET_SRC" && -f "$(dirname "$WIDGET_SRC")/icons/$shortcut.png" ]]; then
      cp "$(dirname "$WIDGET_SRC")/icons/$shortcut.png" "$ICONS_DIR/$shortcut.png"
      chmod 600 "$ICONS_DIR/$shortcut.png"
      print_success "Ícono copiado: $ICONS_DIR/$shortcut.png"
    elif [[ -s "$ICONS_DIR/$shortcut.png" ]]; then
      print_info "Ícono existente: $ICONS_DIR/$shortcut.png"
    elif [[ "$shortcut" == "nvim" ]]; then
      # Si se ejecuta sin el repo, descarga la marca oficial de Neovim.
      if curl -fLsS --max-time 30 \
        https://raw.githubusercontent.com/neovim/neovim.github.io/6568b9011ddb2965dc5118d28f17d5b7ce7dd8da/static/logos/neovim-mark.png \
        -o "$ICONS_DIR/nvim.png.tmp"; then
        mv "$ICONS_DIR/nvim.png.tmp" "$ICONS_DIR/nvim.png"
        chmod 600 "$ICONS_DIR/nvim.png"
        print_success "Ícono de Neovim descargado"
      else
        rm -f "$ICONS_DIR/nvim.png.tmp"
        print_warning "No se pudo descargar el ícono: copiá un PNG a $ICONS_DIR/nvim.png"
      fi
    elif [[ "$shortcut" == "agy" ]]; then
      # Logo oficial de Google Antigravity (antigravity.google).
      if curl -fLsS --max-time 30 \
        https://antigravity.google/assets/image/antigravity-logo.png \
        -o "$ICONS_DIR/agy.png.tmp"; then
        mv "$ICONS_DIR/agy.png.tmp" "$ICONS_DIR/agy.png"
        chmod 600 "$ICONS_DIR/agy.png"
        print_success "Ícono de Antigravity descargado"
      else
        rm -f "$ICONS_DIR/agy.png.tmp"
        print_warning "No se pudo descargar el ícono: copiá un PNG a $ICONS_DIR/agy.png"
      fi
    elif [[ "$shortcut" == "claude-code" || "$shortcut" == "openclaw" ]]; then
      # Iconos oficiales de LobeHub (claudecode-color / openclaw-color).
      if curl -fLsS --max-time 30 \
        "https://cdn.jsdelivr.net/npm/@lobehub/icons-static-png@latest/light/${shortcut//-}-color.png" \
        -o "$ICONS_DIR/$shortcut.png.tmp"; then
        mv "$ICONS_DIR/$shortcut.png.tmp" "$ICONS_DIR/$shortcut.png"
        chmod 600 "$ICONS_DIR/$shortcut.png"
        print_success "Ícono de $shortcut descargado"
      else
        rm -f "$ICONS_DIR/$shortcut.png.tmp"
        print_warning "No se pudo descargar el ícono: copiá un PNG a $ICONS_DIR/$shortcut.png"
      fi
    else
      print_info "Ícono opcional: poné un PNG en $ICONS_DIR/$shortcut.png y recreá los atajos."
    fi
  done

  # Abre la pantalla exacta del permiso para que sea un solo toggle.
  print_info "Android 10+ exige 'Mostrar sobre otras apps' en Termux para lanzar la terminal desde el widget."
  read -p "¿Abrir los ajustes del permiso ahora? [S/n]: " overlay_ok
  if [[ ! "$overlay_ok" =~ ^[Nn]$ ]]; then
    if am start -n com.miui.securitycenter/com.miui.permcenter.permissions.PermissionsEditorActivity --es extra_pkgname com.termux >/dev/null 2>&1; then
      print_success "Ajustes de permisos abiertos (MIUI)"
    elif am start -a android.settings.action.MANAGE_OVERLAY_PERMISSION -d package:com.termux >/dev/null 2>&1; then
      print_success "Ajustes de 'Mostrar sobre otras apps' abiertos"
    elif am start -a android.settings.APPLICATION_DETAILS_SETTINGS -d package:com.termux >/dev/null 2>&1; then
      print_success "Info de la app Termux abierta"
    else
      print_warning "Abrilo a mano: Ajustes → Apps → Termux → Otros permisos → Mostrar ventanas emergentes mientras se ejecuta en segundo plano"
    fi
    print_info "En MIUI el permiso se llama 'Mostrar ventanas emergentes mientras se ejecuta en segundo plano'."
  fi

  # Abre Termux:Widget para que solo quede tocar CREATE SHORTCUTS.
  read -p "¿Abrir Termux:Widget para crear los atajos? [S/n]: " tw_ok
  if [[ ! "$tw_ok" =~ ^[Nn]$ ]]; then
    am start -n com.termux.widget/.activities.TermuxWidgetMainActivity >/dev/null 2>&1 ||
      print_warning "No se pudo abrir Termux:Widget (¿está instalado?)"
  fi
  print_info "En Termux:Widget tocá CREATE SHORTCUTS para publicar opencode y nvim con sus íconos."
  print_info "Después: mantené presionado el ícono de Termux:Widget en el launcher y añadí el atajo al inicio."
fi

# ═══════════════════════════════════════════════════════════
# PASO 22d: Voice/Dictación AGY CLI
# ───────────────────────────────────────────────────────────
# AGY tiene dictado de voz nativo (F5 o /voice dentro del TUI).
# Funciona vía WebSocket al backend de Google — no depende de
# ningún binario local de audio ni de la app Termux:API.
# Lo que sí se necesita:
#   • Permiso de MICRÓFONO en la app Termux (Android Settings)
#   • voice-engine-addr = "default" en settings.json (ya incluido
#     en dotfiles-dizzi/Antigravity/.gemini/antigravity-cli/settings.json)
#   • Keybinding voice.start_dictation = F5 (ya en keybindings.json)
# Para usar el micrófono de otra máquina vía SSH:
#   En el host: agy mic-serve --addr 127.0.0.1:4713
#   En Termux:  voice-engine-addr = "ws://HOST:4713"
# ═══════════════════════════════════════════════════════════
print_step "22d/23: Voice/Dictación AGY"
AGY_SETTINGS_DIR="${HOME}/.gemini/antigravity-cli"
AGY_SETTINGS="${AGY_SETTINGS_DIR}/settings.json"
AGY_KEYBINDINGS="${AGY_SETTINGS_DIR}/keybindings.json"

# Verificar si AGY está instalado
if ! command -v agy &>/dev/null && [[ ! -f "${HOME}/.local/share/core-termux-data/antigravity-cli/agy.va39" ]]; then
  print_warning "agy no encontrado; saltando configuración de voice (instala AGY primero)"
else
  mkdir -p "$AGY_SETTINGS_DIR"

  # --- settings.json: agregar voice-engine-addr si no existe ---
  if [[ -f "$AGY_SETTINGS" ]]; then
    if ! grep -q '"voice-engine-addr"' "$AGY_SETTINGS"; then
      # Insertar antes del último }
      sed -i 's/^}$/  "voice-engine-addr": "default"\n}/' "$AGY_SETTINGS"
      print_success "voice-engine-addr agregado a settings.json"
    else
      print_info "voice-engine-addr ya configurado en settings.json"
    fi
  else
    # Crear settings mínimo con voice
    cat >"$AGY_SETTINGS" <<'AGYSETTINGS'
{
  "agentMode": "accept-edits",
  "allowNonWorkspaceAccess": true,
  "voice-engine-addr": "default"
}
AGYSETTINGS
    chmod 600 "$AGY_SETTINGS"
    print_success "settings.json creado con voice habilitado"
  fi

  # --- keybindings.json: agregar voice.start_dictation = F5 ---
  if [[ -f "$AGY_KEYBINDINGS" ]]; then
    if ! grep -q '"voice.start_dictation"' "$AGY_KEYBINDINGS"; then
      sed -i 's/^}$/  "voice.start_dictation": ["f5"]\n}/' "$AGY_KEYBINDINGS"
      print_success "voice.start_dictation (F5) agregado a keybindings.json"
    else
      print_info "voice.start_dictation ya está en keybindings.json"
    fi
  fi

  # --- Permiso de micrófono en Android ---
  print_info "Voice/Dictación AGY configurado:"
  print_info "  • F5 (o /voice en el TUI) → inicia/para el dictado"
  print_info "  • El texto transcripto se inserta directo en el prompt"
  print_info "  • Máx. 3m 30s por sesión (autostop automático)"
  print_info ""
  print_info "⚠️  PERMISO REQUERIDO: Ajustes → Apps → Termux → Permisos → Micrófono → Permitir"

  # Intentar abrir los ajustes de permisos de Termux directamente
  read -p "  ¿Abrir ajustes de permisos de Termux ahora? [S/n]: " mic_perm_ok
  if [[ ! "$mic_perm_ok" =~ ^[Nn]$ ]]; then
    if am start -a android.settings.APPLICATION_DETAILS_SETTINGS -d package:com.termux >/dev/null 2>&1; then
      print_success "Ajustes de Termux abiertos → tocá Permisos → Micrófono"
    elif am start -n com.miui.securitycenter/com.miui.permcenter.permissions.PermissionsEditorActivity \
        --es extra_pkgname com.termux >/dev/null 2>&1; then
      print_success "Ajustes de permisos abiertos (MIUI)"
    else
      print_warning "Abrí manualmente: Ajustes → Apps → Termux → Permisos → Micrófono"
    fi
  fi

  # mic-serve: modo avanzado para redirigir micrófono remoto
  print_info ""
  print_info "mic-serve (opcional, para Termux sobre SSH):"
  print_info "  En la máquina CON micrófono: agy mic-serve --addr 127.0.0.1:4713"
  print_info "  En settings.json de Termux:  \"voice-engine-addr\": \"ws://HOST:4713\""
fi

# ═══════════════════════════════════════════════════════════
# PASO 23: Finalización
# ═══════════════════════════════════════════════════════════
print_step "23/23: Finalización"

clear
cat <<'FINAL'
╔══════════════════════════════════════════════════════════╗
║          🎉 INSTALACIÓN COMPLETADA 🎉                   ║
╠══════════════════════════════════════════════════════════╣
║  ✅ Sistema + Git (auto-push habilitado)                ║
║  ✅ Zsh + Plugins                                       ║
║  ✅ Starship/Oh-My-Posh                                 ║
║  ✅ CLI Modernas (btop, bat, eza, fzf…)                ║
║  ✅ IA Tools                                            ║
║  ✅ Core-Termux + OpenCode                              ║
║  ✅ .gitignore seguro                                   ║
║  ✅ Workspace + Discord RPC                             ║
║  ✅ pyenv removido                                      ║
║  ✅ Voice/Dictación AGY (F5 en el TUI)                 ║
╚══════════════════════════════════════════════════════════╝
FINAL

echo -e "\n${GREEN}🚀 Git Config:${NC}"
echo -e "  ${CYAN}✅ push.autoSetupRemote = true${NC}"
echo -e "  ${CYAN}Ahora solo: git push (sin --set-upstream)${NC}"

echo -e "\n${YELLOW}⚠️  IMPORTANTE - API Keys:${NC}"
echo -e "  ${CYAN}NUNCA commitear .opencommit o *api-keys*${NC}"
echo -e "  ${CYAN}Usar variables de entorno en ~/.zshrc${NC}"

echo -e "\n${GREEN}Siguiente:${NC}"
echo -e "  ${CYAN}1.${NC} source ~/.zshrc  ${GREEN}# (automático, ver abajo)${NC}"
echo -e "  ${CYAN}2.${NC} gh auth login"
echo -e "  ${CYAN}3.${NC} git push  ${GREEN}# ¡Sin --set-upstream!${NC}"
echo ""

# ─────────────────────────────────────────────────────────────
# Core-Termux: comandos del README (core --help para todos)
# ─────────────────────────────────────────────────────────────
if command -v core >/dev/null 2>&1; then
  echo -e "\n${MAGENTA}${BOLD}🧰 Core-Termux — Comandos principales${NC}"
  echo -e "  ${CYAN}core --version${NC}              Versión"
  echo -e "  ${CYAN}core install <módulo>${NC}       Instalar módulo (lang|db|ai|editor|dev|npm|shell|ui|auto)"
  echo -e "  ${CYAN}core install ai --opencode --ollama${NC}  Solo esos agentes"
  echo -e "  ${CYAN}core list ai${NC}                Ver agentes y estado"
  echo -e "  ${CYAN}core show ai --opencode${NC}     Doc de un tool"
  echo -e "  ${CYAN}core update core${NC}            Actualizar framework"
  echo -e "  ${CYAN}core reinstall ai --opencode${NC} Reinstalar sin desinstalar todo"
  echo -e "  ${CYAN}core agent ask -p \"...\"${NC}     Asistente IA local"
  echo -e "  ${CYAN}core brain save/search${NC}      Memoria (second brain)"
  echo -e "  ${CYAN}core env set${NC}                Variables env (API keys)"
  echo -e "  ${CYAN}core pg start${NC}               Postgres"
  echo -e "  ${CYAN}core init next|react|nest|express${NC}  Configurar proyecto"
  echo -e "  ${CYAN}core voice opencode${NC}         Voz → opencode"
  echo -e "  ${CYAN}agy voice (F5/${NC}/voice${CYAN})${NC}       Dictado voz → AGY CLI"
  echo ""
fi

# Recargar zsh con el .zshrc nuevo (mata el prompt fantasma de oh-my-posh viejo).
# Si se cancela, el usuario recarga manualmente con `exec zsh`.
echo -e "${CYAN}🔄 Recargando zsh con la config nueva...${NC}"
exec zsh
