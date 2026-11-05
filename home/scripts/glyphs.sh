#!/bin/bash
# Glyphs / Emoji picker - usa rofimoji + fuzzel (como Hyprland bindings L169-170)
# Uso: glyphs.sh [nerd]  -- sin args = emoji, con "nerd" = nerd_font

# Opción 1: rofimoji + fuzzel (tu config Hyprland L169-170)
if command -v rofimoji >/dev/null 2>&1 && command -v fuzzel >/dev/null 2>&1; then
  pkill fuzzel 2>/dev/null || true
  if [[ "$1" == "nerd" ]]; then
    rofimoji --action copy --selector fuzzel --prompt="Emoji Historial 󰁝 󰁅:"
  else
    rofimoji --action copy --selector fuzzel --prompt="Nerd Font Historial 󰁝 󰁅:" --files nerd_font
  fi
  exit 0
fi

# Fallback: rofimoji sin fuzzel
if command -v rofimoji >/dev/null 2>&1; then
  rofimoji --action copy
  exit 0
fi

# Fallback: rofi emoji
if command -v rofi >/dev/null 2>&1; then
  rofi -show emoji -modi emoji
  exit 0
fi

notify-send "⚠️ Glyphs" "Instala rofimoji y fuzzel para usar Mod+Shift+Period" 2>/dev/null || true
