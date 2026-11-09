#!/bin/bash
# ~/.config/eww/scripts/switch-workspace.sh <workspace_id>
# Cambia al workspace especificado
# Soporta: hyprland, niri, plasma, cinnamon

WS_ID="$1"
[ -z "$WS_ID" ] && exit 1

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

switch_hyprland() {
    hyprctl dispatch workspace "$WS_ID"
}

switch_niri() {
    # niri usa workspaces 0-indexados internamente
    niri msg action focus-workspace --idx $((WS_ID - 1))
}

switch_plasma() {
    if command -v wmctrl >/dev/null 2>&1; then
        # wmctrl usa 0-indexado
        wmctrl -s $((WS_ID - 1))
    elif command -v qdbus6 >/dev/null 2>&1; then
        qdbus6 org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager.switchTo $((WS_ID - 1))
    elif command -v gdbus >/dev/null 2>&1; then
        gdbus call --session --dest org.kde.KWin --object-path /VirtualDesktopManager \
            --method org.kde.KWin.VirtualDesktopManager.switchTo "uint32:$((WS_ID - 1))"
    fi
}

switch_cinnamon() {
    if command -v wmctrl >/dev/null 2>&1; then
        wmctrl -s $((WS_ID - 1))
    elif command -v xdotool >/dev/null 2>&1; then
        xdotool set_desktop $((WS_ID - 1))
    fi
}

DESKTOP=$(detect_desktop)

case "$DESKTOP" in
    hyprland)
        switch_hyprland
        ;;
    niri)
        switch_niri
        ;;
    plasma)
        switch_plasma
        ;;
    cinnamon)
        switch_cinnamon
        ;;
esac