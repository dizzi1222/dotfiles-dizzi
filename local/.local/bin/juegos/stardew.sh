#!/bin/bash
# Stardew Valley — prioridad Steam; si no hay Steam, ~/.wine; si no, botella gaming.
#
# 1) Steam (app 413150): Steam Input maneja el mando, no hace falta antimicrox.
# 2) Prefijo Wine clásico ~/.wine (Lutris/NixOS viejo).
# 3) Botella "gaming" de Bottles, ruta de instalación:
#    C:\Games\Stardew Valley\StardewModdingAPI.exe
set -uo pipefail

. "$(dirname "$(readlink -f "$0")")/_bottles.sh"

STEAM_APPID=413150
BOTTLE="gaming"

# ── 1) Steam ───────────────────────────────────────────────────────────
if command -v steam >/dev/null 2>&1; then
  for manifest in \
    "$HOME/.local/share/Steam/steamapps/appmanifest_${STEAM_APPID}.acf" \
    "$HOME/.steam/steam/steamapps/appmanifest_${STEAM_APPID}.acf"; do
    if [ -f "$manifest" ]; then
      exec steam "steam://rungameid/${STEAM_APPID}"
    fi
  done
  echo "stardew: Steam está instalado pero Stardew Valley (413150) no aparece;" >&2
  echo "         probando ~/.wine y la botella '$BOTTLE'..." >&2
fi

# ── 2) Prefijo Wine clásico ~/.wine ────────────────────────────────────
for exe in \
  "$HOME/.wine/drive_c/Games/Stardew Valley/StardewModdingAPI.exe" \
  "$HOME/.wine/drive_c/Games/Stardew Valley/Stardew Valley.exe"; do
  if [ -f "$exe" ]; then
    wine_run_prefix "$HOME/.wine" "$exe"
    exit $?
  fi
done

# ── 3) Botella "gaming" de Bottles ─────────────────────────────────────
CANDIDATES=(
  "C:\\Games\\Stardew Valley\\StardewModdingAPI.exe"
  "C:\\Games\\Stardew Valley\\Stardew Valley.exe"
)
EXE="$(bottles_pick_exe "$BOTTLE" "${CANDIDATES[@]}" 2>/dev/null || true)"
if [ -z "$EXE" ]; then
  echo "stardew: no se encontró Steam, ~/.wine ni Stardew Valley en la botella '$BOTTLE'." >&2
  echo "         ruta esperada en Bottles: $(bottles_expected_unix "$BOTTLE" "${CANDIDATES[0]}")" >&2
  exit 1
fi

bottles_run "$BOTTLE" "$EXE" "$@"
