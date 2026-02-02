# =============================================================================
#
#                    CONFIGURACIÓN DE ZSH EN ARCH LINUX WSL
#
# =============================================================================


# mapear Ctrl + Backspace
bindkey '^H' backward-kill-word
# bindkey '^[[3;5~' kill-word
# Borra la palabra anterior (Ctrl+W)
bindkey '^W' backward-kill-word
#
# # Borra la palabra anterior (Ctrl+Backspace)
# bindkey '^?' backward-kill-word

# ESTO HACE QUE neofetch cargue primero
# si prefieres puedes quitarlo para cargar ANTES el prompt instant.
      typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
      typeset -g POWERLEVEL9K_INSTANT_PROMPT=off

# =============================================================================
#
#                      CONFIGURACIÓN DE HERRAMIENTAS Y PATH
#
# =============================================================================

export PATH="$HOME/.local/bin:$PATH"
# ---------------------------------------------------------------------------------------------
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes


# ---------------------------------------------------------------------------------------------

# ACA ESTAN LOS TEMAS
# ACA ESTAN LOS TEMAS
# ACA ESTAN LOS TEMAS

# Tema original:
# ZSH_THEME="robbyrussell"

# Mi tema preferido de ZSH # pero entra en conflcito con ohmypsoh shell
# ZSH_THEME="powerlevel10k/powerlevel10k"

# /////////////////////////////////////////////////////////////////////////////
# ---------------------------------------------------------------------------------------------
# ///////////////////////////////////////////////////////////////////////

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# DESACTIVAR UPDATES DE OH MY ZSH 🚨
zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
# Correcto:
plugins=(
  git
  zsh-syntax-highlighting
  zsh-autosuggestions
  zsh-completions
  zsh-history-substring-search
    # alias-tips          # OPCIONAL -← FALTA ESTE
    # zsh-vi-mode         # OPCIONAL -← FALTA ESTE
)

# Esta línea debe estar después de 'plugins=()'
# source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# /////////////////////////////////////////////////////////////////////////////
# ---------------------------------------------------------------------------------------------
# ///////////////////////////////////////////////////////////////////////

# ACA ESTAN IMPORTADOS LOS PLUGINS
# ACA ESTAN IMPORTADOS LOS PLUGINS
# ACA ESTAN IMPORTADOS LOS PLUGINS

# Sugerencia y autocompleta en gris [Control+E]
source ~/.zsh/zsh-autocomplete/zsh-autocomplete.plugin.zsh

#Búsqueda interactiva: Cuando presionas Tab para autocompletar un comando, argumento o archivo [tab o ArrowUp o ArrowDown]
source ~/.zsh/fzf-tab/fzf-tab.plugin.zsh

# Consejo: No lo pongas antes de otros plugins como autosuggestions, por conflictos, ya que puede interferir con ellos.

# /////////////////////////////////////////////////////////////////////////////
# ---------------------------------------------------------------------------------------------
# ///////////////////////////////////////////////////////////////////////

# Carga de un programa al iniciar la terminal (opcional).
# fastfetch con wallpaper actual
$HOME/dotfiles-dizzi/home/scripts/wallpaper-prompt-fastfetch


# guardar el historial:
# guardar el historial:
# guardar el historial:

# === Configuración del Historial de Zsh ===
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# Opciones para historial ordenado y sincronizado
setopt EXTENDED_HISTORY          # Guarda timestamps
setopt HIST_EXPIRE_DUPS_FIRST    # Expira duplicados primero
setopt HIST_IGNORE_DUPS          # No guarda duplicados consecutivos
setopt HIST_IGNORE_ALL_DUPS      # Elimina duplicados antiguos del historial
setopt HIST_FIND_NO_DUPS         # No muestra duplicados al buscar
setopt HIST_SAVE_NO_DUPS         # No escribe duplicados al archivo
setopt SHARE_HISTORY             # Comparte historial entre sesiones en tiempo real
setopt INC_APPEND_HISTORY        # Escribe inmediatamente, no al cerrar
setopt HIST_IGNORE_SPACE         # No guarda comandos que empiecen con espacio
setopt HIST_VERIFY               # Confirma sustituciones


