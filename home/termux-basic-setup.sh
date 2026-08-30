
#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# TERMUX SETUP COMPLETO - Versión Final con Git Config
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
║   📱 SETUP FINAL - Con Git Auto Push 🚀                 ║
╚══════════════════════════════════════════════════════════╝
BANNER

read -p "Presiona Enter..."

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
print_step "4/23: Desarrollo"
pkg install -y clang make cmake python nodejs-lts rust golang >/dev/null 2>&1
print_success "Entorno de desarrollo"
print_info "pyenv NO recomendado en Termux"

# ═══════════════════════════════════════════════════════════
# PASO 5: Editores
# ═══════════════════════════════════════════════════════════
print_step "5/23: Editores"
pkg install -y neovim vim nano micro >/dev/null 2>&1
mkdir -p ~/bin
cat > ~/bin/termux-file-editor << 'EDITOR'
#!/bin/bash
nvim "$@"
EDITOR
chmod +x ~/bin/termux-file-editor
grep -q "EDITOR=nvim" ~/.bashrc 2>/dev/null || echo 'export EDITOR=nvim' >> ~/.bashrc
print_success "Editores instalados"

# ═══════════════════════════════════════════════════════════
# PASO 6: CLI Modernas
# ═══════════════════════════════════════════════════════════
print_step "6/23: CLI Modernas"
pkg install -y bat eza fd ripgrep fzf jq tree htop ncdu duf dust zoxide >/dev/null 2>&1
print_success "CLI modernas"

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
    chsh -s zsh && print_success "zsh es ahora tu shell por defecto (reabrí Termux)" \
      || print_warning "chsh falló — corré manualmente: chsh -s zsh"
  fi

  if [[ ! -d ~/.oh-my-zsh ]]; then
    print_installing "Oh-My-Zsh..."
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" >/dev/null 2>&1
  fi
  
  ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  
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
# PASO 9: Prompts
# ═══════════════════════════════════════════════════════════
print_step "9/23: Prompts"
echo "Elige tu prompt:"
echo "  1) Starship (recomendado - ligero)"
echo "  2) Oh-My-Posh (más features)"
echo "  3) Ninguno"
read -p "Opción [1-3]: " prompt_choice

case "$prompt_choice" in
  1)
    pkg install -y starship >/dev/null 2>&1
    mkdir -p ~/.config
    # NO generar preset si ya hay config propia (stow usa ~/.config/starship/starship.toml)
    if [[ ! -f ~/.config/starship/starship.toml && ! -f ~/.config/starship.toml ]]; then
      starship preset nerd-font-symbols -o ~/.config/starship.toml 2>/dev/null
    fi
    print_success "Starship instalado"
    ;;
  2)
    pkg install -y oh-my-posh >/dev/null 2>&1
    print_success "Oh-My-Posh instalado"
    ;;
  *)
    print_warning "Prompts omitidos"
    ;;
esac

# ═══════════════════════════════════════════════════════════
# PASO 10: Pokemon (CON FIX)
# ═══════════════════════════════════════════════════════════
print_step "10/23: Pokemon-colorscripts"
read -p "¿Instalar pokemon? [S/n]: " pokemon_install
if [[ ! "$pokemon_install" =~ ^[Nn]$ ]]; then
  if ! command -v pokemon-colorscripts &> /dev/null; then
    if timeout 30 git clone --depth 1 https://gitlab.com/phoneybadger/pokemon-colorscripts.git /tmp/pokemon 2>/dev/null; then
      cd /tmp/pokemon
      timeout 30 ./install.sh >/dev/null 2>&1 && print_success "Pokemon OK" || {
        mkdir -p ~/.local/bin
        cat > ~/.local/bin/pokemon-colorscripts << 'POKE'
#!/bin/bash
POKEMONS=("⚡ Pikachu" "🔥 Charizard" "🌱 Bulbasaur")
echo "${POKEMONS[$RANDOM % ${#POKEMONS[@]}]}"
POKE
        chmod +x ~/.local/bin/pokemon-colorscripts
        print_warning "Pokemon simple"
      }
      cd ~; rm -rf /tmp/pokemon
    fi
  fi
fi

# Resto de pasos (11-18) - igual que antes
print_step "11/23: Tmux"
pkg install -y tmux >/dev/null 2>&1
[[ ! -f ~/.tmux.conf ]] && cat > ~/.tmux.conf << 'TMUX'
set -g mouse on
set -g base-index 1
TMUX
print_success "Tmux"

