#!/usr/bin/env bash
# setup-wine-discord-bridge.sh — configura el prefijo Wine (~/.wine) con
# wine-discord-ipc-bridge (0e4ef622) y rpc-bridge (enderice2).
#
# Qué hace (idempotente):
#   1) Comprueba que `wine` esté instalado (si no: sudo rpm-ostree install wine).
#   2) Inicializa WINEPREFIX (~/.wine por defecto) con wineboot si no existe.
#   3) Localiza/descarga winediscordipcbridge.exe y bridge.exe.
#   4) Los copia a <prefijo>/drive_c/windows/system32/discord/.
#   5) Deja los dos lanzadores .desktop con icono propio.
#
# Uso:  bash ~/scripts/setup-wine-discord-bridge.sh
#       WINEPREFIX=/ruta/prefijo bash ~/scripts/setup-wine-discord-bridge.sh
set -euo pipefail

log() { printf '  ✓ %s\n' "$*"; }
warn() { printf '  ⚠️  %s\n' "$*" >&2; }

EXE_WINE="winediscordipcbridge.exe"
EXE_RPC="bridge.exe"
SUBDIR="discord"

# ---------------------------------------------------------------- 1) wine ----
WINE_OK=1
if ! command -v wine >/dev/null 2>&1; then
  warn "wine no está instalado todavía (sudo rpm-ostree install wine + reboot)."
  warn "Se preparan exes y lanzadores; el prefijo se inicializará al primer uso."
  WINE_OK=0
fi

# ------------------------------------------------------ 2) prefijo ~/.wine ----
export WINEPREFIX="${WINEPREFIX:-$HOME/.wine}"
if [ "$WINE_OK" -eq 1 ] && [ ! -d "$WINEPREFIX/drive_c" ]; then
  echo "Inicializando prefijo Wine en $WINEPREFIX …"
  WINEDLLOVERRIDES="mscoree,mshtml=" wineboot -i >/dev/null 2>&1 || true
fi
if [ "$WINE_OK" -eq 1 ] && [ ! -d "$WINEPREFIX/drive_c" ]; then
  warn "No se pudo crear el prefijo $WINEPREFIX"
  exit 1
fi
log "Prefijo Wine: $WINEPREFIX $([ "$WINE_OK" -eq 1 ] || echo '(pendiente de wineboot)')"

# --------------------------------------------------------------- 3) exes ----
find_exe() {
  local name="$1" c
  for c in "$HOME/.local/bin/$name" "$HOME/Descargas/$name" \
           "$HOME/Descargas/bridge/$name" "/opt/wine-discord-ipc-bridge/$name" \
           "/opt/rpc-bridge/$name"; do
    if [ -f "$c" ]; then printf '%s\n' "$c"; return 0; fi
  done
  return 1
}

download_exe() { # repo, patrón de asset, destino
  local repo="$1" pat="$2" dest="$3" url
  echo "  Descargando $pat desde GitHub ($repo)…"
  url=$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" \
        | grep -o '"browser_download_url":[[:space:]]*"[^"]*'"$pat"'[^"]*"' \
        | head -1 | cut -d'"' -f4)
  [ -n "$url" ] || return 1
  mkdir -p "$(dirname "$dest")"
  curl -fsSL -o "$dest" "$url"
}

WINE_SRC="$(find_exe "$EXE_WINE" || true)"
if [ -z "$WINE_SRC" ]; then
  if download_exe 0e4ef622/wine-discord-ipc-bridge "$EXE_WINE" "$HOME/.local/bin/$EXE_WINE"; then
    WINE_SRC="$HOME/.local/bin/$EXE_WINE"
  fi
fi
[ -n "$WINE_SRC" ] && log "$EXE_WINE: $WINE_SRC" || warn "$EXE_WINE no disponible (se omite)"

RPC_SRC="$(find_exe "$EXE_RPC" || true)"
if [ -z "$RPC_SRC" ]; then
  if download_exe enderice2/rpc-bridge "$EXE_RPC" "$HOME/.local/bin/$EXE_RPC"; then
    RPC_SRC="$HOME/.local/bin/$EXE_RPC"
  fi
fi
[ -n "$RPC_SRC" ] && log "$EXE_RPC: $RPC_SRC" || warn "$EXE_RPC no disponible (se omite)"

# ------------------------------------------- 4) copiar al sistema32\discord ----
DEST="$WINEPREFIX/drive_c/windows/system32/$SUBDIR"
mkdir -p "$DEST"
if [ -n "$WINE_SRC" ]; then
  cp -f "$WINE_SRC" "$DEST/$EXE_WINE"
  chmod +x "$DEST/$EXE_WINE" 2>/dev/null || true
  log "$EXE_WINE -> ${DEST#"$HOME"/}"
fi
if [ -n "$RPC_SRC" ]; then
  cp -f "$RPC_SRC" "$DEST/$EXE_RPC"
  chmod +x "$DEST/$EXE_RPC" 2>/dev/null || true
  log "$EXE_RPC -> ${DEST#"$HOME"/}"
fi

# ------------------------------------------------ 5) lanzadores .desktop ----
APPS="$HOME/.local/share/applications"
mkdir -p "$APPS"

cat > "$APPS/wine-discord-ipc-bridge-wine.desktop" <<'DESKTOP'
[Desktop Entry]
Name=Wine Discord IPC Bridge (Wine)
Comment=Lanza el bridge manual (0e4ef622) en el prefijo ~/.wine — lanzar ANTES del juego
Exec=/home/diego/.local/bin/juegos/wine-discord-ipc-bridge.sh wine
Icon=wine-discord-ipc-bridge
Type=Application
Terminal=false
StartupNotify=false
Categories=Game;
DESKTOP

cat > "$APPS/wine-discord-ipc-bridge-bottles.desktop" <<'DESKTOP'
[Desktop Entry]
Name=Wine Discord IPC Bridge (Bottles)
Comment=Lanza el bridge manual (0e4ef622) en la botella gaming — lanzar ANTES del juego
Exec=/home/diego/.local/bin/juegos/wine-discord-ipc-bridge.sh bottles
Icon=wine-discord-ipc-bridge-bottles
Type=Application
Terminal=false
StartupNotify=false
Categories=Game;
DESKTOP

command -v update-desktop-database >/dev/null 2>&1 && \
  update-desktop-database "$APPS" >/dev/null 2>&1 || true
command -v kbuildsycoca6 >/dev/null 2>&1 && \
  kbuildsycoca6 --noincremental >/dev/null 2>&1 || true

# Iconos propios (hicolor): resuelven aunque el tema activo no tenga "wine"
ICONS="$HOME/.local/share/icons/hicolor/scalable/apps"
REPO_ICONS="$HOME/dotfiles-dizzi/local/.local/share/icons/hicolor/scalable/apps"
mkdir -p "$ICONS"
for n in wine-discord-ipc-bridge wine-discord-ipc-bridge-bottles; do
  if [ -f "$ICONS/$n.svg" ]; then
    :
  elif [ -f "$REPO_ICONS/$n.svg" ]; then
    cp -f "$REPO_ICONS/$n.svg" "$ICONS/$n.svg"
  fi
done
command -v gtk-update-icon-cache >/dev/null 2>&1 && \
  gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" >/dev/null 2>&1 || true

log "Lanzadores .desktop actualizados (Wine + Bottles) con iconos"
echo
echo "Siguiente paso: abre el juego y ANTES lanza"
echo "  ~/.local/bin/juegos/wine-discord-ipc-bridge.sh wine"
echo "(las apps de KDE también aparecen como 'Wine Discord IPC Bridge (Wine)')"
