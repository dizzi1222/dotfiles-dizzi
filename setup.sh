#!/bin/bash

# Ruta a tu repo de dotfiles (cámbiala si es diferente)
DOTFILES_DIR="$HOME/dotfiles"

# Función para crear enlaces simbólicos con backup si existe
link_file() {
  local src=$1
  local dest=$2

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    echo "Backup de $dest a ${dest}.backup"
    mv "$dest" "${dest}.backup"
  fi

  echo "Creando enlace simbólico: $dest -> $src"
  ln -s "$src" "$dest"
}

echo "Setup de dotfiles iniciado..."

# Ejemplos de archivos para linkear
link_file "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
link_file "$DOTFILES_DIR/.bashrc" "$HOME/.bashrc"
link_file "$DOTFILES_DIR/.bash_profile" "$HOME/.bash_profile"
link_file "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
link_file "$DOTFILES_DIR/.p10k.zsh" "$HOME/.p10k.zsh"
link_file "$DOTFILES_DIR/.Xclients" "$HOME/.Xclients"
link_file "$DOTFILES_DIR/.xinitrc" "$HOME/.xinitrc"

# Linkear toda la carpeta .local/bin
if [ -d "$HOME/.local/bin" ]; then
  echo "Backup de ~/.local/bin a ~/.local/bin.backup"
  mv "$HOME/.local/bin" "$HOME/.local/bin.backup"
fi
echo "Linkeando ~/.local/bin"
ln -s "$DOTFILES_DIR/.local/bin" "$HOME/.local/bin"

# Asegurar permisos de ejecución en tus scripts (ejemplo montar_gdrive.sh)
chmod +x "$DOTFILES_DIR/montar_gdrive.sh"

echo "Setup completado. Por favor, reinicia la sesión o abre una nueva terminal."

exit 0
