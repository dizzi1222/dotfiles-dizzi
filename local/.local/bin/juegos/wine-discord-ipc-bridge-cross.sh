#!/bin/bash
# wine-discord-ipc-bridge-cross.sh — Wrapper cross-system para Bazzite y Nix/CachyOS
#
# Bazzite: necesita wine-staging (GE-Proton8-26) para AF_UNIX sockets
# Nix/CachyOS: usa wine del sistema (wine-normal, sin AF_UNIX necesario si Discord usa pipe nativo)
#
# Uso: wine-discord-ipc-bridge-cross.sh [wine|bottles]

MODE="${1:-wine}"

# ── Detectar si estamos en Bazzite (tiene GE-Proton8-26 runner) ──
GE_RUNNER="$HOME/.var/app/com.usebottles.bottles/data/bottles/runners/GE-Proton8-26"
SODA_RUNNER="$HOME/.var/app/com.usebottles.bottles/data/bottles/runners/soda-11.0-10"

if [ -x "$GE_RUNNER/bin/wine" ]; then
  # Bazzite: usar GE-Proton8-26 para AF_UNIX sockets
  exec env WINEPREFIX="$HOME/.wine" \
    LD_LIBRARY_PATH="$GE_RUNNER/lib:$GE_RUNNER/lib/wine/x86_64-unix:$GE_RUNNER/lib/wine/i386-unix" \
    "$GE_RUNNER/bin/wine" "$HOME/.local/bin/winediscordipcbridge.exe"
elif command -v wine >/dev/null 2>&1; then
  # Nix/CachyOS: usar wine del sistema
  exec env WINEPREFIX="$HOME/.wine" wine "$HOME/.local/bin/winediscordipcbridge.exe"
else
  echo "wine-discord-ipc-bridge-cross: no wine disponible" >&2
  exit 1
fi
