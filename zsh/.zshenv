# API keys globales (todos los zsh, incluidos no interactivos)
[ -f "$HOME/.api-keys.sh" ] && source "$HOME/.api-keys.sh"

# .zshenv
export ZSH="$HOME/.oh-my-zsh"
export PATH="$HOME/bin:$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"

# Hermes se instala dentro de Ubuntu/proot (binario glibc), no en Termux.
# Función en .zshenv: disponible en shells interactivos y `zsh -c`.
hermes() {
  local linux_home="/root/hermes-user"
  local hermes_bin="$linux_home/.local/bin/hermes"
  local hermes_path="$linux_home/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
  if ! command -v proot-distro >/dev/null 2>&1; then
    print -u2 "Hermes Agent requiere proot-distro con Ubuntu instalado."
    return 127
  fi
  export PROOT_NO_SECCOMP=1
  proot-distro login ubuntu -- /usr/bin/env HOME="$linux_home" HERMES_HOME="$linux_home/.hermes" PATH="$hermes_path" "$hermes_bin" "$@"
}

export TERMINAL=kitty
export QT_QPA_PLATFORMTHEME=gtk3

# API keys: se cargan en .zshenv (corre en TODOS los zsh, incluido 'zsh -c'
# de lazygit) para que oco/opencommit y otras herramientas de IA las vean
# sin depender de .zshrc (que solo corre en shells interactivos).
if [ -f "$HOME/.api-keys.sh" ]; then
  source "$HOME/.api-keys.sh"
fi
