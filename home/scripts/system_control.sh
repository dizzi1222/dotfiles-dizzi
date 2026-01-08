# #######################################################################################
# CONFIG de ZENITIES- THEMES - hayyaoe
# #######################################################################################

CHOICE=$(printf "\n󰣇\n\n󰜫\n\n\n\n󰂜\n\n\n\n\n\n\n󰩫\n\n󰺐\n\n\n\n 󰬺\n 󰬻\n󰋊󰬼\n " | rofi -dmenu -p "󱍕         " -replace -config ~/.config/rofi/config-power-grid.rasi)

case "$CHOICE" in "")
  sh ~/scripts/pavucontrol.sh
  ;;
"")
  networkmanager_dmenu
  ;;
"")
  sh ~/.config/eww/scripts/bluetuith.sh
  ;;
"")
  sh ~/scripts/launch_widgets.sh
  ;;
"")
  pactl set-source-mute @DEFAULT_SOURCE@ toggle
  ;;
"")
  pactl set-sink-mute @DEFAULT_SINK@ toggle
  ;;
"󰺐")
  kitty -e /usr/bin/scrcpy
  ;;
"")
  sh ~/scripts/power_management.sh
  ;;
"")
  sh ~/.config/eww/scripts/power-modes-fuzzel.sh
  ;;
"")
  sh ~/.config/eww/scripts/toggle-game-mode.sh
  ;;
"󰂜")
  sh ~/.config/eww/scripts/toggle-dnd.sh
  swaync-client -t
  ;;
"")
  sh ~/.config/eww/scripts/toggle-night-mode.sh
  ;;
"󰩫")
  sh -c "scripts/gyazo-wayland-captura-clip"

  ;;
"")
  sh -c "scripts/gyazo-wayland-captura-menu-rofi"
  ;;
"")
  kitty -e ~/scripts/limpiar_cache.sh
  ;;
"")
  sh ~/scripts/git_clean.sh
  ;;
"󰜫")
  kitty -e ~/omarchy-arch-bin/omarchy-webapp-install
  ;;
"")
  kitty -e ~/omarchy-arch-bin/omarchy-pkg-install
  ;;
"󰣇")
  kitty -e ~/omarchy-arch-bin/omarchy-pkg-aur-install
  ;;
"")
  kitty -e ~/scripts/show_githelp.sh
  ;;
" 󰬺")
  # Fase 1 de la instalación de Hyprland, en ROOT
  kitty -e ~/HYPER-arch-INSTALL.sh
  ;;
" 󰬻")
  # Fase 2 de la instalación de Hyprland, con usuario normal
  # su diego
  kitty -e ~/fase2-HyprInstall-full.sh
  ;;
"󰋊󰬼")
  # Es el mismo que el fase 2 pero post particion para reparar grub
  # su diego
  kitty -e ~/repair-grub-fase2-HyprInstall-post-Particionar.sh
  ;;
" ")
  kitty -e ~/fix_file_limits.sh
  ;;
*)
  exit 1
  ;;
esac
