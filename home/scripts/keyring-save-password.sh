#!/usr/bin/env bash
# Guarda una sola vez la contraseña del llavero Login, cifrada con systemd-creds,
# y activa el servicio que lo desbloquea automáticamente en cada inicio de sesión.
set -euo pipefail

script_path="$(readlink -f "${BASH_SOURCE[0]}")"
dotfiles_dir="$(cd "$(dirname "$script_path")/../.." && pwd)"
helper="$dotfiles_dir/home/scripts/keyring-auto-unlock.py"
unit_src="$dotfiles_dir/systemd/.config/systemd/user/keyring-auto-unlock.service"
unit_dst="$HOME/.config/systemd/user/keyring-auto-unlock.service"
unit_name="keyring-auto-unlock.service"
cred_dir="$HOME/.config/credstore.encrypted"
cred_file="$cred_dir/keyring-password"
reset=0

for arg in "$@"; do
  case "$arg" in
    --reset) reset=1 ;;
    --status) ;;
    --help|-h)
      cat <<EOF
Uso: bash $0 [--reset|--status]

  (sin opciones)  Guarda la contraseña del llavero Login y activa el servicio.
  --reset         Borra la credencial guardada y vuelve a pedir la contraseña.
  --status        Muestra si hay credencial y si el servicio está activo.

La contraseña se pide una sola vez por terminal y se guarda cifrada en:
  $cred_file
EOF
      exit 0
      ;;
    *) echo "Opción no válida: $arg" >&2; exit 2 ;;
  esac
done

info() { printf '%s\n' "$*"; }
warn() { printf 'Aviso: %s\n' "$*" >&2; }
die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

show_status() {
  local enabled active locked
  if [[ -f "$cred_file" ]]; then
    info "Credencial: $cred_file ($(stat -c '%s bytes, modo %a' "$cred_file"))"
  else
    info "Credencial: no existe ($cred_file)"
  fi
  enabled="$(systemctl --user is-enabled "$unit_name" 2>/dev/null || true)"
  active="$(systemctl --user is-active "$unit_name" 2>/dev/null || true)"
  locked="$(busctl --user get-property org.freedesktop.secrets /org/freedesktop/secrets/collection/login org.freedesktop.Secret.Collection Locked 2>/dev/null || true)"
  info "Servicio: ${enabled:-desconocido} / ${active:-desconocido}"
  info "Llavero Login: ${locked:-no disponible}"
}

if [[ " $* " == *" --status "* ]]; then
  show_status
  exit 0
fi

[[ $EUID -ne 0 ]] || die "Ejecuta este script como tu usuario, sin sudo."
[[ -f "$helper" ]] || die "Falta el helper: $helper"
[[ -f "$unit_src" ]] || die "Falta la unidad systemd: $unit_src"
command -v systemd-creds >/dev/null || die "Falta systemd-creds."
command -v python3 >/dev/null || die "Falta python3."
python3 -c 'import dbus' 2>/dev/null || die "Falta python-dbus (sudo pacman -S python-dbus)."

# El paquete systemd ya está enlazado por stow; si no, se crea el enlace.
if [[ ! -e "$unit_dst" ]]; then
  mkdir -p "$HOME/.config/systemd/user"
  ln -sfn "$unit_src" "$unit_dst"
fi
systemctl --user daemon-reload

if [[ "$reset" -eq 1 ]]; then
  rm -f "$cred_file"
  info "Credencial anterior eliminada."
fi

if [[ -f "$cred_file" && "$reset" -eq 0 ]]; then
  info "Ya hay una contraseña guardada; solo se activa el servicio."
  systemctl --user enable --now "$unit_name"
  show_status
  exit 0
fi

if [[ ! -t 0 ]]; then
  info "No hay terminal interactiva: no se puede pedir la contraseña."
  info "Ejecuta después, en tu terminal:"
  info "  bash $script_path"
  exit 0
fi

info "Se pedirá una sola vez la contraseña ACTUAL del llavero Login (no la de sudo)."
info "Si no la recuerdas, cámbiala primero desde Seahorse."
while :; do
  IFS= read -rsp "Contraseña actual del llavero: " password || { printf '\n'; die "Cancelado."; }
  printf '\n'
  IFS= read -rsp "Repite la contraseña: " password2 || { printf '\n'; die "Cancelado."; }
  printf '\n'
  [[ -n "$password" ]] || { warn "La contraseña no puede estar vacía."; continue; }
  [[ "$password" == "$password2" ]] && break
  warn "No coinciden; inténtalo de nuevo."
done

# Si el llavero está bloqueado, esto valida la contraseña antes de guardarla.
# Si ya está desbloqueado, gnome-keyring no puede validarla aquí: se usará en el próximo login.
locked_now="$(busctl --user get-property org.freedesktop.secrets /org/freedesktop/secrets/collection/login org.freedesktop.Secret.Collection Locked 2>/dev/null || true)"
if [[ "$locked_now" == "b false" ]]; then
  info "El llavero ya está desbloqueado; la contraseña se comprobará al próximo inicio de sesión."
fi
if ! printf '%s' "$password" | python3 "$helper"; then
  die "No se pudo desbloquear el llavero. Comprueba la contraseña y vuelve a ejecutar el script."
fi

mkdir -p "$cred_dir"
chmod 700 "$cred_dir"
umask 077
if ! printf '%s' "$password" | systemd-creds --user --name=keyring-password --with-key=host encrypt - "$cred_file"; then
  die "No se pudo cifrar la credencial. Prueba: sudo systemd-creds setup"
fi
chmod 600 "$cred_file"

# Verifica que el cifrado se puede leer antes de dar por buena la credencial.
if ! decrypted="$(systemd-creds --user --name=keyring-password decrypt "$cred_file" -)"; then
  rm -f "$cred_file"
  die "No se pudo descifrar la credencial; se eliminó."
fi
if [[ "$decrypted" != "$password" ]]; then
  rm -f "$cred_file"
  die "La credencial cifrada no coincide; se eliminó."
fi
unset decrypted password password2

systemctl --user enable --now "$unit_name" || die "No se pudo activar $unit_name."
info "Contraseña guardada y servicio activado. No volverá a pedirla en cada inicio de sesión."
show_status
