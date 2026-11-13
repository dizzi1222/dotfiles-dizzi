#!/usr/bin/env bash
# test-via-a.sh — Prueba Vía A: compositor Wayland Kiosk (cage) en NVIDIA card0 (Arzopa)
set -uo pipefail

export WLR_DRM_DEVICES=/dev/dri/card0
export WLR_BACKENDS=drm
export WLR_LIBINPUT_NO_DEVICES=1
export WLR_NO_HARDWARE_CURSORS=1
export WLR_RENDERER="${WLR_RENDERER:-gles2}"
export LIBSEAT_BACKEND=logind

LOG="/tmp/cage-via-a.log"
printf '[%s] Iniciando test Vía A con cage en /dev/dri/card0...\n' "$(date '+%F %T')" > "$LOG"

# Ejecutar cage con timeout de prueba o app
if [ "${1:-}" = "zen" ]; then
  exec cage -d -D -- flatpak run app.zen_browser.zen >> "$LOG" 2>&1
else
  cage -d -D -- true >> "$LOG" 2>&1
  RC=$?
  cat "$LOG"
  exit $RC
fi
