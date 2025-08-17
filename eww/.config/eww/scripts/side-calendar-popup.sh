#!/usr/bin/env bash

LOCK_FILE="$HOME/.cache/eww-side-calendar.lock"

run() {
  eww -c "$HOME/.config/eww" open side-calendar
}

# Arrancar daemon si no está corriendo
if ! pgrep -x eww >/dev/null; then
  eww -c "$HOME/.config/eww" daemon
  sleep 1
fi

# Toggle del calendario
if [[ ! -f "$LOCK_FILE" ]]; then
  touch "$LOCK_FILE"
  run
else
  eww -c "$HOME/.config/eww" close side-calendar
  rm "$LOCK_FILE"
fi

