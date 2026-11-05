#!/usr/bin/env bash
# Lanza la copia de Spotify que Spicetify puede modificar en Bazzite.
set -euo pipefail

spotify_dir="$HOME/.local/share/spotify-spicetify"
if [ ! -x "$spotify_dir/spotify" ]; then
  exec /usr/bin/spotify "$@"
fi

export LD_LIBRARY_PATH="$spotify_dir/ffmpeg${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
flags_file="$HOME/.config/spotify/spotify-flags.conf"
env_file="$HOME/.config/spotify/spotify.env"

if [ ! -f "$flags_file" ]; then
  /usr/share/spotify/generate_flags_file.sh
fi
if [ ! -f "$env_file" ]; then
  /usr/share/spotify/generate_envs_file.sh
fi

mapfile -t flags < <(grep -v -E '^\s*$|^#' "$flags_file" || true)
mapfile -t vars < <(grep -v -E '^\s*$|^#|^[^=]*$' "$env_file" || true)
if [ "${#vars[@]}" -gt 0 ]; then
  exec env "${vars[@]}" "$spotify_dir/spotify" "${flags[@]}" "$@"
fi
exec "$spotify_dir/spotify" "${flags[@]}" "$@"
