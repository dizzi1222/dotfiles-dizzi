#!/bin/sh
# Abre opencode continuando la última sesión del directorio actual.
# No cambia de carpeta: respeta el working_dir del lanzador (Lutris/Steam).
set -u

if command -v opencode >/dev/null 2>&1; then
  exec opencode --continue "$@"
fi

# Fallback si se lanza desde un entorno sin ~/.local/bin en el PATH.
if [ -x "$HOME/.local/bin/opencode" ]; then
  exec "$HOME/.local/bin/opencode" --continue "$@"
fi

echo "opencode.sh: no se encontró el binario opencode." >&2
exit 127
