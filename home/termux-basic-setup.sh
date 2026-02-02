#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# TERMUX SETUP COMPLETO - TODO EN UN SOLO SCRIPT
# ═══════════════════════════════════════════════════════════════════════════════

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; MAGENTA='\033[0;35m'; CYAN='\033[0;36m'
BOLD='\033[1m'; NC='\033[0m'

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
║   📱 SETUP COMPLETO - TODO EN UN SCRIPT 🚀              ║
╚══════════════════════════════════════════════════════════╝
BANNER

read -p "Presiona Enter..."

# ═══════════════════════════════════════════════════════════
# PASO 1: Sistema
# ═══════════════════════════════════════════════════════════
print_step "1/21: Sistema"
pkg update -y >/dev/null 2>&1 && pkg upgrade -y >/dev/null 2>&1
print_success "Sistema actualizado"

# ═══════════════════════════════════════════════════════════
# PASO 2: Básicos
# ═══════════════════════════════════════════════════════════
print_step "2/21: Básicos"
pkg install -y git curl wget openssh coreutils findutils grep sed gawk \
  tar gzip bzip2 xz-utils unzip zip procps less man ncurses-utils termux-api >/dev/null 2>&1
print_success "Herramientas básicas"

# ═══════════════════════════════════════════════════════════
# PASO 3: Desarrollo
# ═══════════════════════════════════════════════════════════
print_step "3/21: Desarrollo"
pkg install -y clang make cmake python nodejs-lts rust golang >/dev/null 2>&1
print_success "Entorno de desarrollo"
print_info "pyenv NO recomendado en Termux (usar Python del sistema)"

# ═══════════════════════════════════════════════════════════
# PASO 4: Editores
# ═══════════════════════════════════════════════════════════
print_step "4/21: Editores"
pkg install -y neovim vim nano micro >/dev/null 2>&1
mkdir -p ~/bin
cat > ~/bin/termux-file-editor << 'EDITOR'
#!/bin/bash
nvim "$@"
EDITOR
chmod +x ~/bin/termux-file-editor
grep -q "EDITOR=nvim" ~/.bashrc 2>/dev/null || echo 'export EDITOR=nvim' >> ~/.bashrc
grep -q "VISUAL=nvim" ~/.bashrc 2>/dev/null || echo 'export VISUAL=nvim' >> ~/.bashrc
print_success "Editores instalados"

# ═══════════════════════════════════════════════════════════
# PASO 5: CLI Modernas
# ═══════════════════════════════════════════════════════════
print_step "5/21: CLI Modernas"
pkg install -y bat eza fd ripgrep fzf jq tree htop ncdu duf dust zoxide >/dev/null 2>&1
print_success "CLI modernas"

# ═══════════════════════════════════════════════════════════
# PASO 6: GitHub CLI
# ═══════════════════════════════════════════════════════════
print_step "6/21: GitHub CLI"
pkg install -y gh >/dev/null 2>&1
print_success "gh instalado"
print_info "Autenticar: gh auth login"

# ═══════════════════════════════════════════════════════════
# PASO 7: Zsh Plugins
# ═══════════════════════════════════════════════════════════
print_step "7/21: Zsh + Plugins"
read -p "¿Instalar Zsh+Plugins? [S/n]: " zsh_install

if [[ ! "$zsh_install" =~ ^[Nn]$ ]]; then
  pkg install -y zsh >/dev/null 2>&1
  
  # Oh-My-Zsh
  if [[ ! -d ~/.oh-my-zsh ]]; then
    print_installing "Oh-My-Zsh..."
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" >/dev/null 2>&1
  fi
  
  ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  
  # Plugins
  print_installing "Plugins..."
  [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]] && \
    git clone --depth 1 -q https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" 2>/dev/null
  
  [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]] && \
    git clone --depth 1 -q https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM/plugins/zsh-autosuggestions" 2>/dev/null
  
  [[ ! -d "$ZSH_CUSTOM/plugins/zsh-completions" ]] && \
    git clone --depth 1 -q https://github.com/zsh-users/zsh-completions.git "$ZSH_CUSTOM/plugins/zsh-completions" 2>/dev/null
  
  [[ ! -d "$ZSH_CUSTOM/plugins/zsh-history-substring-search" ]] && \
    git clone --depth 1 -q https://github.com/zsh-users/zsh-history-substring-search.git "$ZSH_CUSTOM/plugins/zsh-history-substring-search" 2>/dev/null
  
  mkdir -p ~/.zsh
  [[ ! -d ~/.zsh/zsh-autocomplete ]] && \
    git clone --depth 1 -q https://github.com/marlonrichert/zsh-autocomplete.git ~/.zsh/zsh-autocomplete 2>/dev/null
  
  [[ ! -d ~/.zsh/fzf-tab ]] && \
    git clone --depth 1 -q https://github.com/Aloxaf/fzf-tab.git ~/.zsh/fzf-tab 2>/dev/null
  
  print_success "Plugins instalados"
  print_warning "Tu .zshrc NO ha sido modificado"
