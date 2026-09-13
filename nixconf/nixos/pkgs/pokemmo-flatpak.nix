{ writeShellScriptBin }:

writeShellScriptBin "pokemmo-launcher" ''
  exec flatpak run --branch=stable --arch=x86_64 --command=pokemmo.sh com.pokemmo.PokeMMO --launch "$@"
''