#!/bin/bash
# ~/.config/eww/scripts/toggle-dnd.sh
# Alterna No Molestar (DND)
# Soporta: swaync, dunst, plasma (plasmashell), cinnamon (notification-daemon)

DND_STATE_FILE="/tmp/dnd_active"

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

toggle_swaync() {
    SWAYNC_CLIENT="$(command -v swaync-client || echo "$HOME/.local/bin/swaync-client")"
    DND_STATUS=$("$SWAYNC_CLIENT" --get-dnd 2>/dev/null)

    if [ "$DND_STATUS" = "true" ]; then
        "$SWAYNC_CLIENT" --dnd-off
        rm -f "$DND_STATE_FILE"
        notify-send "🔔 Notificaciones" "Reactivadas (DND OFF)" -t 2000
    else
        "$SWAYNC_CLIENT" --dnd-on
        touch "$DND_STATE_FILE"
        notify-send "🔕 Notificaciones" "Pausadas (DND ON)" -t 2000
    fi
}

toggle_dunst() {
    DND_STATUS=$(dunstctl is-paused 2>/dev/null)

    if [ "$DND_STATUS" = "true" ]; then
        dunstctl set-paused false
        rm -f "$DND_STATE_FILE"
        notify-send "🔔 Notificaciones" "Reactivadas (DND OFF)" -t 2000
    else
        dunstctl set-paused true
        touch "$DND_STATE_FILE"
        notify-send "🔕 Notificaciones" "Pausadas (DND ON)" -t 2000
    fi
}

toggle_plasma() {
    # Plasma usa DoNotDisturb en plasmashell via DBus
    if command -v qdbus6 >/dev/null 2>&1; then
        CURRENT=$(qdbus6 org.kde.plasmashell /org/kde/PlasmaShell org.kde.PlasmaShell.doNotDisturb 2>/dev/null)
        if [ "$CURRENT" = "true" ]; then
            qdbus6 org.kde.plasmashell /org/kde/PlasmaShell org.kde.PlasmaShell.setDoNotDisturb false
            rm -f "$DND_STATE_FILE"
            notify-send "🔔 Notificaciones" "Reactivadas (DND OFF)" -t 2000
        else
            qdbus6 org.kde.plasmashell /org/kde/PlasmaShell org.kde.PlasmaShell.setDoNotDisturb true
            touch "$DND_STATE_FILE"
            notify-send "🔕 Notificaciones" "Pausadas (DND ON)" -t 2000
        fi
    elif command -v qdbus >/dev/null 2>&1; then
        CURRENT=$(qdbus org.kde.plasmashell /org/kde/PlasmaShell org.kde.PlasmaShell.doNotDisturb 2>/dev/null)
        if [ "$CURRENT" = "true" ]; then
            qdbus org.kde.plasmashell /org/kde/PlasmaShell org.kde.PlasmaShell.setDoNotDisturb false
            rm -f "$DND_STATE_FILE"
            notify-send "🔔 Notificaciones" "Reactivadas (DND OFF)" -t 2000
        else
            qdbus org.kde.plasmashell /org/kde/PlasmaShell org.kde.PlasmaShell.setDoNotDisturb true
            touch "$DND_STATE_FILE"
            notify-send "🔕 Notificaciones" "Pausadas (DND ON)" -t 2000
        fi
    elif command -v gdbus >/dev/null 2>&1; then
        CURRENT=$(gdbus call --session --dest org.kde.plasmashell --object-path /org/kde/PlasmaShell \
            --method org.kde.PlasmaShell.doNotDisturb 2>/dev/null | grep -o 'true\|false')
        if [ "$CURRENT" = "true" ]; then
            gdbus call --session --dest org.kde.plasmashell --object-path /org/kde/PlasmaShell \
                --method org.kde.PlasmaShell.setDoNotDisturb false
            rm -f "$DND_STATE_FILE"
            notify-send "🔔 Notificaciones" "Reactivadas (DND OFF)" -t 2000
        else
            gdbus call --session --dest org.kde.plasmashell --object-path /org/kde/PlasmaShell \
                --method org.kde.PlasmaShell.setDoNotDisturb true
            touch "$DND_STATE_FILE"
            notify-send "🔕 Notificaciones" "Pausadas (DND ON)" -t 2000
        fi
    else
        # Fallback a swaync/dunst si están corriendo
        if pgrep -x "swaync" >/dev/null 2>&1; then
            toggle_swaync
        elif pgrep -x "dunst" >/dev/null 2>&1; then
            toggle_dunst
        fi
    fi
}

