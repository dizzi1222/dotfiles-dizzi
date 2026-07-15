#!/bin/bash
# Fix Bluetooth — fuerza perfil A2DP estéreo (KZ AZ09 / Vogek)
# Auto-detecta auricular conectado y configura audio

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
CARD="bluez_card.${CARD_ID}"
notify() { notify-send -i "audio-headphones" "$NAME" "$1"; }
# ────────────────────────────────────────────────────────────

# 1. Corregir state files de WirePlumber (HFP o "off" → A2DP)
if grep -q "${CARD}=headset-head-unit\|${CARD}=off" "$STATE_PROFILE" 2>/dev/null; then
  systemctl --user stop wireplumber
  sed -i "s/${CARD}=headset-head-unit/${CARD}=a2dp-sink/g" "$STATE_PROFILE"
  sed -i "s/${CARD}=off/${CARD}=a2dp-sink/g" "$STATE_PROFILE"
  sed -i "/saved-headset-profile:${CARD}/d" "$STATE_AUTOSWITCH" 2>/dev/null
  systemctl --user start wireplumber
  sleep 2
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

# 4. Esperar a que PipeWire registre el sink (hasta 15s)
SINK_ID=""
for i in $(seq 1 15); do
  SINK_ID=$(pactl list sinks short | grep -F "$MAC" | awk '{print $1}')
  [ -n "$SINK_ID" ] && break
  sleep 1
done

if [ -z "$SINK_ID" ]; then
  notify "❌ Sink no encontrado después de 15s"
  exit 1
fi

# 5. Forzar perfil A2DP en la card
pactl set-card-profile "$CARD" a2dp-sink 2>/dev/null
sleep 0.5

# 6. Re-leer sink ID (puede cambiar tras cambiar perfil)
SINK_ID=$(pactl list sinks short | grep -F "$MAC" | awk '{print $1}')

# 7. Establecer como sink por defecto y desmutear
pactl set-default-sink "$SINK_ID"
pactl set-sink-mute "$SINK_ID" 0

# 8. Subir volumen a 80% si estaba muy bajo
VOL=$(wpctl get-volume "$SINK_ID" 2>/dev/null | awk '{printf "%.0f", $2 * 100}')
if [ -n "$VOL" ] && [ "$VOL" -lt 30 ]; then
  wpctl set-volume "$SINK_ID" 0.8
fi

notify "✅ Conectado — A2DP estéreo | Vol: $(wpctl get-volume "$SINK_ID" 2>/dev/null | awk '{printf "%.0f%%", $2 * 100}')"
