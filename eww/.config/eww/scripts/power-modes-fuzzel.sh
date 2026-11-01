#!/bin/bash
# ~/.config/eww/scripts/power-modes-fuzzel.sh

# Estados
BLUR_STATE="/tmp/hypr_blur_disabled"
GAME_STATE="/tmp/hypr_game_mode"

# Check Blur State
IS_BLUR_ENABLED=$(hyprctl getoption decoration:blur:enabled | awk '/int:/ {print $2}')

if [[ "$IS_BLUR_ENABLED" == "1" ]]; then
    BLUR_OPTION="󰂷󰈈 Desactivar Blur"
else
    BLUR_OPTION="󰂵󰂵 Activar Blur"
fi

GAME_SCRIPT="$HOME/.config/eww/scripts/toggle-game-mode.sh"

# TLP solo se orquesta desde este selector de modos.
apply_charge() {
    local fullcharge="$1"
    if command -v tlp >/dev/null 2>&1; then
        if [ "$fullcharge" = true ]; then
            # Modo gaming/ahorro: carga completa (100%) vía fullcharge.
            sudo -n tlp fullcharge >/dev/null 2>&1 || true
        else
            # Modo desktop/balanced: umbral 30/80. No toca el governor.
            sudo -n tlp setcharge 30 80 >/dev/null 2>&1 || true
        fi
    fi
}

# Función helper
game_off() { [[ -f "$GAME_STATE" ]] && bash "$GAME_SCRIPT" off; }

# Menú
CHOICE=$(fuzzel --dmenu --prompt="Modos de Energía:" <<< \
"󰂄 Modo Ahorro (Low Power)
󰗑 Modo Equilibrado (Balanced)
󱓞 Modo Juego (Performance)
$BLUR_OPTION
🔄 RESET Total" 2>/dev/null)

[[ -z "$CHOICE" ]] && exit 0

# Lógica
case "$CHOICE" in
    *"Modo Ahorro"*)
        game_off
        apply_charge true
        eww update power-mode-icon="󰂄"
        cpupower frequency-set -g powersave
        notify-send "󰂄 Modo Ahorro Activo" "Energía optimizada + carga completa"
        ;;

    *"Modo Equilibrado"*)
        game_off
        apply_charge false
        eww update power-mode-icon=""
        cpupower frequency-set -g powersave
        notify-send " Modo Equilibrado" "Configuración normal + carga 30/80"
        ;;

    *"Modo Juego"*)
        bash "$GAME_SCRIPT"

        if [[ -f "$GAME_STATE" ]]; then
            apply_charge true
            cpupower frequency-set -g performance
            eww update power-mode-icon=""
        else
            apply_charge false
            cpupower frequency-set -g powersave
            eww update power-mode-icon=""
        fi
        ;;

    *"Blur"*)
        if [[ "$IS_BLUR_ENABLED" == "1" ]]; then
            hyprctl keyword decoration:blur:enabled false
            rm "$BLUR_STATE" 2>/dev/null
            notify-send "󰈈 Blur Desactivado" "Modo por defecto"
        else
            hyprctl keyword decoration:blur:enabled true
            touch "$BLUR_STATE"
            notify-send "󰈈 Blur Activado" "Experimental"
        fi
        ;;

    *"RESET"*)
        game_off
        [[ -f "$BLUR_STATE" ]] && hyprctl keyword decoration:blur:enabled false && rm "$BLUR_STATE"
        apply_charge false
        cpupower frequency-set -g powersave
        hyprctl reload
        eww update power-mode-icon=""
        notify-send "🔄 Sistema Reseteado" "Configuración por defecto"
        ;;
esac
