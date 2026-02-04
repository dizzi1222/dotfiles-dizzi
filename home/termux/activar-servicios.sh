#!/data/data/com.termux/files/usr/bin/bash

DEVICE="127.0.0.1:5555"

echo "⚡ Activando servicios de accesibilidad..."
echo ""

# Activar TODOS los servicios
adb -s $DEVICE shell settings put secure enabled_accessibility_services "\
com.inscode.autoclicker/com.inscode.autoclicker.service.ClickService:\
com.arlosoft.macrodroid/com.arlosoft.macrodroid.accessibility.MacroDroidAccessibilityService:\
com.arlosoft.macrodroid/com.arlosoft.macrodroid.accessibility.AccessibilityServiceUI:\
com.farmerbb.taskbar/com.farmerbb.taskbar.service.TaskbarAccessibilityService:\
com.circletosearch.android/com.circletosearch.android.accessibility.CircleToSearchAccessibilityService:\
com.urbanvpn.android/com.urbanvpn.android.accessibility.UrbanVPNAccessibilityService:\
com.x8bit.bitwarden/com.x8bit.bitwarden.Accessibility.AccessibilityService:\
com.tombayley.volumepanel/com.tombayley.volumepanel.accessibility.VolumeAccessibilityService"

adb -s $DEVICE shell settings put secure accessibility_enabled 1

echo "✅ Servicios activados"
echo ""
echo "📋 Verificando..."
adb -s $DEVICE shell settings get secure enabled_accessibility_services | tr ':' '\n' | nl