fi

# ═══════════════════════════════════════════════════════════
# PASO 8: Prompts (Starship o Oh-My-Posh)
# ═══════════════════════════════════════════════════════════
print_step "8/21: Prompts"
echo "Elige tu prompt:"
echo "  1) Starship (recomendado - ligero)"
echo "  2) Oh-My-Posh (más features)"
echo "  3) Ninguno"
read -p "Opción [1-3]: " prompt_choice

case "$prompt_choice" in
  1)
    print_installing "Starship..."
    pkg install -y starship >/dev/null 2>&1
    mkdir -p ~/.config
    [[ ! -f ~/.config/starship.toml ]] && starship preset nerd-font-symbols -o ~/.config/starship.toml 2>/dev/null
    print_success "Starship instalado"
    print_info "Agregar a .zshrc: eval \"\$(starship init zsh)\""
    ;;
  2)
    print_installing "Oh-My-Posh..."
    pkg install -y oh-my-posh >/dev/null 2>&1
    print_success "Oh-My-Posh instalado"
    print_info "Agregar a .zshrc: eval \"\$(oh-my-posh init zsh)\""
    ;;
  *)
    print_warning "Prompts omitidos"
    ;;
esac

# ═══════════════════════════════════════════════════════════
# PASO 9: Pokemon-colorscripts
# ═══════════════════════════════════════════════════════════
print_step "9/21: Pokemon-colorscripts"
read -p "¿Instalar pokemon-colorscripts? [S/n]: " pokemon_install
if [[ ! "$pokemon_install" =~ ^[Nn]$ ]]; then
  if ! command -v pokemon-colorscripts &> /dev/null; then
    print_installing "Instalando..."
    
    # Método 1: Desde GitLab con timeout
    if timeout 30 git clone --depth 1 https://gitlab.com/phoneybadger/pokemon-colorscripts.git /tmp/pokemon 2>/dev/null; then
      cd /tmp/pokemon
      timeout 30 ./install.sh >/dev/null 2>&1 && print_success "Pokemon OK" || {
        print_warning "Install.sh falló, método alternativo..."
        # Método 2: Instalación manual
        mkdir -p ~/.local/bin ~/.local/share/pokemon-colorscripts
        cp pokemon-colorscripts.sh ~/.local/bin/pokemon-colorscripts 2>/dev/null || true
        chmod +x ~/.local/bin/pokemon-colorscripts 2>/dev/null
        print_warning "Pokemon instalado (método manual)"
      }
      cd ~
      rm -rf /tmp/pokemon
    else
      # Método 3: Script fallback
      print_installing "Fallback simple..."
      mkdir -p ~/.local/bin
      cat > ~/.local/bin/pokemon-colorscripts << 'POKE'
#!/bin/bash
POKEMONS=("⚡ Pikachu" "🔥 Charizard" "🌱 Bulbasaur" "💧 Squirtle" "👁️ Mewtwo")
echo "${POKEMONS[$RANDOM % ${#POKEMONS[@]}]}"
POKE
      chmod +x ~/.local/bin/pokemon-colorscripts
      print_warning "Pokemon simplificado"
    fi
  else
    print_success "Ya instalado"
  fi
fi

# ═══════════════════════════════════════════════════════════
# PASO 10: Tmux
# ═══════════════════════════════════════════════════════════
print_step "10/21: Tmux"
pkg install -y tmux >/dev/null 2>&1
if [[ ! -f ~/.tmux.conf ]]; then
  cat > ~/.tmux.conf << 'TMUX'
