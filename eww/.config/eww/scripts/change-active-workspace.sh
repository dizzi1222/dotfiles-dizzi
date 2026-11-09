#!/bin/bash
# ~/.config/eww/scripts/change-active-workspace.sh <direction>
# Cambia workspace relativo (scroll up/down): "up" | "down"
# Soporta: hyprland, niri, plasma, cinnamon

DIRECTION="$1"
[ -z "$DIRECTION" ] && exit 1

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

get_current() {
    case "$(detect_desktop)" in
        hyprland)
            hyprctl activeworkspace -j | jq -r '.id'
            ;;
        niri)
            niri msg focused-workspace -j 2>/dev/null | jq -r '.idx // 0' | awk '{print $1+1}'
            ;;
        plasma)
            if command -v wmctrl >/dev/null 2>&1; then
                wmctrl -d | awk '$2 == "*" {print $1+1}'
            elif command -v qdbus6 >/dev/null 2>&1; then
                qdbus6 org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager.current 2>/dev/null | awk '{print $1+1}'
            elif command -v gdbus >/dev/null 2>&1; then
                gdbus call --session --dest org.kde.KWin --object-path /VirtualDesktopManager \
                    --method org.kde.KWin.VirtualDesktopManager.current 2>/dev/null | grep -oE '[0-9]+' | head -1 | awk '{print $1+1}'
            else
                echo "1"
            fi
            ;;
        cinnamon)
            if command -v wmctrl >/dev/null 2>&1; then
                wmctrl -d | awk '$2 == "*" {print $1+1}'
            elif command -v xdotool >/dev/null 2>&1; then
                xdotool get_desktop | awk '{print $1+1}'
            else
                echo "1"
            fi
            ;;
        *)
            echo "1"
            ;;
    esac
}

get_count() {
    case "$(detect_desktop)" in
        hyprland)
            hyprctl workspaces -j | jq 'length'
            ;;
        niri)
            echo "10"
            ;;
        plasma)
            if command -v wmctrl >/dev/null 2>&1; then
                wmctrl -d | wc -l
            elif command -v qdbus6 >/dev/null 2>&1; then
                qdbus6 org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager.count 2>/dev/null
            elif command -v gdbus >/dev/null 2>&1; then
                gdbus call --session --dest org.kde.KWin --object-path /VirtualDesktopManager \
                    --method org.kde.KWin.VirtualDesktopManager.count 2>/dev/null | grep -oE '[0-9]+' | head -1
            else
                echo "4"
            fi
            ;;
        cinnamon)
            if command -v wmctrl >/dev/null 2>&1; then
                wmctrl -d | wc -l
            elif command -v xdotool >/dev/null 2>&1; then
                xdotool get_num_desktops
            else
                echo "4"
            fi
            ;;
        *)
            echo "4"
            ;;
    esac
}

CURRENT=$(get_current)
COUNT=$(get_count)

case "$DIRECTION" in
    up)
        NEW=$((CURRENT + 1))
        [ "$NEW" -gt "$COUNT" ] && NEW=1
        ;;
    down)
        NEW=$((CURRENT - 1))
        [ "$NEW" -lt 1 ] && NEW=$COUNT
        ;;
    *)
        exit 1
        ;;
esac

exec ~/.config/eww/scripts/switch-workspace.sh "$NEW"