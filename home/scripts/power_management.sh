# #######################################################################################
# CONFIG de ZENITIES- THEMES - hayyaoe
# #######################################################################################

CHOICE=$(printf "\n\n\n\n󰒲\n" | rofi -dmenu -replace -config ~/.config/rofi/config-power.rasi)

case "$CHOICE" in
"")
  cd /$HOME
  # shutdown now
  sync # Fuerza escritura a disco
  sleep 0.5
  sudo systemctl --force --force poweroff # Doble --force = bypass todo

  ;;
"")
  cd /$HOME
  sync # Fuerza escritura a disco
  sleep 0.5
  sudo systemctl --force --force reboot # Doble --force = bypass todo
  ;;
"")
  hyprlock # funciona en Niri too
  ;;
"")
  cd /$HOME
  systemctl suspend
  ;;
"󰒲")
  # hibernar
  cd /$HOME
  sync # Fuerza escritura a disco
  sleep 0.5
  # Hibernation configurado en GRUB: resume=/swapfile resume_offset=18472960
  sudo systemctl hibernate
  ;;
"")
  cd /$HOME
  hyprctl dispatch exit
  if pgrep -x "niri" >/dev/null; then
    # Niri: mata el proceso principal (equivale a "exit")
    killall niri
    pkill -TERM niri
    sleep 2
    pkill -KILL niri # Por si no respondió al TERM
  fi
  ;;
*)
  exit 1
  ;;
esac

