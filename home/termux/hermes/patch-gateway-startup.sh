#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

MODE="${1:-apply}"
case "$MODE" in
  apply|restore) ;;
  *) printf 'Uso: %s [apply|restore]\n' "$0" >&2; exit 2 ;;
esac

PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
ROOTFS="$PREFIX/var/lib/proot-distro/containers/ubuntu/rootfs"
HERMES_REPO="$ROOTFS/root/hermes-user/.hermes/hermes-agent"
PATCH_FILE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/patches/gateway-startup-adaptive.patch"
HERMES_REPO_GUEST="/root/hermes-user/.hermes/hermes-agent"

if [[ ! -d "$HERMES_REPO/.git" || ! -f "$PATCH_FILE" ]]; then
  printf 'No se encontró el checkout de Hermes o su parche: %s\n' "$HERMES_REPO" >&2
  exit 1
fi

if git -C "$HERMES_REPO" apply --unidiff-zero --reverse --check "$PATCH_FILE" >/dev/null 2>&1; then
  if [[ "$MODE" == restore ]]; then
    git -C "$HERMES_REPO" apply --unidiff-zero --reverse "$PATCH_FILE"
    printf '%s\n' 'Fuentes upstream de Hermes restauradas; el TUI compilado conserva el arreglo.'
    exit 0
  fi
elif git -C "$HERMES_REPO" apply --unidiff-zero --check "$PATCH_FILE" >/dev/null 2>&1; then
  if [[ "$MODE" == restore ]]; then
    printf '%s\n' 'Las fuentes de Hermes ya están limpias.'
    exit 0
  fi
  git -C "$HERMES_REPO" apply --unidiff-zero "$PATCH_FILE"
else
  printf '%s\n' 'La versión instalada de Hermes no coincide con el parche de dotfiles; no la modifiqué.' >&2
  exit 1
fi

if [[ "$MODE" == restore ]]; then
  printf '%s\n' 'No había cambios de fuentes que restaurar.'
  exit 0
fi

BOOTSTRAP="$HERMES_REPO/ui-tui/dist/scripts/gateway_bootstrap.py"
BUNDLE="$HERMES_REPO/ui-tui/dist/entry.js"
if ! grep -Fq 'timeout=None if start or recover else 30' "$BOOTSTRAP" 2>/dev/null || \
  ! grep -Fq 'const timeout = start || recover ? 36e4 : 4e4;' "$BUNDLE" 2>/dev/null; then
  NODE_HOST="$(find "$ROOTFS/root/hermes-user/.hermes/tools" -maxdepth 4 -type f -path '*/bin/node' -print | sort -V | tail -n 1)"
  if [[ -z "$NODE_HOST" ]]; then
    printf '%s\n' 'No encontré el Node Linux de Hermes para compilar el TUI.' >&2
    exit 1
  fi
  NODE_GUEST="${NODE_HOST#"$ROOTFS"}"
  if [[ "$NODE_GUEST" == "$NODE_HOST" ]]; then
    printf 'El Node del TUI está fuera del rootfs de Ubuntu: %s\n' "$NODE_HOST" >&2
    exit 1
  fi

  export PROOT_NO_SECCOMP=1
  proot-distro login ubuntu -- /bin/bash -c \
    'cd -- "$1" && exec "$2" scripts/build/tui.mjs' \
    hermes-tui-build "$HERMES_REPO_GUEST" "$NODE_GUEST"
fi

if ! grep -Fq 'timeout=None if start or recover else 30' "$BOOTSTRAP" || \
  ! grep -Fq 'const timeout = start || recover ? 36e4 : 4e4;' "$BUNDLE"; then
  printf '%s\n' 'La compilación terminó, pero los artefactos del TUI no contienen el arreglo esperado.' >&2
  exit 1
fi

printf '%s\n' 'Gateway adaptativo aplicado: inicio/recuperación hasta 300 s de progreso; timeout externo 360 s.'
