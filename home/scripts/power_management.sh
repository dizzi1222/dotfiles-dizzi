# #######################################################################################
# CONFIG de ZENITIES- THEMES - hayyaoe
# #######################################################################################

CHOICE=$(printf "\n\n\n\n\n󰒲" | rofi -dmenu -replace -config ~/.config/rofi/config-power.rasi)

case "$CHOICE" in
"")
  cd /$HOME
  # shutdown now
  sync                                             # Fuerza escritura a disco
  kitty -- sudo systemctl poweroff --force --force # Doble --force = bypass todo

  ;;
"")
  cd /$HOME
  sync # Fuerza escritura a disco
  sleep 1
  kitty -- sudo systemctl reboot --force --force # Doble --force = bypass todo
  ;;
"")
  hyprlock # funciona en Niri too
  ;;
"")
  cd /$HOME
  sync # Fuerza escritura a disco
  sleep 1
  kitty -- sudo systemctl suspend --force --force # o usa sleep
  ;;
"󰒲")
  # hibernar
  # Hibernation configurado en GRUB: resume=/swapfile resume_offset=18472960
  sync # Fuerza escritura a disco
  sleep 1
  # sudo systemctl hibernate --force --force
  systemctl hibernate
  # Verificar si la hibernación está correctamente configurada
  if ! grep -q "resume=" /proc/cmdline || ! swapon --show | grep -q "/"; then
    notify-send "⚠️ NO PUEDES HIBERNAR!" "Falta configuración de SWAP o parámetros de resume en GRUB " -i dialog-warning -t 5000
  fi
  ;;
"")
  cd /$HOME
  if pgrep -x "niri" >/dev/null; then
    niri msg action quit
    # Niri: mata el proceso principal (equivale a "exit")
    killall niri
    pkill -TERM niri
    sleep 2
    pkill -KILL niri # Por si no respondió al TERM
  elif pgrep -x "Hyprland" >/dev/null; then
    hyprctl dispatch exit
  elif pgrep -x "plasmashell" >/dev/null; then
    qdbus org.kde.ksmserver /KSMServer logout 0 0 0
  elif pgrep -x "gnome-shell" >/dev/null; then
    gnome-session-quit --no-prompt
  elif pgrep -x "cinnamon" >/dev/null; then
    cinnamon-session-quit --logout --no-prompt
  elif pgrep -x "mate-session" >/dev/null; then
    mate-session-save --force-logout
  elif pgrep -x "xfce4-session" >/dev/null; then
    xfce4-session-logout --logout
  elif pgrep -x "sway" >/dev/null; then
    swaymsg exit
  else
    loginctl terminate-session "$XDG_SESSION_ID"
  fi
  ;;
*)
  exit 1
  ;;
esac
