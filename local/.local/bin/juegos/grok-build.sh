#!/bin/sh
# Inicia el agente de programación Grok Build (comando oficial `grok`).
set -u

if command -v grok >/dev/null 2>&1; then
  exec grok "$@"
fi

for grok_bin in "$HOME/.grok/bin/grok" "$HOME/.local/bin/grok"; do
  if [ -x "$grok_bin" ]; then
    exec "$grok_bin" "$@"
  fi
done

echo "grok-build.sh: no se encontró Grok Build." >&2
echo "Instálalo con: curl -fsSL https://x.ai/cli/install.sh | bash" >&2
exit 127
