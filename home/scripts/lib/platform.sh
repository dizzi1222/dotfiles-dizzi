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
    hyprctl dispatch exec "[float; size ${geom/ /x}]" "$@"
  else
    setsid "$@" &>/dev/null &
  fi
}