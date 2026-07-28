#!/bin/bash
# Devuelve el icono basado en el perfil de energía activo.
# Este sistema usa TLP (power-profiles-daemon desactivado), así que leemos
# el governor de la CPU en lugar de `powerprofilesctl`.

GOVERNOR=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)

case "$GOVERNOR" in
    powersave)
        # Modo Ahorro (Low Power)
        echo "󰂄"
        ;;
    performance)
        # Modo Juego/Rendimiento (Performance/Optimized)
        echo ""
        ;;
    *)
        # Fallback (Icono de batería genérico si falla)
        echo "󱊡"
        ;;
esac
