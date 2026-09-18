{ lib, appimageTools, fetchurl }:

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

  meta = {
    description = "CurseForge App - Mod manager for Minecraft, WoW and other games";
    homepage = "https://www.curseforge.com";
    license = lib.licenses.unfreeRedistributable;
    platforms = lib.platforms.linux;
  };
}