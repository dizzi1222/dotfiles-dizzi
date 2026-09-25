{ lib
, appimageTools
, fetchurl
, stdenvNoCC
, glibc
, zlib
, symlinkJoin
, makeDesktopItem
, writeShellScriptBin
, gtk3
, nss
, nspr
, atk
, at-spi2-atk
, at-spi2-core
, cairo
, pango
, cups
, dbus
, expat
, glib
, libx11
, libxcomposite
, libxdamage
, libxext
, libxfixes
, libxrandr
, libxcb
, libxkbcommon
, libgbm
, alsa-lib
, libGL
, libdrm
, fontconfig
, freetype
, systemd
}:

# CurseForge App (gestor de mods: Minecraft, WoW, etc.)
# AppImage Linux oficial de Overwolf/CurseForge. wrapType2 extrae el AppImage
# y lo deja ejecutable directamente (sin depender de FUSE ni appimage-run).
# Nota: para deep-links del navegador (instalar mods con un clic) CurseForge
# pide un helper aparte; con AppImage los deep-links no funcionan por defecto.
appimageTools.wrapType2 {
  pname = "curseforge";
  version = "1.321.1-39714";

  src = fetchurl {
    url = "https://curseforge.overwolf.com/electron/linux/CurseForge-1.321.1-39714.AppImage";
    hash = "sha256-4DQZNlrJGY1gGAyqB74+vhhI9lCDPAEQrayhSX5G0Uc=";
  };

  appimage = stdenvNoCC.mkDerivation {
    pname = "curseforge";
    version = "1.321.1-39714";
    inherit src;
    dontUnpack = true;
    nativeBuildInputs = [ zlib ];
    LD_LIBRARY_PATH = "${zlib}/lib";

    buildPhase = ''
      runHook preBuild
      # /nix/store es read-only: copiar a un path writable y chmod +x.
      cp --no-preserve=mode "$src" ./app.AppImage
      chmod +w+x ./app.AppImage
      patchelf --set-interpreter "${glibc}/lib/ld-linux-x86-64.so.2" ./app.AppImage
      # --appimage-extract no necesita FUSE y produce ./squashfs-root (AppDir)
      ./app.AppImage --appimage-extract
      test -d squashfs-root || { echo "la extraccion fallo"; exit 1; }
      chmod -R u+w squashfs-root
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      # El AppDir va en libexec/curseforge/ y NO en la raiz: varios
      # AppImages (vortex, curseforge, amethyst) traen un "AppRun" en su raiz,
      # y buildEnv (que usa home-manager para armar el PATH) falla con
      # "two given paths contain a conflicting subpath: AppRun".
      mkdir -p "$out/libexec/curseforge"
      cp -r squashfs-root/. "$out/libexec/curseforge/"
      chmod +x "$out/libexec/curseforge/AppRun" 2>/dev/null || true
      # NOTE: NO se crea $out/bin/curseforge aca. El binario del PATH lo
      # genera el wrapper de mas abajo (writeShellScriptBin) para inyectar el
      # runtime de Electron; si los dos existieran, buildEnv reportaria
      # "colliding files" y podria ganar el symlink sin las libs.

      # el .desktop declara Icon=curseforge; el AppImage trae curseforge.png.
      # FALLBACK: si el AppImage no lo trae (o cambia el nombre), usamos el
      # icono versionado en nixconf/assets/. Asi el menu nunca queda sin icono.
      mkdir -p "$out/share/icons/hicolor/256x256/apps"
      if [ -f "$out/libexec/curseforge/curseforge.png" ]; then
        cp "$out/libexec/curseforge/curseforge.png" \
           "$out/share/icons/hicolor/256x256/apps/curseforge.png"
      elif [ -f "${assets}/curseforge.svg" ]; then
        mkdir -p "$out/share/icons/hicolor/scalable/apps"
        cp "${assets}/curseforge.svg" \
           "$out/share/icons/hicolor/scalable/apps/curseforge.svg"
      fi
      runHook postInstall
    '';

    dontPatchELF = true;

    meta = {
      description = "CurseForge App - Mod manager for Minecraft, WoW and other games";
      homepage = "https://www.curseforge.com";
      license = lib.licenses.unfreeRedistributable;
      platforms = lib.platforms.linux;
    };
  };

  # Runtime de Electron/Chromium. El AppImage trae el binario de Electron
  # pero NO sus libs nativas: el AppDir solo tiene 6 .so viejos de
  # appindicator en usr/lib. Por eso sin esto muere al arrancar con
  # "error while loading shared libraries: libnspr4.so: cannot open shared
  # object file" (el primero que falla de ~30).
  #
  # Verificado con ldd sobre libexec/curseforge/curseforge: 0 "not found".
  # libudev NO viene de `libudev-zero` (ese expone libudev.so.0); Electron
  # pide libudev.so.1, que vive en el output `udev-lib` de systemd.
  runtimeLibs = lib.makeLibraryPath [
    gtk3
    nss
    nspr
    atk
    at-spi2-atk
    at-spi2-core
    cairo
    pango
    cups
    dbus
    expat
    glib
    libx11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxcb
    libxkbcommon
    libgbm
    alsa-lib
    libGL
    libdrm
    fontconfig
    freetype
  ] + ":${lib.getOutput "udev-lib" systemd}/lib";

  bin = writeShellScriptBin "curseforge" ''
    export LD_LIBRARY_PATH="${runtimeLibs}:''${LD_LIBRARY_PATH:-}"

    # APPDIR hay que exportarlo SIEMPRE. El AppRun de Overwolf lo autodetecta
    # con este loop (AppRun:15-22):
    #     path="$(dirname "$(readlink -f "$0")")"
    #     while [[ "$path" != "" && ! -e "$path/$1" ]]; do path=''${path%/*}; done
    # Con el login, $1 es una URL (cfauth://code=...&state=...). "-e $path/$1"
    # nunca es true para una URL, asi que el while se come /nix/store/... hasta
    # dejar path="" -> APPDIR="" -> BIN="/curseforge":
    #     AppRun: line 45: /curseforge: No such file or directory
    # Con APPDIR ya puesto, el AppRun se salta ese bloque entero.
    export APPDIR="${appimage}/libexec/curseforge"

    exec "$APPDIR/AppRun" "$@"
  '';

  # El login de CurseForge es OAuth en el navegador del sistema + deep link:
  #   1. la app abre https://curseforge.overwolf.com/auth/v3/login-start.html
  #   2. el navegador autentica y redirige a cfauth://<token>
  #   3. Electron debe recibir esa URL por app.on("second-instance")
  #
  # Para que ese paso funcione el .desktop necesita LAS DOS cosas:
  #   - exec con %U   : sin field code, gio lanza la app y DESCARTA la URL
  #                      en silencio (no hay error, solo no llega el token)
  #   - mimeType cfauth: sin declararlo, gio no resuelve el handler y ademas
  #                      el "secret service" no lo encuentra
  # Electron registra el handler solo (xdg-settings/xdg-mime -> curseforge.desktop)
  # en ~/.config/mimeapps.list, pero el archivo lo poneis nosotros.
  desktop = makeDesktopItem {
    name = "curseforge";
    exec = "curseforge %U";
    icon = "curseforge";
    desktopName = "CurseForge";
    genericName = "Mod Manager";
    comment = "CurseForge - Mod manager for Minecraft, WoW and other games";
    categories = [ "Game" ];
    keywords = [ "CurseForge" "mod" "mods" "mod manager" "Minecraft" "WoW" "Overwolf" ];
    mimeTypes = [
      "x-scheme-handler/cfauth"
      "x-scheme-handler/curseforge"
      "x-scheme-handler/curseforge-checkout"
    ];
  };
in
symlinkJoin {
  name = "curseforge-${appimage.version}";
  paths = [ desktop bin appimage ];
}
