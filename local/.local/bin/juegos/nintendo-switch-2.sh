#!/bin/sh
# Nintendo Switch 2 (OoT Remake) — Lichii, emulador de Switch 2.
# Lutris inyecta LD_LIBRARY_PATH con sus propias libs y las AppImage abortan
# (SIGABRT=134) al cargar Qt contra ellas: hay que limpiarlo antes de exec.
set -u

unset LD_LIBRARY_PATH LD_PRELOAD LD_AUDIT

export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export __VK_LAYER_NV_optimus=NVIDIA_only
export DRI_PRIME=1

GAMES=/var/mnt/games-swap/NintendoSwitch2
LOG="$GAMES/lichii-error.log"

for exe in "$GAMES/lichii-pgo.AppImage" \
           "$GAMES/lichii-linux-x86_64.AppImage" \
           "$HOME/Games/lichii/lichii-pgo.AppImage"; do
  if [ -x "$exe" ]; then
    cd "$(dirname "$exe")" || exit 1
    exec "$exe" "$@"
  fi
done

echo "nintendo-switch-2: no se encontró la AppImage de Lichii." >&2
echo "  esperado: $GAMES/lichii-pgo.AppImage" >&2
echo "  partición: $(findmnt -n -o TARGET /dev/nvme0n1p4 2>/dev/null || echo 'NO montada')" >&2
exit 1
