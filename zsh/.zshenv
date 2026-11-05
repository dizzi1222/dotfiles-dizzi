
# .zshenv
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
export ZSH="$HOME/.oh-my-zsh"
export PATH="$HOME/bin:$HOME/.local/bin:$HOME/.npm-global/bin:$HOME/.local/opt/google-cloud-sdk/bin:$PATH"
export TERMINAL=kitty
# En Plasma el tema Qt lo maneja KDE; no forzar gtk3.
# export QT_QPA_PLATFORMTHEME=gtk3

# API keys: se cargan en .zshenv (corre en TODOS los zsh, incluido 'zsh -c'
# de lazygit) para que oco/opencommit y otras herramientas de IA las vean
# sin depender de .zshrc (que solo corre en shells interactivos).
if [ -f "$HOME/.api-keys.sh" ]; then
  source "$HOME/.api-keys.sh"
fi
