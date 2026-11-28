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
  export WLR_BACKENDS=drm,libinput
  export WLR_DRM_DEVICES="$DRM_DEV"
  export WLR_NO_HARDWARE_CURSORS=1
  export WLR_RENDERER="${WLR_RENDERER:-gles2}"
  export LD_PRELOAD="/usr/local/lib/libseat-seat-arzopa.so"
  # Arranca aunque seat-arzopa no tenga teclado/touchpad (sin periféricos se
  # quedan en la laptop). Sin esto cage abortaba y systemd lo reiniciaba en
  # bucle; si después llegan, libinput los toma por hotplug.
  export WLR_LIBINPUT_NO_DEVICES=1

  # Sin sg: cambia fsgid a video y rompe el portal FUSE de Flatpak.
  # El acceso a card0 y al touchpad se resuelve con udev/seat-arzopa.
  exec cage -d -m last -- flatpak run app.zen_browser.zen >>"$LOG" 2>&1
}

stop_arzopa() {
  log "stop: matando cage de la Arzopa"
  pkill -f "cage -d -m last" 2>/dev/null || true
}

# ExecCondition: sin monitor en card0 (NVIDIA) no se lanza cage. Salir con 1
# deja la unidad omitida, no fallida.
check_arzopa() {
  local card="${DRM_DEV##*/}" drv c
  drv=$(readlink -f "/sys/class/drm/$card/device/driver" 2>/dev/null) || drv=""
  if [ "${drv##*/}" != nvidia ]; then
    log "check: $card usa '${drv##*/}', no la NVIDIA; no se lanza cage"
    return 1
  fi
  for c in /sys/class/drm/"$card"-*; do
    [ "$(cat "$c/status" 2>/dev/null)" = connected ] || continue
    [ "$(head -c 128 "$c/edid" 2>/dev/null | wc -c)" -ge 128 ] && return 0
  done
  log "check: sin monitor en $card; no se lanza cage"
  return 1
}

case "${1:-start}" in
  start) start_arzopa ;;
  stop) stop_arzopa ;;
  check) check_arzopa ;;
  *)
    printf 'Uso: %s {start|stop|check}\n' "$0" >&2
    exit 1
    ;;
esac
