{ lib, stdenv, fetchFromGitHub, sddm }:

stdenv.mkDerivation rec {
  pname = "sddm-astronaut-theme";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "keyitdev";
    repo = "sddm-astronaut-theme";
    rev = "v1.0.0";
    sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  # Use the theme directly from the repo
  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    mkdir -p $out/share/sddm/themes/sddm-astronaut-theme
    cp -r * $out/share/sddm/themes/sddm-astronaut-theme/
  '';
}