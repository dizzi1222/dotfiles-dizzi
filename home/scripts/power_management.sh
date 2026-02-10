# #######################################################################################
# CONFIG de ZENITIES- THEMES - hayyaoe
# #######################################################################################

CHOICE=$(printf "\n\n\n\n\n󰒲" | rofi -dmenu -replace -config ~/.config/rofi/config-power.rasi)

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
  sync # Fuerza escritura a disco
  sleep 0.5
  systemctl --force --force suspend # o usa sleep
  ;;
"󰒲")
  # hibernar
  # Hibernation configurado en GRUB: resume=/swapfile resume_offset=18472960
  # sudo systemctl hibernate --force --force
  sudo systemctl hibernate
  # Verificar si la hibernación está correctamente configurada
  if ! grep -q "resume=" /proc/cmdline || ! swapon --show | grep -q "/"; then
    notify-send "⚠️ NO PUEDES HIBERNAR!" "Falta configuración de SWAP o parámetros de resume en GRUB " -i dialog-warning -t 5000
  fi
  ;;
"")
  cd /$HOME
  if pgrep -x "niri" >/dev/null; then
    # Niri: mata el proceso principal (equivale a "exit")
    killall niri
    pkill -TERM niri
    sleep 2
    pkill -KILL niri # Por si no respondió al TERM
  fi
  hyprctl dispatch --force --force exit
  ;;
*)
  exit 1
  ;;
esac
