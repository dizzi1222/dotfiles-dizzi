#!/bin/bash
# wine-discord-ipc-bridge-cross.sh — Wrapper cross-system para Bazzite y Nix/CachyOS
#
# Bazzite: los runners de Bottles (soda/GE) traen soporte i386 + wine-mono,
#          necesarios porque winediscordipcbridge.exe es un PE32 (32-bit).
#          El wine del sistema (11.20 x86_64 sin wine-wow64) NO puede ejecutarlo
#          (falla al mapear syswow64/ntdll.dll).
# Nix/CachyOS: usa wine del sistema (wine-normal).
#
# Uso: wine-discord-ipc-bridge-cross.sh [bottles|wine]
#   bottles -> prefijo de la botella "gaming" de Bottles (Flatpak)  [RECOMENDADO]
#   wine    -> prefijo ~/.wine  (solo si NO tiene dotnet40 roto; ver abajo)
#
# ⚠ ~/.wine en esta máquina tiene dotnet40 instalado a medias por winetricks.
#   Eso deja el servicio "clr_optimization_v4.0.30319_32" autostart en el
#   registro y, al arrancar wine, .NET Framework intenta iniciarlo y muestra
#   el diálogo "This application could not be started" (rundll32.exe).
#   Por eso el modo wine se niega a usarlo salvo FORCE=1.
#
# IMPORTANTE (Discord Flatpak):
#   El Flatpak de Discord publica el socket en
#     $XDG_RUNTIME_DIR/app/com.discordapp.Discord/discord-ipc-0
#   y el bridge lo detecta solo. NO crear el symlink
#     /run/user/1000/discord-ipc-0 -> app/com.discordapp.Discord/discord-ipc-0
#   porque provoca un bucle (el socat interno apunta a esa misma ruta).

set -euo pipefail

MODE="${1:-bottles}"
UID_NUM="$(id -u)"
XDG_RT="${XDG_RUNTIME_DIR:-/run/user/$UID_NUM}"

RUNNER_CANDIDATES=(
  "$HOME/.var/app/com.usebottles.bottles/data/bottles/runners/soda-11.0-10"
  "$HOME/.var/app/com.usebottles.bottles/data/bottles/runners/GE-Proton8-26"
)
EXE_SRC="$HOME/.local/bin/winediscordipcbridge.exe"
BOTTLE_PREFIX="$HOME/.var/app/com.usebottles.bottles/data/bottles/bottles/gaming"
WINE_PREFIX="$HOME/.wine"

# ── Elegir runner con soporte 32-bit (i386-unix) ─────────────────────────────
RUNNER=""
for r in "${RUNNER_CANDIDATES[@]}"; do
  if [ -x "$r/bin/wine" ] && [ -d "$r/lib/wine/i386-unix" ]; then
    RUNNER="$r"
    break
  fi
done
if [ -z "$RUNNER" ]; then
  echo "wine-discord-ipc-bridge-cross: no hay runner de Bottles con soporte i386." >&2
  echo "  winediscordipcbridge.exe es 32-bit; el wine del sistema sin wine-wow64 no sirve." >&2
  echo "  Instala wine-wow64 (rpm-ostree) o un runner de Bottles." >&2
  exit 1
fi

case "$MODE" in
  bottles) PREFIX="$BOTTLE_PREFIX" ;;
  wine)    PREFIX="$WINE_PREFIX"   ;;
  *)       echo "uso: $0 {bottles|wine}" >&2; exit 1 ;;
esac

[ -f "$EXE_SRC" ] || { echo "wine-discord-ipc-bridge-cross: falta $EXE_SRC" >&2; exit 1; }
[ -d "$PREFIX/drive_c" ] || { echo "wine-discord-ipc-bridge-cross: prefijo no existe: $PREFIX" >&2; exit 1; }

# ── Prefijo con dotnet40 roto: aviso (el bridge es nativo, no .NET) ──────────
if [ "$MODE" = "wine" ]; then
  if grep -qs "dotnet40" "$WINE_PREFIX/winetricks.log" 2>/dev/null \
     || [ -d "$WINE_PREFIX/drive_c/windows/Microsoft.NET/Framework64/v4.0.30319" ]; then
    echo "⚠  ~/.wine tiene restos de dotnet40 (winetricks). El bridge funciona" >&2
    echo "   (es nativo), pero cualquier app .NET en este prefijo mostrará" >&2
    echo "   'This application could not be started'. Para apps .NET usa la" >&2
    echo "   botella 'gaming' (tiene wine-mono)." >&2
  fi
fi

# ── Aviso si Discord no está publicando el socket ────────────────────────────
if [ -S "$XDG_RT/app/com.discordapp.Discord/discord-ipc-0" ]; then
  echo "✓ Socket Discord (Flatpak) detectado: $XDG_RT/app/com.discordapp.Discord/discord-ipc-0"
elif [ -S "$XDG_RT/discord-ipc-0" ]; then
  echo "✓ Socket Discord (nativo) detectado: $XDG_RT/discord-ipc-0"
else
  echo "⚠  Discord no expone discord-ipc-0. Abre Discord (flatpak run com.discordapp.Discord)." >&2
fi

# ── Instalar el bridge dentro del prefijo ────────────────────────────────────
DEST="$PREFIX/drive_c/windows/system32/discord"
mkdir -p "$DEST"
if ! cmp -s "$EXE_SRC" "$DEST/winediscordipcbridge.exe"; then
  cp -f "$EXE_SRC" "$DEST/winediscordipcbridge.exe"
  echo "  bridge copiado a $DEST"
fi

echo "== wine-discord-ipc-bridge ($MODE) =="
echo "   prefijo: $PREFIX"
echo "   runner : $RUNNER"

exec env WINEPREFIX="$PREFIX" XDG_RUNTIME_DIR="$XDG_RT" \
  LD_LIBRARY_PATH="$RUNNER/lib:$RUNNER/lib/wine/x86_64-unix:$RUNNER/lib/wine/i386-unix" \
  "$RUNNER/bin/wine" 'C:\windows\system32\discord\winediscordipcbridge.exe'
