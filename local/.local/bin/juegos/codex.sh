#!/bin/sh
# Abre Codex (ChatGPT) TUI en modo resume picker
set -u

# Cargar entorno de usuario si no está en PATH
export PATH="$HOME/.npm-global/bin:$HOME/.local/bin:/home/linuxbrew/.linuxbrew/bin:$PATH"

if [ $# -eq 0 ]; then
  set -- resume --no-daemon
fi

if command -v codex >/dev/null 2>&1; then
  exec codex "$@"
fi

# Fallbacks habituales
for c in "$HOME/.npm-global/bin/codex" "$HOME/.local/bin/codex" "/usr/local/bin/codex"; do
  if [ -x "$c" ]; then
    exec "$c" "$@"
  fi
done

echo "codex.sh: no se encontró el binario codex." >&2
echo "Instalalo con: npm i -g @openai/codex" >&2
exit 127
