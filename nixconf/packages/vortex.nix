{ lib, writeShellScriptBin, makeDesktopItem, symlinkJoin, nexusmods-app-unfree }:

# Vortex (NexusMods.App) — alias de búsqueda/arranque.
# El paquete nixpkgs `nexusmods-app-unfree` expone `NexusMods.App`; esto añade:
#   - binario `vortex` → NexusMods.App (arranque directo)
#   - .desktop con Name/GenericName/Keywords "Vortex …" para encontrarlo en
#     launcher (rofi/fuzzel/vicinae) buscando "vortex" o "nexus mods"
let
  bin = writeShellScriptBin "vortex" ''
    exec ${nexusmods-app-unfree}/bin/NexusMods.App "$@"
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