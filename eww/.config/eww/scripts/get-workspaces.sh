#!/bin/bash
# ~/.config/eww/scripts/get-workspaces.sh
# Devuelve JSON de workspaces para Eww: [{"id": 1}, {"id": 2}, ...]
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

get_workspaces_hyprland() {
    hyprctl workspaces -j | jq -c 'sort_by(.id) | map({id: .id})'
}

get_workspaces_niri() {
    # niri no tiene workspaces tradicionales, usa "workspaces" virtuales
    # Devolvemos 1-10 por defecto
    seq 1 10 | jq -R -s 'split("\n") | map(select(. != "")) | map({id: tonumber})'
}

get_workspaces_plasma() {
    # Plasma/KWin: usar wmctrl o qdbus para obtener escritorios virtuales
    if command -v wmctrl >/dev/null 2>&1; then
        wmctrl -d | awk '{print $1}' | sort -n | jq -R -s 'split("\n") | map(select(. != "")) | map({id: tonumber})'
    elif command -v qdbus6 >/dev/null 2>&1; then
        qdbus6 org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager.count 2>/dev/null | \
        awk -v count="${1:-$(cat)}" 'BEGIN {for(i=1;i<=count;i++) print i}' | \
        jq -R -s 'split("\n") | map(select(. != "")) | map({id: tonumber})'
    elif command -v gdbus >/dev/null 2>&1; then
        gdbus call --session --dest org.kde.KWin --object-path /VirtualDesktopManager \
            --method org.kde.KWin.VirtualDesktopManager.count 2>/dev/null | \
        grep -oE '[0-9]+' | head -1 | \
        awk -v count="${1:-$(cat)}" 'BEGIN {for(i=1;i<=count;i++) print i}' | \
        jq -R -s 'split("\n") | map(select(. != "")) | map({id: tonumber})'
    else
        # Fallback: 4 escritorios por defecto
        seq 1 4 | jq -R -s 'split("\n") | map(select(. != "")) | map({id: tonumber})'
    fi
}

get_workspaces_cinnamon() {
    # Cinnamon: usar wmctrl o xdotool
    if command -v wmctrl >/dev/null 2>&1; then
        wmctrl -d | awk '{print $1}' | sort -n | jq -R -s 'split("\n") | map(select(. != "")) | map({id: tonumber})'
    elif command -v xdotool >/dev/null 2>&1; then
        xdotool get_num_desktops | awk -v count="${1:-$(cat)}" 'BEGIN {for(i=0;i<count;i++) print i+1}' | \
        jq -R -s 'split("\n") | map(select(. != "")) | map({id: tonumber})'
    else
        # Fallback: 4 escritorios por defecto
        seq 1 4 | jq -R -s 'split("\n") | map(select(. != "")) | map({id: tonumber})'
    fi
}

DESKTOP=$(detect_desktop)

case "$DESKTOP" in
    hyprland)
        get_workspaces_hyprland
        # Listener para eventos de Hyprland
        socat -u UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" - | \
        while read -r line; do
            case "$line" in
                "workspace>>"*|"focusedmon>>"*|"createworkspace>>"*|"destroyworkspace>>"*|"movewindow>>"*|"activewindow>>"*)
                    get_workspaces_hyprland
                    ;;
            esac
        done
        ;;
    niri)
        get_workspaces_niri
        # niri no tiene listener simple de workspaces, usamos polling via defpoll en eww
        ;;
    plasma)
        get_workspaces_plasma
        # Para Plasma, podríamos escuchar eventos DBus pero es complejo
        # Eww hará polling cada 30s via defpoll
        ;;
    cinnamon)
        get_workspaces_cinnamon
        # Para Cinnamon, similar a Plasma
        ;;
    *)
        echo "[]"
        ;;
esac