set -g mouse on
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on
bind r source-file ~/.tmux.conf \; display "Recargado!"
bind | split-window -h
bind - split-window -v
set -g default-terminal "screen-256color"
TMUX
fi
print_success "Tmux configurado"

# ═══════════════════════════════════════════════════════════
# PASO 11: Yazi
# ═══════════════════════════════════════════════════════════
print_step "11/21: Yazi"
pkg install -y yazi >/dev/null 2>&1
print_success "Yazi instalado"

# ═══════════════════════════════════════════════════════════
# PASO 12: Fastfetch
# ═══════════════════════════════════════════════════════════
print_step "12/21: Fastfetch"
pkg install -y fastfetch 2>/dev/null || pkg install -y neofetch 2>/dev/null
print_success "System info instalado"

# ═══════════════════════════════════════════════════════════
# PASO 13: Termux-API
# ═══════════════════════════════════════════════════════════
print_step "13/21: Termux-API"
pkg install -y termux-api >/dev/null 2>&1
print_success "termux-api instalado"
print_warning "Instala 'Termux:API' desde F-Droid"

# ═══════════════════════════════════════════════════════════
# PASO 14: Aliases
# ═══════════════════════════════════════════════════════════
print_step "14/21: Aliases"
if [[ ! -f ~/.termux_aliases ]]; then
  cat > ~/.termux_aliases << 'ALIASES'
alias ..='cd ..'; alias ...='cd ../..'; alias ~='cd ~'
command -v eza &> /dev/null && alias ls='eza --icons' && alias ll='eza -lah --icons'
command -v bat &> /dev/null && alias cat='bat'
alias v='nvim'; alias vi='nvim'; alias vim='nvim'
alias g='git'; alias gs='git status'; alias ga='git add'; alias gc='git commit'
alias gp='git push'; alias gl='git log --oneline --graph'
alias update='pkg update && pkg upgrade'
alias py='python'; alias n='node'; alias np='npm'
alias ai='tgpt'; alias ask='tgpt -i'; alias commit='opencommit'
alias ff='fastfetch'; alias fm='yazi'
command -v pokemon-colorscripts &> /dev/null && alias poke='pokemon-colorscripts -r'
ALIASES
fi
print_success "Aliases configurados"

# ═══════════════════════════════════════════════════════════
# PASO 15: IA Tools Básicas
# ═══════════════════════════════════════════════════════════
print_step "15/21: IA Tools Básicas"
read -p "¿Instalar IA Tools básicas? [S/n]: " ia_install
if [[ ! "$ia_install" =~ ^[Nn]$ ]]; then
  # tgpt
  if ! command -v tgpt &> /dev/null; then
    print_installing "tgpt..."
    curl -sSL https://github.com/aandrew-me/tgpt/releases/latest/download/tgpt-linux-arm64 \
      -o /data/data/com.termux/files/usr/bin/tgpt 2>/dev/null && \
      chmod +x /data/data/com.termux/files/usr/bin/tgpt && \
      print_success "tgpt OK" || print_warning "tgpt falló"
  fi
  
  # opencommit
  print_installing "opencommit..."
  npm install -g opencommit 2>/dev/null && print_success "opencommit OK" || print_warning "opencommit falló"
  
  # pywal
  print_installing "pywal..."
  pip install pywal --break-system-packages 2>/dev/null && print_success "pywal OK" || true
  
  pkg install -y imagemagick 2>/dev/null
  
  # proot-distro
  print_installing "proot-distro..."
  pkg install -y proot-distro >/dev/null 2>&1
  print_success "proot-distro OK"
fi

