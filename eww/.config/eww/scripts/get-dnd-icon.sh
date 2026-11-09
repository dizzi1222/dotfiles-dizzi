#!/bin/bash
# ~/.config/eww/scripts/get-dnd-icon.sh
# Devuelve el icono de DND basado en el estado actual
# Soporta: swaync, dunst, plasma (plasmashell), cinnamon, gnome

ICON_DND="󰂞"    # Silencio/Pausado (DND ON)
ICON_ACTIVE="󰂛" # Timbre/Notificación (DND OFF)

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

get_dnd_swaync() {
    SWAYNC_CLIENT="$(command -v swaync-client || echo "$HOME/.local/bin/swaync-client")"
    "$SWAYNC_CLIENT" --get-dnd 2>/dev/null
}

get_dnd_dunst() {
    dunstctl is-paused 2>/dev/null
}

get_dnd_plasma() {
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

get_dnd_cinnamon() {
    # Cinnamon: usar archivo de estado como fallback
    DND_STATE_FILE="/tmp/dnd_active"
    if [ -f "$DND_STATE_FILE" ]; then
        echo "true"
    else
        echo "false"
    fi
}

get_dnd_gnome() {
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
DND_STATUS=""

case "$DESKTOP" in
    plasma)
        DND_STATUS=$(get_dnd_plasma)
        ;;
    cinnamon)
        DND_STATUS=$(get_dnd_cinnamon)
        ;;
    gnome)
        DND_STATUS=$(get_dnd_gnome)
        ;;
    *)
        # hyprland, niri, unknown: usar swaync o dunst
        if pgrep -x "swaync" >/dev/null 2>&1 || pgrep -x ".swaync-wrapped" >/dev/null 2>&1; then
            DND_STATUS=$(get_dnd_swaync)
        elif pgrep -x "dunst" >/dev/null 2>&1; then
            DND_STATUS=$(get_dnd_dunst)
        else
            # Fallback a archivo de estado
            DND_STATE_FILE="/tmp/dnd_active"
            if [ -f "$DND_STATE_FILE" ]; then
                DND_STATUS="true"
            else
                DND_STATUS="false"
            fi
        fi
        ;;
esac

# Devolver icono basado en estado
if [ "$DND_STATUS" = "true" ]; then
    echo "$ICON_DND"
else
    echo "$ICON_ACTIVE"
fi