#!/bin/bash
# PES6 — botella "gaming" de Bottles (Bazzite / Flatpak).
# Rutas tal como las deja el instalador dentro de la botella:
#   C:\Games\KONAMI\Pro Evolution Soccer 6\PES6.exe
# (la vieja ~/.wine/drive_c/Games/... era del prefijo Lutris/NixOS)
set -uo pipefail

. "$(dirname "$(readlink -f "$0")")/_bottles.sh"

BOTTLE="gaming"
CANDIDATES=(
  "C:\\Games\\KONAMI\\Pro Evolution Soccer 6\\PES6.exe"
  "C:\\Program Files\\KONAMI\\Pro Evolution Soccer 6\\PES6.exe"
  "C:\\Program Files (x86)\\KONAMI\\Pro Evolution Soccer 6\\PES6.exe"
)

EXE="$(bottles_pick_exe "$BOTTLE" "${CANDIDATES[@]}" 2>/dev/null || true)"
if [ -z "$EXE" ]; then
  echo "pes6: PES6 no está instalado en la botella '$BOTTLE'." >&2
  echo "      esperado: $(bottles_expected_unix "$BOTTLE" "${CANDIDATES[0]}")" >&2
  echo "      instalalo desde Bottles > gaming y volvé a ejecutar este script." >&2
  exit 1
fi

# PES6 necesita el cwd en la carpeta del juego.
GAME_DIR="$(dirname "$(bottles_exe_unix "$BOTTLE" "$EXE")")"
cd "$GAME_DIR" 2>/dev/null || true

bottles_run "$BOTTLE" "$EXE" "$@"