# ═══════════════════════════════════════════════════════════
# PASO 16: IA Tools Avanzadas
# ═══════════════════════════════════════════════════════════
print_step "16/21: IA Tools Avanzadas"
read -p "¿Instalar IAs avanzadas (gemini, claude, aider)? [S/n]: " ia_advanced
if [[ ! "$ia_advanced" =~ ^[Nn]$ ]]; then
  # Gemini
  print_installing "gemini-ai-cli..."
  npm install -g gemini-ai-cli 2>/dev/null && print_success "gemini OK" || print_warning "gemini falló"
  
  # Claude (Python SDK + wrapper)
  print_installing "anthropic (Claude)..."
  pip install anthropic --break-system-packages 2>/dev/null && {
    cat > /data/data/com.termux/files/usr/bin/claude << 'CLAUDE'
#!/usr/bin/env python
import sys, os
from anthropic import Anthropic
client = Anthropic(api_key=os.environ.get("ANTHROPIC_API_KEY"))
if len(sys.argv) < 2:
    print("Uso: claude 'tu pregunta'")
    sys.exit(1)
message = client.messages.create(
    model="claude-sonnet-4-20250514",
    max_tokens=1024,
    messages=[{"role": "user", "content": " ".join(sys.argv[1:])}]
)
print(message.content[0].text)
CLAUDE
    chmod +x /data/data/com.termux/files/usr/bin/claude
    print_success "claude OK"
  } || print_warning "claude falló"
  
  # Aider
  print_installing "aider..."
  pip install aider-chat --break-system-packages 2>/dev/null && print_success "aider OK" || print_warning "aider falló"
  
  # LiteLLM
  print_installing "litellm..."
  pip install litellm --break-system-packages 2>/dev/null && print_success "litellm OK" || true
fi

# ═══════════════════════════════════════════════════════════
# PASO 17: Fira Code
# ═══════════════════════════════════════════════════════════
print_step "17/21: Fira Code Nerd Font"
read -p "¿Instalar Fira Code? [S/n]: " font_install
if [[ ! "$font_install" =~ ^[Nn]$ ]]; then
  if [[ ! -f ~/.termux/fonts/FiraCodeNerdFont-Regular.ttf ]]; then
    print_installing "Descargando..."
    pkg install -y wget unzip >/dev/null 2>&1
    mkdir -p ~/.termux/fonts
    cd ~/.termux/fonts
    wget -q https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/FiraCode.zip 2>/dev/null && \
      unzip -q FiraCode.zip && rm FiraCode.zip && \
      print_success "Fira Code OK" || print_warning "Error descargando"
    cd ~
    print_info "Aplicar: termux-reload-settings"
  else
    print_success "Ya instalada"
  fi
fi

# ═══════════════════════════════════════════════════════════
# PASO 18: Stow + Dotfiles
# ═══════════════════════════════════════════════════════════
print_step "18/21: Stow + Dotfiles"
read -p "¿Configurar dotfiles? [S/n]: " stow_install
if [[ ! "$stow_install" =~ ^[Nn]$ ]]; then
  pkg install -y stow >/dev/null 2>&1
  
  DOT_DIR=""
  for dir in ~/dotfiles-dizzi ~/dotfiles-termux ~/dotfiles; do
    [[ -d "$dir" ]] && DOT_DIR="$dir" && break
  done
  
  if [[ -n "$DOT_DIR" ]] && [[ -d "$DOT_DIR" ]]; then
    cd "$DOT_DIR"
    
    # Verificar si estamos en rama termux
    current_branch=$(git branch --show-current 2>/dev/null || echo "")
    if [[ "$current_branch" != "termux" ]]; then
      print_warning "No estás en rama 'termux'"
      read -p "¿Cambiar a rama termux? [S/n]: " switch_branch
      if [[ ! "$switch_branch" =~ ^[Nn]$ ]]; then
        git checkout termux 2>/dev/null || print_warning "Rama termux no existe"
      fi
    fi
    
    print_info "Aplicando dotfiles..."
    
    # Aplicar solo configs compatibles con Termux
    for pkg in nvim starship tmux yazi fastfetch; do
      [[ -d "$pkg" ]] && {
        stow "$pkg" --adopt 2>&1 | grep -v "BUG" || true
        print_success "$pkg aplicado"
      }
    done
    
    # Para zsh, usar zsh-termux si existe
    if [[ -d "zsh-termux" ]]; then
      stow zsh-termux --adopt 2>&1 | grep -v "BUG" || true
      print_success "zsh-termux aplicado"
    else
      print_warning "zsh omitido (no tocar tu .zshrc)"
    fi
    
    cd ~
  fi
fi

# ═══════════════════════════════════════════════════════════
# PASO 19: Parchar .zshrc (SILENCIAR AVISOS)
# ═══════════════════════════════════════════════════════════
print_step "19/21: Silenciar Avisos en .zshrc"
read -p "¿Silenciar avisos molestos en .zshrc? [S/n]: " patch_zshrc

