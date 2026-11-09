#!/bin/bash
# ~/.config/eww/scripts/toggle-night-mode.sh
# Alterna modo noche (redshift/gammastep/hyprsunset/KWin NightLight)
# Soporta: hyprland (hyprsunset), niri (sunsetr), plasma (KWin NightLight), cinnamon (redshift/gammastep)

TEMP_NORMAL=6500
TEMP_NIGHT=3500
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

activate_night_mode() {
    local compositor=$(detect_desktop)

    case "$compositor" in
    "hyprland")
        pkill -x hyprsunset 2>/dev/null
        nohup hyprsunset -t "$TEMP_NIGHT" >/dev/null 2>&1 &
        ;;
    "niri")
        pkill -x sunsetr 2>/dev/null
        sunsetr &
        ;;
    "plasma")
        # KWin NightLight via DBus
        if command -v qdbus6 >/dev/null 2>&1; then
            qdbus6 org.kde.KWin /org/kde/KWin/NightLight org.kde.KWin.NightLight.setEnabled true
            qdbus6 org.kde.KWin /org/kde/KWin/NightLight org.kde.KWin.NightLight.setTemperature "$TEMP_NIGHT"
        elif command -v qdbus >/dev/null 2>&1; then
            qdbus org.kde.KWin /org/kde/KWin/NightLight org.kde.KWin.NightLight.setEnabled true
            qdbus org.kde.KWin /org/kde/KWin/NightLight org.kde.KWin.NightLight.setTemperature "$TEMP_NIGHT"
        elif command -v gdbus >/dev/null 2>&1; then
            gdbus call --session --dest org.kde.KWin --object-path /org/kde/KWin/NightLight \
                --method org.kde.KWin.NightLight.setEnabled true
            gdbus call --session --dest org.kde.KWin --object-path /org/kde/KWin/NightLight \
                --method org.kde.KWin.NightLight.setTemperature "uint32:$TEMP_NIGHT"
        else
            # Fallback: gammastep
            pkill -x gammastep 2>/dev/null
            nohup gammastep -O "$TEMP_NIGHT" >/dev/null 2>&1 &
        fi
        ;;
    "cinnamon"|"gnome")
        # redshift o gammastep
        pkill -x redshift 2>/dev/null
        pkill -x gammastep 2>/dev/null
        if command -v gammastep >/dev/null 2>&1; then
            nohup gammastep -O "$TEMP_NIGHT" >/dev/null 2>&1 &
        elif command -v redshift >/dev/null 2>&1; then
            nohup redshift -O "$TEMP_NIGHT" >/dev/null 2>&1 &
        fi
        ;;
    *)
        echo "❌ Compositor no soportado"
        return 1
        ;;
    esac

    touch "$NIGHT_MODE_FILE"
    notify-send "🌙 Modo Noche" "Activado (${TEMP_NIGHT}K)" -t 2000
}

deactivate_night_mode() {
    local compositor=$(detect_desktop)

    case "$compositor" in
    "hyprland")
        pkill -x hyprsunset 2>/dev/null
        hyprsunset -t "$TEMP_NORMAL" >/dev/null 2>&1 &
        ;;
    "niri")
        pkill -x sunsetr 2>/dev/null
        ;;
    "plasma")
        if command -v qdbus6 >/dev/null 2>&1; then
            qdbus6 org.kde.KWin /org/kde/KWin/NightLight org.kde.KWin.NightLight.setEnabled false
        elif command -v qdbus >/dev/null 2>&1; then
            qdbus org.kde.KWin /org/kde/KWin/NightLight org.kde.KWin.NightLight.setEnabled false
        elif command -v gdbus >/dev/null 2>&1; then
            gdbus call --session --dest org.kde.KWin --object-path /org/kde/KWin/NightLight \
                --method org.kde.KWin.NightLight.setEnabled false
        else
            pkill -x gammastep 2>/dev/null
            pkill -x redshift 2>/dev/null
        fi
        ;;
    "cinnamon"|"gnome")
        pkill -x redshift 2>/dev/null
        pkill -x gammastep 2>/dev/null
        # Restaurar temperatura normal
        if command -v gammastep >/dev/null 2>&1; then
            gammastep -O "$TEMP_NORMAL" >/dev/null 2>&1 &
        elif command -v redshift >/dev/null 2>&1; then
            redshift -O "$TEMP_NORMAL" >/dev/null 2>&1 &
        fi
        ;;
    *)
        echo "❌ Compositor no soportado"
        return 1
        ;;
    esac

    rm -f "$NIGHT_MODE_FILE"
    notify-send "☀️ Modo Día" "Activado (${TEMP_NORMAL}K)" -t 2000
}

status() {
    if [ -f "$NIGHT_MODE_FILE" ]; then
        echo "true"
    else
        echo "false"
    fi
}

case "${1:-toggle}" in
    status)
        status
        ;;
    on)
        activate_night_mode
        ;;
    off)
        deactivate_night_mode
        ;;
    toggle|*)
        if [ -f "$NIGHT_MODE_FILE" ]; then
            deactivate_night_mode
        else
            activate_night_mode
        fi
        ;;
esac