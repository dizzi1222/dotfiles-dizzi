#!/bin/bash
# customrp-discord.sh — Lanza CustomRP con bridge IPC para Discord
# Uso: customrp-discord.sh [wine|bottles]
#   wine   → usa ~/.wine con wine-staging (GE-Proton)
#   bottles → usa botella "gaming" de Bottles

set -euo pipefail

MODE="${1:-wine}"

# Runners
SODA_RUNNER="$HOME/.var/app/com.usebottles.bottles/data/bottles/runners/soda-11.0-10"
STAGING_RUNNER="$HOME/.var/app/com.usebottles.bottles/data/bottles/runners/GE-Proton8-26"

kill_old_bridges() {
  pkill -f "bridge.exe" 2>/dev/null || true
  pkill -f "winediscordipcbridge" 2>/dev/null || true
  sleep 1
}

wait_for_socket() {
  local timeout=10
  local elapsed=0
  while [ ! -S "/run/user/1000/discord-ipc-0" ] && [ $elapsed -lt $timeout ]; do
    sleep 0.5
    elapsed=$((elapsed + 1))
  done
  if [ -S "/run/user/1000/discord-ipc-0" ]; then
    echo "✓ Socket Discord detectado: /run/user/1000/discord-ipc-0"
    return 0
  else
    echo "✗ Timeout: Socket Discord no apareció"
    return 1
  fi
}

case "$MODE" in
  wine)
    echo "=== Modo Wine (~/.wine) con wine-staging ==="
    kill_old_bridges
    
    export WINEPREFIX="$HOME/.wine"
    export LD_LIBRARY_PATH="$STAGING_RUNNER/lib:$STAGING_RUNNER/lib/wine/x86_64-unix:$STAGING_RUNNER/lib/wine/i386-unix"
    
    echo "Iniciando bridge.exe (wine-staging)..."
    "$STAGING_RUNNER/bin/wine" "$WINEPREFIX/drive_c/windows/system32/discord/bridge.exe" >/tmp/bridge-wine.log 2>&1 &
    BRIDGE_PID=$!
    
    if wait_for_socket; then
      echo "Iniciando CustomRP..."
      "$STAGING_RUNNER/bin/wine" "$WINEPREFIX/drive_c/users/diego/AppData/Roaming/CustomRP/CustomRP.exe"
    else
      kill $BRIDGE_PID 2>/dev/null || true
      exit 1
    fi
    ;;
    
  bottles)
    echo "=== Modo Bottles (botella gaming) ==="
    kill_old_bridges
    
    BOTTLE="gaming"
    EXE="C:\\Users\\diego\\AppData\\Roaming\\CustomRP\\CustomRP.exe"
    
    echo "Iniciando bridge.exe en botella..."
    flatpak run --command=bottles-cli com.usebottles.bottles run -b "$BOTTLE" -e "C:\\windows\\system32\\discord\\bridge.exe" >/tmp/bridge-bottles.log 2>&1 &
    BRIDGE_PID=$!
    
    if wait_for_socket; then
      echo "Iniciando CustomRP en botella..."
      flatpak run --command=bottles-cli com.usebottles.bottles run -b "$BOTTLE" -e "$EXE"
    else
      kill $BRIDGE_PID 2>/dev/null || true
      exit 1
    fi
    ;;
    
  *)
    echo "Uso: $0 {wine|bottles}"
    exit 1
    ;;
esac
