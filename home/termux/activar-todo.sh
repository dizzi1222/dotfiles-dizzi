#!/data/data/com.termux/files/usr/bin/bash

echo "🚀 Configuración completa de Termux..."
echo ""

# 1. Limpiar emulador fantasma
adb disconnect emulator-5554 2>/dev/null

# 2. Iniciar Shizuku
echo "🔧 Iniciando Shizuku..."
# bash ~/dotfiles-dizzi/home/termux/start_shizuku.sh
# sleep 12

# 3. Limpiar conexiones duplicadas
echo "🧹 Limpiando conexiones..."
adb disconnect localhost:5555 2>/dev/null
adb disconnect emulator-5554 2>/dev/null
sleep 2

# 4. Verificar conexión
DEVICE="127.0.0.1:5555"
if ! adb devices | grep -q "${DEVICE}.*device"; then
    echo "❌ ADB no conectado"
    exit 1
fi

echo "✅ ADB conectado a $DEVICE"

# 5. PIN automático
echo "🔐 Configurando PIN..."
adb -s $DEVICE shell device_config put auto_pin_confirmation AutoPinConfirmation__enable_auto_pin_confirmation true

# 6. Activar servicios
echo "♿ Activando servicios..."
bash ~/dotfiles-dizzi/home/termux/activar-servicios.sh

# 7. Auto-instalar en boot (solo si no existe)
if [ ! -f ~/.termux/boot/activar-todo.sh ]; then
    echo "📦 Instalando en Termux:Boot..."
    mkdir -p ~/.termux/boot
    cp ~/dotfiles-dizzi/home/termux/activar-todo.sh ~/.termux/boot/
    chmod +x ~/.termux/boot/activar-todo.sh
    echo "✅ Script instalado en boot"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Configuración completada!"
echo ""
echo "⚠️  IMPORTANTE: Si es la PRIMERA VEZ,"
echo "    ve a Ajustes y ACEPTA manualmente"
echo "    los permisos de accesibilidad."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
