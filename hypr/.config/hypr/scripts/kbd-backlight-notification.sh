#!/bin/bash
TIMEOUT=2000
DEVICE="tpacpi::kbd_backlight"
KBD_PATH="/sys/class/leds/$DEVICE/brightness"
MAX=$(cat /sys/class/leds/$DEVICE/max_brightness)

get_brightness() {
    cat "$KBD_PATH"
}

send_notification() {
    local brightness=$1
    local percentage=$((brightness * 100 / MAX))
    
    if [ "$brightness" -eq 0 ]; then
        icon="keyboard-brightness-symbolic"
        text="Off"
    else
        icon="keyboard-brightness-symbolic"
        text="Level $brightness/$MAX (${percentage}%)"
    fi
    
    notify-send -t $TIMEOUT -h string:x-canonical-private-synchronous:kbd-backlight \
        -h int:value:"$percentage" -i "$icon" "Keyboard" "$text"
}

case "$1" in
    up)
        ~/scripts/kbd-backlight-up
        sleep 0.1
        ;;
    down)
        ~/scripts/kbd-backlight-down
        sleep 0.1
        ;;
    toggle)
        current=$(get_brightness)
        if [ "$current" -eq 0 ]; then
            ~/scripts/kbd-backlight-set "$MAX"
        else
            ~/scripts/kbd-backlight-set 0
        fi
        sleep 0.1
        ;;
    *)
        echo "Uso: $0 [up|down|toggle]"
        exit 1
        ;;
esac

BRIGHTNESS=$(get_brightness)
send_notification "$BRIGHTNESS"
