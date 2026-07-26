{ lib, stdenv, fetchFromGitHub, python3, makeWrapper, lzip }:

stdenv.mkDerivation {
  pname = "waydroid-script";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "casualsnek";
    repo = "waydroid_script";
    rev = "main";
    hash = "sha256-zSHZlhHJHWZRE3I5pYWhD4o8aNpa8rTiEtl2qJTuRjw=";
  };

  buildInputs = [
    (python3.withPackages (ps: with ps; [ tqdm requests inquirerpy ]))
  ];

  nativeBuildInputs = [ makeWrapper ];

  postPatch = ''
    patchShebangs main.py
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/libexec
    cp -r . $out/libexec/waydroid_script
    mkdir -p $out/bin
    makeWrapper $out/libexec/waydroid_script/main.py $out/bin/waydroid_script \
      --prefix PATH : "${lib.makeBinPath [ lzip ]}"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Tools to install Magisk, GApps, and libhoudini on Waydroid";
    homepage = "https://github.com/casualsnek/waydroid_script";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
  };
}
