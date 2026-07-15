#!/bin/bash
# Fix Bluetooth KZ AZ09 — fuerza perfil A2DP estéreo y sink por defecto
# Problema: WirePlumber guarda headset-head-unit (HFP/mono) o "off" en vez de a2dp-sink

MAC="7A:7F:30:A6:90:FD"
NAME="KZ AZ09"
CARD="bluez_card.7A_7F_30_A6_90_FD"
STATE_PROFILE="$HOME/.local/state/wireplumber/default-profile"
STATE_AUTOSWITCH="$HOME/.local/state/wireplumber/bluetooth-autoswitch"

notify() { notify-send -i "$HOME/.local/share/icons/kz-az09-icon.png" "$NAME" "$1"; }

# 1. Corregir state files de WirePlumber si están en HFP o "off"
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
  SINK_ID=$(pactl list sinks short | grep "7A_7F_30_A6_90_FD\|7A:7F:30:A6:90:FD" | awk '{print $1}')
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
SINK_ID=$(pactl list sinks short | grep "7A_7F_30_A6_90_FD\|7A:7F:30:A6:90:FD" | awk '{print $1}')

# 7. Establecer como sink por defecto y desmutear
pactl set-default-sink "$SINK_ID"
pactl set-sink-mute "$SINK_ID" 0

# 8. Subir volumen a 80% si estaba muy bajo
VOL=$(wpctl get-volume "$SINK_ID" 2>/dev/null | awk '{print $2 * 100}')
if [ -n "$VOL" ] && [ "$VOL" -lt 30 ]; then
  wpctl set-volume "$SINK_ID" 0.8
fi

notify "✅ Conectado — A2DP estéreo | Vol: $(wpctl get-volume "$SINK_ID" 2>/dev/null | awk '{printf "%.0f%%", $2 * 100}')"
