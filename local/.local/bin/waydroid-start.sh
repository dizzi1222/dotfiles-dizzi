#!/bin/bash
waydroid session stop 2>/dev/null
sudo systemctl stop waydroid-container
sudo systemctl start waydroid-container
sleep 3

# Fix resolución interna
waydroid prop set persist.waydroid.width 1920
waydroid prop set persist.waydroid.height 1080
waydroid prop set persist.waydroid.multi_windows false # ← importante en Hyprland

# Aplicar windowrule en caliente si estamos en Hyprland
ir [ "$XDG_CURRENT_DESKTOP" = "Hyprland" ]; then
  hyprctl keyword windowrulev2 "float, class:^(Waydroid)$"
  hyprctl keyword windowrulev2 "size 1920 1080, class:^(Waydroid)$"
fi

waydroid show-full-ui
