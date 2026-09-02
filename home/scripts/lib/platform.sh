#!/bin/bash

# ============================================================
# platform.sh — helpers por plataforma (CachyOS/Arch vs NixOS)
# Es sourced por los scripts en home/scripts/
# ============================================================

is_arch() {
  grep -qiE 'arch|cachyos' /etc/os-release 2>/dev/null
}

wm_spawn() {
  local geom="$1"
  shift

  if [ -n "$NIRI_SOCKET" ]; then
    niri msg action spawn -- "$@"
  elif [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    hyprctl dispatch exec "[float; size $geom] $*"
  else
    setsid "$@" &>/dev/null &
  fi
}

wm_monitor_scale() {
  local mon="$1"
  local scale="$2"

  if [ -n "$NIRI_SOCKET" ]; then
    niri msg output "$mon" scale "$scale"
  elif [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    hyprctl keyword monitor "$mon,preferred,auto,1,$scale" || hyprctl keyword monitor "$mon,preferred,auto,$scale"
  else
    echo "wm_monitor_scale: WM no soportado (niri/hyprland)" >&2
    return 1
  fi
}
