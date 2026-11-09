#!/bin/bash
# ~/.config/eww/scripts/logout.sh
# Cierra la sesión / logout
# Soporta: hyprland, niri, plasma, cinnamon, gnome

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

logout_hyprland() {
    hyprctl dispatch exit
}

logout_niri() {
    niri msg action quit
}

logout_plasma() {
    # Intentar varios métodos en orden
    if command -v qdbus6 >/dev/null 2>&1; then
        qdbus6 org.kde.Shutdown /Shutdown org.kde.Shutdown.logout
    elif command -v qdbus >/dev/null 2>&1; then
        qdbus org.kde.Shutdown /Shutdown org.kde.Shutdown.logout
    elif command -v gdbus >/dev/null 2>&1; then
        gdbus call --session --dest org.kde.Shutdown --object-path /Shutdown \
            --method org.kde.Shutdown.logout
    elif command -v loginctl >/dev/null 2>&1; then
        loginctl terminate-session "$XDG_SESSION_ID"
    else
        # Fallback: matar plasmashell (cierra sesión)
        pkill -x plasmashell
    fi
}

logout_cinnamon() {
    if command -v cinnamon-session-quit >/dev/null 2>&1; then
        cinnamon-session-quit --logout --no-prompt
    elif command -v gdbus >/dev/null 2>&1; then
        gdbus call --session --dest org.cinnamon.SessionManager --object-path /org/cinnamon/SessionManager \
            --method org.cinnamon.SessionManager.Logout "uint32:0"
    elif command -v loginctl >/dev/null 2>&1; then
        loginctl terminate-session "$XDG_SESSION_ID"
    else
        pkill -x cinnamon-session
    fi
}

logout_gnome() {
    if command -v gdbus >/dev/null 2>&1; then
        gdbus call --session --dest org.gnome.SessionManager --object-path /org/gnome/SessionManager \
            --method org.gnome.SessionManager.Logout "uint32:0"
    elif command -v gnome-session-quit >/dev/null 2>&1; then
        gnome-session-quit --logout --no-prompt
    elif command -v loginctl >/dev/null 2>&1; then
        loginctl terminate-session "$XDG_SESSION_ID"
    fi
}

DESKTOP=$(detect_desktop)

case "$DESKTOP" in
    hyprland)
        logout_hyprland
        ;;
    niri)
        logout_niri
        ;;
    plasma)
        logout_plasma
        ;;
    cinnamon)
        logout_cinnamon
        ;;
    gnome)
        logout_gnome
        ;;
    *)
        # Fallback genérico
        loginctl terminate-session "$XDG_SESSION_ID" 2>/dev/null || \
        pkill -x Hyprland 2>/dev/null || \
        pkill -x niri 2>/dev/null || \
        pkill -x plasmashell 2>/dev/null || \
        pkill -x cinnamon-session 2>/dev/null
        ;;
esac