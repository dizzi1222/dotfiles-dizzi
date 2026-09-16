{ config, pkgs, ... }:

{
  # ── Music Downloaders ──────────────────────────────────────
  # Investigación 2026-09: Melora y Spotiflyer NO se usan.
  #  - Melora: Windows-only (WinUI3/.NET10), sin build Linux.
  #  - Spotiflyer: proyecto original descontinuado (2023); spotiflyer.app
  #    es un sitio tercero que vende "Spotify Premium APK" (riesgo malware).
  # Alternativas nativas en nixpkgs + GrayJay desktop (repo oficial FUTO).
  home.packages = with pkgs; [
    grayjay
    spotube
    spotdl
    streamrip
    yt-dlp
    ffmpeg
  ];
}