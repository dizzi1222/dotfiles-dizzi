#!/bin/bash
# Mueve la ventana flotante "nemo-desktop" (title) a un workspace aislado y nombrado.
# La ventana "Desktop" (title, los iconos del escritorio) se queda donde está.
# Solo aplica en niri; en Hyprland nemo se maneja con special:magic.
# shellcheck source=lib/platform.sh
source "$(dirname "$0")/lib/platform.sh"

if [ -n "$NIRI_SOCKET" ] && command -v jq >/dev/null; then
  # Espera activa (poll): la ventana puede tardar en mapearse al arrancar.
  WID=""
  for _ in $(seq 1 40); do
    WID="$(niri msg --json windows 2>/dev/null | jq -r '.[] | select(.title == "nemo-desktop") | .id' | head -n1)"
    [ -n "$WID" ] && break
    sleep 1
  done
  if [ -n "$WID" ]; then
    # Workspace "isolated" por NOMBRE: la window-rule (open-on-workspace)
    # lo crea/usar al mapear. Mover por índice es inestable con 2 monitores
    # (los idx se duplican y "9" cae en un workspace arbitrario).
    niri msg action move-window-to-workspace "isolated" --window-id "$WID" >/dev/null 2>&1
    # Force floating idempotente: open-floating de la rule solo aplica al
    # mapear; post-hibernación/boot frío la ventana puede llegar tiled.
    if [ "$(niri msg --json windows 2>/dev/null | jq -r --argjson wid "$WID" '.[] | select(.id == $wid) | .is_floating')" = "false" ]; then
      niri msg action move-window-to-floating --id "$WID" >/dev/null 2>&1
    fi
    niri msg action focus-workspace 1 >/dev/null 2>&1
  fi
fi
