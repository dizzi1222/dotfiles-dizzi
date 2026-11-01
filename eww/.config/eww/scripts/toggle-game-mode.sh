#!/bin/bash
# toggle-game-mode.sh — configuración visual de gaming

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

case "${1:-toggle}" in
on)
  apply_config "${GAME_CONFIG[@]}"
  touch "$STATE_FILE"
  notify-send "🚀 Modo Juego Activado" "Hyprland optimizado"
  ;;
off)
  apply_config "${DEFAULT_CONFIG[@]}"
  rm -f "$STATE_FILE"
  notify-send "🎮 Modo Juego Desactivado" "Configuración visual normal"
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
