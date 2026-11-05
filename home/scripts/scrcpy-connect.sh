#!/usr/bin/env bash

CONFIG_FILE="$HOME/.config/scrcpy-connect.conf"

# Resolver binarios aunque el script se lance sin ~/.zshrc (brew no está en PATH)
resolve_bin() {
  local name="$1"
  shift
  local found candidate
  found="$(command -v "$name" 2>/dev/null || true)"
  if [ -z "$found" ]; then
    for candidate in "$@"; do
      if [ -x "$candidate" ]; then
        found="$candidate"
        break
      fi
    done
  fi
  printf '%s' "$found"
}

ADB_BIN="$(resolve_bin adb \
  /home/linuxbrew/.linuxbrew/bin/adb \
  "$HOME/.linuxbrew/bin/adb" \
  /usr/bin/adb \
  /usr/local/bin/adb)"
SCRCPY_BIN="${SCRCPY_BIN:-$(resolve_bin scrcpy \
  /home/linuxbrew/.linuxbrew/bin/scrcpy \
  "$HOME/.nix-profile/bin/scrcpy" \
  /usr/bin/scrcpy)}"

if [ -z "$ADB_BIN" ] || [ ! -x "$ADB_BIN" ]; then
  echo "❌ No se encontró adb."
  echo "   Instálalo con: brew install --cask android-platform-tools"
  exit 1
fi

if [ -z "$SCRCPY_BIN" ] || [ ! -x "$SCRCPY_BIN" ]; then
  echo "❌ No se encontró scrcpy."
  echo "   Instálalo con: brew install scrcpy"
  exit 1
fi

# El ffmpeg de Homebrew se compila sin VA-API: pedir hwdec falla con
# "Could not create VA-API device". Se detecta y se usa software directamente.
# Override manual: SCRCPY_HWDEC=auto|vaapi|disabled
SCRCPY_HWDEC="${SCRCPY_HWDEC:-auto}"
if [ "$SCRCPY_HWDEC" = "auto" ]; then
  AVUTIL_LIB="$(ldd "$SCRCPY_BIN" 2>/dev/null | awk '/libavutil/ {print $3; exit}')"
  if [ -n "$AVUTIL_LIB" ] && ! ldd "$AVUTIL_LIB" 2>/dev/null | grep -q 'libva\.so'; then
    SCRCPY_HWDEC="disabled"
  else
    SCRCPY_HWDEC=""
  fi
fi
SCRCPY_HWDEC_ARGS=()
[ -n "$SCRCPY_HWDEC" ] && SCRCPY_HWDEC_ARGS=("--hwdec=$SCRCPY_HWDEC")

# Wrapper: todas las llamadas del script usan el adb resuelto
adb() { "$ADB_BIN" "$@"; }

load_last_port() {
  [ -f "$CONFIG_FILE" ] && grep -m1 '^last_debug_port=' "$CONFIG_FILE" | cut -d= -f2
}

load_last_ip() {
  [ -f "$CONFIG_FILE" ] && grep -m1 '^last_ip=' "$CONFIG_FILE" | cut -d= -f2
}

save_conn() {
  mkdir -p "$(dirname "$CONFIG_FILE")" 2>/dev/null
  printf 'last_debug_port=%s\nlast_ip=%s\n' "$1" "$2" > "$CONFIG_FILE"
}

# mDNS: adb descubre los servicios de depuración inalámbrica del teléfono
mdns_addr_for() {
  adb mdns services 2>/dev/null | awk -v svc="$1" 'index($0, svc) {print $NF; exit}'
}

start_keepalive() {
  local serial="${1:-}"
  (
    while true; do
      if [ -n "$serial" ]; then
        adb -s "$serial" shell echo > /dev/null 2>&1
      else
        adb shell echo > /dev/null 2>&1
      fi
      sleep 20
    done
  ) &
  KEEPALIVE_PID=$!
  trap 'stop_keepalive' EXIT INT TERM
}

stop_keepalive() {
  [ -n "$KEEPALIVE_PID" ] || return 0
  kill "$KEEPALIVE_PID" 2>/dev/null
  wait "$KEEPALIVE_PID" 2>/dev/null
  KEEPALIVE_PID=""
}

device_is_ready() {
  adb devices 2>/dev/null | awk -v s="$1" '$1 == s && $2 == "device" {found=1} END {exit !found}'
}

LAST_PORT=$(load_last_port)
: "${LAST_PORT:=39781}"
LAST_IP=$(load_last_ip)
: "${LAST_IP:=10.0.0.6}"

clear
echo "󰺐  Scrcpy Connect - Android Screen Mirror"
echo "============================================"
echo ""
echo "1) USB Directo (sin lag, recomendado para jugar)"
echo "2) USB → WiFi (adb tcpip, conectar por USB y pasar a WiFi)"
echo "3) Depuración Inalámbrica (Android 11+, pairing por código)"
echo "4) Salir"
echo ""
read -r -p "Selecciona una opción [1-4]: " opcion

