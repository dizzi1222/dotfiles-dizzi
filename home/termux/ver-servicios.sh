#!/data/data/com.termux/files/usr/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 SERVICIOS DE ACCESIBILIDAD ACTIVOS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📱 Estado general:"
echo "   Accesibilidad habilitada: $(adb shell settings get secure accessibility_enabled)"
echo ""
echo "✅ Servicios activos:"
adb shell settings get secure enabled_accessibility_services | tr ':' '\n'
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 APPS CON SERVICIOS INSTALADOS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
adb shell pm list packages | grep -E "click|macro|task|urban|bitwarden|circle|nova|escaner|volume" | sed 's/package://'
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
