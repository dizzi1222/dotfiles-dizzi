# Vortex (NexusMods.App) — gestor de mods oficial de Nexus Mods.
#
# POR QUÉ NO appimageTools.wrapType2:
#
# 1. `appimageTools` calcula mal el offset del payload SQUASHFS. Lee 1507016
#    del ELF; la runtime real del AppImage (`--appimage-offset`) dice 1469984.
#    El valor 1507016 NI APARECE en el archivo (0 hits de búsqueda), así que
#    no es que esté "un poco mal": lo calcula con otro criterio.
# 2. El payload va comprimido con ZSTD. `unsquashfs` (squashfs-tools, sin
#    soporte zstd) no lo lee en NINGÚN offset — probado en 0, 1139297, 1469984
#    y 1507016. La runtime del AppImage sí lo lee (trae su propio lector con
#    zstd), por eso `--appimage-extract` funciona y `unsquashfs` no.
# 3. `wrapType2` renombra el ejecutable a <pname> y solo expone $out/bin/.
#    Nunca copia el .desktop ni los iconos del AppDir a share/, así que el
#    menú quedaba sin entrada y con Icon= inexistente.
#
# Workaround: extraer con la propia runtime del AppImage (`--appimage-extract`,
# no necesita FUSE) y envolver el AppRun. NO usa appimageTools, así que no
# depende de unsquashfs ni de su cálculo de offset.
#
# El binario es .NET (NexusMods.App.dll), por eso necesita libicu para
# globalization. Se expone vía LD_LIBRARY_PATH + DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=0.
#
# AppImage v0.21.1 (tag con "v") — 269,972,672 bytes.
{ lib
, stdenvNoCC
, fetchurl
, autoPatchelfHook
, glibc
, zlib
, patchelf
, icu
, fontconfig
, freetype
, libX11
, libXext
, libXrandr
, libXi
, libXcursor
, libXfixes
, libXrender
, libXinerama
, libSM
, libICE
, libXxf86vm
, writeShellScriptBin
, makeDesktopItem
, symlinkJoin
}:

