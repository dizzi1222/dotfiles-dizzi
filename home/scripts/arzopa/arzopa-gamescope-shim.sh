#!/usr/bin/env bash
# arzopa-gamescope-shim.sh — adapta el helper de gamescope-launcher a cage/Arzopa.
# Ignora los flags de gamescope y ejecuta el comando tras "--" dentro de cage
# en card0 (NVIDIA), con el shim de libseat para usar seat-arzopa.
set -euo pipefail

while [ "$#" -gt 0 ] && [ "$1" != "--" ]; do
  shift
done
[ "${1:-}" = "--" ] && shift

export LIBSEAT_BACKEND=noop
export WLR_BACKENDS=drm,libinput
export WLR_DRM_DEVICES="${ARZOPA_DRM_DEV:-/dev/dri/card0}"
export WLR_NO_HARDWARE_CURSORS=1
export WLR_RENDERER="${WLR_RENDERER:-gles2}"
export LD_PRELOAD="/usr/local/lib/libseat-seat-arzopa.so"
export WLR_LIBINPUT_NO_DEVICES=1

# En Game Mode, el launcher para antes el servicio de Zen y eso devuelve el
# teclado/touchpad a la laptop: se vuelven a repartir para esta app y regresan
# a la laptop cuando se cierra.
if [ "${XDG_CURRENT_DESKTOP:-}" = gamescope ]; then
  sudo -n /usr/local/bin/arzopa-attach >/dev/null 2>&1 || true
  # El detach corre al salir por cualquier vía: fin normal, error o señal
  trap 'sudo -n /usr/local/bin/arzopa-detach --inputs >/dev/null 2>&1 || true' EXIT
  # cage en segundo plano + wait: con cage en primer plano bash retrasa el trap
  # hasta que cage termine, y un SIGTERM solo al shim lo dejaría corriendo
  cage -d -m last -- "$@" &
  pid=$! sig=0
  trap 'sig=1; kill -TERM "$pid" 2>/dev/null || true' TERM INT HUP
  rc=0
  wait "$pid" || rc=$?
  # Una señal corta el wait antes de que cage salga: se espera de nuevo
  while [ "$sig" = 1 ]; do sig=0 rc=0; wait "$pid" || rc=$?; done
  exit "$rc"
fi

exec cage -d -m last -- "$@"
