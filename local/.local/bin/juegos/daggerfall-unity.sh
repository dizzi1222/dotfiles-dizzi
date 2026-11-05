#!/bin/bash
# Daggerfall Unity — build Linux nativo.
# En Bazzite no existe `steam-run` (eso era de NixOS): el binario .x86_64 corre
# directo contra los drivers del sistema. Si no está el build nativo, se prueba
# la botella "gaming" de Bottles (C:\Games\Daggerfall Unity\DaggerfallUnity.exe)
# y por último la app de Steam (1812390).
set -uo pipefail

. "$(dirname "$(readlink -f "$0")")/_bottles.sh"

# Unity autodetecta los drivers SDL; no forzar backends de NixOS.
unset SDL_VIDEODRIVER SDL_AUDIODRIVER

ARGS=(-screen-fullscreen 0 -screen-width 1280 -screen-height 720)

# ── 1) Build Linux nativo ──────────────────────────────────────────────
for bin in \
  "$HOME/Games/Daggerfall Unity/DaggerfallUnity.x86_64" \
  "$HOME/DaggerfallUnity.x86_64" \
  "$HOME/mi_gdmusica/Daggerfall Unity/DaggerfallUnity.x86_64" \
  "$HOME/.local/bin/DaggerfallUnity.x86_64"; do
  if [ -x "$bin" ]; then
    exec "$bin" "${ARGS[@]}" "$@"
  fi
done

if command -v daggerfall-unity >/dev/null 2>&1; then
  exec daggerfall-unity "${ARGS[@]}" "$@"
fi

# ── 2) Botella "gaming" de Bottles ─────────────────────────────────────
BOTTLE="gaming"
CANDIDATES=(
  "C:\\Games\\Daggerfall Unity\\DaggerfallUnity.exe"
  "C:\\Games\\DaggerfallUnity\\DaggerfallUnity.exe"
)
EXE="$(bottles_pick_exe "$BOTTLE" "${CANDIDATES[@]}" 2>/dev/null || true)"
if [ -n "$EXE" ]; then
  bottles_run "$BOTTLE" "$EXE" "$@"
  exit $?
fi

# ── 3) Steam (app 1812390) ─────────────────────────────────────────────
if command -v steam >/dev/null 2>&1 \
  && [ -f "$HOME/.local/share/Steam/steamapps/appmanifest_1812390.acf" ]; then
  exec steam steam://rungameid/1812390
fi

echo "daggerfall-unity: no se encontró Daggerfall Unity." >&2
echo "  build Linux:  ~/Games/Daggerfall Unity/DaggerfallUnity.x86_64" >&2
echo "  Bottles:      $(bottles_expected_unix "$BOTTLE" "${CANDIDATES[0]}")" >&2
echo "  descarga:     https://www.dfworkshop.net/" >&2
exit 1
