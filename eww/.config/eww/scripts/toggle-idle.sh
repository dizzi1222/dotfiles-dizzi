#!/bin/bash
# ~/.config/eww/scripts/toggle-idle.sh
# Alterna inhibición de suspensión/protector de pantalla (idle)
# Soporta: hyprland (hypridle), niri (swayidle), plasma (powerdevil), cinnamon (cinnamon-screensaver)

STATE_FILE="/tmp/idle_inhibited"

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

toggle_hyprland() {
    if [ -f "$STATE_FILE" ]; then
        # Reanudar hypridle
        pkill -CONT hypridle 2>/dev/null
        systemctl --user start hypridle 2>/dev/null
        rm -f "$STATE_FILE"
        notify-send "☕ Idle" "Reactivado (hypridle)" -t 2000
    else
        # Pausar hypridle
        pkill -STOP hypridle 2>/dev/null
        touch "$STATE_FILE"
        notify-send "☕ Idle" "Inhibido (hypridle pausado)" -t 2000
    fi
}

toggle_niri() {
    if [ -f "$STATE_FILE" ]; then
        pkill -CONT swayidle 2>/dev/null
        systemctl --user start swayidle 2>/dev/null
        rm -f "$STATE_FILE"
        notify-send "☕ Idle" "Reactivado (swayidle)" -t 2000
    else
        pkill -STOP swayidle 2>/dev/null
        touch "$STATE_FILE"
        notify-send "☕ Idle" "Inhibido (swayidle pausado)" -t 2000
    fi
}

toggle_plasma() {
    if [ -f "$STATE_FILE" ]; then
        # Reactivar inhibición de idle en Plasma (PowerDevil)
        if command -v qdbus6 >/dev/null 2>&1; then
            qdbus6 org.kde.PowerDevil /org/kde/PowerDevil org.kde.PowerDevil.releaseIdleInhibition
        elif command -v qdbus >/dev/null 2>&1; then
            qdbus org.kde.PowerDevil /org/kde/PowerDevil org.kde.PowerDevil.releaseIdleInhibition
        elif command -v gdbus >/dev/null 2>&1; then
            gdbus call --session --dest org.kde.PowerDevil --object-path /org/kde/PowerDevil \
                --method org.kde.PowerDevil.releaseIdleInhibition
        fi
        rm -f "$STATE_FILE"
        notify-send "☕ Idle" "Reactivado (Plasma PowerDevil)" -t 2000
    else
        # Inhibir idle en Plasma (PowerDevil)
        if command -v qdbus6 >/dev/null 2>&1; then
            qdbus6 org.kde.PowerDevil /org/kde/PowerDevil org.kde.PowerDevil.requestIdleInhibition "eww" "Usuario inhibió idle"
        elif command -v qdbus >/dev/null 2>&1; then
            qdbus org.kde.PowerDevil /org/kde/PowerDevil org.kde.PowerDevil.requestIdleInhibition "eww" "Usuario inhibió idle"
        elif command -v gdbus >/dev/null 2>&1; then
            gdbus call --session --dest org.kde.PowerDevil --object-path /org/kde/PowerDevil \
                --method org.kde.PowerDevil.requestIdleInhibition "eww" "Usuario inhibió idle"
        fi
        touch "$STATE_FILE"
        notify-send "☕ Idle" "Inhibido (Plasma PowerDevil)" -t 2000
    fi
}

toggle_cinnamon() {
    if [ -f "$STATE_FILE" ]; then
        # Reanudar cinnamon-screensaver
        pkill -CONT cinnamon-screensaver 2>/dev/null
        rm -f "$STATE_FILE"
        notify-send "☕ Idle" "Reactivado (Cinnamon)" -t 2000
    else
        # Pausar cinnamon-screensaver
        pkill -STOP cinnamon-screensaver 2>/dev/null
        touch "$STATE_FILE"
        notify-send "☕ Idle" "Inhibido (Cinnamon pausado)" -t 2000
    fi
}

toggle_gnome() {
    if [ -f "$STATE_FILE" ]; then
        # Reactivar gnome-session idle inhibition
        gdbus call --session --dest org.gnome.SessionManager --object-path /org/gnome/SessionManager \
            --method org.gnome.SessionManager.Inhibit "eww" "idle" "Usuario reactivó idle" "uint32:0" 2>/dev/null
        rm -f "$STATE_FILE"
        notify-send "☕ Idle" "Reactivado (GNOME)" -t 2000
    else
        # Inhibir idle en GNOME
        gdbus call --session --dest org.gnome.SessionManager --object-path /org/gnome/SessionManager \
            --method org.gnome.SessionManager.Inhibit "eww" "idle" "Usuario inhibió idle" "uint32:4" 2>/dev/null
        touch "$STATE_FILE"
        notify-send "☕ Idle" "Inhibido (GNOME)" -t 2000
    fi
}

status() {
    if [ -f "$STATE_FILE" ]; then
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
        # Forzar inhibición
        rm -f "$STATE_FILE"
        "$0" toggle
        ;;
    off)
        # Forzar reactivación
        touch "$STATE_FILE"
        "$0" toggle
        ;;
    toggle|*)
        DESKTOP=$(detect_desktop)
        case "$DESKTOP" in
            hyprland)
                toggle_hyprland
                ;;
            niri)
                toggle_niri
                ;;
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
                # Fallback genérico usando systemd-inhibit
                if [ -f "$STATE_FILE" ]; then
                    pkill -f "systemd-inhibit.*idle" 2>/dev/null
                    rm -f "$STATE_FILE"
                    notify-send "☕ Idle" "Reactivado" -t 2000
                else
                    systemd-inhibit --what=idle --who="eww" --why="Usuario inhibió idle" sleep infinity &
                    echo $! > "$STATE_FILE.pid"
                    touch "$STATE_FILE"
                    notify-send "☕ Idle" "Inhibido" -t 2000
                fi
                ;;
        esac
        ;;
esac