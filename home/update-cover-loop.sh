#!/usr/bin/env bash
# ~/.config/eww/scripts/update-cover-loop.sh

# Forzar salida consistente en inglés
export LC_ALL=C
export LANG=C

while true; do
  eww update current-music-cover="$(
    ~/.config/eww/scripts/mpris-cover.sh
  )"
  sleep 1
done
