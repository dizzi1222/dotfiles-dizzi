#!/bin/bash
# ~/.config/eww/scripts/toggle-night-mode.sh

TEMP_NORMAL=6500
TEMP_NIGHT=3500
NIGHT_MODE_FILE="/tmp/night_mode_active"

# 🔧 Función para detectar el compositor
detect_compositor() {
  if command -v niri >/dev/null 2>&1 && pgrep -x niri >/dev/null; then
    echo "niri"
  elif command -v hyprctl >/dev/null 2>&1 && pgrep -x Hyprland >/dev/null; then
    echo "hyprland"
  else
    echo "unknown"
  fi
}

# 🔧 Función para activar modo noche
activate_night_mode() {
  local compositor=$(detect_compositor)

  case "$compositor" in
  "hyprland")
    pkill -x hyprsunset 2>/dev/null
    nohup hyprsunset -t "$TEMP_NIGHT" >/dev/null 2>&1 &
    ;;
  "niri")
    pkill -x sunsetr 2>/dev/null
    sunsetr
    ;;
  *)
    echo "❌ Compositor no soportado"
    return 1
    ;;
  esac

  touch "$NIGHT_MODE_FILE"
  notify-send "🌙 Modo Noche" "Activado (${TEMP_NIGHT}K)" -t 2000
}

# 🔧 Función para desactivar modo noche
deactivate_night_mode() {
  local compositor=$(detect_compositor)

  case "$compositor" in
  "hyprland")
    pkill -x hyprsunset 2>/dev/null
    hyprsunset -t "$TEMP_NORMAL" >/dev/null 2>&1 &
    ;;
  "niri")
    pkill -x sunsetr 2>/dev/null
    ;;
  *)
    echo "❌ Compositor no soportado"
    return 1
    ;;
  esac

  rm -f "$NIGHT_MODE_FILE"
  notify-send "☀️ Modo Día" "Activado (${TEMP_NORMAL}K)" -t 2000
}

# 🎯 Main
case "$1" in
"status")
  if [ -f "$NIGHT_MODE_FILE" ]; then
    echo "true"
  else
    echo "false"
  fi
  ;;
*)
  if [ -f "$NIGHT_MODE_FILE" ]; then
    deactivate_night_mode
  else
    activate_night_mode
  fi
  ;;
esac
