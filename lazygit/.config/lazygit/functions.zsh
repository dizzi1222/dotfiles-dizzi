# Funciones disponibles en el prompt ':' de lazygit.
# lazygit ejecuta `$SHELL -c <comando>` (no interactivo), así que las funciones
# de ~/.zshrc no existen ahí. Este stub re-ejecuta gitflow en un zsh
# interactivo, que sí carga ~/.zshrc completo (gitflow y sus helpers).
gitflow() {
  zsh -ic gitflow
}