# =============================================================================
#
#                     ALIAS, FUNCIONES Y OTRAS OPCIONES
#
# =============================================================================

# ELIMINA ESTAS LÍNEAS (causan problemas):
# function zle-line-finish() {...}
# zle -N zle-line-finish

# === Tu Alias para Guardar y Mostrar el Historial ===
# Aseguramos que /tmp/history sea un archivo y no un directorio.
rm -f /tmp/history

# El alias ahora usará 'fc -l 1' para listar todo el historial desde el principio,
# o 'history 0' que también debería funcionar para obtener todo el historial.
# 'fc -l 1' es a menudo más robusto para obtener todo el historial sin límites.
alias history='fc -l 1 > /tmp/history && cat /tmp/history'
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📂 ALIASES DE EXA (reemplazo moderno de ls)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ls - 🖼️ Ver imágenes en la terminal
alias ls='exa --icons --color=always'

# Aliases NUEVOS (agregar estos):
alias ll='exa -lha --icons --git --color=always'           # Detallado completo
alias la='exa -a --icons --color=always'                   # Mostrar ocultos
alias lt='exa -T --icons --color=always'                   # Árbol simple
alias lta='exa -Ta --icons --color=always'                 # Árbol + ocultos
alias ltl='exa -lTa --icons --git --color=always'          # Árbol detallado
alias lsd='exa -D --icons --color=always'                  # Solo directorios
alias lss='exa -lha --sort=size --reverse --icons'         # Por tamaño
alias lst='exa -lha --sort=modified --reverse --icons'     # Por fecha

