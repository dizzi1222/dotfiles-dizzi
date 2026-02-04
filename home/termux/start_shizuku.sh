#!/data/data/com.termux/files/usr/bin/bash
# Espera 30 segundos tras el arranque para que el Wi-Fi esté estable
sleep 30
# Ejecuta el script
curl -sSL https://gitlab.com/marmota/adb-wifi-enabler/-/raw/main/doit.sh | bash
