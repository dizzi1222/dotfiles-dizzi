#!/usr/bin/env bash

CONFIG_FILE="$HOME/.config/scrcpy-connect.conf"

load_last_port() {
  if [ -f "$CONFIG_FILE" ]; then
    grep "last_debug_port=" "$CONFIG_FILE" | cut -d= -f2
  fi
}

save_last_port() {
  mkdir -p "$(dirname "$CONFIG_FILE")" 2>/dev/null
  echo "last_debug_port=$1" > "$CONFIG_FILE"
}

start_keepalive() {
  (
    while true; do
      adb shell echo > /dev/null 2>&1
      sleep 20
    done
  ) &
  KEEPALIVE_PID=$!
}

stop_keepalive() {
  kill "$KEEPALIVE_PID" 2>/dev/null
  wait "$KEEPALIVE_PID" 2>/dev/null
}

LAST_PORT=$(load_last_port)
: "${LAST_PORT:=39781}"

clear
echo "󰺐  Scrcpy Connect - Android Screen Mirror"
echo "============================================"
echo ""
echo "1) USB Directo (sin lag, recomendado para jugar)"
echo "2) USB → WiFi (adb tcpip, conectar por USB y pasar a WiFi)"
echo "3) Depuración Inalámbrica (Android 11+, pairing por código)"
echo "4) Salir"
echo ""
read -p "Selecciona una opción [1-4]: " opcion

case "$opcion" in
1)
  echo ""
  echo "▶ Conecta el teléfono por USB directo al PC"
  echo "  (sin dock hub de por medio)"
  echo ""
  read -p "Presiona Enter cuando esté conectado..."
  adb kill-server >/dev/null 2>&1
  adb devices
  DEVICE=$(adb devices | grep -w "device" | head -1 | awk '{print $1}')
  if [ -z "$DEVICE" ]; then
    echo "❌ No se detectó ningún dispositivo USB."
    echo "   Verifica: depuración USB activada, cable funcional."
    read -p "Presiona Enter para salir..."
    exit 1
  fi
  echo "✅ Dispositivo detectado: $DEVICE"
  echo "▶ Iniciando scrcpy..."
  sleep 1
  /usr/bin/scrcpy
  ;;
2)
  echo ""
  echo "▶ Conecta el teléfono por USB directo al PC (solo temporal)"
  echo ""
  read -p "Presiona Enter cuando esté conectado..."
  adb kill-server >/dev/null 2>&1
  adb devices
  DEVICE=$(adb devices | grep -w "device" | head -1 | awk '{print $1}')
  if [ -z "$DEVICE" ]; then
    echo "❌ No se detectó ningún dispositivo USB."
    read -p "Presiona Enter para salir..."
    exit 1
  fi
  echo "✅ Dispositivo detectado: $DEVICE"
  IP=$(adb shell ip addr show wlan0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
  [ -z "$IP" ] && IP=$(adb shell ifconfig wlan0 2>/dev/null | grep 'inet addr' | awk '{print $2}' | cut -d: -f2)
  [ -z "$IP" ] && read -p "IP del teléfono: " IP
  echo "▶ Cambiando a modo TCP/IP en puerto 5555..."
  adb tcpip 5555
  sleep 2
  echo "▶ Desconecta el USB y presiona Enter..."
  read -p ""
  echo "▶ Conectando a $IP:5555 ..."
  adb connect "$IP:5555"
  sleep 1
  if adb devices | grep -q "5555.*device"; then
    echo "✅ Conectado. Iniciando scrcpy..."
    echo "   (keepalive activo cada 20s para evitar desconexión)"
    sleep 1
    start_keepalive
    /usr/bin/scrcpy
    stop_keepalive
  else
    echo "❌ Falló. Verifica: misma red, firewall, IP correcta."
    read -p "Presiona Enter..."
    exit 1
  fi
  ;;
3)
  echo ""
  echo "▶ Requisitos:"
  echo "   • Misma red WiFi que el teléfono (IP: 10.0.0.6)"
  echo "   • Depuración Inalámbrica activada en Developer Options"
  echo ""
  echo "   Opciones:"
  echo "   E) Emparejar por primera vez (necesitas código)"
  echo "   r) Reconectar (si ya está emparejado, solo puerto)"
  echo ""
  read -p "¿Emparejar o Reconectar? [E/r]: " TIPO
  IP="10.0.0.6"
  echo ""
  if [[ "$TIPO" =~ ^[Rr] ]]; then
    read -p "Puerto de depuración (ej la mia: $LAST_PORT): " DEBUG_PORT
    DEBUG_PORT="${DEBUG_PORT:-$LAST_PORT}"
    save_last_port "$DEBUG_PORT"
    echo "   ✓ Puerto guardado: $DEBUG_PORT"
    adb connect "$IP:$DEBUG_PORT"
  else
    echo "   Presiona 'Emparejar dispositivo con código de emparejamiento'"
    read -p "Puerto de emparejamiento (ej: 40625): " PAIR_PORT
    read -p "Código de 6 dígitos: " CODE
    echo "▶ Emparejando..."
    echo "$CODE" | adb pair "$IP:$PAIR_PORT"
    [ $? -ne 0 ] && echo "❌ Falló." && read -p "Presiona Enter..." && exit 1
    sleep 1
    read -p "Puerto de depuración (ej la mia: $LAST_PORT): " DEBUG_PORT
    DEBUG_PORT="${DEBUG_PORT:-$LAST_PORT}"
    save_last_port "$DEBUG_PORT"
    echo "   ✓ Puerto guardado: $DEBUG_PORT"
    adb connect "$IP:$DEBUG_PORT"
  fi
  sleep 1
  adb devices
  if adb devices | grep -q "device$"; then
    echo "✅ Conectado. Iniciando scrcpy..."
    echo "   (keepalive activo cada 20s para evitar desconexión)"
    sleep 1
    start_keepalive
    /usr/bin/scrcpy
    stop_keepalive
  else
    echo "❌ Falló la conexión."
    read -p "Presiona Enter..."
    exit 1
  fi
  ;;
4 | *)
  exit 0
  ;;
esac
