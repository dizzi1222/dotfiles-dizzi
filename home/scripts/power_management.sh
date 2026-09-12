# #######################################################################################
# CONFIG de ZENITIES- THEMES - hayyaoe
# #######################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/platform.sh"

CHOICE=$(printf "\n\n\n\n\n󰒲" | rofi -dmenu -replace -config ~/.config/rofi/config-power.rasi)

case "$CHOICE" in
"")
  cd /$HOME
  # shutdown now
  sync                                                                                                   # Fuerza escritura a disco
  wm_spawn "500 200" kitty --title "PowerOff" -- sudo systemctl poweroff --force --force # Doble --force = bypass todo
  # poweroff
  ;;
"")
  cd /$HOME
  sync # Fuerza escritura a disco
  sleep 1
  wm_spawn "500 200" kitty --title "Reboot" -- sudo systemctl reboot --force --force # Doble --force = bypass todo
  # reboot
  ;;
"")
  hyprlock # funciona en Niri too
  ;;
"")
  cd /$HOME
  sync # Fuerza escritura a disco
  sleep 1
  wm_spawn "500 200" kitty --title "Suspend" -- sudo systemctl suspend --force --force # o usa sleep
  ;;
"󰒲")
  # hibernar
  # Hibernation configurado en GRUB: resume=/swapfile resume_offset=18472960
  systemctl hibernate
  # kitty -- sudo systemctl hibernate --force --force
  # Verificar si la hibernación está correctamente configurada
  if ! grep -q "resume=" /proc/cmdline || ! swapon --show | grep -q "/"; then
    notify-send "⚠️ NO PUEDES HIBERNAR!" "Falta configuración de SWAP o parámetros de resume en GRUB " -i dialog-warning -t 5000
  fi
  ;;
"")
  cd /$HOME
  case "$(wm_detect)" in
  niri)
    niri msg action quit
    pkill niri
    pkill -TERM niri
    sleep 2
    pkill -KILL niri # Por si no respondió al TERM
    ;;
  hyprland)
    # hyprctl necesita HYPRLAND_INSTANCE_SIGNATURE; si rofi no lo exportó,
    # lo derivamos del socket de la instancia en XDG_RUNTIME_DIR
    sig="${HYPRLAND_INSTANCE_SIGNATURE:-}"
    if [ -z "$sig" ]; then
      hypr_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr"
      sig="$(ls "$hypr_dir" 2>/dev/null | head -1)"
    fi
    if [ -n "$sig" ]; then
      HYPRLAND_INSTANCE_SIGNATURE="$sig" hyprctl dispatch exit
      sleep 3
    fi
    if pgrep -x "Hyprland" >/dev/null; then
      pkill -TERM -x Hyprland
      sleep 2
      pkill -KILL -x Hyprland # Por si no respondió al TERM
    fi
    ;;
  plasma)
    qdbus org.kde.ksmserver /KSMServer logout 0 0 0
    ;;
  gnome)
    gnome-session-quit --no-prompt
    ;;
  cinnamon)
    cinnamon-session-quit --logout --no-prompt
    ;;
  *)
    loginctl terminate-session "$XDG_SESSION_ID"
    ;;
  esac
  ;;
*)
  exit 1
  ;;
esac
