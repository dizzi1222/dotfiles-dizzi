#!/usr/bin/env bash
# Brightness control script for Wayland
# Usage: brightness.sh {up|down|get}

get_brightness() {
    brightnessctl get
}

max_brightness() {
    brightnessctl max
}

get_percent() {
    local current=$(brightnessctl get)
    local max=$(brightnessctl max)
    echo $(( current * 100 / max ))
}

case "$1" in
    up)
        brightnessctl set 5%+
        notify-send -u low -h int:$(get_percent) "Brightness" "$(get_percent)%"
        ;;
    down)
        brightnessctl set 5%-
        notify-send -u low -h int:$(get_percent) "Brightness" "$(get_percent)%"
        ;;
    get)
        echo "$(get_percent)%"
        ;;
    *)
        echo "Usage: brightness.sh {up|down|get}"
        exit 1
        ;;
esac
