# mapear Ctrl + Backspace
bindkey '^H' backward-kill-word
bindkey '^[[3;5~' kill-word
# Borra la palabra anterior (Ctrl+W)
bindkey '^W' backward-kill-word

# Borra la palabra anterior (Ctrl+Backspace)
bindkey '^?' backward-kill-word
# ESTO HACE QUE neofetch cargue primero
# si prefieres puedes quitarlo para cargar ANTES el prompt instant.
      typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
      typeset -g POWERLEVEL9K_INSTANT_PROMPT=off
      
# /////////////////////////////////////////////////////////////////////////////


export PATH="$HOME/.local/bin:$PATH"
# /////////////////////////////////////////////////////////////////////////////
# ---------------------------------------------------------------------------------------------
# ///////////////////////////////////////////////////////////////////////

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


# /////////////////////////////////////////////////////////////////////////////
# ---------------------------------------------------------------------------------------------
# ///////////////////////////////////////////////////////////////////////

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
# zstyle ':omz:update' mode disabled  # disable automatic updates
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
)

# Esta línea debe estar después de 'plugins=()'
source $ZSH/oh-my-zsh.sh

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

# ls - 🖼️ Ver imágenes en la terminal
alias ls='exa --icons --color=always'
# Sugerencia y autocompleta en gris [Control+E]
source ~/.zsh/zsh-autocomplete/zsh-autocomplete.plugin.zsh

#Búsqueda interactiva: Cuando presionas Tab para autocompletar un comando, argumento o archivo [tab o ArrowUp o ArrowDown]
source ~/.zsh/fzf-tab/fzf-tab.plugin.zsh

# Consejo: No lo pongas antes de otros plugins como autosuggestions, por conflictos, ya que puede interferir con ellos.

# /////////////////////////////////////////////////////////////////////////////
# ---------------------------------------------------------------------------------------------
# ///////////////////////////////////////////////////////////////////////

# ACA PUEDES CAMBIAR TODA LA CONFIGURACION DEL PROMPT
# ACA PUEDES CAMBIAR TODA LA CONFIGURACION DEL PROMPT
# ACA PUEDES CAMBIAR TODA LA CONFIGURACION DEL PROMPT

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


# ACA CARGA EL NEOFETCH CON EL ASCII ETC
# ACA CARGA EL NEOFETCH CON EL ASCII ETC
# ACA CARGA EL NEOFETCH CON EL ASCII ETC

# podria ser neofetch - pero mas lento
fastfetch
# neofetch tiene mas comunidad

PATH=~/.console-ninja/.bin:$PATH

# guardar el historial:
# guardar el historial:
# guardar el historial:

# === Configuración del Historial de Zsh ===
HISTFILE=~/.zsh_history # Dónde se guarda el historial
HISTSIZE=10000         # Número de líneas de historial en memoria
SAVEHIST=10000         # Número de líneas de historial que se guardan en el archivo

# Opciones para el historial (asegúrate de que estén presentes y activas)
setopt appendhistory      # Añadir cada comando al archivo del historial
setopt sharehistory       # Compartir historial entre todas las sesiones de Zsh
setopt hist_ignore_dups   # No guardar comandos duplicados consecutivamente
setopt hist_ignore_space  # No guardar comandos que empiecen con espacio
setopt hist_verify        # Confirmar un comando si hay sustitución en él
setopt extendedhistory    # Guardar marcas de tiempo en el historial

# Esto es para que Zsh maneje la escritura del historial correctamente al salir
# y para que cada comando se guarde inmediatamente.
function zle-line-finish() {
    zle .accept-line
    # Guarda la línea actual en el historial cuando se completa
    print -s $BUFFER
}
zle -N zle-line-finish

# === Tu Alias para Guardar y Mostrar el Historial ===
# Aseguramos que /tmp/history sea un archivo y no un directorio.
rm -f /tmp/history

# El alias ahora usará 'fc -l 1' para listar todo el historial desde el principio,
# o 'history 0' que también debería funcionar para obtener todo el historial.
# 'fc -l 1' es a menudo más robusto para obtener todo el historial sin límites.
alias history='fc -l 1 > /tmp/history && cat /tmp/history'

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
# HABILITAR OH MY POSH [trae mas temas]
# https://ohmyposh.dev/docs/themes
eval "$(oh-my-posh init zsh --config 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/1_shell.omp.json')"
