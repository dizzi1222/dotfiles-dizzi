# Amethyst Mod Manager — gestor de mods nativo Linux (fork de Mod Organizer 2).
#
# POR QUÉ NO appimageTools.wrapType2 (bug de lectura de offset, no de upstream):
#
# 1. `appimageTools` calcula el offset del payload SQUASHFS leyendo el ELF y
#    obtiene 1507016. La runtime real del AppImage (`--appimage-offset`) dice
#    1469984. Offset incorrecto -> "Can't find a valid SQUASHFS superblock".
#    El valor 1507016 NI SIQUIERA aparece en el archivo (busqueda de patron:
#    0 hits), asi que no es que este "un poco mal".
# 2. El payload va comprimido con ZSTD. `unsquashfs` (squashfs-tools, sin
#    soporte zstd) no lo lee en NINGUN offset — probado en 0, 1139297, 1469984
#    y 1507016. La runtime del AppImage si lo lee (trae su propio lector con
#    zstd), por eso `--appimage-extract` funciona y `unsquashfs` no.
#
# La nota anterior del repo decia que v2.5.1 "si extrae limpio": FALSO, se
# verifico que v2.5.1 y v2.5.2 fallan igual con appimageTools.
#
# Workaround: extraer con la propia runtime del AppImage (`--appimage-extract`,
# no necesita FUSE) y envolver el AppRun. NO usa appimageTools, asi que no
# depende de unsquashfs.
#
# AppImage v2.5.1 (x86_64, 118 MiB comprimido -> ~416 MiB AppDir).
{ lib
, stdenvNoCC
, fetchurl
, makeDesktopItem
, symlinkJoin
}:

let
  version = "2.5.1";

  amethyst-appimage = stdenvNoCC.mkDerivation {
    pname = "amethyst-appimage";
    inherit version;
    src = fetchurl {
      url = "https://github.com/ChrisDKN/Amethyst-Mod-Manager/releases/download/v${version}/AmethystModManager-${version}-x86_64.AppImage";
      hash = "sha256-Kf5Um5jnZ+FpGh13w4/KBxdrUnzJqhKjzBrEwpcbXns=";
    };

    dontUnpack = true;

    buildPhase = ''
      runHook preBuild
      # /nix/store es read-only: hay que copiar a un path writable para poder
      # hacer chmod +x de la runtime. Sin esto -> "Operation not permitted".
      cp "$src" ./amethyst.AppImage
      chmod +x ./amethyst.AppImage
      # --appimage-extract no necesita FUSE y produce ./squashfs-root (AppDir)
      ./amethyst.AppImage --appimage-extract
      test -d squashfs-root || { echo "la extraccion fallo"; exit 1; }
      chmod -R u+w squashfs-root
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      # AppDir completo en libexec/amethyst: el AppRun resuelve sus libs
      # relativas a $APPDIR (= dirname de $0), por eso el symlink en bin/ es
      # relativo y el AppDir NO puede vivir en $out directo.
      mkdir -p "$out/libexec/amethyst" "$out/bin"
      cp -r squashfs-root/. "$out/libexec/amethyst/"
      chmod +x "$out/libexec/amethyst/AppRun"
      ln -s ../libexec/amethyst/AppRun "$out/bin/amethyst"

      # El .desktop usa Icon=amethyst, pero el AppDir solo trae mod-manager.png.
      mkdir -p "$out/share/icons/hicolor/256x256/apps"
      cp "$out/libexec/amethyst/mod-manager.png" \
         "$out/share/icons/hicolor/256x256/apps/amethyst.png"
      runHook postInstall
    '';

    # El AppImage trae sus propias libs en libexec/amethyst/lib: no se patchea ELF.
    dontPatchELF = true;

    meta = {
      description = "Amethyst - Native Linux mod manager (MO2-style) for Skyrim/Fallout 4";
      homepage = "https://github.com/ChrisDKN/Amethyst-Mod-Manager";
      license = lib.licenses.mit;
      platforms = lib.platforms.linux;
      mainProgram = "amethyst";
    };
  };

  # .desktop propio: el del AppDir usa Exec=mod-manager %u, que no existe en $PATH
  desktop = makeDesktopItem {
    name = "amethyst-mod-manager";
    exec = "amethyst";
    icon = "amethyst";
    desktopName = "Amethyst Mod Manager";
    genericName = "Mod Manager";
    comment = "Game mod manager for Linux (MO2-style, fork of Mod Organizer 2)";
    categories = [ "Game" ];
    keywords = [ "Amethyst" "mod" "mods" "mod manager" "MO2" "Skyrim" "Fallout" ];
    startupNotify = true;
  };
in
symlinkJoin {
  name = "amethyst-${version}";
  paths = [ amethyst-appimage desktop ];
}
