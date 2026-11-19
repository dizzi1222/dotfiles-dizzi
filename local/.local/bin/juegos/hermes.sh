#!/bin/sh
# Inicia Hermes Agent desde kitty, Lutris o el escritorio.
set -u

if [ "$#" -eq 0 ]; then
  HERMES_TUI_CWD="${HERMES_TUI_CWD:-$HOME/HERMES AI}"
  export HERMES_TUI_CWD
  if [ ! -d "$HERMES_TUI_CWD" ]; then
    printf 'hermes.sh: no existe el workspace %s. Ejecuta los enlaces de hermes/link-configs.sh.\n' "$HERMES_TUI_CWD" >&2
    exit 1
  fi
  cd -- "$HERMES_TUI_CWD" || exit 1
  set -- --tui --resume latest
fi

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

printf 'hermes.sh: no se encontró el binario hermes.\n' >&2
printf 'Instálalo con: curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash\n' >&2
exit 127
