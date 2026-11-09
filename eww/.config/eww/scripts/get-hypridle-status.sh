#!/bin/bash
# ~/.config/eww/scripts/get-hypridle-status.sh
# Devuelve "true" si idle está inhibido (NO corriendo), "false" si idle está activo
# Soporta: hyprland (hypridle), niri (swayidle), plasma (PowerDevil), cinnamon (cinnamon-screensaver)

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

status_hyprland() {
    # En Hyprland: true = idle inhibido (hypridle NO corriendo o pausado)
    if pgrep -x "hypridle" >/dev/null; then
        # Verificar si está pausado (STOP signal)
        PID=$(pgrep -x hypridle | head -1)
        STATE=$(ps -o state= -p "$PID" 2>/dev/null | head -c1)
        if [ "$STATE" = "T" ]; then
            echo "true"  # Pausado = inhibido
        else
            echo "false" # Corriendo = activo
        fi
    else
        echo "true"  # No corriendo = inhibido
    fi
}

status_niri() {
    if pgrep -x "swayidle" >/dev/null; then
        PID=$(pgrep -x swayidle | head -1)
        STATE=$(ps -o state= -p "$PID" 2>/dev/null | head -c1)
        if [ "$STATE" = "T" ]; then
            echo "true"
        else
            echo "false"
        fi
    else
        echo "true"
    fi
}

status_plasma() {
    # Plasma: verificar si hay inhibición de idle activa via PowerDevil
    # O verificar estado del screensaver
    if command -v qdbus6 >/dev/null 2>&1; then
        # Verificar si screensaver está activo
        SAVER_ACTIVE=$(qdbus6 org.kde.ScreenSaver /ScreenSaver org.kde.ScreenSaver.GetActive 2>/dev/null)
        if [ "$SAVER_ACTIVE" = "true" ]; then
            echo "false"  # Screensaver activo = idle funcionando
        else
            # Verificar inhibiciones en PowerDevil
            # No hay API simple, usamos archivo de estado como fallback
            [ -f "/tmp/idle_inhibited" ] && echo "true" || echo "false"
        fi
    elif command -v gdbus >/dev/null 2>&1; then
        SAVER_ACTIVE=$(gdbus call --session --dest org.freedesktop.ScreenSaver --object-path /ScreenSaver \
            --method org.freedesktop.ScreenSaver.GetActive 2>/dev/null | grep -o 'true\|false')
        if [ "$SAVER_ACTIVE" = "true" ]; then
            echo "false"
        else
            [ -f "/tmp/idle_inhibited" ] && echo "true" || echo "false"
        fi
    else
        [ -f "/tmp/idle_inhibited" ] && echo "true" || echo "false"
    fi
}

status_cinnamon() {
    # Cinnamon: verificar cinnamon-screensaver
    if pgrep -x "cinnamon-screensaver" >/dev/null; then
        PID=$(pgrep -x cinnamon-screensaver | head -1)
        STATE=$(ps -o state= -p "$PID" 2>/dev/null | head -c1)
        if [ "$STATE" = "T" ]; then
            echo "true"  # Pausado = inhibido
        else
            # Verificar si screensaver está activo via DBus
            if command -v gdbus >/dev/null 2>&1; then
                SAVER_ACTIVE=$(gdbus call --session --dest org.freedesktop.ScreenSaver --object-path /ScreenSaver \
                    --method org.freedesktop.ScreenSaver.GetActive 2>/dev/null | grep -o 'true\|false')
                if [ "$SAVER_ACTIVE" = "true" ]; then
                    echo "false"
                else
                    echo "false"  # Corriendo y no activo = idle activo
                fi
            else
                echo "false"
            fi
        fi
    else
        echo "true"  # No corriendo = inhibido
    fi
}

status_gnome() {
    if command -v gdbus >/dev/null 2>&1; then
        SAVER_ACTIVE=$(gdbus call --session --dest org.gnome.ScreenSaver --object-path /org/gnome/ScreenSaver \
            --method org.gnome.ScreenSaver.GetActive 2>/dev/null | grep -o 'true\|false')
        if [ "$SAVER_ACTIVE" = "true" ]; then
            echo "false"
        else
            [ -f "/tmp/idle_inhibited" ] && echo "true" || echo "false"
        fi
    else
        [ -f "/tmp/idle_inhibited" ] && echo "true" || echo "false"
    fi
}

DESKTOP=$(detect_desktop)

case "$DESKTOP" in
    hyprland)
        status_hyprland
        ;;
    niri)
        status_niri
        ;;
    plasma)
        status_plasma
        ;;
    cinnamon)
        status_cinnamon
        ;;
    gnome)
        status_gnome
        ;;
    *)
        [ -f "/tmp/idle_inhibited" ] && echo "true" || echo "false"
        ;;
esac