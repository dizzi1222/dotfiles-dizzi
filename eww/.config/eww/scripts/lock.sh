#!/bin/bash
# ~/.config/eww/scripts/lock.sh
# Bloquea la pantalla
# Soporta: hyprland (hyprlock), niri (swaylock), plasma (loginctl/qdbus), cinnamon (cinnamon-screensaver-command)

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

lock_hyprland() {
    hyprlock
}

lock_niri() {
    swaylock -f -c 000000
}

lock_plasma() {
    # Intentar varios métodos en orden de preferencia
    if command -v loginctl >/dev/null 2>&1; then
        loginctl lock-session
    elif command -v qdbus6 >/dev/null 2>&1; then
        qdbus6 org.kde.ScreenSaver /ScreenSaver Lock
    elif command -v qdbus >/dev/null 2>&1; then
        qdbus org.kde.ScreenSaver /ScreenSaver Lock
    elif command -v gdbus >/dev/null 2>&1; then
        gdbus call --session --dest org.freedesktop.ScreenSaver --object-path /ScreenSaver \
            --method org.freedesktop.ScreenSaver.Lock
    else
        # Fallback genérico
        loginctl lock-session 2>/dev/null || dm-tool lock 2>/dev/null || xdg-screensaver lock 2>/dev/null
    fi
}

lock_cinnamon() {
    if command -v cinnamon-screensaver-command >/dev/null 2>&1; then
        cinnamon-screensaver-command -l
    elif command -v gdbus >/dev/null 2>&1; then
        gdbus call --session --dest org.freedesktop.ScreenSaver --object-path /ScreenSaver \
            --method org.freedesktop.ScreenSaver.Lock
    else
        xdg-screensaver lock 2>/dev/null || dm-tool lock 2>/dev/null
    fi
}

lock_gnome() {
    if command -v gdbus >/dev/null 2>&1; then
        gdbus call --session --dest org.gnome.ScreenSaver --object-path /org/gnome/ScreenSaver \
            --method org.gnome.ScreenSaver.Lock
    else
        gnome-screensaver-command -l 2>/dev/null || xdg-screensaver lock 2>/dev/null
    fi
}

DESKTOP=$(detect_desktop)

case "$DESKTOP" in
    hyprland)
        lock_hyprland
        ;;
    niri)
        lock_niri
        ;;
    plasma)
        lock_plasma
        ;;
    cinnamon)
        lock_cinnamon
        ;;
    gnome)
        lock_gnome
        ;;
    *)
        # Fallback genérico
        loginctl lock-session 2>/dev/null || \
        dm-tool lock 2>/dev/null || \
        xdg-screensaver lock 2>/dev/null || \
        swaylock -f -c 000000 2>/dev/null || \
        hyprlock 2>/dev/null
        ;;
esac