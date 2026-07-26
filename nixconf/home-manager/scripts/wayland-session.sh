#!/usr/bin/env bash
# Wayland session script
# Usage: wayland-session.sh {start|stop|status}

case "$1" in
    start)
        if [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
            echo "Starting Hyprland..."
            Hyprland &
        else
            echo "Hyprland already running (HIS: $HYPRLAND_INSTANCE_SIGNATURE)"
        fi
        ;;
    stop)
        if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
            echo "Stopping Hyprland..."
            hyprctl dispatch exit
        else
            echo "Hyprland not running"
        fi
        ;;
    status)
        if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
            echo "Hyprland running (HIS: $HYPRLAND_INSTANCE_SIGNATURE)"
        else
            echo "Hyprland not running"
        fi
        ;;
    *)
        echo "Usage: wayland-session.sh {start|stop|status}"
        exit 1
        ;;
esac
