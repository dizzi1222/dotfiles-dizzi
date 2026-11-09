#!/bin/bash
# ~/.config/eww/scripts/get-nighmode-icon.sh
# Devuelve el icono correspondiente al estado del modo noche
# Soporta: hyprland, niri, plasma, cinnamon, gnome

# Archivo de estado para night mode (fallback)
NIGHT_MODE_FILE="/tmp/night_mode_active"

detect_desktop() {
    if [ -n "$NIRI_SOCKET" ] || pgrep -x "niri" >/dev/null 2>&1; then
        echo "niri"
    elif [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ] || pgrep -x "Hyprland" >/dev/null 2>&1; then
        echo "hyprland"
    elif pgrep -x "plasmashell" >/dev/null 2>&1; then
        echo "plasma"
    elif pgrep -x "cinnamon" >/dev/null 2>&1; then
        echo "cinnamon"
    elif pgrep -x "gnome-shell" >/dev/null 2>&1; then
        echo "gnome"
    else
        echo "unknown"
    fi
}

is_night_active_plasma() {
    if command -v qdbus6 >/dev/null 2>&1; then
        qdbus6 org.kde.KWin /org/kde/KWin/NightLight org.kde.KWin.NightLight.enabled 2>/dev/null | grep -q "true"
    elif command -v qdbus >/dev/null 2>&1; then
        qdbus org.kde.KWin /org/kde/KWin/NightLight org.kde.KWin.NightLight.enabled 2>/dev/null | grep -q "true"
    elif command -v gdbus >/dev/null 2>&1; then
        gdbus call --session --dest org.kde.KWin --object-path /org/kde/KWin/NightLight \
            --method org.kde.KWin.NightLight.enabled 2>/dev/null | grep -q "true"
    else
        [ -f "$NIGHT_MODE_FILE" ]
    fi
}

is_night_active_cinnamon_gnome() {
    # Verificar si redshift/gammastep está corriendo con temperatura nocturna
    if pgrep -x "redshift" >/dev/null 2>&1 || pgrep -x "gammastep" >/dev/null 2>&1; then
        return 0
    fi
    [ -f "$NIGHT_MODE_FILE" ]
}

DESKTOP=$(detect_desktop)

case "$DESKTOP" in
    plasma)
        if is_night_active_plasma; then
            echo ""  # Luna
        else
            echo ""  # Sol
        fi
        ;;
    cinnamon|gnome)
        if is_night_active_cinnamon_gnome; then
            echo ""
        else
            echo ""
        fi
        ;;
    hyprland|niri|*)
        # Usar archivo de estado para hyprland/niri/desconocido
        if [ -f "$NIGHT_MODE_FILE" ]; then
            echo ""
        else
            echo ""
        fi
        ;;
esac