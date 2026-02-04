#!/data/data/com.termux/files/usr/bin/bash

echo "🔌 Conectando ADB..."
bash start_shizuku.sh &
sleep 8

# Limpiar conexiones duplicadas
echo "🧹 Limpiando conexiones duplicadas..."
adb disconnect localhost:5555 2>/dev/null
sleep 1

# Reconectar solo a 127.0.0.1
adb connect 127.0.0.1:5555

echo ""
echo "📱 Dispositivos conectados:"
adb devices
echo ""
echo "✅ Listo! Ahora ejecuta: ./ver-servicios.sh"
