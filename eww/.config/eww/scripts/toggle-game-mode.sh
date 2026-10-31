#!/bin/bash
# ~/.config/eww/scripts/game-mode.sh

STATE_FILE="/tmp/hypr_game_mode"

# Configuraciones como arrays (más eficiente que eval)
DEFAULT_CONFIG=(
  "animations:enabled true"
  "decoration:blur:enabled false"
  "decoration:shadow:enabled false"
  "decoration:rounding 14"
  "general:gaps_in 5"
  "general:gaps_out 3"
)

GAME_CONFIG=(
  "animations:enabled false"
  "decoration:rounding 0"
  "general:gaps_in 0"
  "general:gaps_out 0"
)

apply_config() {
  local config=("$@")
  for setting in "${config[@]}"; do
    hyprctl keyword "$setting" >/dev/null
  done
}

apply_charge() {
  local mode="$1"
  if command -v tlp >/dev/null 2>&1; then
    if [ "$mode" = "full" ]; then
      # Modo gaming: carga completa (100%) vía fullcharge.
      sudo -n tlp fullcharge >/dev/null 2>&1 || true
    else
      # Modo desktop: umbral 50/80 (solo thresholds; NO toca el perfil
      # balanced/performance, eso lo gestiona el script de power-modes).
      sudo -n tlp setcharge 50 80 >/dev/null 2>&1 || true
    fi
  fi
}

case "${1:-toggle}" in
on)
  apply_config "${GAME_CONFIG[@]}"
  apply_charge full
  touch "$STATE_FILE"
  notify-send "🚀 Modo Juego Activado" "Hyprland optimizado + carga 100%"
  ;;
off)
  apply_config "${DEFAULT_CONFIG[@]}"
  apply_charge desktop
  rm -f "$STATE_FILE"
  notify-send "🎮 Modo Juego Desactivado" "Configuración normal + carga 50/80"
  ;;
status)
  [[ -f "$STATE_FILE" ]] && echo "active" || echo "inactive"
  ;;
toggle)
  if [[ -f "$STATE_FILE" ]]; then
    "$0" off
  else
    "$0" on
  fi
  ;;
esac
