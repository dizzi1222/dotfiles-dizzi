#!/bin/sh
# Abre openclaw
set -u

if command -v openclaw >/dev/null 2>&1; then
  exec openclaw "$@"
fi

# Fallback
if [ -x "$HOME/.local/bin/openclaw" ]; then
  exec "$HOME/.local/bin/openclaw" "$@"
fi

echo "openclaw.sh: no se encontró el binario openclaw." >&2
exit 127
