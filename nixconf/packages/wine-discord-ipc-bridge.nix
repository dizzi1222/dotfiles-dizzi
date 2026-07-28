{ lib, stdenvNoCC, fetchurl }:

# wine-discord-ipc-bridge: bridge de Discord Rich Presence para juegos bajo
# Proton/Wine (Steam). El .exe se compila para i686-windows (corre dentro del
# wineprefix); NO se puede compilar desde Linux sin el cross-toolchain mingw,
# por eso usamos los binarios precompilados del release v0.0.3 + el script .sh
# del tag. Se referencia en Steam → Launch Options por juego:
#   /nix/store/<...>-wine-discord-ipc-bridge-0.0.3/bin/winediscordipcbridge-steam.sh %command%
stdenvNoCC.mkDerivation {
  pname = "wine-discord-ipc-bridge";
  version = "0.0.3";

  src =
    fetchurl {
      url = "https://github.com/0e4ef622/wine-discord-ipc-bridge/releases/download/v0.0.3/winediscordipcbridge.exe";
      hash = "sha256-ubZuuZAUR83CgsdJ8/KEkxVOrea1CWYaeNOfjdxriPo=";
    };

  steamSh =
    fetchurl {
      url = "https://raw.githubusercontent.com/0e4ef622/wine-discord-ipc-bridge/v0.0.3/winediscordipcbridge-steam.sh";
      hash = "sha256-ZVyWYsubV+BTIbZf2qf+0Gob14Er/WE8xkg2E+lb5xc=";
    };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp $src $out/bin/winediscordipcbridge.exe
    cp $steamSh $out/bin/winediscordipcbridge-steam.sh
    chmod +x $out/bin/winediscordipcbridge-steam.sh
    runHook postInstall
  '';

  meta = {
    description = "Enable games running under wine to use Discord Rich Presence (prebuilt v0.0.3 release)";
    homepage = "https://github.com/0e4ef622/wine-discord-ipc-bridge";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
    broken = false;
  };
}