# notepad estilo Windows
notepad() {
  if [ $# -eq 0 ]; then
    gedit --new-window >/dev/null 2>&1 &
  else
    gedit --new-window "$@" >/dev/null 2>&1 &
  fi
  disown
}

# explorer estilo Windows
explorer() {
  if [ $# -eq 0 ]; then
    nautilus --new-window >/dev/null 2>&1 &
  else
    nautilus --new-window "$@" >/dev/null 2>&1 &
  fi
  disown
}
# === Tus otros aliases y configuraciones ===


# alias vlc='flatpak run org.videolan.VLC'

# Shell Integration para Ghostty
if [ -n "${GHOSTTY_RESOURCES_DIR}" ]; then
    source "${GHOSTTY_RESOURCES_DIR}/shell-integration/zsh/ghostty-integration"
fi

export PATH=/home/diego/musicpresence/musicpresence-2.3.2-linux-x86_64/usr/bin:$PATH
export PATH=$HOME/cmus/bin:$PATH

# Gemini AI instalacion:
# Añade el directorio global de npm al PATH. NPM_GLOBAL
export PATH=~/.npm-global/bin:$PATH

# ⚙️ Abre la configuración de Wine (winecfg) para el prefijo .wine-11
# ⚙️ Abre la configuración de Wine (w# 1. Función Principal para correr comandos con Wine en el prefijo 11

# 🍷  alternativa a wine del prefijo .wine
# 1. Función Principal para correr comandos con Wine en el prefijo 11
# Uso: wine11 /ruta/al/instalador.exe, o wine11 explorer
wine11() {
    echo "⚙️ Ejecutando comando en el prefijo: /home/diego/.wine-11"
    # El $@ pasa todos los argumentos al comando 'wine'
    WINEPREFIX=/home/diego/.wine-11 wine "$@"
}

# 2. Función para Winetricks
# Uso: wine11tricks d3dx9 corefonts vcrun2022
wine11tricks() {
    echo "⚙️ Ejecutando winetricks en el prefijo: /home/diego/.wine-11"
    # El $@ pasa todos los argumentos al comando 'winetricks'
    WINEPREFIX=/home/diego/.wine-11 winetricks "$@"
}

# 3. Función para Winecfg (Configuración)
# Uso: wine11cfg (no necesita argumentos adicionales)
wine11cfg() {
    echo "⚙️ Abriendo winecfg para el prefijo: /home/diego/.wine-11"
    WINEPREFIX=/home/diego/.wine-11 winecfg
}
wine11uninstaller() {
    echo "⚙️ Abriendo el desinstalador para el prefijo: /home/diego/.wine-11"
    WINEPREFIX=/home/diego/.wine-11 wine uninstaller
}
wineuninstaller() {
    echo "⚙️ Abriendo el desinstalador para el prefijo: /home/diego/.wine-11"
    wine uninstaller
}
wine11file() {
    echo "⚙️ Abriendo winefile para el prefijo: /home/diego/.wine-11"
    WINEPREFIX=/home/diego/.wine-11 winefile
}

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
alias code="code --enable-features=WaylandWindowDecorations --ozone-platform-hint=auto"
alias code="code --enable-features=WaylandWindowDecorations --ozone-platform-hint=auto"

export PATH=$PATH:/home/diego/.spicetify

# =============================================================================
#
#                        CONFIGURACIÓN DEL PROMPT
#
# =============================================================================

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
# Carga la configuración del prompt.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# HABILITAR OH MY POSH [trae mas temas]
# https://ohmyposh.dev/docs/themes
eval "$(oh-my-posh init zsh --config 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/1_shell.omp.json')"

# HABILITAR STARSHIP [AESTHETIC UPGRADE]
# export STARSHIP_CONFIG="$HOME/dotfiles-dizzi/starship/.config/starship/starship.toml"
# eval "$(starship init zsh)"

# Configuración global de Git
git config --global core.quotepath false
git config --global core.precomposeunicode true
git config --global i18n.commitencoding utf-8
git config --global i18n.logoutputencoding utf-8

# Agrega al final del archivo ~/.zshrc
# Reparar problemas de codificación de caracteres. [UTF-8]
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

# ════════════════════════════════════════════════════════════════════════════════════════════════
# Configuración de opencommit (oco) con Ollama ~ [opencommit] > con control de Nothink
# alias aicommit='oco'
# ════════════════════════════════════════════════════════════════════════════════════════════════

# Activar nothink por defecto (commits rápidos)
export OCO_NOTHINK=true

# Wrapper inteligente
aicommit() {
  if [ "$OCO_NOTHINK" = true ]; then
    local nothink_prompt="/set nothink"
    
    if [ $# -eq 0 ]; then
      oco -c "$nothink_prompt"
    else
      oco -c "$nothink_prompt. Context: $*"
    fi
  else
    oco "$@"
  fi
}

# Toggle rápido
aicommit-toggle() {
  if [ "$OCO_NOTHINK" = true ]; then
    export OCO_NOTHINK=false
    echo "🧠 Reasoning activado"
  else
    export OCO_NOTHINK=true
    echo "⚡ Nothink activado"
  fi
}

# Comando para reconfigurar opencommit fácilmente
# Función dinámica para configurar opencommit
aicommitconfig() {
  echo "📦 Configurando opencommit con Ollama..."
  
  # Detectar entorno
  if grep -qi microsoft /proc/version 2>/dev/null; then
    local WINDOWS_HOST=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}')
    local OLLAMA_URL="http://${WINDOWS_HOST}:11434"
    echo "🪟 WSL detectado, usando Windows host: ${WINDOWS_HOST}"
  else
    local OLLAMA_URL="http://localhost:11434"
    echo "🐧 Linux nativo detectado, usando localhost"
  fi
  
  # Verificar conexión
  if ! curl -s "${OLLAMA_URL}/api/tags" &>/dev/null; then
    echo "❌ Ollama no responde"
    return 1
  fi
  
  echo "✅ Ollama detectado en ${OLLAMA_URL}"
  echo ""
  
  # Obtener modelos
  local models=($(ollama list | tail -n +2 | awk '{print $1}'))
  
  if [[ ${#models[@]} -eq 0 ]]; then
    echo "❌ No hay modelos"
    return 1
  fi
  
  echo "Modelos disponibles:"
  echo "💡 Tip: Esta configuración usa /api/chat (optimizado para modelos cloud)"
  echo ""
  
  select model in "${models[@]}" "❌ Cancelar"; do
    [[ "$model" == "❌ Cancelar" ]] && return 0
    
    if [[ -n "$model" ]]; then
      # Configurar
      oco config set OCO_AI_PROVIDER=ollama
      oco config set OCO_MODEL="$model"
      oco config set OCO_API_URL="${OLLAMA_URL}/api/chat"  # 🔥 Usa variable en vez de hardcodear
      # oco config set OCO_API_KEY="ANTHROPIC_API_KEY" # ESTO ENTRA EN CONFLICTO CON Ollama y afecta el Git push:
      # oco config set OCO_GITPUSH=false      
      oco config set OCO_LANGUAGE=es_ES
      oco config set OCO_TOKENS_MAX_INPUT=12000
      oco config set OCO_TOKENS_MAX_OUTPUT=500
      oco config set OCO_ONE_LINE_COMMIT=false
      
      echo ""
      echo "✅ opencommit configurado correctamente:"
      echo "   • Provider: ollama"
      echo "   • URL: ${OLLAMA_URL}/api/chat"  # 🔥 Muestra URL correcta
      echo "   • Modelo: $model"
      echo "   • Idioma: es_ES"
      echo "   • Recomendación: Para modelos locales, quita /api/chat manualmente"
      
      if oco --version &>/dev/null; then
        echo "✅ opencommit funcional"
      fi
      
      break
    fi
  done
}

# Mostrar modelo actual
alias aicommit-showmodel='oco config get OCO_MODEL'

# Alias adicionales útiles
alias aicommitreset='oco config reset'  # Resetear configuración
alias modellist='ollama list'  # Listar modelos disponibles
alias EspacioTotal='dust /*' # Tamaño de los archivos en el directorio actual
# =============================================================================
#                    GIT ALIASES Y FUNCIONES MEJORADAS
# =============================================================================

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📦 COMMITS RÁPIDOS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Versión 1: Commit con plantilla personalizable
gitcommit() {
  # Archivo de plantilla en ~/.config/git/commit-template.txt
  local template_file="$HOME/commit-template.txt"

  # Crear plantilla por defecto si no existe
  if [ ! -f "$template_file" ]; then
    mkdir -p "$HOME/.config/git"
    cat > "$template_file" << 'TEMPLATE'
feat(arch 󰣇): 󰊢 Best Linux 🐧 Setup

# Agrega contexto adicional aquí:
# -
# -
# -

# Recuerda usar 'gitflow' para commits más complejos
TEMPLATE
    echo "✅ Plantilla creada en: $template_file"
  fi

  # Abrir editor con la plantilla
  git add .
  git commit -t "$template_file"

  # Preguntar si pushear
  echo -n "¿Pushear cambios? (y/n): "
  read push_answer
  if [[ "$push_answer" == "y" || "$push_answer" == "Y" ]]; then
    git push
    echo "✅ Cambios pusheados"
  else
    echo "⚠️ Commit realizado sin push"
  fi
}

# Versión 1b: Commit rápido sin abrir editor (usa plantilla inline)
gitquick() {
  local default_msg="feat(arch 󰣇): 󰊢 Best Linux 🐧 Setup"

  if [ $# -gt 0 ]; then
    # Si pasas argumento, úsalo como contexto adicional
    git add . && git commit -m "$default_msg

- $*" && git push
  else
    git add . && git commit -m "$default_msg" && git push
  fi

  echo "✅ Commit rápido realizado"
}

# Versión 2: Commit con AI LOCAL (sin cloud models)
# aicommit()

# Versión 3: Función interactiva (mensaje personalizado)
gitc() {
  if [ $# -eq 0 ]; then
    echo "💬 Escribe tu mensaje de commit:"
    read commit_msg
  else
    commit_msg="$*"
  fi

  git add .
  git commit -m "$commit_msg"
  git push

  echo "✅ Cambios pusheados con mensaje: $commit_msg"
}

# Versión 4: Commit con tipo y scope (Conventional Commits)
gitconv() {
  local type scope msg

  echo "📝 Tipo de commit (feat/fix/docs/style/refactor/test/chore):"
  read type

  echo "📦 Scope (opcional, ej: hyprland, waybar, scripts):"
  read scope

  echo "💬 Mensaje del commit:"
  read msg

  if [ -n "$scope" ]; then
    full_msg="${type}(${scope}): ${msg}"
  else
    full_msg="${type}: ${msg}"
  fi

  git add .
  git commit -m "$full_msg"
  git push

  echo "✅ Commit: $full_msg"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔍 GIT UTILITIES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Ver historial de commits (visual)
alias gitlog='git log --oneline --graph --decorate --all'
alias gitlogfull='git log --graph --pretty=format:"%Cred%h%Creset - %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit'

# Ver diferencias antes de commit
alias gitdiff='git diff'
alias gitdiffs='git diff --staged'

# Status con formato limpio
alias gits='git status -sb'

# Deshacer último commit (mantiene cambios)
alias gitundo='git reset --soft HEAD~1'

# Deshacer último commit (borra cambios)
alias gitundobard='git reset --hard HEAD~1'

# Editar commits históricos (últimos 5)
alias CommitsHistorial='git rebase -i HEAD~5'

# Editar el último commit
alias CommitEditar='git commit --amend'

# Stash rápido
alias gitstash='git stash'
alias gitstashpop='git stash pop'
alias gitstashlist='git stash list'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔄 BRANCHING
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Ver branches
alias gitb='git branch -a'

# Crear y cambiar a nueva branch
gitnew() {
  if [ $# -eq 0 ]; then
    echo "❌ Uso: gitnew <nombre-de-branch>"
  else
    git checkout -b "$1"
    echo "✅ Branch '$1' creada y activa"
  fi
}

# Cambiar de branch
alias gitco='git checkout'

# Mergear branch
gitmerge() {
  if [ $# -eq 0 ]; then
    echo "❌ Uso: gitmerge <branch-a-mergear>"
  else
    git merge "$1"
    echo "✅ Branch '$1' mergeada"
  fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🚀 PUSH/PULL MEJORADOS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Push forzado (con cuidado)
alias gitpushforce='git push --force-with-lease'

# Pull con rebase (más limpio)
alias gitpull='git pull --rebase'

# Sincronizar fork con upstream
gitsync() {
  git fetch upstream
  git checkout main
  git merge upstream/main
  git push
  echo "✅ Fork sincronizado con upstream"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🧹 LIMPIEZA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Limpiar archivos no trackeados
alias gitcleanfiles='git clean -fd'

# Reset completo al último commit
alias gitreset='git reset --hard HEAD'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📊 ESTADÍSTICAS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Ver contribuciones por autor
alias gitstats='git shortlog -sn --all'

alias gitshowcom='tig'

# Ver tamaño del repo
alias gitsize='git count-objects -vH'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🎯 FUNCIÓN COMPLETA TODO-EN-UNO
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Workflow completo con menú interactivo
gitflow() {
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "     🚀 GIT WORKFLOW INTERACTIVO"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "0. 🚀 Editar commit actual  "
  echo "1. 📝 Commit con plantilla (abre editor)  "
  echo "2. ⚡ Commit rápido (sin editor)"
  echo "3. 🤖 Commit con AI LOCAL (opencommit)"
  echo "4. 📦 Commit convencional (feat/fix/etc)"
  echo "5. 🔍 Ver status"
  echo "6. 📊 Ver log"
  echo "7. 📄 Editar plantilla de commit"
  echo "8. 📦 Revisar archivos historial de git"
  echo "9. 🔁 Editar Commits históricos  "
  echo "10. ❌ Eliminar commit actual"
  echo "11. ❌ Cancelar"
  echo ""
  echo -n "Elige opción: "
  read option

  case $option in
    0)
      CommitEditar
      ;;
    1)
      gitcommit
      ;;
    2)
      echo "💬 Contexto adicional (opcional, Enter para saltar):"
      read context
      if [ -n "$context" ]; then
        gitquick "$context"
      else
        gitquick
      fi
      ;;
    3)
      aicommit
      ;;
    4)
      gitconv
      ;;
    5)
      git status -sb
      ;;
    6)
      git log --oneline --graph --decorate --all -10
      ;;
    7)
      local template_file="$HOME/commit-template.txt"
      if [ ! -f "$template_file" ]; then
        mkdir -p "$HOME/.config/git"
        cat > "$template_file" << 'TEMPLATE'
feat(arch 󰣇): 󰊢 Best Linux 🐧 Setup

# Agrega contexto adicional aquí:
# -
# -
# -

# Recuerda usar 'gitflow' para commits más complejos
TEMPLATE
      fi
      ${EDITOR:-nano} "$template_file"
      echo "✅ Plantilla actualizada"
      ;;
    8)
      tig
      ;;
      #
    9)
      CommitsHistorial
      ;;
    10)
      git reset --soft HEAD~1
      ;;
    11)
      echo "❌ Cancelado"
      ;;
    *)
      echo "❌ Opción inválida"
      ;;
  esac
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  💡 AYUDA COMPLETA DE GIT 󰊢  
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

