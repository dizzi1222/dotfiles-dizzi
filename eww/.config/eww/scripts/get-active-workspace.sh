#!/bin/bash
# ~/.config/eww/scripts/get-active-workspace.sh
# Devuelve el ID del workspace activo
# Soporta: hyprland, niri, plasma, cinnamon

detect_desktop() {
    if [ -n "$NIRI_SOCKET" ] || pgrep -x "niri" >/dev/null 2>&1; then
        echo "niri"
    elif [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ] || pgrep -x "Hyprland" >/dev/null 2>&1; then
        echo "hyprland"
    elif pgrep -x "plasmashell" >/dev/null 2>&1; then
        echo "plasma"
    elif pgrep -x "cinnamon" >/dev/null 2>&1; then
        echo "cinnamon"
    else
        echo "unknown"
    fi
}

get_active_hyprland() {
    hyprctl monitors -j | jq -r '.[] | select(.focused) | .activeWorkspace.id'

    socat -u UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" - | \
    stdbuf -o0 awk -F '>>|,' -e '/^workspace>>/ {print $2}' -e '/^focusedmon>>/ {print $3}'
}

get_active_niri() {
    # niri: usar niri msg focused-workspace
    # Como niri no tiene listener simple, usamos polling
    while true; do
        niri msg focused-workspace -j 2>/dev/null | jq -r '.idx // 1' | awk '{print $1+1}'
        sleep 1
    done
}

get_active_plasma() {
    # Plasma/KWin: usar wmctrl o qdbus
    if command -v wmctrl >/dev/null 2>&1; then
        while true; do
            wmctrl -d | awk '$2 == "*" {print $1+1}'
            sleep 1
        done
    elif command -v qdbus6 >/dev/null 2>&1; then
        while true; do
            qdbus6 org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager.current 2>/dev/null | \
            awk '{print $1+1}'
            sleep 1
        done
    elif command -v gdbus >/dev/null 2>&1; then
        while true; do
            gdbus call --session --dest org.kde.KWin --object-path /VirtualDesktopManager \
                --method org.kde.KWin.VirtualDesktopManager.current 2>/dev/null | \
            grep -oE '[0-9]+' | head -1 | awk '{print $1+1}'
            sleep 1
        done
    else
        echo "1"
        sleep infinity
    fi
}

get_active_cinnamon() {
    # Cinnamon: usar wmctrl o xdotool
    if command -v wmctrl >/dev/null 2>&1; then
        while true; do
            wmctrl -d | awk '$2 == "*" {print $1+1}'
            sleep 1
        done
    elif command -v xdotool >/dev/null 2>&1; then
        while true; do
            xdotool get_desktop | awk '{print $1+1}'
            sleep 1
        done
    else
        echo "1"
        sleep infinity
    fi
}

DESKTOP=$(detect_desktop)

case "$DESKTOP" in
    hyprland)
        get_active_hyprland
        ;;
    niri)
        get_active_niri
        ;;
    plasma)
        get_active_plasma
        ;;
    cinnamon)
        get_active_cinnamon
        ;;
    *)
        echo "1"
        ;;
esac