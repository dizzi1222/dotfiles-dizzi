#!/bin/bash
# Sunshine Local Audio — Loopback para escuchar audio de Sunshine en aurífonos locales
# Sunshine usa null sinks (sink-sunshine-stereo, etc.) para capturar audio y transmitirlo.
# Este script crea un loopback que copia ese audio al sink real (aurífonos/bocinas).
#
# Uso:
#   sunshine-local-audio.sh on    — Activar loopback
#   sunshine-local-audio.sh off   — Desactivar loopback
#   sunshine-local-audio.sh status — Ver estado

SUNSHINE_SINK="sink-sunshine-stereo"
PIDFILE="/tmp/sunshine-local-audio.pid"

get_real_sink() {
  # Buscar sink real de hardware — ignorar null sinks, sunshine, easyeffects
  # Priorizar Bluetooth (AZ09) si está conectado, sino el speaker interno
  local bt_sink
  bt_sink=$(pactl list sinks short 2>/dev/null | grep "bluez_output" | awk '{print $1; exit}')
  if [ -n "$bt_sink" ]; then
    echo "$bt_sink"
    return
  fi
  pactl list sinks short 2>/dev/null \
    | grep -v "sunshine\|easyeffects\|auto_null\|sink-sunshine" \
    | head -1 | awk '{print $1}'
}

is_running() {
  if [ -f "$PIDFILE" ]; then
    local pid
    pid=$(cat "$PIDFILE")
    if kill -0 "$pid" 2>/dev/null; then
      return 0
    fi
    rm -f "$PIDFILE"
  fi
  return 1
}

start_loopback() {
  if is_running; then
    echo "Ya está activo (PID: $(cat $PIDFILE))"
    return 0
  fi

  local real_sink
  real_sink=$(get_real_sink)

  if [ -z "$real_sink" ]; then
    echo "❌ No hay sink real de hardware disponible"
    echo "Sinks disponibles:"
    pactl list sinks short
    exit 1
  fi

  local sink_name
  sink_name=$(pactl list sinks short | awk -v id="$real_sink" '$1==id {for(i=2;i<=NF;i++) printf "%s ", $i; print ""}')

  echo "🔊 Sunshine sink: $SUNSHINE_SINK"
  echo "🎧 Sink local:    $real_sink ($sink_name)"

  # Verificar que el sink de Sunshine existe
  if ! pactl list sinks short | grep -q "$SUNSHINE_SINK"; then
    echo "❌ Sink de Sunshine no encontrado. ¿Está Sunshine corriendo?"
    exit 1
  fi

  # Crear loopback con pw-loopback
  pw-loopback \
    --capture "$SUNSHINE_SINK" \
    --playback "$real_sink" \
    --capture-props="audio.position=[FL FR]" \
    --playback-props="audio.position=[FL FR]" &

  local pid=$!
  sleep 0.5

  if kill -0 "$pid" 2>/dev/null; then
    echo "$pid" > "$PIDFILE"
    echo "✅ Loopback activo (PID: $pid)"
    echo "   $SUNSHINE_SINK → $real_sink"
  else
    echo "❌ pw-loopback falló al iniciar"
    exit 1
  fi
}

stop_loopback() {
  if is_running; then
    local pid
    pid=$(cat "$PIDFILE")
    kill "$pid" 2>/dev/null
    wait "$pid" 2>/dev/null
    rm -f "$PIDFILE"
    echo "🛑 Loopback detenido"
  else
    # Matar cualquier pw-loopback huérfano apuntando a Sunshine
    pkill -f "pw-loopback.*sink-sunshine" 2>/dev/null
    echo "No había loopback activo"
  fi
}

status() {
  if is_running; then
    echo "✅ Activo (PID: $(cat $PIDFILE))"
    echo "   sink-sunshine-stereo → $(get_real_sink)"
  else
    echo "❌ Inactivo"
  fi
  echo ""
  echo "Sinks de hardware:"
  pactl list sinks short 2>/dev/null \
    | grep -v "sunshine\|easyeffects\|auto_null\|sink-sunshine" \
    | awk '{printf "  %s  %s %s\n", $1, $2, $3}'
}

case "${1:-on}" in
  on)     start_loopback ;;
  off)    stop_loopback ;;
  status) status ;;
  *)      echo "Uso: $0 {on|off|status}" ;;
esac
