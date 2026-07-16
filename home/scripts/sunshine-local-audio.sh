#!/bin/bash
# Sunshine Local Audio — Loopback para escuchar audio de Sunshine en aurífonos locales
# Sunshine usa null sinks (sink-sunshine-stereo, etc.) para capturar audio y transmitirlo.
# Este script crea un loopback que copia ese audio al sink real (aurífonos/bocinas).
# Prioriza BT (A2DP) → fallback a speaker interno.
#
# Uso:
#   sunshine-local-audio.sh on    — Activar loopback
#   sunshine-local-audio.sh off   — Desactivar loopback
#   sunshine-local-audio.sh status — Ver estado

SUNSHINE_SINK="sink-sunshine-stereo"
PIDFILE="/tmp/sunshine-local-audio.pid"

# ── BT detection (same as fix-bt.sh) ───────────────────────
KZ_MAC="7A:7F:30:A6_90_FD"
KZ_MAC_DOTS="7A:7F:30:A6:90:FD"

get_real_sink_node() {
  # Returns the PipeWire node.name for the best available sink
  # Priority: BT A2DP → ALSA internal speaker

  # Check BT headphones (KZ AZ09)
  if bluetoothctl info "$KZ_MAC_DOTS" 2>/dev/null | grep -q "Connected: yes"; then
    # Force A2DP profile if needed
    local card="bluez_card.7A_7F_30_A6_90_FD"
    local current_profile
    current_profile=$(pactl list cards 2>/dev/null | grep -A20 "$card" | grep "active profile" | sed 's/.*: //')
    if [ "$current_profile" != "a2dp-sink" ]; then
      echo "🔧 Forzando perfil A2DP..."
      pactl set-card-profile "$card" a2dp-sink 2>/dev/null
      sleep 1
    fi

    local bt_name
    bt_name=$(pactl list sinks 2>/dev/null | grep -B1 "bluez_output" | grep "node.name" | head -1 | sed 's/.*"\(.*\)"/\1/')
    if [ -n "$bt_name" ]; then
      echo "$bt_name"
      return
    fi
  fi

  # Fallback: ALSA internal speaker
  pactl list sinks 2>/dev/null \
    | grep -A1 "alsa_output" | grep "node.name" | head -1 | sed 's/.*"\(.*\)"/\1/'
}

get_sink_display() {
  # Returns a human-readable description for the sink node name
  local node_name="$1"
  pactl list sinks short 2>/dev/null | awk -v name="$node_name" '$2==name {for(i=3;i<=NF;i++) printf "%s ", $i; print ""}'
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

  # Verificar Sunshine sink
  if ! pactl list sinks short 2>/dev/null | grep -q "$SUNSHINE_SINK"; then
    echo "❌ Sink de Sunshine no encontrado. ¿Está Sunshine corriendo?"
    exit 1
  fi

  local real_sink
  real_sink=$(get_real_sink_node)

  if [ -z "$real_sink" ]; then
    echo "❌ No hay sink de hardware disponible"
    echo "Sinks disponibles:"
    pactl list sinks short 2>/dev/null
    exit 1
  fi

  local sink_desc
  sink_desc=$(get_sink_display "$real_sink")

  echo "🔊 Sunshine sink: $SUNSHINE_SINK"
  echo "🎧 Sink local:    $real_sink ($sink_desc)"

  # Crear loopback — pw-loopback necesita node names
  pw-loopback \
    --capture "$SUNSHINE_SINK.monitor" \
    --playback "$real_sink" \
    --capture-props="audio.position=[FL FR]" \
    --playback-props="audio.position=[FL FR]" &

  local pid=$!
  sleep 1

  if kill -0 "$pid" 2>/dev/null; then
    echo "$pid" > "$PIDFILE"
    echo "✅ Loopback activo (PID: $pid)"
    echo "   $SUNSHINE_SINK.monitor → $real_sink"
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
    pkill -f "pw-loopback.*sink-sunshine" 2>/dev/null
    echo "No había loopback activo"
  fi
}

status() {
  if is_running; then
    echo "✅ Activo (PID: $(cat $PIDFILE))"
    local real_sink
    real_sink=$(get_real_sink_node)
    echo "   $SUNSHINE_SINK.monitor → $real_sink"
  else
    echo "❌ Inactivo"
  fi
  echo ""
  echo "Sinks:"
  pactl list sinks short 2>/dev/null \
    | awk '{printf "  %-6s %-50s %s %s\n", $1, $2, $3, $4}'
}

case "${1:-on}" in
  on)     start_loopback ;;
  off)    stop_loopback ;;
  status) status ;;
  *)      echo "Uso: $0 {on|off|status}" ;;
esac
