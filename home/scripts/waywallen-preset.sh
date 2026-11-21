#!/usr/bin/env bash
# waywallen-preset.sh — Fuerza org.waywallen.kde como plugin de wallpaper en Plasma
# y lanza Waywallen (flatpak) en modo headless
set -euo pipefail

APPLETSRC="${XDG_CONFIG_HOME:-$HOME/.config}/plasma-org.kde.plasma.desktop-appletsrc"

# Parchear el plugin de wallpaper en containment 1 (desktop principal)
kwriteconfig6 \
  --file "$APPLETSRC" \
  --group "Containments" \
  --group "1" \
  --key "wallpaperplugin" \
  "org.waywallen.kde"

# Lanzar waywallen headless si no está corriendo
if ! pgrep -f "waywallen --no-ui" > /dev/null 2>&1; then
  flatpak run --command=sh org.waywallen.waywallen \
    -c "waywallen --no-ui" &
  disown
fi

echo "Waywallen preset aplicado."
