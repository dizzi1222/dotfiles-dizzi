{ lib, runCommand, fetchFromGitHub }:

let
  classic = fetchFromGitHub {
    owner = "Lxtharia";
    repo = "minegrub-theme";
    rev = "main";
    hash = "sha256-tCHT7ZL4Fen/Y8Nv3c6iRdPx+1ZceUbGwREWPcZlQ3w=";
  };

  worldSelection = fetchFromGitHub {
    owner = "Lxtharia";
    repo = "minegrub-world-selection";
    rev = "main";
    hash = "sha256-Hlp081T6HUd4n6CaTf3aousZwBuBly6+0T+Y2d5y+SE=";
  };
in
runCommand "minegrub-themes" {} ''
  mkdir -p $out/share/grub/themes
  cp -r ${classic}/minegrub $out/share/grub/themes/minegrub
  cp -r ${worldSelection}/minegrub-world-selection $out/share/grub/themes/minegrub-world-selection
''
