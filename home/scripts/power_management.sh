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
    pkill -f "xdg-desktop-portal-hyprland" # Huérfano que queda tras logout y cuelga la sesion
    sudo systemctl restart display-manager # Fallback definitivo: garantiza vuelta a SDDM
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
      sleep 1
    fi
    if pgrep -x "Hyprland" >/dev/null; then
      pkill -TERM -x Hyprland
      sleep 1
      pkill -KILL -x Hyprland # Por si no respondió al TERM
    fi
    pkill -f "xdg-desktop-portal-hyprland" # Huérfano que queda tras logout y cuelga la sesion
    sudo systemctl restart display-manager # Fallback definitivo: garantiza vuelta a SDDM
    ;;
  plasma)
    qdbus org.kde.ksmserver /KSMServer logout 0 0 0
    sudo systemctl restart display-manager # Fallback definitivo: garantiza vuelta a SDDM
    ;;
  gnome)
    gnome-session-quit --no-prompt
    sudo systemctl restart display-manager # Fallback definitivo: garantiza vuelta a SDDM
    ;;
  cinnamon)
    cinnamon-session-quit --logout --no-prompt
    sudo systemctl restart display-manager # Fallback definitivo: garantiza vuelta a SDDM
    ;;
*) 
    loginctl terminate-session "$XDG_SESSION_ID"
    sudo systemctl restart display-manager # Fallback definitivo: garantiza vuelta a SDDM
    ;;
  esac

  # Garantiza Xwayland en la próxima sesión wayland (niri): su unit viene del
  # paquete con WantedBy=graphical-session.target pero no está habilitada, por
  # eso nemo-desktop (app X11) muere con "Cannot open display" tras el swap.
  systemctl --user enable --now xwayland-satellite.service 2>/dev/null || true
  ;;
*)
  exit 1
  ;;
esac
