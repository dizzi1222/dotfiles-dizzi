#!/bin/sh
# Abre opencode continuando la última sesión de este directorio (juegos).
set -u

DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd) || exit 1
cd "$DIR" || exit 1

if command -v opencode >/dev/null 2>&1; then
  exec opencode --continue "$@"
fi

# Fallback si se lanza desde un entorno sin ~/.local/bin en el PATH.
if [ -x "$HOME/.local/bin/opencode" ]; then
  exec "$HOME/.local/bin/opencode" --continue "$@"
fi

echo "opencode.sh: no se encontró el binario opencode." >&2
exit 127
