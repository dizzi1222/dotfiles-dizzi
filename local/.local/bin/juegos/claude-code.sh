#!/bin/sh
# Abre claude-code continuando la última sesión del directorio actual.
# Respeta el working_dir del lanzador (Lutris/Steam).
set -u

CLAUDE_BIN="/home/diego/.npm-global/bin/claude"

if [ -x "$CLAUDE_BIN" ]; then
  exec "$CLAUDE_BIN" --continue "$@"
fi

echo "claude-code.sh: no se encontró el binario claude en $CLAUDE_BIN" >&2
exit 127