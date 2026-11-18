#!/bin/sh
# Inicia la aplicación de escritorio oficial Grok Bot.
set -u

if command -v grok-bot >/dev/null 2>&1; then
  exec grok-bot "$@"
fi

for grok_bot_bin in /usr/bin/grok-bot /usr/local/bin/grok-bot; do
  if [ -x "$grok_bot_bin" ]; then
    exec "$grok_bot_bin" "$@"
  fi
done

for grok_bot_appimage in "$HOME/.local/opt/grok-bot.AppImage" "$HOME/.local/opt/Grok_Bot.AppImage"; do
  if [ -x "$grok_bot_appimage" ]; then
    exec "$grok_bot_appimage" "$@"
  fi
done

echo "grokbot.sh: no se encontró Grok Bot." >&2
echo "Instala el RPM o AppImage oficial desde las opciones de ~/bazzite-install.sh." >&2
exit 127
