#!/usr/bin/env bash
# arzopa-gamemode.sh — Zen Browser en la Arzopa durante SteamOS Game Mode.
#
# Requisitos (los instala setup-via-a-arzopa.sh):
#   - card0 (NVIDIA) asignada a seat-arzopa ANTES de que gamescope haga
#     TakeControl de seat0 (drop-in ExecStartPre del unit de gamescope).
#   - diego en el grupo video: al sacar card0 de seat0 desaparece la ACL de
#     logind y el dispositivo queda root:video 0660.
#   - LIBSEAT_BACKEND=noop: en seat-arzopa no hay sesión logind que controlar.
#
# Estado: WIP. Pendiente validar tras reiniciar que card0 queda sin DRM master.
# Ver README-arzopa-gamemode.md para el diagnóstico completo.
set -euo pipefail

DRM_DEV="${ARZOPA_DRM_DEV:-/dev/dri/card0}"
LOG="${XDG_CACHE_HOME:-$HOME/.cache}/arzopa-gamemode.log"
mkdir -p "${LOG%/*}" 2>/dev/null || true

log() {
  printf '[%s] %s\n' "$(date '+%F %T')" "$*" | tee -a "$LOG"
}

start_arzopa() {
  log "start: DRM=$DRM_DEV renderer=${WLR_RENDERER:-gles2}"

  export LIBSEAT_BACKEND=noop
  export WLR_BACKENDS=drm
  export WLR_DRM_DEVICES="$DRM_DEV"
  export WLR_NO_HARDWARE_CURSORS=1
  export WLR_RENDERER="${WLR_RENDERER:-gles2}"
  export LD_PRELOAD="/usr/local/lib/libseat-seat-arzopa.so"
  unset WLR_LIBINPUT_NO_DEVICES

  # Sin sg: cambia fsgid a video y rompe el portal FUSE de Flatpak.
  # El acceso a card0 y al touchpad se resuelve con udev/seat-arzopa.
  exec cage -d -m last -- flatpak run app.zen_browser.zen >>"$LOG" 2>&1
}

stop_arzopa() {
  log "stop: matando cage de la Arzopa"
  pkill -f "cage -d -m last" 2>/dev/null || true
}

case "${1:-start}" in
  start) start_arzopa ;;
  stop) stop_arzopa ;;
  *)
    printf 'Uso: %s {start|stop}\n' "$0" >&2
    exit 1
    ;;
esac
