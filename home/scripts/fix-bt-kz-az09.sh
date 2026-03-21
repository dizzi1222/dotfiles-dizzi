#!/bin/bash
# Fix Bluetooth KZ AZ09 — fuerza perfil A2DP estéreo
# Problema: WirePlumber guarda headset-head-unit (HFP/mono) en vez de a2dp-sink

MAC="7A:7F:30:A6:90:FD"
NAME="KZ AZ09"
STATE_PROFILE="$HOME/.local/state/wireplumber/default-profile"
STATE_AUTOSWITCH="$HOME/.local/state/wireplumber/bluetooth-autoswitch"

notify() { notify-send -i "$HOME/.local/share/icons/kz-az09-icon.png" "$NAME" "$1"; }

# 1. Corregir state files de WirePlumber
if grep -q "bluez_card.7A_7F_30_A6_90_FD=headset-head-unit" "$STATE_PROFILE" 2>/dev/null; then
  systemctl --user stop wireplumber
  sed -i 's/bluez_card.7A_7F_30_A6_90_FD=headset-head-unit/bluez_card.7A_7F_30_A6_90_FD=a2dp-sink/' "$STATE_PROFILE"
  sed -i '/saved-headset-profile:bluez_card.7A_7F_30_A6_90_FD/d' "$STATE_AUTOSWITCH" 2>/dev/null
  systemctl --user start wireplumber
  sleep 1
fi

# 2. Reconectar si está desconectado
CONNECTED=$(bluetoothctl info "$MAC" | grep "Connected: yes")
if [ -z "$CONNECTED" ]; then
  notify "Conectando..."
  bluetoothctl connect "$MAC" > /dev/null 2>&1
  sleep 3
fi

# 3. Verificar conexión
CONNECTED=$(bluetoothctl info "$MAC" | grep "Connected: yes")
if [ -z "$CONNECTED" ]; then
  notify "❌ No se pudo conectar"
  exit 1
fi

# 4. Esperar a que PipeWire registre el sink
sleep 1
SINK_ID=$(pactl list sinks short | grep "7A_7F_30_A6_90_FD\|7A:7F:30:A6:90:FD" | awk '{print $1}')

if [ -z "$SINK_ID" ]; then
  notify "❌ Sink de audio no encontrado"
  exit 1
fi

# 5. Forzar perfil A2DP en la card
pactl set-card-profile "bluez_card.7A_7F_30_A6_90_FD" a2dp-sink 2>/dev/null

# 6. Establecer como sink por defecto y desmutear
pactl set-default-sink "$SINK_ID"
pactl set-sink-mute "$SINK_ID" 0

notify "✅ Conectado — Perfil A2DP estéreo activo"
