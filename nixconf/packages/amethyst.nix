{ lib, appimageTools, fetchurl }:

# Amethyst Mod Manager — gestor de mods nativo Linux (alternativa a Mod Organizer 2).
# AppImage oficial del release v2.5.1 (x86_64). El v2.5.2 salió con el offset
# SQUASHFS desalineado (`FATAL ERROR: Can't find a valid SQUASHFS superblock`
# en appimageTools.extract) → bajado a 2.5.1 que sí extrae limpio.
appimageTools.wrapType2 {
  pname = "amethyst";
  version = "2.5.1";

  src = fetchurl {
    url = "https://github.com/ChrisDKN/Amethyst-Mod-Manager/releases/download/v2.5.1/AmethystModManager-2.5.1-x86_64.AppImage";
    hash = "sha256-Kf5Um5jnZ+FpGh13w4/KBxdrUnzJqhKjzBrEwpcbXns=";
  };

  meta = {
    description = "Amethyst - Native Linux mod manager (MO2-style) for multiple games";
    homepage = "https://github.com/ChrisDKN/Amethyst-Mod-Manager";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}