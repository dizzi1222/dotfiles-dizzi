
# .zshenv
export ZSH="$HOME/.oh-my-zsh"
export PATH="$HOME/bin:$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"
export TERMINAL=kitty
export QT_QPA_PLATFORMTHEME=gtk3

# API keys: se cargan en .zshenv (corre en TODOS los zsh, incluido 'zsh -c'
# de lazygit) para que oco/opencommit y otras herramientas de IA las vean
# sin depender de .zshrc (que solo corre en shells interactivos).
if [ -f "$HOME/.api-keys.sh" ]; then
  source "$HOME/.api-keys.sh"
fi