if [[ ! "$patch_zshrc" =~ ^[Nn]$ ]] && [[ -f ~/.zshrc ]]; then
  print_installing "Parchando .zshrc..."
  
  # Backup
  cp ~/.zshrc ~/.zshrc.backup-$(date +%s) 2>/dev/null
  
  # Silenciar oh-my-posh
  sed -i 's/^eval "$(oh-my-posh/command -v oh-my-posh \&>\/dev\/null \&\& eval "$(oh-my-posh/' ~/.zshrc 2>/dev/null
  
  # REMOVER pyenv completamente (no funciona en Termux)
  sed -i 's/^eval "$(pyenv/# eval "$(pyenv  # pyenv no funciona en Termux/' ~/.zshrc 2>/dev/null
  sed -i '/^export PYENV_ROOT/d' ~/.zshrc 2>/dev/null
  sed -i '/pyenv\/bin/d' ~/.zshrc 2>/dev/null
  
  # Silenciar .api-keys.sh
  sed -i 's|^source ~/\.api-keys\.sh|\[ -f ~/\.api-keys\.sh \] \&\& source ~/\.api-keys\.sh|' ~/.zshrc 2>/dev/null
  sed -i 's|^chmod.*\.api-keys\.sh|\[ -f ~/\.api-keys\.sh \] \&\& &|' ~/.zshrc 2>/dev/null
  
  # Silenciar pokemon
  if ! command -v pokemon-colorscripts &> /dev/null; then
    sed -i 's/^pokemon-colorscripts/# pokemon-colorscripts/' ~/.zshrc 2>/dev/null
    sed -i 's/^command -v pokemon-colorscripts/# command -v pokemon-colorscripts/' ~/.zshrc 2>/dev/null
  fi
  
  # Agregar HISTFILE si no existe
  if ! grep -q "HISTFILE=" ~/.zshrc; then
    cat >> ~/.zshrc << 'HIST'

# HISTORIAL
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_ALL_DUPS
HIST
  fi
  
  # Agregar PATH si no existe
  if ! grep -q "go/bin" ~/.zshrc; then
    echo 'export PATH=$PATH:~/go/bin:~/.local/bin' >> ~/.zshrc
  fi
  
  # Agregar prompt elegido
  if command -v starship &> /dev/null && ! grep -q "starship init" ~/.zshrc; then
    cat >> ~/.zshrc << 'STARSHIP'

# Starship
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"
STARSHIP
  elif command -v oh-my-posh &> /dev/null && ! grep -q "oh-my-posh init" ~/.zshrc; then
    cat >> ~/.zshrc << 'OHMYPOSH'

# Oh-My-Posh
command -v oh-my-posh >/dev/null 2>&1 && eval "$(oh-my-posh init zsh)"
OHMYPOSH
  fi
  
  # Silenciador global
  if ! grep -q "command_not_found_handler" ~/.zshrc; then
    cat >> ~/.zshrc << 'HANDLER'

# Silenciador de errores
command_not_found_handler() {
  case "$1" in
    pokemon-colorscripts|gh|oh-my-posh|pyenv|ollama) return 127 ;;
    *) printf "zsh: command not found: %s\n" "$1" >&2; return 127 ;;
  esac
}
HANDLER
  fi
  
  print_success ".zshrc parchado"
  print_info "Backup: ~/.zshrc.backup-*"
  print_info "pyenv REMOVIDO (no funciona en Termux)"
elif [[ ! "$patch_zshrc" =~ ^[Nn]$ ]]; then
  print_warning ".zshrc no encontrado"
fi

# ═══════════════════════════════════════════════════════════
# PASO 20: Crear Rama Termux (Opcional)
# ═══════════════════════════════════════════════════════════
print_step "20/21: Rama Termux (Opcional)"
read -p "¿Crear rama 'termux' en dotfiles? [S/n]: " create_branch

