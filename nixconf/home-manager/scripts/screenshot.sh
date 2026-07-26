#!/usr/bin/env bash
# Screenshot script for Wayland
# Usage: screenshot.sh {region|full|window}

case "$1" in
    region)
        grim -g "$(slurp)" - | satty -f -
        ;;
    full)
        grim - | satty -f -
        ;;
    window)
        grim -g "$(hyprctl activewindow -j | jq -r '.at | to_entries | map("\(.value)") | join(",")') $(hyprctl activewindow -j | jq -r '.size | to_entries | map("\(.value)") | join(",")')" - | satty -f -
        ;;
    copy)
        grim -g "$(slurp)" - | wl-copy
        notify-send "Screenshot" "Copied to clipboard"
        ;;
    *)
        echo "Usage: screenshot.sh {region|full|window|copy}"
        exit 1
        ;;
esac
