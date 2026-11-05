#!/bin/bash
# customrp-discord.sh — Lanza CustomRP con bridge IPC para Discord
# Uso: customrp-discord.sh [bottles|wine]
#   bottles → botella "gaming" de Bottles (recomendado en Bazzite)
#   wine    → prefijo ~/.wine
#
# El bridge se delega a wine-discord-ipc-bridge-cross.sh (una sola fuente de
# verdad). Ojo: winediscordipcbridge.exe es PE32 .NET, necesita runner con
# soporte i386 (soda/GE). El wine del sistema (x86_64 sin wine-wow64) falla.

set -euo pipefail

MODE="${1:-bottles}"
UID_NUM="$(id -u)"
XDG_RT="${XDG_RUNTIME_DIR:-/run/user/$UID_NUM}"

HERE="$(dirname "$(readlink -f "$0")")"
BRIDGE_SCRIPT="$HERE/wine-discord-ipc-bridge-cross.sh"

# Runners (el que exista con i386)
SODA_RUNNER="$HOME/.var/app/com.usebottles.bottles/data/bottles/runners/soda-11.0-10"
STAGING_RUNNER="$HOME/.var/app/com.usebottles.bottles/data/bottles/runners/GE-Proton8-26"
RUNNER=""
for r in "$SODA_RUNNER" "$STAGING_RUNNER"; do
  if [ -x "$r/bin/wine" ] && [ -d "$r/lib/wine/i386-unix" ]; then RUNNER="$r"; break; fi
done
[ -n "$RUNNER" ] || { echo "customrp-discord: no hay runner Bottles 32-bit" >&2; exit 1; }

BOTTLE_PREFIX="$HOME/.var/app/com.usebottles.bottles/data/bottles/bottles/gaming"
WINE_PREFIX="$HOME/.wine"

kill_old_bridges() {
  pkill -f "winediscordipcbridge" 2>/dev/null || true
  pkill -f "discord/bridge.exe" 2>/dev/null || true
  sleep 1
}

# Discord publica el socket en el runtime dir privado del Flatpak
# ($XDG_RUNTIME_DIR/app/com.discordapp.Discord/discord-ipc-0) o, si es nativo,
# en $XDG_RUNTIME_DIR/discord-ipc-0. Nunca en /run/user/1000/discord-ipc-0 con Flatpak.
discord_socket() {
  for p in "$XDG_RT/app/com.discordapp.Discord/discord-ipc-0" "$XDG_RT/discord-ipc-0"; do
    [ -S "$p" ] && { echo "$p"; return 0; }
  done
  return 1
}

wait_for_socket() {
  local timeout=15 elapsed=0 p
  while [ $elapsed -lt $timeout ]; do
    if p="$(discord_socket)"; then
      echo "✓ Socket Discord detectado: $p"
      return 0
    fi
    sleep 0.5
    elapsed=$((elapsed + 1))
  done
  echo "✗ Timeout: Discord no expone discord-ipc-0. Abre Discord primero." >&2
  return 1
}

case "$MODE" in
  wine)
    echo "=== Modo Wine (~/.wine) ==="
    PREFIX="$WINE_PREFIX"
    CUSTOMRP_EXE='C:\users\diego\AppData\Roaming\CustomRP\CustomRP.exe'
    ;;
  bottles)
    echo "=== Modo Bottles (botella gaming) ==="
    PREFIX="$BOTTLE_PREFIX"
    CUSTOMRP_EXE='C:\users\diego\AppData\Roaming\CustomRP\CustomRP.exe'
    ;;
  *)
    echo "Uso: $0 {bottles|wine}" >&2
    exit 1
    ;;
esac

[ -x "$BRIDGE_SCRIPT" ] || { echo "customrp-discord: falta $BRIDGE_SCRIPT" >&2; exit 1; }

wait_for_socket || exit 1
kill_old_bridges

echo "Iniciando bridge IPC..."
"$BRIDGE_SCRIPT" "$MODE" >/tmp/bridge-${MODE}.log 2>&1 &
BRIDGE_PID=$!
sleep 3

if ! kill -0 "$BRIDGE_PID" 2>/dev/null; then
  echo "✗ El bridge murió; revisa /tmp/bridge-${MODE}.log" >&2
  exit 1
fi
echo "✓ Bridge activo (pid $BRIDGE_PID, log /tmp/bridge-${MODE}.log)"

echo "Iniciando CustomRP..."
if [ ! -f "$PREFIX/drive_c/users/diego/AppData/Roaming/CustomRP/CustomRP.exe" ]; then
  echo "⚠  CustomRP no está instalado en este prefijo:" >&2
  echo "   $PREFIX/drive_c/users/diego/AppData/Roaming/CustomRP/CustomRP.exe" >&2
  echo "   Instálalo desde https://customrp.com o copia la carpeta CustomRP." >&2
  exit 1
fi

exec env WINEPREFIX="$PREFIX" XDG_RUNTIME_DIR="$XDG_RT" \
  LD_LIBRARY_PATH="$RUNNER/lib:$RUNNER/lib/wine/x86_64-unix:$RUNNER/lib/wine/i386-unix" \
  "$RUNNER/bin/wine" "$CUSTOMRP_EXE"
