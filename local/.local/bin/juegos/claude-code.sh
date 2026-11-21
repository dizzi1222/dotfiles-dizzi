#!/bin/sh
# Abre claude-code con el selector de sesiones (--resume).
set -u

export PATH="$HOME/.npm-global/bin:$HOME/.local/bin:/home/linuxbrew/.linuxbrew/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"

CLAUDE_BIN="/home/diego/.npm-global/bin/claude"
if [ ! -x "$CLAUDE_BIN" ]; then
  CLAUDE_BIN="$(command -v claude 2>/dev/null || true)"
fi

if [ -x "$CLAUDE_BIN" ]; then
  exec "$CLAUDE_BIN" --resume "$@"
fi

echo "claude-code.sh: no se encontró el binario claude" >&2
exit 127
