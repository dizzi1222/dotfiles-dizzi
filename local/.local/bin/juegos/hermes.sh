#!/bin/sh
# Inicia Hermes Agent desde kitty, Lutris o el escritorio.
set -u

if command -v hermes >/dev/null 2>&1; then
  exec hermes "$@"
fi

for hermes_bin in \
  "$HOME/.local/bin/hermes" \
  "$HOME/.hermes/hermes-agent/.hermes/bin/hermes" \
  "$HOME/.hermes/bin/hermes"; do
  if [ -x "$hermes_bin" ]; then
    exec "$hermes_bin" "$@"
  fi
done

echo "hermes.sh: no se encontró el binario hermes." >&2
echo "Instálalo con: curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash" >&2
exit 127
