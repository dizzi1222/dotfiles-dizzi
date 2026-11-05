#!/usr/bin/env bash

set -euo pipefail

client="$HOME/.local/bin/swaync-client"

case "${1:-}" in
  logout)
    exec qdbus-qt6 org.kde.LogoutPrompt /LogoutPrompt org.kde.LogoutPrompt.promptLogout
    ;;
  lock)
    exec qdbus-qt6 org.freedesktop.ScreenSaver /ScreenSaver org.freedesktop.ScreenSaver.Lock
    ;;
  bluetooth)
    "$client" --close-panel --skip-wait || true
    if command -v kitty >/dev/null && command -v bluetuith >/dev/null; then
      exec kitty --class bluetooth bluetuith
    fi
    if command -v kitty >/dev/null && command -v bluetui >/dev/null; then
      exec kitty --class bluetooth bluetui
    fi
    exec kcmshell6 kcm_bluetooth
    ;;
  dnd)
    exec "$client" --toggle-dnd --skip-wait
    ;;
  dnd-status)
    exec "$client" --get-dnd --skip-wait
    ;;
  night-status)
    exec kreadconfig6 --file kwinrc --group NightColor --key Active --default false
    ;;
  night-mode)
    active=$(kreadconfig6 --file kwinrc --group NightColor --key Active --default false)
    if [ "$active" = true ]; then
      active=false
    else
      active=true
    fi
    kwriteconfig6 --file kwinrc --group NightColor --key Active --type bool "$active"
    exec qdbus-qt6 org.kde.KWin /KWin org.kde.KWin.reconfigure
    ;;
  *)
    printf 'Acción de SwayNC desconocida: %s\n' "${1:-}" >&2
    exit 2
    ;;
esac