alias limpiar_cache='bash ~/scripts/limpiar_cache.sh'
alias githelp='bash ~/scripts/git-help.sh'
alias gitclean='bash ~/scripts/git_clean.sh'

# ═══════════════════════════════════════════════════════════
# PYMACRO RECORD (LOCAL CONFIG)
# ═══════════════════════════════════════════════════════════
# Pyenv configuration
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
# eval "$(pyenv init -)"
# COMANDOS DE OMARCHY
alias omarchy-launch-webapp='bash ~/omarchy-arch-bin/omarchy-launch-webapp'
alias omarchy-webapp-install='bash ~/omarchy-arch-bin/omarchy-webapp-install'
alias omarchy-pkg-install='bash ~/omarchy-arch-bin/omarchy-pkg-install'
alias omarchy-pkg-aur-install='bash ~/omarchy-arch-bin/omarchy-pkg-aur-install'

# Config para the clicker de CARGO/rust
export PATH="$HOME/.cargo/bin:$PATH"
# Si quieres cambiar el repo rápidamente sin menú: para darle uso a Windows +Z 󱞣
export GIT_CLEAN_REPO="$HOME/dotfiles-dizzi"
                                                    
# ═══════════════════════════════════════════════════════════
# Editor por defecto (Git, etc)
# ═══════════════════════════════════════════════════════════
export EDITOR="nvim"
export VISUAL="nvim"
export GIT_EDITOR="nvim"

# ═══════════════════════════════════════════════════════════
# Config de TERMIX STARSHIP 
# ═══════════════════════════════════════════════════════════

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""

plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions zsh-history-substring-search)

# source $ZSH/oh-my-zsh.sh

[[ -d ~/.zsh/zsh-autocomplete ]] && source ~/.zsh/zsh-autocomplete/zsh-autocomplete.plugin.zsh
[[ -d ~/.zsh/fzf-tab ]] && source ~/.zsh/fzf-tab/fzf-tab.plugin.zsh

command -v zoxide >/dev/null && eval "$(zoxide init zsh)"
command -v fzf >/dev/null && eval "$(fzf --zsh)"

[[ -f ~/.termux_aliases ]] && source ~/.termux_aliases

# Pokemon (comentado por defecto)
# # command -v pokemon-colorscripts >/dev/null && pokemon-colorscripts -r
#
# # Starship (AL FINAL)
command -v starship >/dev/null && eval "$(starship init zsh)"
