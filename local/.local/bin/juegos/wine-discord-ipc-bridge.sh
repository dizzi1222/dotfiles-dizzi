#!/bin/bash
# wine-discord-ipc-bridge (0e4ef622): lanza el bridge MANUAL en un prefijo dado.
# Uso:  wine-discord-ipc-bridge.sh wine     -> prefijo ~/.wine
#       wine-discord-ipc-bridge.sh bottles  -> botella "gaming" (Bottles)
# MANUAL: debe lanzarse ANTES del juego, en el mismo prefijo (no es servicio).
set -euo pipefail

BRIDGE=""
for cand in "$(command -v winediscordipcbridge.exe 2>/dev/null || true)" \
  "/opt/wine-discord-ipc-bridge/winediscordipcbridge.exe"; do
  [ -z "$BRIDGE" ] && [ -n "$cand" ] && [ -f "$cand" ] && BRIDGE="$cand"
done
[ -n "$BRIDGE" ] || { echo "wine-discord-ipc-bridge: exe no encontrado (¿pacote wine-discord-ipc-bridge-git instalado?)" >&2; exit 1; }

case "${1:-}" in
  wine)
    exec env WINEPREFIX="$HOME/.wine" wine "$BRIDGE"
    ;;
  bottles)
    for dir in \
      "$HOME/.var/app/com.usebottles.bottles/data/bottles/bottles" \
      "$HOME/.local/share/bottles/bottles" \
      "$HOME/.local/bottles"; do
      if [ -d "$dir/gaming/drive_c" ]; then
        BOTTLES_BASE="$dir"
        break
      fi
    done
    [ -n "${BOTTLES_BASE:-}" ] || { echo "wine-discord-ipc-bridge: no se encontró la botella 'gaming'" >&2; exit 1; }
    TARGET="$BOTTLES_BASE/gaming/drive_c/windows/system32/discord"
    if [ ! -f "$TARGET/winediscordipcbridge.exe" ]; then
      mkdir -p "$TARGET"
      cp "$BRIDGE" "$TARGET/winediscordipcbridge.exe"
    fi
    if command -v bottles-cli >/dev/null 2>&1; then
      BOTTLES_CLI=(bottles-cli)
    else
      BOTTLES_CLI=(flatpak run --command=bottles-cli com.usebottles.bottles)
    fi
    exec "${BOTTLES_CLI[@]}" run -b gaming -e "C:\\windows\\system32\\discord\\winediscordipcbridge.exe"
    ;;
  *)
    echo "uso: $0 {wine|bottles}" >&2
    exit 1
    ;;
esac