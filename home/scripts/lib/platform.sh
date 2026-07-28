#!/bin/bash

# ============================================================
# platform.sh — helpers por plataforma (CachyOS/Arch vs NixOS)
# Es sourced por los scripts en home/scripts/
# ============================================================

is_arch() {
  grep -qiE 'arch|cachyos' /etc/os-release 2>/dev/null
}

wm_detect() {
  # Retorna el WM/DE actual: niri | hyprland | plasma | cinnamon | gnome | unknown
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

wm_spawn() {
  local geom="$1"
  shift

  case "$(wm_detect)" in
  niri)
    niri msg action spawn -- "$@"
    ;;
  hyprland)
    hyprctl dispatch exec "[float; size $geom] $*"
    ;;
  *)
    setsid "$@" &>/dev/null &
    ;;
  esac
}

wm_monitor_scale() {
  local mon="$1"
  local scale="$2"

  case "$(wm_detect)" in
  niri)
    niri msg output "$mon" scale "$scale"
    ;;
  hyprland)
    hyprctl keyword monitor "$mon,preferred,auto,1,$scale" || hyprctl keyword monitor "$mon,preferred,auto,$scale"
    ;;
  plasma)
    kscreen-doctor output."$mon".scale "$scale"
    ;;
  cinnamon)
    xrandr --output "$mon" --scale "$scale"x"$scale"
    ;;
  *)
    echo "wm_monitor_scale: WM/DE no soportado (niri/hyprland/plasma/cinnamon)" >&2
    return 1
    ;;
  esac
}