print_step "12/23: Yazi"
pkg install -y yazi >/dev/null 2>&1
print_success "Yazi"

print_step "13/23: Fastfetch"
pkg install -y fastfetch 2>/dev/null || pkg install -y neofetch 2>/dev/null
print_success "System info"

print_step "14/23: Termux-API"
pkg install -y termux-api >/dev/null 2>&1
print_success "termux-api"

print_step "15/23: Aliases"
[[ ! -f ~/.termux_aliases ]] && cat > ~/.termux_aliases << 'ALIASES'
alias ai='tgpt'; alias ask='tgpt -i'
alias g='git'; alias gs='git status'
alias dot='cd ~/dotfiles-dizzi'
alias ddot='cd ~/dotfiles-dizzi'
ALIASES
# Cargar aliases en shells (bash y zsh)
grep -q "termux_aliases" ~/.bashrc 2>/dev/null || echo 'source ~/.termux_aliases' >> ~/.bashrc
grep -q "termux_aliases" ~/.zshrc 2>/dev/null || echo 'source ~/.termux_aliases' >> ~/.zshrc
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

    oc_ok() { # 0 si opencode responde como OpenCode (no como Bun sin module graph)
      command -v opencode &>/dev/null || return 1
      [[ "$(opencode --version 2>/dev/null)" == "1.2.13" ]] && return 1
      opencode --help 2>&1 | head -1 | grep -qi '^Bun ' && return 1
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
      print_info "Ruta A (recomendada, sin proot): bun-termux + binario oficial."
      print_info "  curl -fsSL https://raw.githubusercontent.com/Happ1ness-dev/bun-termux/main/manager | bash -s install"
      print_info "  curl -LO https://github.com/anomalyco/opencode/releases/latest/download/opencode-linux-arm64.tar.gz"
      print_info "  mkdir -p ~/.opencode/bin && tar -xzf opencode-linux-arm64.tar.gz -C ~/.opencode/bin/"
      print_info "  python ~/bun-termux/helper_scripts/replace_runtime.py ~/.opencode/bin/opencode"
      print_info "  export PATH=\"\$HOME/.opencode/bin:\$PATH\"  → agregar a ~/.zshrc"
      print_info "Verificar: opencode --version debe dar ≥1.18 (no la versión de Bun)."
    fi
  fi

  npm install -g opencommit 2>/dev/null
  pip install pywal --break-system-packages 2>/dev/null
  pkg install -y proot-distro imagemagick >/dev/null 2>&1
  print_success "IA Tools"
fi
print_info "Claude Code/Gemini CLI: solo vía proot-distro (Ubuntu/Debian)"

print_step "17/23: Fira Code"
read -p "¿Instalar Fira Code? [S/n]: " font_install
if [[ ! "$font_install" =~ ^[Nn]$ ]] && [[ ! -f ~/.termux/font.ttf ]]; then
  pkg install -y wget unzip >/dev/null 2>&1
  mkdir -p ~/.termux/fonts; cd ~/.termux/fonts
  wget -q https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/FiraCode.zip && \
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
    # Stow desde la raíz: cada paquete del repo tiene estructura .config/
    for pkg in nvim starship zsh tmux opencode fastfetch bottom htop neofetch yazi zellij kew fish font fonts icons local mcphub etc; do
      [[ -d "$pkg" ]] && stow "$pkg" --adopt 2>/dev/null | grep -v "BUG" || true
    done
    cd ~
    print_success "Dotfiles ($DOTFILES)"
  fi
fi

# ═══════════════════════════════════════════════════════════
# PASO 19: Parchar .zshrc
# ═══════════════════════════════════════════════════════════
print_step "19/23: Silenciar Avisos"
read -p "¿Parchar .zshrc? [S/n]: " patch_zshrc
if [[ ! "$patch_zshrc" =~ ^[Nn]$ ]] && [[ -f ~/.zshrc ]]; then
  cp ~/.zshrc ~/.zshrc.backup-$(date +%s)
  
  # oh-my-posh: envolver en guard (rompe el prompt si no está instalado)
  sed -i 's|^eval "$(oh-my-posh init zsh)"|command -v oh-my-posh >/dev/null 2>\&\& eval "$(oh-my-posh init zsh)"|' ~/.zshrc
  sed -i 's/^eval "$(pyenv/# eval "$(pyenv  # pyenv no funciona/' ~/.zshrc 2>/dev/null
  sed -i 's|^source ~/\.api-keys\.sh|\[ -f ~/\.api-keys\.sh \] \&\& source ~/\.api-keys\.sh|' ~/.zshrc 2>/dev/null
  
  ! grep -q "HISTFILE=" ~/.zshrc && cat >> ~/.zshrc << 'HIST'
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY SHARE_HISTORY
HIST
  
  ! grep -q "go/bin" ~/.zshrc && echo 'export PATH=$PATH:~/go/bin:~/.local/bin' >> ~/.zshrc
  
  command -v starship &> /dev/null && ! grep -q "starship init" ~/.zshrc && \
    echo 'command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"' >> ~/.zshrc

  # Usar la config de starship del repo (stoweada), no el preset genérico
  ! grep -q "STARSHIP_CONFIG" ~/.zshrc && [[ -f ~/.config/starship/starship.toml ]] && \
    echo 'export STARSHIP_CONFIG=~/.config/starship/starship.toml' >> ~/.zshrc

  # Starship: silenciar configs órfanas con claves desconocidas (p.ej. [battery] de StarshipRoot)
  if command -v starship >/dev/null 2>&1 && [[ -f ~/.config/starship.toml ]] \
     && ! grep -q "\[battery\]" ~/.config/starship.toml; then
    echo -e '\n[battery]\ndisabled = true' >> ~/.config/starship.toml
  fi

  # Fastfetch: el .zshrc heredado del laptop arranca wallpaper-prompt-fastfetch (depende de
  # swww/Hyprland, que NO existen en Termux) → cae en fallback sin la config del repo.
  # Reemplazar por llamada portable: config stoweada (~/.config/fastfetch/config.jsonc).
  grep -q "wallpaper-prompt-fastfetch" ~/.zshrc && \
    sed -i 's|^.*wallpaper-prompt-fastfetch.*$|command -v fastfetch >/dev/null 2>\&1 \&\& fastfetch --config ~/.config/fastfetch/config.jsonc|' ~/.zshrc
  
  print_success ".zshrc parchado"
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
        cat >> .gitignore << 'IGNORE'

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
# PASO 21: Rama Termux
# ═══════════════════════════════════════════════════════════
print_step "21/23: Rama Termux"
read -p "¿Crear rama termux? [S/n]: " create_branch
if [[ ! "$create_branch" =~ ^[Nn]$ ]]; then
  for dir in ~/dotfiles-dizzi ~/dotfiles-termux ~/dotfiles; do
    [[ -d "$dir" ]] && cd "$dir" && break
  done
  
  if git rev-parse --git-dir >/dev/null 2>&1; then
    if ! git show-ref --verify --quiet refs/heads/termux; then
      git checkout -b termux 2>/dev/null
      mkdir -p termux zsh-termux
      [[ -f ~/.zshrc ]] && cp ~/.zshrc zsh-termux/.zshrc
      git add . 2>/dev/null
      git commit -m "feat: rama termux" 2>/dev/null || true
      print_success "Rama creada"
    fi
  fi
  cd ~
fi

# ═══════════════════════════════════════════════════════════
# PASO 22: Workspace + Discord RPC
# ═══════════════════════════════════════════════════════════
print_step "22/23: Workspace + Discord RPC"
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
    (cd ~/workspace/opencode-discord-rpc && npm install --silent && npm run build --silent) \
      && print_success "discord-rpc compilado" || print_warning "build falló, revisa npm"
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
║  ✅ IA Tools                                            ║
║  ✅ .gitignore seguro                                   ║
║  ✅ Workspace + Discord RPC                             ║
║  ✅ pyenv removido                                      ║
╚══════════════════════════════════════════════════════════╝
FINAL

echo -e "\n${GREEN}🚀 Git Config:${NC}"
echo -e "  ${CYAN}✅ push.autoSetupRemote = true${NC}"
echo -e "  ${CYAN}Ahora solo: git push (sin --set-upstream)${NC}"

echo -e "\n${YELLOW}⚠️  IMPORTANTE - API Keys:${NC}"
echo -e "  ${CYAN}NUNCA commitear .opencommit o *api-keys*${NC}"
echo -e "  ${CYAN}Usar variables de entorno en ~/.zshrc${NC}"

echo -e "\n${GREEN}Siguiente:${NC}"
echo -e "  ${CYAN}1.${NC} source ~/.zshrc"
echo -e "  ${CYAN}2.${NC} gh auth login"
echo -e "  ${CYAN}3.${NC} git push  ${GREEN}# ¡Sin --set-upstream!${NC}"
echo ""
