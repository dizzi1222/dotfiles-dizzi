#!/usr/bin/env bash
# Volume control script for Wayland (PipeWire)
# Usage: volume.sh {up|down|toggle|set}

get_volume() {
    pamixer --get-volume
}

is_muted() {
    pamixer --get-mute
}

case "$1" in
    up)
        pamixer -i 5
        notify-send -u low -h int:$(pamixer --get-volume) "Volume" "$(get_volume)%"
        ;;
    down)
        pamixer -d 5
        notify-send -u low -h int:$(pamixer --get-volume) "Volume" "$(get_volume)%"
        ;;
    toggle)
        pamixer -t
        if is_muted; then
            notify-send -u low "Volume" "Muted"
        else
            notify-send -u low "Volume" "$(get_volume)%"
        fi
        ;;
    set)
        pamixer --set-volume "$2"
        notify-send -u low "Volume" "$(get_volume)%"
        ;;
    *)
        echo "Usage: volume.sh {up|down|toggle|set [0-100]}"
        exit 1
        ;;
esac
