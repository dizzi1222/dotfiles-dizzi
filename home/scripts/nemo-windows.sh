#!/bin/bash
hyprctl dispatch workspace special:magic
pkill nemo-desktop 2>/dev/null
sleep 0.5
nemo-desktop &
sleep 3
~/.config/hypr/scripts/omarchy-hyprland-window-pop
