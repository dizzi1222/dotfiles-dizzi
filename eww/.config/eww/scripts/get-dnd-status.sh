#!/bin/bash
# ~/.config/eww/scripts/get-dnd-status.sh
# Devuelve 'true' o 'false' para el estado del botón toggle DND
# Soporta: swaync, dunst, plasma, cinnamon, gnome

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

get_status_swaync() {
    SWAYNC_CLIENT="$(command -v swaync-client || echo "$HOME/.local/bin/swaync-client")"
    "$SWAYNC_CLIENT" --get-dnd 2>/dev/null
}

get_status_dunst() {
    dunstctl is-paused 2>/dev/null
}

get_status_plasma() {
    if command -v qdbus6 >/dev/null 2>&1; then
        qdbus6 org.kde.plasmashell /org/kde/PlasmaShell org.kde.PlasmaShell.doNotDisturb 2>/dev/null
    elif command -v qdbus >/dev/null 2>&1; then
        qdbus org.kde.plasmashell /org/kde/PlasmaShell org.kde.PlasmaShell.doNotDisturb 2>/dev/null
    elif command -v gdbus >/dev/null 2>&1; then
        gdbus call --session --dest org.kde.plasmashell --object-path /org/kde/PlasmaShell \
            --method org.kde.PlasmaShell.doNotDisturb 2>/dev/null | grep -o 'true\|false'
    else
        echo "false"
    fi
}

get_status_cinnamon() {
    DND_STATE_FILE="/tmp/dnd_active"
    if [ -f "$DND_STATE_FILE" ]; then
        echo "true"
    else
        echo "false"
    fi
}

get_status_gnome() {
    if command -v gsettings >/dev/null 2>&1; then
        CURRENT=$(gsettings get org.gnome.desktop.notifications show-banners 2>/dev/null)
        if [ "$CURRENT" = "true" ]; then
            echo "false"
        else
            echo "true"
        fi
    else
        echo "false"
    fi
}

DESKTOP=$(detect_desktop)

case "$DESKTOP" in
    plasma)
        get_status_plasma
        ;;
    cinnamon)
        get_status_cinnamon
        ;;
    gnome)
        get_status_gnome
        ;;
    *)
        # hyprland, niri, unknown
        if pgrep -x "swaync" >/dev/null 2>&1 || pgrep -x ".swaync-wrapped" >/dev/null 2>&1; then
            get_status_swaync
        elif pgrep -x "dunst" >/dev/null 2>&1; then
            get_status_dunst
        else
            DND_STATE_FILE="/tmp/dnd_active"
            if [ -f "$DND_STATE_FILE" ]; then
                echo "true"
            else
                echo "false"
            fi
        fi
        ;;
esac
