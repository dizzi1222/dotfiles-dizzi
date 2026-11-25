#!/usr/bin/env bash
# Reaplica los parches locales de Hermes (hermes/patches/*.patch) sobre el checkout
# ~/.hermes/hermes-agent. Idempotente: un parche ya aplicado se salta.
#
# Por qué existe: las actualizaciones de Hermes Desktop ejecutan
# `hermes update --keep-stash`, que guarda los cambios locales del código en un
# stash y NO los reaplica. Un arreglo hecho directamente en el código de Hermes se
# pierde en la siguiente actualización; aquí vive en los dotfiles y vuelve solo.
#
# Uso:
#   apply-patches.sh            aplica los parches pendientes
#   apply-patches.sh --install  instala la unidad systemd --user que los reaplica
#                               tras cada actualización (repetir al añadir parches)
#
# Salida: 0 = todo aplicado · 1 = algún parche ya no encaja con la versión actual
#         75 = hay una actualización de Hermes en curso (systemd reintenta)
set -euo pipefail

DOTFILES_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
PATCH_DIR="$DOTFILES_ROOT/hermes/patches"
HERMES_HOME="${HERMES_HOME:-${HOME:?}/.hermes}"
CHECKOUT="${HERMES_CHECKOUT:-$HERMES_HOME/hermes-agent}"
UNIT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
UNIT_NAME="hermes-patches"
EX_TEMPFAIL=75

shopt -s nullglob
patches=("$PATCH_DIR"/*.patch)
shopt -u nullglob

g() { git -C "$CHECKOUT" "$@"; }

# Rutas del checkout que tocan los parches (para que la unidad .path las vigile).
patched_paths() {
  sed -n 's|^+++ b/||p' "${patches[@]}" | sort -u
}

install_units() {
  local path_lines="" file
  while IFS= read -r file; do
    path_lines+="PathChanged=$CHECKOUT/$file"$'\n'
  done < <(patched_paths)

  mkdir -p -- "$UNIT_DIR"
  cat >"$UNIT_DIR/$UNIT_NAME.path" <<EOF
# Generado por $DOTFILES_ROOT/hermes/apply-patches.sh --install (no editar a mano).
[Unit]
Description=Reaplicar parches locales de Hermes cuando una actualización los quita

[Path]
${path_lines}Unit=$UNIT_NAME.service

[Install]
WantedBy=default.target
EOF

  cat >"$UNIT_DIR/$UNIT_NAME.service" <<EOF
# Generado por $DOTFILES_ROOT/hermes/apply-patches.sh --install (no editar a mano).
[Unit]
Description=Reaplicar parches locales de Hermes ($PATCH_DIR)
# Una actualización larga puede tardar más de media hora: reintentos sin tope.
StartLimitIntervalSec=0

[Service]
Type=oneshot
Environment=HERMES_HOME=$HERMES_HOME HERMES_CHECKOUT=$CHECKOUT
ExecStart=$DOTFILES_ROOT/hermes/apply-patches.sh
# $EX_TEMPFAIL = actualización en curso: reintentar cada minuto hasta que termine.
RestartForceExitStatus=$EX_TEMPFAIL
RestartSec=60
EOF

  systemctl --user daemon-reload
  systemctl --user enable --now "$UNIT_NAME.path"
  printf 'Unidad instalada: %s.path vigila %s archivo(s) del checkout.\n' \
    "$UNIT_NAME" "$(patched_paths | wc -l)"
}

# Las actualizaciones guardan cada vez un stash con estos mismos parches. Se borra
# solo el autostash de Hermes cuyo contenido es EXACTAMENTE base + parches (sin
# archivos sin seguimiento ni cambios en el índice): se reconstruye desde los
# dotfiles, así que borrarlo no pierde nada. Cualquier otro stash se conserva.
prune_redundant_autostashes() {
  local tmp entries i sel sha subject base expected
  tmp="$(mktemp -d)"
  mapfile -t entries < <(g stash list --format='%gd %H %gs')

  for ((i = ${#entries[@]} - 1; i >= 0; i--)); do
    read -r sel sha subject <<<"${entries[i]}"
    [[ $subject == *hermes-update-autostash-* ]] || continue
    # `--include-untracked` siempre añade ^3; solo vale si no guarda ningún archivo.
    [[ -z "$(g ls-tree --name-only "$sha^3" 2>/dev/null)" ]] || continue
    base="$(g rev-parse "$sha^1")"
    [[ "$(g rev-parse "$sha^2^{tree}")" == "$(g rev-parse "$base^{tree}")" ]] || continue

    rm -f -- "$tmp/index"
    GIT_INDEX_FILE="$tmp/index" git -C "$CHECKOUT" read-tree "$base" || continue
    GIT_INDEX_FILE="$tmp/index" git -C "$CHECKOUT" apply --cached "${patches[@]}" 2>/dev/null || continue
    expected="$(GIT_INDEX_FILE="$tmp/index" git -C "$CHECKOUT" write-tree)" || continue
    [[ $expected == "$(g rev-parse "$sha^{tree}")" ]] || continue

    g stash drop -q "$sel"
    printf '🧹 Stash redundante eliminado: %s (%s)\n' "$sel" "$subject"
  done
  rm -rf -- "$tmp"
}

apply_patches() {
  local patch name status=0 applied=0 lock

  # `hermes update` toma un flock exclusivo sobre este archivo antes de tocar el
  # checkout. Un intento compartido sin espera es la misma sonda que usa Hermes.
  lock="$(g rev-parse --path-format=absolute --git-common-dir)/hermes-update.lock"
  if [[ -e $lock ]] && ! flock -n -s "$lock" true 2>/dev/null; then
    printf 'Hay una actualización de Hermes en curso; se reintentará al terminar.\n' >&2
    return "$EX_TEMPFAIL"
  fi

  for patch in "${patches[@]}"; do
    name="$(basename -- "$patch")"
    if g apply --reverse --check "$patch" 2>/dev/null; then
      printf '✓ %s: ya aplicado\n' "$name"
    elif g apply --check "$patch" 2>/dev/null; then
      g apply "$patch"
      printf '✓ %s: aplicado\n' "$name"
      applied=1
    else
      printf '⚠ %s: no encaja con esta versión de Hermes; hay que rehacerlo.\n' "$name" >&2
      status=1
    fi
  done

  prune_redundant_autostashes
  if ((applied)); then
    printf 'La TUI se recompila sola la próxima vez que abras hermes --tui.\n'
  fi
  return "$status"
}

if [[ ! -d $CHECKOUT/.git ]]; then
  printf 'No hay checkout git de Hermes en %s; nada que parchear.\n' "$CHECKOUT" >&2
  exit 0
fi
if ((${#patches[@]} == 0)); then
  printf 'No hay parches en %s.\n' "$PATCH_DIR"
  exit 0
fi

# Serializa la ejecución manual con la de systemd.
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/$UNIT_NAME.lock"
flock 9

case "${1:-}" in
  --install) install_units ;;
  "") ;;
  *)
    printf 'Uso: %s [--install]\n' "$0" >&2
    exit 2
    ;;
esac

apply_patches
