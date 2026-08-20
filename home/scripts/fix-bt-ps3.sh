#!/bin/bash
# Fix Bluetooth PS3 Controller (SIXAXIS/DualShock 3)
# Reconecta y verifica que el kernel lo detecte como gamepad

MAC="54:42:69:06:41:9F"
NAME="PS3 Controller"

notify() { notify-send -i "$HOME/.local/share/icons/ps3-controller-icon.png" "$NAME" "$1"; }

# 1. Asegurar que el módulo hid-sony está cargado
if ! lsmod | grep -q hid_sony; then
  modprobe hid-sony 2>/dev/null || notify "⚠ hid-sony no disponible, intentando igual..."
fi

# 2. Reconectar si está desconectado
CONNECTED=$(bluetoothctl info "$MAC" | grep "Connected: yes")
if [ -z "$CONNECTED" ]; then
  notify "Conectando..."
  bluetoothctl connect "$MAC" > /dev/null 2>&1
  sleep 3
fi

# 3. Verificar conexión BT
CONNECTED=$(bluetoothctl info "$MAC" | grep "Connected: yes")
if [ -z "$CONNECTED" ]; then
  notify "❌ No se pudo conectar"
  exit 1
fi

# 4. Esperar a que el kernel registre el joystick
sleep 2
JS_DEV=$(ls /dev/input/js* 2>/dev/null | head -1)

if [ -z "$JS_DEV" ]; then
  notify "⚠ Conectado por BT pero sin /dev/input/js* — prueba encender primero por USB"
  exit 1
fi

# 5. Confirmar que es el PS3
DEVICE_NAME=$(cat /sys/class/input/$(basename "$JS_DEV")/device/name 2>/dev/null)
notify "✅ Detectado como gamepad: $DEVICE_NAME ($JS_DEV)"