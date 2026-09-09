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
    # Workspace índice 9 (determinista): enfocarlo lo crea si no existe.
    # Mover por ÍNDICE (no por nombre) evita colisiones con un "isolated" viejo.
    niri msg action focus-workspace 9 >/dev/null 2>&1
    niri msg action set-workspace-name "isolated" >/dev/null 2>&1
    niri msg action move-window-to-workspace 9 --window-id "$WID" >/dev/null 2>&1
    # El FLOATING NO siempre lo garantiza la window-rule (open-floating solo
    # aplica al mapear; post-hibernación/boot frío la ventana llega tiled).
    # Forzarlo idempotente solo si la ventana NO está flotando ya.
    if [ "$(niri msg --json windows 2>/dev/null | jq -r --argjson wid "$WID" '.[] | select(.id == $wid) | .is_floating')" = "false" ]; then
      niri msg action move-window-to-floating --id "$WID" >/dev/null 2>&1
    fi
    niri msg action focus-workspace 1 >/dev/null 2>&1
  fi
fi
