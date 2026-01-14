# #######################################################################################
# CONFIG de ZENITIES- THEMES - hayyaoe
# #######################################################################################

CHOICE=$(printf "\0meta\x1fgit ayuda help comandos\n󰣇\0meta\x1faur instalar paquetes arch\n\0meta\x1fpkg instalar paquetes pacman\n󰜫\0meta\x1fwebapp instalar aplicaciones web\n󰳾\0meta\x1fautoclick, mouse, macro, tinytask god\n\0meta\x1faudio mute silenciar volumen\0meta\x1fpulse audio control volumen\n󰂜\0meta\x1fdnd notificaciones do not disturb\n\0meta\x1fgit clean limpiar repositorio\n\0meta\x1flimpiar cache limpieza\n󰌌 󱊮\0meta\x1fautopress de tecla, teclado, keyboard macro, auto\n\0meta\x1fred network wifi ethernet, network & internet\n\0meta\x1fbluetooth bluetuith conexion\n\n\0meta\x1fgame modo juego gaming\n\0meta\x1fpower perfomance optimizar rendimiento energia bateria\n\0meta\x1fgyazo captura screenshot menu\n󰩫\0meta\x1fgyazo captura screenshot clipboard\n\0meta\x1fnight noche modo nocturno oscuro\n\n\0meta\x1fmicrofono mic mute toggle\n 󰬺\0meta\x1fhyprland install fase1 root instalacion arch\n 󰬻\0meta\x1fhyprland install fase2 user instalacion arch\n󰋊󰬼\0meta\x1fgrub reparar repair boot particion\n󰁨\0meta\x1ffile repair-reparar limits arreglar fix ulimit fuiles (archivos)\n󱄲󰖳\0meta\x1fbottles wine windows instalar\n\0meta\x1ffix de ydotool, para macros, autoclick, systemd\n 󱕴\0meta\x1fgnome, keyring, Gnome Keyring, llaves, reparar para GDM, SDDM [Brave] mejor que KDE\n󰺐\0meta\x1fscrcpy android telefono\n\0meta\x1fwidgets eww lanzar" | rofi -dmenu -p "󱍕         " -replace -config ~/.config/rofi/config-power-grid.rasi)

# Los íconos se muestran, las descripciones son para búsqueda (invisibles con color transparente)

# Extraer solo el ícono (antes del meta tag)
ICON=$(echo "$CHOICE" | awk -F '\0meta' '{print $1}')

case "$ICON" in
"")
  sh ~/scripts/pavucontrol.sh
  ;;
"")
  # networkmanager_dmenu
  kitty -e impala # Mejor para gestionar redes
  ;;
"")
  # sh ~/.config/eww/scripts/bluetuith.sh
  kitty -e bluetui # Mejor para gestionar bluetooth
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
"󰋊󰬼")
  # Es el mismo que el fase 2 pero post particion para reparar grub
  # su diego
  kitty -e ~/repair-grub-fase2-HyprInstall-post-Particionar.sh
  ;;
"󰁨")
  kitty -e ~/fix_file_limits.sh
  ;;
"󱄲󰖳")
  kitty -e ~/install-bottles.sh
  ;;
"󰳾")
  kitty -e ~/wrapper/autoclicker-menu
  ;;
"󰌌 󱊮")
  kitty -e ~/wrapper/autopress-menu
  ;;
"")
  kitty -e ~/fix-ydotool.sh
  ;;
" 󱕴")
  kitty -e ~/fix-brave-keyring-gnomev2.sh
  ;;
*)
  exit 1
  ;;
esac
