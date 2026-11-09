#!/bin/bash
# ~/.config/eww/scripts/power-modes-fuzzel.sh
# Selector de modos de energía
# Soporta: hyprland, plasma (powerprofilesctl/tlp), cinnamon (tlp), gnome (powerprofilesctl)

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

DESKTOP=$(detect_desktop)

# Estados locales
BLUR_STATE="/tmp/hypr_blur_disabled"
GAME_STATE="/tmp/game_mode_active"

# Verificar estado de blur (solo Hyprland)
IS_BLUR_ENABLED="0"
if [ "$DESKTOP" = "hyprland" ]; then
    IS_BLUR_ENABLED=$(hyprctl getoption decoration:blur:enabled 2>/dev/null | awk '/int:/ {print $2}')
fi

if [[ "$IS_BLUR_ENABLED" == "1" ]]; then
    BLUR_OPTION="󰂷󰈈 Desactivar Blur"
else
    BLUR_OPTION="󰂵󰂵 Activar Blur"
fi

GAME_SCRIPT="$HOME/.config/eww/scripts/toggle-game-mode.sh"

# Función helper para TLP charge
apply_charge() {
    local fullcharge="$1"
    if command -v tlp >/dev/null 2>&1; then
        if [ "$fullcharge" = true ]; then
            sudo -n tlp fullcharge >/dev/null 2>&1 || true
        else
            sudo -n tlp setcharge 30 80 >/dev/null 2>&1 || true
        fi
    fi
}

game_off() {
    [[ -f "$GAME_STATE" ]] && bash "$GAME_SCRIPT" off
}

# Menú específico por desktop
if [ "$DESKTOP" = "plasma" ] && command -v powerprofilesctl >/dev/null 2>&1; then
    # Plasma con powerprofilesctl
    CURRENT_PROFILE=$(powerprofilesctl get 2>/dev/null)
    CHOICE=$(fuzzel --dmenu --prompt="Modos de Energía:" <<< \
"󰂄 Ahorro (Power Saver)
󰗑 Equilibrado (Balanced)
󱓞 Rendimiento (Performance)
$BLUR_OPTION
🔄 RESET Total" 2>/dev/null)
elif [ "$DESKTOP" = "gnome" ] && command -v powerprofilesctl >/dev/null 2>&1; then
    # GNOME con powerprofilesctl
    CURRENT_PROFILE=$(powerprofilesctl get 2>/dev/null)
    CHOICE=$(fuzzel --dmenu --prompt="Modos de Energía:" <<< \
"󰂄 Ahorro (Power Saver)
󰗑 Equilibrado (Balanced)
󱓞 Rendimiento (Performance)
🔄 RESET Total" 2>/dev/null)
else
    # Hyprland, niri, cinnamon, unknown - menú original con TLP/cpupower
    CHOICE=$(fuzzel --dmenu --prompt="Modos de Energía:" <<< \
"󰂄 Modo Ahorro (Low Power)
󰗑 Modo Equilibrado (Balanced)
󱓞 Modo Juego (Performance)
$BLUR_OPTION
🔄 RESET Total" 2>/dev/null)
fi

[[ -z "$CHOICE" ]] && exit 0

# Lógica
case "$CHOICE" in
    *"Ahorro"*|*"Power Saver"*)
        game_off
        apply_charge true
        if command -v powerprofilesctl >/dev/null 2>&1; then
            powerprofilesctl set power-saver
        else
            cpupower frequency-set -g powersave 2>/dev/null || true
        fi
        eww update power-mode-icon="󰂄"
        notify-send "󰂄 Modo Ahorro Activo" "Energía optimizada + carga completa" -t 3000
        ;;

    *"Equilibrado"*|*"Balanced"*)
        game_off
        apply_charge false
        if command -v powerprofilesctl >/dev/null 2>&1; then
            powerprofilesctl set balanced
        else
            cpupower frequency-set -g powersave 2>/dev/null || true
        fi
        eww update power-mode-icon=""
        notify-send "󰗑 Modo Equilibrado" "Configuración normal + carga 30/80" -t 3000
        ;;

    *"Rendimiento"*|*"Performance"*|*"Juego"*)
        if [ "$DESKTOP" != "hyprland" ] && [ "$DESKTOP" != "niri" ]; then
            # En Plasma/GNOME/Cinnamon, "Rendimiento" no activa game mode automáticamente
            bash "$GAME_SCRIPT"
        else
            bash "$GAME_SCRIPT"
        fi

        if [[ -f "$GAME_STATE" ]]; then
            apply_charge true
            if command -v powerprofilesctl >/dev/null 2>&1; then
                powerprofilesctl set performance
            else
                cpupower frequency-set -g performance 2>/dev/null || true
            fi
            eww update power-mode-icon=""
        else
            apply_charge false
            if command -v powerprofilesctl >/dev/null 2>&1; then
                powerprofilesctl set balanced
            else
                cpupower frequency-set -g powersave 2>/dev/null || true
            fi
            eww update power-mode-icon=""
        fi
        ;;

    *"Blur"*)
        if [ "$DESKTOP" = "hyprland" ]; then
            if [[ "$IS_BLUR_ENABLED" == "1" ]]; then
                hyprctl keyword decoration:blur:enabled false
                rm "$BLUR_STATE" 2>/dev/null
                notify-send "󰈈 Blur Desactivado" "Modo por defecto" -t 2000
            else
                hyprctl keyword decoration:blur:enabled true
                touch "$BLUR_STATE"
                notify-send "󰂷 Blur Activado" "Experimental" -t 2000
            fi
        else
            notify-send "Blur" "Solo disponible en Hyprland" -t 2000
        fi
        ;;

    *"RESET"*)
        game_off
        if [ "$DESKTOP" = "hyprland" ]; then
            [[ -f "$BLUR_STATE" ]] && hyprctl keyword decoration:blur:enabled false && rm "$BLUR_STATE"
        fi
        apply_charge false
        if command -v powerprofilesctl >/dev/null 2>&1; then
            powerprofilesctl set balanced
        else
            cpupower frequency-set -g powersave 2>/dev/null || true
        fi
        if [ "$DESKTOP" = "hyprland" ]; then
            hyprctl reload
        fi
        eww update power-mode-icon=""
        notify-send "🔄 Sistema Reseteado" "Configuración por defecto" -t 3000
        ;;
esac