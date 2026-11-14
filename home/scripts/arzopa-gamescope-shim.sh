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
export WLR_BACKENDS=drm
export WLR_DRM_DEVICES="${ARZOPA_DRM_DEV:-/dev/dri/card0}"
export WLR_NO_HARDWARE_CURSORS=1
export WLR_RENDERER="${WLR_RENDERER:-gles2}"
export LD_PRELOAD="/usr/local/lib/libseat-seat-arzopa.so"

exec cage -d -m last -- "$@"
