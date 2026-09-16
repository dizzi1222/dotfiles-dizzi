{ config, pkgs, ... }:

{
  # ── Music Downloaders ──────────────────────────────────────
  # Investigación 2026-09: Melora descartada (Windows-only WinUI3).
  # spotiflyer.app NO oficial (sitio tercero con "Spotify Premium APK").
  # Errores visibles observados (sept 2026):
  #   ▸ yt-dlp: HTTP 403 Forbidden en YouTube al descargar (bloqueado).
  #   ▸ streamrip: binario es `rip`; `stream` colisiona con ImageMagick.
  #   ▸ spotiflyer: muerto (2023), obtiene token pero no descarga.
  #   ▸ grayjay: git-lfs pesado (~3.3GB), falla con disco lleno.
  #   ▸ soundbound: login vía Sign Up en la app (auth propia, NO Google).
  home.packages = with pkgs; [
    spotube       # GUI — OK (login y descargas funcionando)
    spotdl        # CLI — OK; interfaz web: `spotdl web` (NO --web)
    ffmpeg        # Base de conversión (spotdl/streamrip la usan)
    #streamrip    # bin=`rip`, lossless Qobuz/Tidal/Deezer; `stream` es ImageMagick
    #yt-dlp       # ERROR visible: HTTP 403 Forbidden en YouTube (2026-09-16)
    #soundbound   # Requiere Sign Up; forgot-password buggy (ClassCastException)
    #spotiflyer   # DESCARTADO (2023): no descarga con Spotify actual
    #grayjay      # Solo con disco liberado (git-lfs ~3.3GB closure)
  ];

  # ── SpotDL Web (interfaz de descarga por navegador) ───────
  # Uso correcto: subcomando `web` (abre http://localhost:8800).
  # El flag `--web` NO existe — por eso `spotdl --web` mostraba el usage
  # y pedía query. Terminal=true para ver logs del servidor.
  xdg.desktopEntries."spotdl-web" = {
    name = "SpotDL Web";
    comment = "Descargar música de Spotify con interfaz web";
    icon = "imgi_1_spotdl";
    exec = "spotdl web";
    terminal = true;
    categories = [ "AudioVideo" "Audio" ];
  };
}