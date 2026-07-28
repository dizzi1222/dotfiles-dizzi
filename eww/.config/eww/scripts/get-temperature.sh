#!/bin/bash

# Get CPU temperature from the kernel thermal zones (no lm_sensors needed).
# Picks the x86_pkg_temp zone when present, else the first CPU zone.
zone=$(ls /sys/class/thermal/ | grep thermal_zone | while read z; do
  type=$(cat /sys/class/thermal/$z/type 2>/dev/null)
  case "$type" in
    x86_pkg_temp) echo "$z"; break ;;
  esac
done | head -1)

if [ -z "$zone" ]; then
  for z in /sys/class/thermal/thermal_zone*/temp; do
    [ -r "$z" ] && { zone=$(basename "$(dirname "$z")"); break; }
  done
fi

temp=$(cat /sys/class/thermal/$zone/temp 2>/dev/null)
if [ -n "$temp" ]; then
  echo $((temp / 1000))
else
  echo "0"
fi
