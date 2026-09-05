#!/bin/bash
# Reinicia el escritorio Nemo (Windows-style) en el WM activo (niri | Hyprland)
# shellcheck source=lib/platform.sh
source "$(dirname "$0")/lib/platform.sh"

if [ -n "$NIRI_SOCKET" ]; then
  # niri: no hay special workspaces; "magic" es un workspace nombrado (windows.kdl)
  niri msg action focus-workspace "magic"
  pkill nemo-desktop 2>/dev/null
  sleep 0.5
  nemo-desktop &
  sleep 3
  niri msg action focus-workspace 1
else
  hyprctl dispatch workspace special:magic
  pkill nemo-desktop 2>/dev/null
  sleep 0.5
  nemo-desktop &
  sleep 3
  ~/.config/hypr/scripts/omarchy-hyprland-window-pop
fi
