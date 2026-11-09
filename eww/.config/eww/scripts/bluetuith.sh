#!/bin/bash
# ~/.config/eww/scripts/bluetuith.sh
# Abre bluetuith/bluetui (TUI bluetooth) en terminal flotante
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

# Detectar el comando bluetooth TUI disponible (bluetui en Fedora/Bazzite, bluetuith en Arch)
BT_CMD="$(command -v bluetui || command -v bluetuith || echo bluetui)"

DESKTOP=$(detect_desktop)

case "$DESKTOP" in
    hyprland)
        # Cerrar swaync si está abierto
        swaync-client -cp 2>/dev/null
        sleep 0.3

        if hyprctl clients -j | jq -e '.[] | select(.class == "bluetooth")' >/dev/null 2>&1; then
            hyprctl dispatch focuswindow "class:bluetooth"
        else
            hyprctl dispatch exec "[float; size 525 260; center; pin] kitty --class bluetooth $BT_CMD"
            sleep 0.5
            hyprctl dispatch focuswindow "class:bluetooth"
        fi
        ;;

    niri)
        swaync-client -cp 2>/dev/null
        sleep 0.3

        # niri: usar niri msg para ventana flotante
        niri msg action spawn -- kitty --class bluetooth -e "$BT_CMD"
        ;;

    plasma)
        # Plasma: usar kitty con reglas de ventana de KWin
        if command -v kitty >/dev/null 2>&1; then
            kitty --class bluetooth -e "$BT_CMD" &
        elif command -v konsole >/dev/null 2>&1; then
            konsole --new-tab -e "$BT_CMD" &
        else
            kitty -e "$BT_CMD" &
        fi
        ;;

    cinnamon|gnome)
        # Cinnamon/GNOME: usar terminal estándar
        if command -v kitty >/dev/null 2>&1; then
            kitty --class bluetooth -e "$BT_CMD" &
        elif command -v gnome-terminal >/dev/null 2>&1; then
            gnome-terminal -- "$BT_CMD" &
        elif command -v konsole >/dev/null 2>&1; then
            konsole --new-tab -e "$BT_CMD" &
        else
            xterm -e "$BT_CMD" &
        fi
        ;;

    *)
        # Fallback genérico
        if command -v kitty >/dev/null 2>&1; then
            kitty --class bluetooth -e "$BT_CMD" &
        elif command -v alacritty >/dev/null 2>&1; then
            alacritty --class bluetooth -e "$BT_CMD" &
        else
            xterm -e "$BT_CMD" &
        fi
        ;;
esac