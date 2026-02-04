#!/bin/bash
echo "=== Iniciando Shizuku ==="
echo "Fecha: $(date)"

# Esperar a que el sistema esté listo
sleep 25

# Intentar conectar con ADB
echo "Conectando con ADB..."
adb devices

# Ejecutar script de Shizuku si existe
if [ -f "/storage/emulated/0/Download/start_shizuku.sh" ]; then
    echo "Ejecutando script de Shizuku..."
    adb shell sh /storage/emulated/0/Download/start_shizuku.sh
else
    echo "Script de Shizuku no encontrado en Download/"
fi

echo "Shizuku iniciado - $(date)"