toggle_cinnamon() {
    # Cinnamon: usar notification-daemon DBus o archivo de estado
    if command -v gdbus >/dev/null 2>&1; then
        # Intentar con el portal de notificaciones
        if gdbus call --session --dest org.freedesktop.Notifications --object-path /org/freedesktop/Notifications \
            --method org.freedesktop.Notifications.GetCapabilities 2>/dev/null | grep -q "dnd"; then
            # No hay API estándar para DND en notification-daemon
            # Usamos archivo de estado como fallback
            if [ -f "$DND_STATE_FILE" ]; then
                rm -f "$DND_STATE_FILE"
                notify-send "🔔 Notificaciones" "Reactivadas (DND OFF)" -t 2000
            else
                touch "$DND_STATE_FILE"
                notify-send "🔕 Notificaciones" "Pausadas (DND ON)" -t 2000
            fi
        else
            # Fallback a swaync/dunst
            if pgrep -x "swaync" >/dev/null 2>&1; then
                toggle_swaync
            elif pgrep -x "dunst" >/dev/null 2>&1; then
                toggle_dunst
            else
                if [ -f "$DND_STATE_FILE" ]; then
                    rm -f "$DND_STATE_FILE"
                    notify-send "🔔 Notificaciones" "Reactivadas (DND OFF)" -t 2000
                else
                    touch "$DND_STATE_FILE"
                    notify-send "🔕 Notificaciones" "Pausadas (DND ON)" -t 2000
                fi
            fi
        fi
    else
        # Fallback a swaync/dunst
        if pgrep -x "swaync" >/dev/null 2>&1; then
            toggle_swaync
        elif pgrep -x "dunst" >/dev/null 2>&1; then
            toggle_dunst
        else
            if [ -f "$DND_STATE_FILE" ]; then
                rm -f "$DND_STATE_FILE"
                notify-send "🔔 Notificaciones" "Reactivadas (DND OFF)" -t 2000
            else
                touch "$DND_STATE_FILE"
                notify-send "🔕 Notificaciones" "Pausadas (DND ON)" -t 2000
            fi
        fi
    fi
}

toggle_gnome() {
    # GNOME: usar portal de notificaciones o gsettings
    if command -v gsettings >/dev/null 2>&1; then
        CURRENT=$(gsettings get org.gnome.desktop.notifications show-banners 2>/dev/null)
        if [ "$CURRENT" = "true" ]; then
            gsettings set org.gnome.desktop.notifications show-banners false
            touch "$DND_STATE_FILE"
            notify-send "🔕 Notificaciones" "Pausadas (DND ON)" -t 2000
        else
            gsettings set org.gnome.desktop.notifications show-banners true
            rm -f "$DND_STATE_FILE"
            notify-send "🔔 Notificaciones" "Reactivadas (DND OFF)" -t 2000
        fi
    else
        if pgrep -x "swaync" >/dev/null 2>&1; then
            toggle_swaync
        elif pgrep -x "dunst" >/dev/null 2>&1; then
            toggle_dunst
        fi
    fi
}

DESKTOP=$(detect_desktop)

case "$DESKTOP" in
    plasma)
        toggle_plasma
        ;;
    cinnamon)
        toggle_cinnamon
        ;;
    gnome)
        toggle_gnome
        ;;
    *)
        # hyprland, niri, unknown: usar swaync o dunst
        if pgrep -x "swaync" >/dev/null 2>&1 || pgrep -x ".swaync-wrapped" >/dev/null 2>&1; then
            toggle_swaync
        elif pgrep -x "dunst" >/dev/null 2>&1; then
            toggle_dunst
        else
            # Fallback genérico
            if [ -f "$DND_STATE_FILE" ]; then
                rm -f "$DND_STATE_FILE"
                notify-send "🔔 Notificaciones" "Reactivadas (DND OFF)" -t 2000
            else
                touch "$DND_STATE_FILE"
                notify-send "🔕 Notificaciones" "Pausadas (DND ON)" -t 2000
            fi
        fi
        ;;
esac