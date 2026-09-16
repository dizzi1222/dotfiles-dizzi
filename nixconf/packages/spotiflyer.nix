{ lib, stdenvNoCC, fetchurl, jre, makeWrapper }:

# SpotiFlyer v3.6.3 — proyecto discontinuado (nov 2023), pero el Linux-JAR
# del release oficial sigue funcionando con Java 21. JAR de Compose for
# Desktop; lo envolvemos con jre para ejecutarlo como `spotiflyer`.
stdenvNoCC.mkDerivation {
  pname = "spotiflyer";
  version = "3.6.3";

  src = fetchurl {
    url = "https://github.com/Shabinder/SpotiFlyer/releases/download/v3.6.3/SpotiFlyer-linux-x64-3.6.3.jar";
    hash = "sha256-7FWLF7BcyYvuTZ4giN2L+hWgoUpx5Xziy49HbchUx7s=";
  };

  dontUnpack = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib $out/bin
    cp $src $out/lib/SpotiFlyer.jar
    makeWrapper ${jre}/bin/java $out/bin/spotiflyer \
      --add-flags "-jar $out/lib/SpotiFlyer.jar"
    runHook postInstall
  '';

  meta = {
    description = "Open source music downloader for Spotify, YouTube, Gaana, Jio-Saavn and SoundCloud (discontinued, JAR v3.6.3)";
    homepage = "https://github.com/Shabinder/SpotiFlyer";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}