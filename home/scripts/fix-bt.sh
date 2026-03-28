#!/bin/bash
# Fix Bluetooth — fuerza perfil A2DP estéreo (KZ AZ09 / Vogek)

STATE_PROFILE="$HOME/.local/state/wireplumber/default-profile"
STATE_AUTOSWITCH="$HOME/.local/state/wireplumber/bluetooth-autoswitch"

# ── Auto-detección ──────────────────────────────────────────
KZ_MAC="7A:7F:30:A6:90:FD"
VOGEK_MAC="F4:4E:FC:52:45:FC"

if bluetoothctl info "$KZ_MAC" 2>/dev/null | grep -q "Connected: yes"; then
  MAC="$KZ_MAC"
  NAME="KZ AZ09"
elif bluetoothctl info "$VOGEK_MAC" 2>/dev/null | grep -q "Connected: yes"; then
  MAC="$VOGEK_MAC"
  NAME="Vogek 094"
else
  notify-send -i "audio-headphones" "Bluetooth" "❌ Ningún auricular conectado"
  exit 1
fi

CARD_ID="${MAC//:/_}"
notify() { notify-send -i "audio-headphones" "$NAME" "$1"; }
# ────────────────────────────────────────────────────────────

# 1. Corregir state files de WirePlumber
if grep -q "bluez_card.${CARD_ID}=headset-head-unit" "$STATE_PROFILE" 2>/dev/null; then
  systemctl --user stop wireplumber
  sed -i "s/bluez_card.${CARD_ID}=headset-head-unit/bluez_card.${CARD_ID}=a2dp-sink/" "$STATE_PROFILE"
  sed -i "/saved-headset-profile:bluez_card.${CARD_ID}/d" "$STATE_AUTOSWITCH" 2>/dev/null
  systemctl --user start wireplumber
  sleep 1
fi

# 2. Reconectar si está desconectado
CONNECTED=$(bluetoothctl info "$MAC" | grep "Connected: yes")
if [ -z "$CONNECTED" ]; then
  notify "Conectando..."
  bluetoothctl connect "$MAC" >/dev/null 2>&1
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
SINK_ID=$(pactl list sinks short | grep -F "$MAC" | awk '{print $1}')
if [ -z "$SINK_ID" ]; then
  notify "❌ Sink de audio no encontrado"
  exit 1
fi

# 5. Forzar perfil A2DP en la card
pactl set-card-profile "bluez_card.${CARD_ID}" a2dp-sink 2>/dev/null

# 6. Establecer como sink por defecto y desmutear
pactl set-default-sink "$SINK_ID"
pactl set-sink-mute "$SINK_ID" 0

notify "✅ Conectado — Perfil A2DP estéreo activo"
