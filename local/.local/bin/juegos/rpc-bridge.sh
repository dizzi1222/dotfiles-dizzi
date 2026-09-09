#!/bin/bash
# rpc-bridge (enderice2): lanza el bridge Rich Presence en ambos prefijos a la vez.
#   - ~/.wine (prefijo nativo): bridge ya Instalado como servicio; esto solo
#     garantiza que esté corriendo por si el servicio de Windows no arrancó.
#   - botella "gaming" (Bottles): copia el bridge.exe a su drive_c si no
#     existe y lo ejecuta. La 1ra vez abre el instalador (botón Install);
#     una vez instalado como servicio en la botella, solo lo arranca.
#   La botella de Bottles puede vivir en cualquiera de estas ubicaciones.
set -euo pipefail

BRIDGE_WINE="/home/diego/.wine/drive_c/windows/system32/discord/bridge.exe"

# Resolución del exe (NixOS -> PATH; Arch/CachyOS -> /opt/rpc-bridge)
if [ ! -f "$BRIDGE_WINE" ]; then
  ALT="$(command -v bridge.exe 2>/dev/null || true)"
  [ -n "$ALT" ] && [ -f "$ALT" ] || ALT="/opt/rpc-bridge/bridge.exe"
  if [ -f "$ALT" ]; then
    mkdir -p "$(dirname "$BRIDGE_WINE")"
    cp "$ALT" "$BRIDGE_WINE"
  fi
fi

# Directorio de botellas de Bottles (según instalación Flatpak o nativa)
# NixOS  -> Flatpak:   ~/.var/app/com.usebottles.bottles/data/bottles/bottles
# CachyOS -> nativo:   ~/.local/share/bottles/bottles
BOTTLES_BASE=""
drive_c_win() {
  printf '%s/gaming/drive_c/windows/system32/discord' "$1"
}

for dir in \
  "$HOME/.var/app/com.usebottles.bottles/data/bottles/bottles" \
  "$HOME/.local/share/bottles/bottles" \
  "$HOME/.local/bottles"; do
  if [ -d "$dir/gaming/drive_c" ]; then
    BOTTLES_BASE="$dir"
    BOTTLE_DIR="$(drive_c_win "$dir")"
    break
  fi
done
if [ -z "$BOTTLES_BASE" ]; then
  echo "rpc-bridge: no se encontró la botella 'gaming' de Bottles" >&2
  exit 1
fi

# 1) Prefijo nativo ~/.wine (blank si el servicio ya lo tiene corriendo)
env WINEPREFIX="/home/diego/.wine" wine "$BRIDGE_WINE" &

# 2) Botella gaming: asegurar bridge.exe dentro de ella y ejecutarlo
if [ ! -f "$BOTTLE_DIR/bridge.exe" ]; then
  mkdir -p "$BOTTLE_DIR"
  cp "$BRIDGE_WINE" "$BOTTLE_DIR/bridge.exe"
fi

# Ejecutor de bottles-cli: nativo si está en PATH, si no vía Flatpak
if command -v bottles-cli >/dev/null 2>&1; then
  BOTTLES_CLI=(bottles-cli)
else
  BOTTLES_CLI=(flatpak run --command=bottles-cli com.usebottles.bottles)
fi

"${BOTTLES_CLI[@]}" run -b gaming -e "C:\\windows\\system32\\discord\\bridge.exe"