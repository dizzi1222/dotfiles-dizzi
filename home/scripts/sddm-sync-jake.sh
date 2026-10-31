#!/usr/bin/env bash
# Instala el respaldo de Jake con permisos legibles por el usuario sddm.
set -euo pipefail

script_path="$(readlink -f "${BASH_SOURCE[0]}")"
dotfiles_dir="$(cd "$(dirname "$script_path")/../.." && pwd)"
theme_config="usr/share/sddm/themes/sddm-astronaut-theme/Themes/jake_the_dog.conf"

if [[ ! -f "$dotfiles_dir/$theme_config" || ! -d "/$(dirname "$theme_config")" ]]; then
  echo "Falta el respaldo de Jake o el tema Astronaut instalado." >&2
  exit 1
fi

if [[ $EUID -ne 0 ]]; then
  exec sudo bash "$script_path"
fi

# install reemplaza el symlink: el greeter no puede atravesar un HOME con modo 700.
install -o root -g root -m 0644 -T "$dotfiles_dir/$theme_config" "/$theme_config"
if id -u sddm >/dev/null 2>&1; then
  runuser -u sddm -- test -r "/$theme_config"
fi
echo "Configuración de Jake instalada y legible por sddm."
