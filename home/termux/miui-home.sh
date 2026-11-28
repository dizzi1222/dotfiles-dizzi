#!/data/data/com.termux/files/usr/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# miui-home.sh — Home real de MIUI con el Ultra Ahorro activo (bypass)
# ═══════════════════════════════════════════════════════════════════════════════
# Receta verificada 2026-11-28 (Redmi Note 9 Pro, MIUI 14 / Android 12):
#   1. Conectar ADB inalámbrico local (escanea el puerto si no hay device).
#   2. Pasos previos que "aflojan" el launcher del Ultra Ahorro:
#      set-home-activity com.miui.home, force-stop com.miui.securityadd,
#      am start explícito del Home de MIUI.
#   3. Asegurar Lawnchair instalado y abrirlo.
#   4. Desde Lawnchair, pulsar el botón Home (círculo) → Home real de MIUI.
#
# Uso: miui-home.sh [--no-install] [--port PUERTO]
# Requisito: depuración inalámbrica activa (o Shizuku/ADB ya emparejado).

set -u

MIUI_HOME="com.miui.home/com.miui.home.launcher.Launcher"
SUPERPOWER_PKG="com.miui.securityadd"
SUPERPOWER_ACT="$SUPERPOWER_PKG/com.miui.superpower.SuperPowerLauncherActivity"
LAWN_PKG="app.lawnchair"
LAWN_REPO="LawnchairLauncher/lawnchair"
INSTALL=1
PORT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-install) INSTALL=0 ;;
    --port) PORT="${2:-}"; shift ;;
    -h|--help) sed -n 2,15p "$0"; exit 0 ;;
  esac
  shift
done

ok()   { printf '\033[32m✔\033[0m %s\n' "$*"; }
info() { printf '\033[36m➜\033[0m %s\n' "$*"; }
warn() { printf '\033[33m⚠\033[0m %s\n' "$*"; }

#Conexión ADB
command -v adb >/dev/null || pkg install -y android-tools >/dev/null 2>&1

find_device() {
  adb devices 2>/dev/null | awk 'NR>1 && $2=="device"{print $1; exit}'
}

DEV="$(find_device)"
if [[ -z "$DEV" ]]; then
  if [[ -z "$PORT" ]]; then
    info "Buscando el puerto de depuración inalámbrica (30000-49999)..."
    PORT="$(timeout 90 bash -c 'for p in $(seq 30000 49999); do
      (echo >/dev/tcp/127.0.0.1/$p) 2>/dev/null && echo $p; done' |
      while read -r p; do
        adb connect "127.0.0.1:$p" 2>/dev/null | awk '/^connected/{f=1} END{exit !f}' && { echo "$p"; break; }
        adb disconnect "127.0.0.1:$p" >/dev/null 2>&1
      done)"
  else
    adb connect "127.0.0.1:$PORT" >/dev/null 2>&1
  fi
  DEV="$(find_device)"
fi
[[ -z "$DEV" ]] && { warn "Sin ADB. Activa la depuración inalámbrica y reintenta (o --port N)."; exit 1; }
ok "ADB conectado: $DEV"

a() { adb -s "$DEV" shell "$@"; }

#Pasos previos: forzar Home y aflojar el launcher del Ultra Ahorro
a cmd package set-home-activity "$MIUI_HOME" >/dev/null 2>&1 && ok "Home preferido: com.miui.home"
a pm disable "$SUPERPOWER_ACT" >/dev/null 2>&1 && ok "SuperPowerLauncher desactivado" \
  || info "SuperPowerLauncher no se puede desactivar sin root (normal)"
a am force-stop "$SUPERPOWER_PKG" && ok "Launcher del Ultra Ahorro detenido"
a am start -W -n "$MIUI_HOME" -f 0x10008000 >/dev/null 2>&1 && ok "Home de MIUI invocado"

#Lawnchair
if ! a pm list packages "$LAWN_PKG" | awk -v p="package:$LAWN_PKG" '$0==p{f=1} END{exit !f}'; then
  if [[ $INSTALL -eq 0 ]]; then
    warn "Lawnchair no está instalado (--no-install)."; exit 1
  fi
  info "Descargando Lawnchair..."
  URL="$(curl -fsSL "https://api.github.com/repos/$LAWN_REPO/releases?per_page=10" |
    awk -F'"' '/browser_download_url/ && /\.apk"/ && !/nightly|Debug/ {print $4; exit}')"
  [[ -z "$URL" ]] && { warn "No encontré el APK de Lawnchair."; exit 1; }
  TMP="$(mktemp -d)"
  curl -fsSL -o "$TMP/lawnchair.apk" "$URL" && adb -s "$DEV" install -r "$TMP/lawnchair.apk" >/dev/null \
    && ok "Lawnchair instalado" || { warn "Falló la instalación de Lawnchair."; rm -rf "$TMP"; exit 1; }
  rm -rf "$TMP"
fi

a monkey -p "$LAWN_PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
sleep 2
if a dumpsys window | awk '/mCurrentFocus/ && /lawnchair/{f=1} END{exit !f}'; then
  ok "Lawnchair al frente"
  info "Ahora pulsa el botón Home (círculo) → Home real de MIUI con el Ultra Ahorro activo."
else
  warn "Lawnchair no quedó al frente; ábrelo desde la pantalla del Ultra Ahorro y pulsa Home."
fi
