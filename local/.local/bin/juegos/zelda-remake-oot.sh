#!/bin/sh
# The Legend of Zelda: Ocarina of Time Remake — cheezyemu / Lichii (Switch 2).
# Lutris exporta LD_LIBRARY_PATH con sus libs; las AppImage abortan (SIGABRT=134)
# si cargan Qt contra ellas: se limpia antes del exec.
set -u

unset LD_LIBRARY_PATH LD_PRELOAD LD_AUDIT

export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export __VK_LAYER_NV_optimus=NVIDIA_only
export DRI_PRIME=1

GAMES="/var/mnt/games-swap/NintendoSwitch2"
ROM="$GAMES/oot.nup"
LOG="$GAMES/zelda-remake-oot-error.log"

cd "$GAMES" || exit 1

# 1) cheezyemu (nuevo) — probar primero
for exe in "$GAMES/cheezyemu-linux-x86_64-pgo.AppImage" \
           "$GAMES/cheezyemu-linux-x86_64.AppImage"; do
  if [ -x "$exe" ]; then
    exec "$exe" -g "$ROM" "$@" 2>>"$LOG"
  fi
done

# 2) Lichii (fallback, el que ya funcionaba)
for exe in "$GAMES/lichii-pgo.AppImage" \
           "$GAMES/lichii-linux-x86_64.AppImage"; do
  if [ -x "$exe" ]; then
    exec "$exe" -g "$ROM" "$@" 2>>"$LOG"
  fi
done

echo "zelda-remake-oot: no se encontró cheezyemu ni Lichii." >&2
echo "  esperado: $GAMES/cheezyemu-linux-x86_64-pgo.AppImage o $GAMES/lichii-pgo.AppImage" >&2
echo "  partición: $(findmnt -n -o TARGET /dev/nvme0n1p4 2>/dev/null || echo 'NO montada')" >&2
exit 1