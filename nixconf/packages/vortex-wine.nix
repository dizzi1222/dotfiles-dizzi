# vortex-wine: lanza el Vortex **Mod Manager** (clásico, bajo Wine) — NO el
# NexusMods.App nativo (ese es packages/vortex.nix). Este package es un
# wrapper que:
#   1. VERIFICA que la instalación de Vortex Windows exista en el wineprefix
#      (tipe: `~/.wine-vortex116` o `$WINEPREFIX`). Si el exe no está, avisa
#      con instrucciones en vez de lanzar una pantalla negra silenciosa.
#   2. Limpia el lockfile de Chromium (evita "Lock file can not be created").
#   3. Lanza con pty (`script`) porque Node/Electron muere con "open EBADF"
#      (createWritableStdioStream) sin un TTY real.
#   4. Usa --no-sandbox + --disable-gpu + --enable-unsafe-swiftshader: sin
#      GPU el gpu-process swiftshader se satura al 92% CPU y congela el mouse;
#      --disable-gpu deja el render por software (Skia) y la UI responde.
#
# La instalación de Vortex 1.16.9 vive en:
#   <prefix>/drive_c/Program Files/Black Tree Gaming Ltd/Vortex/Vortex.exe
#   (instalado con el installer vortex-setup-1.16.9.exe)
#
{ lib, writeShellScriptBin, makeDesktopItem, symlinkJoin }:

let
  exeRelative = "drive_c/Program Files/Black Tree Gaming Ltd/Vortex/Vortex.exe";
  installerHint = "~/Descargas/vortex-setup-1.16.9.exe";

  # Wrapper "vortex-wine": chequea instalacion + limpia locks + lanza.
  bin = writeShellScriptBin "vortex-wine" ''
    set -u
    export WINEPREFIX="''${WINEPREFIX:-$HOME/.wine-vortex116}"
    export WINEDEBUG="''${WINEDEBUG:--all}"
    VORTEX_EXE="$WINEPREFIX/${exeRelative}"
    VORTEX_LOCK="$WINEPREFIX/drive_c/users/diego/AppData/Roaming/Vortex/lockfile"

    # ── 1) Verificar que la instalación existe ────────────────────────
    if [ ! -f "$VORTEX_EXE" ]; then
      echo "Vortex (Wine) NO está instalado en: $WINEPREFIX" >&2
      echo "Instala la 1.16.9 con el installer:" >&2
      echo "  wine ${installerHint} /S" >&2
      echo "o usa el Vortex nativo de Linux:  vortex" >&2
      exit 1
    fi

    # Wine disponible?
    if ! command -v wine >/dev/null 2>&1; then
      echo "No se encontró 'wine' en PATH" >&2
      exit 1
    fi

    # ── 2) Matar instancias previas de Vortex + su wineserver ─────────
    for pid in $(ps -ef | grep "Vortex.exe" | grep -v grep | awk '{print $2}'); do
      kill -9 "$pid" 2>/dev/null
    done
    wineserver -k 2>/dev/null
    sleep 1

    # ── 3) Limpiar lockfile residual de Chromium ──────────────────────
    rm -f "$VORTEX_LOCK" 2>/dev/null

    # ── 4) Lanzar con pty + flags estabilizados ───────────────────────
    executable="$(command -v wine)"
    setsid script -q -c "'$executable' '$VORTEX_EXE' --no-sandbox --disable-gpu --enable-unsafe-swiftshader" /dev/null </dev/null >/dev/null 2>&1 &
    disown
    echo "Vortex (Wine 1.16.9) lanzado desde $WINEPREFIX"
  '';

  desktop = makeDesktopItem {
    name = "vortex-wine";
    exec = "vortex-wine";
    icon = "CFE6_Vortex.0";
    desktopName = "Vortex (Wine)";
    genericName = "Mod Manager";
    comment = "Vortex Mod Manager (1.16.9) bajo Wine — requiere instalación en ~/.wine-vortex116";
    categories = [ "Game" ];
    keywords = [ "Vortex" "Nexus" "Nexus Mods" "mod" "mods" "mod manager" "installer" "wine" ];
    startupNotify = true;
  };

in
symlinkJoin {
  name = "vortex-wine";
  paths = [ bin desktop ];
  meta = {
    description = "Lanzador del Vortex Mod Manager clásico bajo Wine (1.16.9)";
    platforms = lib.platforms.linux;
  };
}