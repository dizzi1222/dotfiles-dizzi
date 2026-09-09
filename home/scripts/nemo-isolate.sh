#!/bin/bash
# Mueve la ventana flotante "nemo-desktop" (title) a un workspace aislado y nombrado.
# La ventana "Desktop" (title, los iconos del escritorio) se queda donde está.
# Solo aplica en niri; en Hyprland nemo se maneja con special:magic.
# shellcheck source=lib/platform.sh
source "$(dirname "$0")/lib/platform.sh"

if [ -n "$NIRI_SOCKET" ] && command -v jq >/dev/null; then
  sleep 3
  WID="$(niri msg --json windows 2>/dev/null | jq -r '.[] | select(.title == "nemo-desktop") | .id' | head -n1)"
  if [ -n "$WID" ]; then
    # Crea (si no existe) un workspace llamado "isolated" y mueve ahí la ventana.
    # niri solo crea workspaces al enfocarlos por índice; el nombre se fija después.
    if ! niri msg --json workspaces 2>/dev/null | jq -e 'any(.[]; .name == "isolated")' >/dev/null 2>&1; then
      niri msg action focus-workspace 99 >/dev/null 2>&1
      niri msg action set-workspace-name "isolated" >/dev/null 2>&1
    fi
    niri msg action move-window-to-workspace "isolated" --window-id "$WID" >/dev/null 2>&1
  fi
fi