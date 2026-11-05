#!/usr/bin/env bash
# Aplica Spicetify a una copia local del Spotify nativo (Bazzite tiene /usr inmutable).
set -euo pipefail

spotify_source=/usr/share/spotify
spotify_path="$HOME/.local/share/spotify-spicetify"
prefs_path="$HOME/.config/spotify/prefs"

if [ "$(id -u)" -eq 0 ]; then
  echo 'Ejecuta este script como tu usuario, sin sudo.' >&2
  exit 1
fi

if [ ! -x /usr/bin/spotify ] || [ ! -d "$spotify_source/Apps" ]; then
  echo 'Spotify nativo no está activo; reinicia si quedó staged en rpm-ostree.' >&2
  exit 1
fi

if pgrep -x spotify >/dev/null 2>&1; then
  echo 'Cierra Spotify por completo antes de copiar y aplicar Spicetify.' >&2
  exit 1
fi

spotify_version=$(rpm -q --qf '%{VERSION}-%{RELEASE}' spotify-client)
if [ -d "$spotify_path" ] && [ ! -f "$spotify_path/.rpm-version" ]; then
  echo "Existe $spotify_path sin marcador de versión; no la sobrescribo." >&2
  exit 1
fi
if [ -f "$spotify_path/.rpm-version" ] &&
  [ "$(cat "$spotify_path/.rpm-version")" != "$spotify_version" ]; then
  echo 'Spotify RPM cambió de versión: conserva la copia modificada; actualízala manualmente antes de reaplicar.' >&2
  exit 1
fi

if [ ! -d "$spotify_path" ]; then
  echo "Copiando Spotify nativo a $spotify_path (sin alterar /usr)…"
  mkdir -p "$spotify_path"
  cp -a --no-preserve=ownership --reflink=auto "$spotify_source/." "$spotify_path/"
  chmod -R u+rwX "$spotify_path"
  printf '%s\n' "$spotify_version" > "$spotify_path/.rpm-version"
fi

if ! command -v spicetify >/dev/null 2>&1; then
  curl -fsSL https://raw.githubusercontent.com/spicetify/cli/main/install.sh | sh
  export PATH="$HOME/.local/bin:$HOME/.spicetify:$PATH"
fi

spicetify config check_spicetify_update 0
spicetify config spotify_path "$spotify_path"
spicetify config prefs_path "$prefs_path"

if [ ! -f "$prefs_path" ]; then
  echo "Abre Spotify, inicia sesión y espera a que se cree $prefs_path; luego repite este script."
  exit 0
fi

spicetify backup apply
curl -fsSL https://raw.githubusercontent.com/spicetify/marketplace/main/resources/install.sh | sh
echo 'Spicetify y Marketplace aplicados. Abre Spotify.'