case "$opcion" in
1)
  echo ""
  echo "▶ Conecta el teléfono por USB directo al PC"
  echo "  (sin dock hub de por medio)"
  echo ""
  read -r -p "Presiona Enter cuando esté conectado..."
  adb kill-server >/dev/null 2>&1
  adb start-server >/dev/null 2>&1
  adb devices
  DEVICE=$(adb devices | awk '$2 == "device" {print $1; exit}')
  if [ -z "$DEVICE" ]; then
    echo "❌ No se detectó ningún dispositivo USB."
    echo "   Verifica: depuración USB activada, cable funcional."
    read -r -p "Presiona Enter para salir..."
    exit 1
  fi
  echo "✅ Dispositivo detectado: $DEVICE"
  echo "▶ Iniciando scrcpy..."
  sleep 1
  "$SCRCPY_BIN" -s "$DEVICE" "${SCRCPY_HWDEC_ARGS[@]}"
  ;;
2)
  echo ""
  echo "▶ Conecta el teléfono por USB directo al PC (solo temporal)"
  echo ""
  read -r -p "Presiona Enter cuando esté conectado..."
  adb kill-server >/dev/null 2>&1
  adb start-server >/dev/null 2>&1
  adb devices
  DEVICE=$(adb devices | awk '$2 == "device" {print $1; exit}')
  if [ -z "$DEVICE" ]; then
    echo "❌ No se detectó ningún dispositivo USB."
    read -r -p "Presiona Enter para salir..."
    exit 1
  fi
  echo "✅ Dispositivo detectado: $DEVICE"
  IP=$(adb shell ip addr show wlan0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
  [ -z "$IP" ] && IP=$(adb shell ifconfig wlan0 2>/dev/null | grep 'inet addr' | awk '{print $2}' | cut -d: -f2)
  [ -z "$IP" ] && read -r -p "IP del teléfono: " IP
  echo "▶ Cambiando a modo TCP/IP en puerto 5555..."
  adb tcpip 5555
  sleep 2
  echo "▶ Desconecta el USB y presiona Enter..."
  read -r -p ""
  echo "▶ Conectando a $IP:5555 ..."
  adb connect "$IP:5555"
  sleep 1
  if device_is_ready "$IP:5555"; then
    echo "✅ Conectado. Iniciando scrcpy..."
    echo "   (keepalive activo cada 20s para evitar desconexión)"
    save_conn 5555 "$IP"
    sleep 1
    start_keepalive "$IP:5555"
    "$SCRCPY_BIN" -s "$IP:5555" "${SCRCPY_HWDEC_ARGS[@]}"
    stop_keepalive
  else
    echo "❌ Falló. Verifica: misma red, firewall, IP correcta."
    read -r -p "Presiona Enter..."
    exit 1
  fi
  ;;
3)
  echo ""
  echo "▶ Requisitos:"
  echo "   • PC y teléfono en la misma red WiFi"
  echo "   • Depuración Inalámbrica activada en Developer Options"
  echo ""
  read -r -p "IP del teléfono [$LAST_IP]: " INPUT_IP
  IP="${INPUT_IP:-$LAST_IP}"

  echo ""
  echo "   Opciones:"
  echo "   E) Emparejar por primera vez (necesitas código)"
  echo "   r) Reconectar (si ya está emparejado, solo puerto)"
  echo ""
  read -r -p "¿Emparejar o Reconectar? [E/r]: " TIPO
  echo ""

  # Puertos anunciados por mDNS (si el teléfono los está publicando)
  MDNS_CONN="$(mdns_addr_for '_adb-tls-connect._tcp')"
  CONNECTED_ADDR=""

  if [[ "$TIPO" =~ ^[Rr] ]]; then
    if [ -n "$MDNS_CONN" ]; then
      echo "   ✓ mDNS detectó el teléfono en $MDNS_CONN"
      CONNECTED_ADDR="$MDNS_CONN"
      DEBUG_PORT="${MDNS_CONN##*:}"
    else
      read -r -p "Puerto de depuración [$LAST_PORT]: " DEBUG_PORT
      DEBUG_PORT="${DEBUG_PORT:-$LAST_PORT}"
      CONNECTED_ADDR="$IP:$DEBUG_PORT"
    fi
    save_conn "$DEBUG_PORT" "$IP"
    adb connect "$CONNECTED_ADDR"
  else
    PAIRED=0
    ATTEMPT=0
    while [ "$ATTEMPT" -lt 3 ]; do
      ATTEMPT=$((ATTEMPT + 1))
      # El puerto de emparejamiento cambia con cada diálogo: redescubrir siempre
      MDNS_PAIR="$(mdns_addr_for '_adb-tls-pairing._tcp')"
      DEF_PAIR_PORT=""
      [ -n "$MDNS_PAIR" ] && DEF_PAIR_PORT="${MDNS_PAIR##*:}"

      echo "   En el teléfono: Depuración inalámbrica → 'Emparejar dispositivo con código'."
      if [ -n "$MDNS_PAIR" ]; then
        echo "   ✓ mDNS detectó el servicio de emparejamiento en $MDNS_PAIR"
      fi
      read -r -p "Puerto de emparejamiento${DEF_PAIR_PORT:+ [$DEF_PAIR_PORT]}: " PAIR_PORT
      PAIR_PORT="${PAIR_PORT:-$DEF_PAIR_PORT}"
      if [ -z "$PAIR_PORT" ]; then
        echo "❌ Falta el puerto de emparejamiento."
        read -r -p "Presiona Enter..."
        exit 1
      fi

      read -r -p "Código de 6 dígitos: " CODE
      CODE="${CODE//[[:space:]]/}"
      if [ -z "$CODE" ]; then
        echo "❌ Falta el código."
        read -r -p "Presiona Enter..."
        exit 1
      fi

      echo "▶ Emparejando en $IP:$PAIR_PORT ..."
      if adb pair "$IP:$PAIR_PORT" "$CODE"; then
        PAIRED=1
        break
      fi

      echo ""
      echo "❌ Falló el emparejamiento (intento $ATTEMPT/3)."
      echo "   Causas típicas: código vencido o mal escrito, puerto de otro diálogo,"
      echo "   diálogo cerrado en el teléfono o pantalla bloqueada."
      if [ "$ATTEMPT" -lt 3 ]; then
        echo "   Genera un código NUEVO en el teléfono y pulsa Enter para reintentar."
        echo "   (se reinicia el servidor adb para limpiar la sesión de pairing)"
        read -r -p ""
        adb kill-server >/dev/null 2>&1
        adb start-server >/dev/null 2>&1
        sleep 1
      fi
    done

    if [ "$PAIRED" -ne 1 ]; then
      echo "❌ No se pudo emparejar tras 3 intentos."
      echo "   Prueba: apagar y encender Depuración inalámbrica, y repetir."
      read -r -p "Presiona Enter..."
      exit 1
    fi

    echo "✅ Emparejado."
    echo "▶ Buscando el puerto de conexión del teléfono..."
    CONN_ADDR=""
    for _ in 1 2 3 4 5 6 7 8 9 10; do
      CONN_ADDR="$(mdns_addr_for '_adb-tls-connect._tcp')"
      [ -n "$CONN_ADDR" ] && break
      sleep 1
    done

    if [ -n "$CONN_ADDR" ]; then
      echo "   ✓ mDNS: $CONN_ADDR"
      adb connect "$CONN_ADDR"
      sleep 1
      device_is_ready "$CONN_ADDR" && CONNECTED_ADDR="$CONN_ADDR"
      DEBUG_PORT="${CONN_ADDR##*:}"
    fi

    # Si mDNS no publicó el puerto o falló el connect, pedirlo a mano
    if [ -z "$CONNECTED_ADDR" ]; then
      read -r -p "Puerto de depuración [$LAST_PORT]: " INPUT_DEBUG
      DEBUG_PORT="${INPUT_DEBUG:-$LAST_PORT}"
      CONNECTED_ADDR="$IP:$DEBUG_PORT"
      adb connect "$CONNECTED_ADDR"
    fi
    save_conn "$DEBUG_PORT" "$IP"
  fi

  sleep 1
  adb devices

  SERIAL=""
  [ -n "$CONNECTED_ADDR" ] && device_is_ready "$CONNECTED_ADDR" && SERIAL="$CONNECTED_ADDR"
  [ -z "$SERIAL" ] && [ -n "$DEBUG_PORT" ] && device_is_ready "$IP:$DEBUG_PORT" && SERIAL="$IP:$DEBUG_PORT"
  if [ -z "$SERIAL" ]; then
    SERIAL="$(adb devices | awk -v ip="$IP" '$2 == "device" && index($1, ip ":") == 1 {print $1; exit}')"
  fi

  if [ -z "$SERIAL" ]; then
    echo "❌ Falló la conexión."
    echo "   Revisa que el puerto de depuración sea el de la pantalla principal"
    echo "   de Depuración inalámbrica (no el de emparejamiento)."
    read -r -p "Presiona Enter..."
    exit 1
  fi

  echo "✅ Conectado: $SERIAL"
  echo "▶ Iniciando scrcpy..."
  echo "   (keepalive activo cada 20s para evitar desconexión)"
  sleep 1
  start_keepalive "$SERIAL"
  "$SCRCPY_BIN" -s "$SERIAL" "${SCRCPY_HWDEC_ARGS[@]}"
  stop_keepalive
  ;;
4 | *)
  exit 0
  ;;
esac