# Vortex (NexusMods.App) — alias de búsqueda/arranque.
# El paquete nixpkgs `nexusmods-app-unfree` expone `NexusMods.App`; esto añade:
#   - binario `vortex` → NexusMods.App (arranque directo)
#   - .desktop con Name/GenericName/Keywords "Vortex …" para encontrarlo en
#     launcher (rofi/fuzzel/vicinae) buscando "vortex" o "nexus mods"
let
  version = "0.21.1";

  # Iconos versionados como fallback (ver installPhase de vortex-extracted).
  assets = ../assets;

  # ── Runtime nativo del AppDir ─────────────────────────────────────
  # El binario es .NET self-contained: el host carga las DLLs del AppDir,
  # pero delega en dlopen() las libs nativas, y en el AppDir no hay ninguna
  # (el RPATH del ELF apunta a $ORIGIN/netcoredeps, que no existe). Sin esto
  # la app NO abre ventana y sale en silencio: el error real solo queda en
  # ~/.local/state/NexusMods.App/Logs/nexusmods.app.main.current.log como
  # [FATAL] DllNotFoundException, y va fallando de a uno:
  #   1. libSkiaSharp.so -> le falta libfontconfig.so.1
  #   2. libX11.so.6      -> backend X11 de Avalonia (DISPLAY de XWayland)
  # Se resuelve con fontconfig + freetype + el set de X11.
  libicu = "${icu}/lib";

  runtimeLibs = lib.makeLibraryPath [
    fontconfig
    freetype
    libX11
    libXext
    libXrandr
    libXi
    libXcursor
    libXfixes
    libXrender
    libXinerama
    libSM
    libICE
    libXxf86vm
  ];

  # El RPATH se hornea en el ELF (ver installPhase de vortex-extracted).
  vortexRpath = "${libicu}:${runtimeLibs}";

  vortex-src = fetchurl {
    url = "https://github.com/Nexus-Mods/NexusMods.App/releases/download/v${version}/NexusMods.App.x86_64.AppImage";
    hash = "sha256-v+fOSxerNRz46l1i6rgOA/fb39M+493pHV24mSpIPuc=";
  };

  vortex-extracted = stdenvNoCC.mkDerivation {
    pname = "vortex-extracted";
    inherit version;
    src = vortex-src;
    dontUnpack = true;
    nativeBuildInputs = [ zlib patchelf ];
    # El ELF AppImage necesita libz en el LD_LIBRARY_PATH para arrancarse
    # dentro del sandbox, igual que libicu en runtime.
    LD_LIBRARY_PATH = "${zlib}/lib";

    buildPhase = ''
      runHook preBuild
      # /nix/store es read-only (fetchurl deja el archivo en 444): hay que
      # copiar a un path writable Y chmod +x antes de tocarlo. Sin esto ->
      # "patchelf: open: Permission denied" o "Operation not permitted".
      cp --no-preserve=mode "$src" ./app.AppImage
      chmod +w ./app.AppImage
      # El AppImage es un ELF AppImage (no un ELF dinamico normal): su
      # "interpreter" apunta a /lib64/ld-linux-x86-64.so.2, que en el host
      # NixOS es un symlink a nix-ld y NO existe dentro del sandbox del build
      # -> "cannot execute: required file not found". Se le da la ruta real
      # del loader de glibc para que el binario sea ejecutable en el sandbox.
      patchelf --set-interpreter "${glibc}/lib/ld-linux-x86-64.so.2" ./app.AppImage
      chmod +x ./app.AppImage
      # --appimage-extract no necesita FUSE y produce ./squashfs-root (AppDir)
      ./app.AppImage --appimage-extract
      test -d squashfs-root || { echo "la extraccion fallo"; exit 1; }
      chmod -R u+w squashfs-root
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      # El AppDir va en libexec/vortex/ y NO en la raiz: varios AppImages
      # (vortex, curseforge, amethyst) traen un "AppRun" en su raiz, y
      # buildEnv (que usa home-manager para armar el PATH) falla con
      # "two given paths contain a conflicting subpath: AppRun".
      # Ademas el AppRun resuelve $APPDIR = dirname($0), asi que las libs
      # relativas siguen funcionando dentro de libexec/vortex/.
      mkdir -p "$out/libexec/vortex" "$out/bin"
      cp -r squashfs-root/. "$out/libexec/vortex/"
      chmod +x "$out/libexec/vortex/AppRun" 2>/dev/null || true
      ln -s ../libexec/vortex/AppRun "$out/bin/NexusMods.App"

      # ── RPATH en el ELF real (usr/bin/NexusMods.App) ────────────
      # Necesario porque la app se auto-genera en CADA arranque
      # ~/.local/share/applications/com.nexusmods.app.desktop con
      #   Exec=<ruta real del ELF> %u
      # o sea, apunta al binario CRUDO, sin nuestro wrapper y por lo tanto
      # sin LD_LIBRARY_PATH. Con el wrapper esa entrada del menu no abre
      # nada (DllNotFoundException silencioso).
      # Se usa --force-rpath (DT_RPATH, no DT_RUNPATH) porque DT_RPATH SI se
      # hereda a las dependencias: sin eso, libSkiaSharp.so se encuentra pero
      # su libfontconfig.so.1 no.
      patchelf --force-rpath --set-rpath "${vortexRpath}" \
        "$out/libexec/vortex/usr/bin/NexusMods.App"

      # El .desktop que genera la app usa Icon=com.nexusmods.app; el nuestro
      # usa Icon=vortex. El mismo svg se instala con LOS DOS nombres para que
      # las dos entradas del menu muestren el mismo icono. El PNG versionado
      # queda de fallback para cuando el AppImage no traiga el svg.
      mkdir -p "$out/share/icons/hicolor/scalable/apps"
      if [ -f "$out/libexec/vortex/com.nexusmods.app.svg" ]; then
        cp "$out/libexec/vortex/com.nexusmods.app.svg" \
           "$out/share/icons/hicolor/scalable/apps/vortex.svg"
        cp "$out/libexec/vortex/com.nexusmods.app.svg" \
           "$out/share/icons/hicolor/scalable/apps/com.nexusmods.app.svg"
      elif [ -f "${assets}/vortex.png" ]; then
        mkdir -p "$out/share/icons/hicolor/256x256/apps"
        cp "${assets}/vortex.png" \
           "$out/share/icons/hicolor/256x256/apps/vortex.png"
        cp "${assets}/vortex.png" \
           "$out/share/icons/hicolor/256x256/apps/com.nexusmods.app.png"
      fi
      runHook postInstall
    '';

    dontPatchELF = true;
  };

  # Wrapper: expone `vortex` con libicu en el path (el App es .NET y lo
  # necesita para globalization; sin esto ->
  # "Couldn't find a valid ICU package installed on the system").
  #
  # ESCAPADO (Nix indented strings):
  #   ${icu}             -> Nix lo interpola (ruta del paquete)  CORRECTO
  #   ''${LD_LIBRARY_PATH} -> produce ${LD_LIBRARY_PATH} literal (bash)  CORRECTO
  # El bug anterior era usar ${icu.lib}: `icu` no tiene output `lib`, solo `out`
  # (verificado con `nix eval nixpkgs#zlib.outputs` -> out/dev/static).
  #
  # libicu/runtimeLibs se definen ARRIBA porque vortex-extracted los hornea
  # como RPATH del ELF; el wrapper los mantiene ademas como belt-and-suspenders
  # (funciona igual si alguien borra el RPATH a mano).
  bin = writeShellScriptBin "vortex" ''
    export LD_LIBRARY_PATH="${libicu}:${runtimeLibs}:''${LD_LIBRARY_PATH:-}"
    exec ${vortex-extracted}/libexec/vortex/AppRun "$@"
  '';
  desktop = makeDesktopItem {
    name = "vortex";
    exec = "vortex";
    icon = "com.nexusmods.app";
    desktopName = "Vortex";
    genericName = "Mod Manager";
    comment = "Vortex (NexusMods.App) - Game mod installer, creator and manager";
    categories = [ "Game" "Utility" ];
    keywords = [ "Vortex" "Nexus" "Nexus Mods" "mod" "mods" "mod manager" "installer" ];
    startupNotify = true;
  };
in
symlinkJoin {
  name = "vortex-${nexusmods-app-unfree.version}";
  paths = [ nexusmods-app-unfree bin desktop ];
}