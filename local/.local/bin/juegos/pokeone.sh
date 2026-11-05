#!/bin/bash
# PokeOne — botella "gaming" de Bottles (Flatpak en Bazzite, nativa en otras).
#
# Cross-system: no fija rutas de una distro concreta. Prueba los sitios donde
# el instalador oficial deja el juego dentro del prefijo:
#   %APPDATA%\PokeOne\files\PokeOne.exe   (instalación actual)
#   %APPDATA%\PokeOne\Launcher.exe        (instalaciones antiguas)
#   C:\Games\PokeOne\Launcher.exe         (Lutris/NixOS viejo)
# y se queda con el primero que EXISTA de verdad.
set -uo pipefail

. "$(dirname "$(readlink -f "$0")")/_bottles.sh"

BOTTLE="gaming"
WINUSER="$(id -un)"

CANDIDATES=(
  "C:\\Users\\${WINUSER}\\AppData\\Roaming\\PokeOne\\files\\PokeOne.exe"
  "C:\\Users\\${WINUSER}\\AppData\\Roaming\\PokeOne\\Launcher.exe"
  "C:\\Games\\PokeOne\\Launcher.exe"
  "C:\\Games\\PokeOne\\PokeOne.exe"
)

# El offload Vulkan y el entorno los maneja Bottles (bottle.yml: dxvk/nvapi).
# Si hiciera falta forzar la iGPU Intel: POKEONE_IGPU=1 pokeone.sh
if [ "${POKEONE_IGPU:-0}" = "1" ]; then
  export BOTTLES_ENV="VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/intel_icd.x86_64.json MESA_LOADER_DRIVER_OVERRIDE=iris"
fi

EXE="$(bottles_pick_exe "$BOTTLE" "${CANDIDATES[@]}" 2>/dev/null || true)"
if [ -z "$EXE" ]; then
  echo "pokeone: PokeOne no está instalado en la botella '$BOTTLE'." >&2
  echo "         esperado: $(bottles_expected_unix "$BOTTLE" "${CANDIDATES[0]}")" >&2
  echo "         instalalo desde Bottles > gaming y volvé a ejecutar este script." >&2
  exit 1
fi

# Unity necesita el cwd en la carpeta del ejecutable (junto a PokeOne_Data).
GAME_DIR="$(dirname "$(bottles_exe_unix "$BOTTLE" "$EXE")")"
cd "$GAME_DIR" 2>/dev/null || true

bottles_run "$BOTTLE" "$EXE" "$@"
