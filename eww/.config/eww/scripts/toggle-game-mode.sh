#!/bin/bash
# ~/.config/eww/scripts/toggle-game-mode.sh
# Configuración visual de gaming / optimización rendimiento
# Soporta: hyprland (hyprctl), niri, plasma (KWin effects), cinnamon (Mutter)

STATE_FILE="/tmp/game_mode_active"

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

apply_hyprland_game() {
    hyprctl keyword animations:enabled false >/dev/null
    hyprctl keyword decoration:blur:enabled false >/dev/null
    hyprctl keyword decoration:shadow:enabled false >/dev/null
    hyprctl keyword decoration:rounding 0 >/dev/null
    hyprctl keyword general:gaps_in 0 >/dev/null
    hyprctl keyword general:gaps_out 0 >/dev/null
    hyprctl keyword misc:vfr 1 >/dev/null  # Variable refresh rate
}

apply_hyprland_default() {
    hyprctl keyword animations:enabled true >/dev/null
    hyprctl keyword decoration:blur:enabled true >/dev/null
    hyprctl keyword decoration:shadow:enabled true >/dev/null
    hyprctl keyword decoration:rounding 14 >/dev/null
    hyprctl keyword general:gaps_in 5 >/dev/null
    hyprctl keyword general:gaps_out 3 >/dev/null
    hyprctl keyword misc:vfr 0 >/dev/null
}

apply_plasma_game() {
    # Desactivar efectos de KWin para gaming
    if command -v qdbus6 >/dev/null 2>&1; then
        qdbus6 org.kde.KWin /KWin org.kde.KWin.setCompositingEnabled false
        # Desactivar efectos individuales
        qdbus6 org.kde.KWin /Effects org.kde.KWin.Effects.setAllEffectsEnabled false
    elif command -v qdbus >/dev/null 2>&1; then
        qdbus org.kde.KWin /KWin org.kde.KWin.setCompositingEnabled false
        qdbus org.kde.KWin /Effects org.kde.KWin.Effects.setAllEffectsEnabled false
    elif command -v kwriteconfig6 >/dev/null 2>&1; then
        kwriteconfig6 --file kwinrc --group Compositing --key Enabled false
        kwriteconfig6 --file kwinrc --group Effects --key AllEffectsEnabled false
        qdbus6 org.kde.KWin /KWin org.kde.KWin.reconfigure 2>/dev/null || true
    fi
    # Desactivar blur
    if command -v kwriteconfig6 >/dev/null 2>&1; then
        kwriteconfig6 --file kwinrc --group Effect-Blur --key Enabled false
        kwriteconfig6 --file kwinrc --group Effect-Shadow --key Enabled false
    fi
}

apply_plasma_default() {
    # Reactivar efectos de KWin
    if command -v qdbus6 >/dev/null 2>&1; then
        qdbus6 org.kde.KWin /KWin org.kde.KWin.setCompositingEnabled true
        qdbus6 org.kde.KWin /Effects org.kde.KWin.Effects.setAllEffectsEnabled true
    elif command -v qdbus >/dev/null 2>&1; then
        qdbus org.kde.KWin /KWin org.kde.KWin.setCompositingEnabled true
        qdbus org.kde.KWin /Effects org.kde.KWin.Effects.setAllEffectsEnabled true
    elif command -v kwriteconfig6 >/dev/null 2>&1; then
        kwriteconfig6 --file kwinrc --group Compositing --key Enabled true
        kwriteconfig6 --file kwinrc --group Effects --key AllEffectsEnabled true
        qdbus6 org.kde.KWin /KWin org.kde.KWin.reconfigure 2>/dev/null || true
    fi
    # Reactivar blur
    if command -v kwriteconfig6 >/dev/null 2>&1; then
        kwriteconfig6 --file kwinrc --group Effect-Blur --key Enabled true
        kwriteconfig6 --file kwinrc --group Effect-Shadow --key Enabled true
    fi
}

apply_cinnamon_game() {
    # Cinnamon usa Mutter: desactivar efectos via gsettings
    if command -v gsettings >/dev/null 2>&1; then
        gsettings set org.cinnamon.desktop.interface enable-animations false 2>/dev/null
        gsettings set org.cinnamon.muffin compositing-mode 'off' 2>/dev/null
    fi
    # También intentar con dconf
    if command -v dconf >/dev/null 2>&1; then
        dconf write /org/cinnamon/desktop/interface/enable-animations false 2>/dev/null
        dconf write /org/cinnamon/muffin/compositing-mode "'off'" 2>/dev/null
    fi
}

apply_cinnamon_default() {
    if command -v gsettings >/dev/null 2>&1; then
        gsettings set org.cinnamon.desktop.interface enable-animations true 2>/dev/null
        gsettings set org.cinnamon.muffin compositing-mode 'full' 2>/dev/null
    fi
    if command -v dconf >/dev/null 2>&1; then
        dconf write /org/cinnamon/desktop/interface/enable-animations true 2>/dev/null
        dconf write /org/cinnamon/muffin/compositing-mode "'full'" 2>/dev/null
    fi
}

apply_gnome_game() {
    if command -v gsettings >/dev/null 2>&1; then
        gsettings set org.gnome.desktop.interface enable-animations false 2>/dev/null
        gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']" 2>/dev/null
    fi
}

apply_gnome_default() {
    if command -v gsettings >/dev/null 2>&1; then
        gsettings set org.gnome.desktop.interface enable-animations true 2>/dev/null
        gsettings set org.gnome.mutter experimental-features "[]" 2>/dev/null
    fi
}

game_on() {
    DESKTOP=$(detect_desktop)
    case "$DESKTOP" in
        hyprland)
            apply_hyprland_game
            ;;
        niri)
            # niri no tiene configuración de efectos similar
            ;;
        plasma)
            apply_plasma_game
            ;;
        cinnamon)
            apply_cinnamon_game
            ;;
        gnome)
            apply_gnome_game
            ;;
    esac

    touch "$STATE_FILE"
    notify-send "🚀 Modo Juego Activado" "Optimizado para rendimiento" -t 3000
}

game_off() {
    DESKTOP=$(detect_desktop)
    case "$DESKTOP" in
        hyprland)
            apply_hyprland_default
            ;;
        niri)
            ;;
        plasma)
            apply_plasma_default
            ;;
        cinnamon)
            apply_cinnamon_default
            ;;
        gnome)
            apply_gnome_default
            ;;
    esac

    rm -f "$STATE_FILE"
    notify-send "🎮 Modo Juego Desactivado" "Configuración visual normal" -t 3000
}

status() {
    if [ -f "$STATE_FILE" ]; then
        echo "active"
    else
        echo "inactive"
    fi
}

case "${1:-toggle}" in
    on)
        game_on
        ;;
    off)
        game_off
        ;;
    status)
        status
        ;;
    toggle|*)
        if [ -f "$STATE_FILE" ]; then
            game_off
        else
            game_on
        fi
        ;;
esac