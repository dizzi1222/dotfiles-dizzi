{ lib, appimageTools, fetchurl }:

# Soundbound (sucesor oficial de SpotiFlyer, mismo autor Shabinder).
# AppImage x64 del release 2.1.0 (linux-x64). wrapType2 extrae el AppImage
# y lo deja ejecutable directamente (sin depender de FUSE ni appimage-run).
appimageTools.wrapType2 {
  pname = "soundbound";
  version = "2.1.0";

  src = fetchurl {
    url = "https://github.com/Shabinder/soundbound-extensions-lib/releases/download/2.1.0/Soundbound-2.1.0-linux-x64.AppImage";
    hash = "sha256-5vICh0eZmAMsJ77lEWi2IL1P54cZReZPu9zUKLnqMuI=";
  };

  meta = {
    description = "Spotify / YouTube / SoundCloud music downloader (successor of SpotiFlyer)";
    homepage = "https://github.com/Shabinder/soundbound";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}