if [[ ! "$create_branch" =~ ^[Nn]$ ]]; then
  DOT_DIR=""
  for dir in ~/dotfiles-dizzi ~/dotfiles-termux ~/dotfiles; do
    [[ -d "$dir" ]] && DOT_DIR="$dir" && break
  done
  
  if [[ -n "$DOT_DIR" ]] && [[ -d "$DOT_DIR" ]]; then
    cd "$DOT_DIR"
    
    # Verificar si rama termux ya existe
    if git show-ref --verify --quiet refs/heads/termux; then
      print_info "Rama 'termux' ya existe"
      git checkout termux 2>/dev/null
    else
      print_installing "Creando rama termux..."
      git checkout -b termux 2>/dev/null && {
        # Crear estructura
        mkdir -p termux zsh-termux
        
        # Copiar .zshrc actual
        [[ -f ~/.zshrc ]] && cp ~/.zshrc zsh-termux/.zshrc
        
        # Mover scripts
        [[ -f ~/termux-setup-COMPLETO.sh ]] && cp ~/termux-setup-COMPLETO.sh termux/
        
        git add . 2>/dev/null
        git commit -m "feat(termux): crear rama separada para Termux" 2>/dev/null || true
        
        print_success "Rama termux creada"
        print_info "Push: git push -u origin termux"
      } || print_warning "Error creando rama"
    fi
    
    cd ~
  fi
fi

# ═══════════════════════════════════════════════════════════
# PASO 21: Finalización
# ═══════════════════════════════════════════════════════════
print_step "21/21: Finalización"

clear
cat <<'FINAL'
╔══════════════════════════════════════════════════════════╗
║          🎉 INSTALACIÓN COMPLETADA 🎉                   ║
╠══════════════════════════════════════════════════════════╣
║  ✅ Sistema + desarrollo                                ║
║  ✅ Zsh + Starship/Oh-My-Posh + Plugins                 ║
║  ✅ GitHub CLI (gh)                                     ║
║  ✅ IA Tools (tgpt, gemini, claude, aider)              ║
║  ✅ CLI modernas + Tmux + Yazi                          ║
║  ✅ Fira Code Nerd Font                                 ║
║  ✅ Dotfiles aplicados                                  ║
║  ✅ .zshrc parchado (avisos silenciados)                ║
║  ✅ pyenv REMOVIDO (no funciona en Termux)              ║
╚══════════════════════════════════════════════════════════╝
FINAL

echo -e "\n${GREEN}🚀 Siguiente:${NC}"
echo -e "  ${CYAN}1.${NC} ${YELLOW}source ~/.zshrc${NC}  # Recargar config"
echo -e "  ${CYAN}2.${NC} ${YELLOW}gh auth login${NC}  # Autenticar GitHub"
echo -e "  ${CYAN}3.${NC} ${YELLOW}tgpt 'hola'${NC}  # Probar IA"

echo -e "\n${YELLOW}🔑 Configurar API Keys en ~/.zshrc:${NC}"
echo -e "  ${CYAN}export GEMINI_API_KEY='...'${NC}"
echo -e "  ${CYAN}export ANTHROPIC_API_KEY='sk-ant-...'${NC}"
echo -e "  ${CYAN}export OPENAI_API_KEY='sk-...'${NC}"

echo -e "\n${CYAN}📦 Herramientas instaladas:${NC}"
command -v tgpt >/dev/null && echo -e "${GREEN}  ✅ tgpt${NC}" || echo -e "${RED}  ❌ tgpt${NC}"
command -v gemini >/dev/null && echo -e "${GREEN}  ✅ gemini${NC}" || echo -e "${YELLOW}  ⚠️  gemini${NC}"
command -v claude >/dev/null && echo -e "${GREEN}  ✅ claude${NC}" || echo -e "${YELLOW}  ⚠️  claude${NC}"
command -v aider >/dev/null && echo -e "${GREEN}  ✅ aider${NC}" || echo -e "${YELLOW}  ⚠️  aider${NC}"
command -v opencommit >/dev/null && echo -e "${GREEN}  ✅ opencommit${NC}" || echo -e "${YELLOW}  ⚠️  opencommit${NC}"
command -v gh >/dev/null && echo -e "${GREEN}  ✅ gh${NC}" || echo -e "${RED}  ❌ gh${NC}"
command -v starship >/dev/null && echo -e "${GREEN}  ✅ starship${NC}" || echo -e "${YELLOW}  ⚠️  starship${NC}"
command -v oh-my-posh >/dev/null && echo -e "${GREEN}  ✅ oh-my-posh${NC}" || echo -e "${YELLOW}  ⚠️  oh-my-posh${NC}"

echo -e "\n${CYAN}⚠️  pyenv fue REMOVIDO (no funciona en Termux)${NC}"
echo -e "${CYAN}    Usa el Python del sistema: $(python --version 2>/dev/null || echo 'N/A')${NC}"

echo -e "\n${GREEN}¡Listo! 🎉${NC}\n"
