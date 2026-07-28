{ lib, runCommand, fetchFromGitHub }:

let
  classic = fetchFromGitHub {
    owner = "Lxtharia";
    repo = "minegrub-theme";
    rev = "main";
    hash = "sha256-NO94JBjSI4jHPaSxXhaZDv3oT7lKpoCzLxjAbWdSjwc=";
  };

  worldSelection = fetchFromGitHub {
    owner = "Lxtharia";
    repo = "minegrub-world-selection";
    rev = "main";
    hash = "sha256-gBlP4aQQ0f3L6S1gWbidbflnp0p5hsJ8qmbyArZ8LO4=";
  };
in
runCommand "minegrub-themes" {} ''
  mkdir -p $out/share/grub/themes
  cp -r ${classic}/minegrub $out/share/grub/themes/minegrub
  cp -r ${worldSelection}/minegrub-world-selection $out/share/grub/themes/minegrub-world-selection
''
