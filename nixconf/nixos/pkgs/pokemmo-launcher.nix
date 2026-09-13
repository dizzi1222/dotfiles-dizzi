{ lib, fetchurl, buildFHSEnv, writeShellScript, openjdk, makeDesktopItem, symlinkJoin
, zlib, libglvnd, mesa, freetype, fontconfig, openalSoft, glib, expat
, xorg, libxkbcommon, stdenv, libGL, gtk3
}:

let
  pname = "pokemmo-launcher";
  version = "4.0f";

  updaterJar = fetchurl {
    url = "https://dl.pokemmo.eu/download/updater/pokemmo_updater.jar";
    hash = "sha256-q2mSnXycd+Uouq4rjZzNBACuCiqDy9BgzwuucyBQfWM=";
  };

  fhs = buildFHSEnv {
    name = pname;

    targetPkgs = ps: [
      openjdk zlib libGL libglvnd mesa mesa.drivers freetype fontconfig openalSoft glib expat
      xorg.libX11 xorg.libXext xorg.libXcursor xorg.libXi
      xorg.libXrandr xorg.libXinerama xorg.libXrender xorg.libXtst
      libxkbcommon stdenv.cc.cc gtk3
    ];

    runScript = writeShellScript "pokemmo-run" ''
      # Asegurar DISPLAY: bajo niri/Hypr el Xwayland puede estar caído y java
      # muere con HeadlessException. Lo levantamos si no hay X activo.
      if [ -z "''${DISPLAY:-}" ]; then
        [ -S /tmp/.X11-unix/X0 ] || systemctl --user start xwayland-satellite.service 2>/dev/null || true
        for _ in $(seq 1 20); do
          [ -S /tmp/.X11-unix/X0 ] && break
          sleep 0.5
        done
        export DISPLAY=:0
      fi

      POKEMMO_DIR="''${XDG_DATA_HOME:-$HOME/.local/share}/pokemmo"
      mkdir -p "$POKEMMO_DIR"
      cd "$POKEMMO_DIR"
      export SDL_VIDEODRIVER=x11
      # TEST iGPU: desactiva DRI_PRIME/NVK para usar Intel UHD 630 (stutter descarte)
      # export DRI_PRIME=1
      export LD_LIBRARY_PATH="/run/opengl-driver/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      export VK_ICD_FILENAMES="/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json"
      # export VK_ICD_FILENAMES="/run/opengl-driver/share/vulkan/icd.d/nouveau_icd.x86_64.json"

      if [ -x "bin/linux/x64/PokeMMO" ]; then
        exec ./bin/linux/x64/PokeMMO "$@"
      fi

      exec java -jar "${updaterJar}" "$@"
    '';
  };

  desktopItem = makeDesktopItem {
    name = "pokemmo";
    exec = "${fhs}/bin/${pname}";
    desktopName = "PokeMMO";
    comment = "PokeMMO Launcher (official updater jar + native client in FHS env)";
    icon = "pokemmo-installer";
    categories = [ "Game" ];
  };
in
symlinkJoin {
  name = "${pname}-${version}";
  paths = [ fhs desktopItem ];
}