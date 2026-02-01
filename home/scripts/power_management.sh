# #######################################################################################
# CONFIG de ZENITIES- THEMES - hayyaoe
# #######################################################################################

CHOICE=$(printf "\n\n\n\n" | rofi -dmenu -replace -config ~/.config/rofi/config-power.rasi)

case "$CHOICE" in
"")
  cd /$HOME
  # hyprctl dispatch exit
  sleep 1
  # shutdown now
  pkill -9 hyprland 2>/dev/null
  pkill -9 niri 2>/dev/null
  sleep 1
  systemctl poweroff
  ;;
"")
  cd /$HOME
  # hyprctl dispatch exit
  sleep 1
  reboot
  ;;
"")
  sleep 1
  hyprlock # funciona en Niri too
  ;;
"")
  cd /$HOME
  sleep 1
  systemctl suspend
  ;;
"")
  cd /$HOME
  sleep 1
  hyprctl dispatch exit
  killall niri
  ;;
*)
  exit 1
  ;;
esac
