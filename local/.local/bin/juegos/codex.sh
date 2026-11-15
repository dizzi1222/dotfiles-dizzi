#!/bin/sh
# Abre Codex (ChatGPT) TUI
set -u

if command -v codex >/dev/null 2>&1; then
  exec codex "$@"
fi

# Fallbacks habituales
for c in "$HOME/.local/bin/codex" "$HOME/.npm-global/bin/codex" "/usr/local/bin/codex"; do
  if [ -x "$c" ]; then
    exec "$c" "$@"
  fi
done

echo "codex.sh: no se encontró el binario codex." >&2
echo "Instalalo con: npm i -g @openai/codex" >&2
exit 127
