#!/bin/bash

# #######################################################################################
# CONFIG de ZENITIES- THEMES - hayyaoe
# #######################################################################################

CHOICE=$(printf "\0meta\x1fgit ayuda help comandos\n󰣇\0meta\x1faur instalar paquetes arch\n\0meta\x1fpkg instalar paquetes pacman\n󰜫\0meta\x1fwebapp instalar aplicaciones web\n󰳾\0meta\x1fautoclick, mouse, macro, tinytask god\n\0meta\x1faudio mute silenciar volumen\0meta\x1fpulse audio control volumen\n󰂜\0meta\x1fdnd notificaciones do not disturb\n\0meta\x1fgit clean limpiar repositorio\n\0meta\x1flimpiar cache limpieza\n󰌌 󱊮\0meta\x1fautopress de tecla, teclado, keyboard macro, auto\n\0meta\x1fred network wifi ethernet, network & internet\n\0meta\x1fbluetooth bluetuith conexion\n\n\0meta\x1fgame modo juego gaming\n\0meta\x1fpower perfomance optimizar rendimiento energia bateria\n\0meta\x1fgyazo captura screenshot menu\n󰩫\0meta\x1fgyazo captura recortar screenshot clipboard\n\0meta\x1fnight noche modo nocturno oscuro night toggle hypr sunset\n\n\0meta\x1fmicrofono mic mute toggle\n 󰬺\0meta\x1fhyprland install fase1 root instalacion arch\n 󰬻\0meta\x1fhyprland install fase2 user instalacion arch\n󰋊󰬼\0meta\x1fgrub reparar repair boot particion\n󰁨\0meta\x1ffile repair-reparar limits arreglar fix ulimit fuiles (archivos)\n󱄲󰖳\0meta\x1fbottles wine windows instalar\n\0meta\x1ffix de ydotool, para macros, autoclick, systemd\n 󱕴\0meta\x1fgnome, keyring, Gnome Keyring, llaves, reparar para GDM, SDDM [Brave] mejor que KDE\n󰺐\0meta\x1fscrcpy android telefono\n \0meta\x1fwaydroid scripts gapps gms magisk ROOT android 13 11\n\0meta\x1fwidgets eww lanzar" | rofi -dmenu -p "󱍕         " -replace -config ~/.config/rofi/config-power-grid.rasi)

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
  kitty -e ~/scripts/scrcpy-connect.sh
  ;;
"󰗃")
  kitty --hold -e bash -c "
    if ! command -v bindfs &>/dev/null; then
      if is_arch; then
        echo '📦 Instalando bindfs...'
        yay -S bindfs --noconfirm
      else
        echo '📦 bindfs no disponible en NixOS. Montando sin bindfs...'
        sudo mkdir -p /mnt/waydroid
        sudo mount --bind \$HOME/.local/share/waydroid/data/media/0 /mnt/waydroid
        sudo mount -o remount,bind,uid=\$(id -u),gid=\$(id -g) /mnt/waydroid
      fi
    fi

    echo '🔧 Preparando montaje...'
    sudo mkdir -p /mnt/waydroid
    sudo umount /mnt/waydroid 2>/dev/null

    echo '🔗 Montando almacenamiento de Waydroid...'
    if command -v bindfs &>/dev/null; then
      sudo bindfs --mirror=\$(id -u) \$HOME/.local/share/waydroid/data/media/0 /mnt/waydroid
    else
      sudo mount --bind \$HOME/.local/share/waydroid/data/media/0 /mnt/waydroid
    fi

    echo '📂 Sincronizando canciones...'
    rsync -av /mnt/waydroid/Android/media/in.shabinder.soundbound/ \$HOME/Descargas/Soundbound/ 2>/dev/null
    rsync -av /mnt/waydroid/Soundbound/ \$HOME/Descargas/Soundbound/ 2>/dev/null

    echo '🧹 Limpiando...'
    sudo umount /mnt/waydroid

    echo ''
    echo '✅ Soundbound sincronizado en ~/Descargas/Soundbound/'
    xdg-open \$HOME/Descargas/Soundbound/
  "
  ;;
"")
  kitty --hold -e bash -c "
    if ! command -v bindfs &>/dev/null; then
      if is_arch; then
        echo '📦 Instalando bindfs...'
        yay -S bindfs --noconfirm
      else
        echo '📦 bindfs no disponible en NixOS. Montando sin bindfs...'
      fi
    fi

    echo '🔧 Preparando montaje...'
    sudo mkdir -p /mnt/waydroid
    sudo umount /mnt/waydroid 2>/dev/null

    echo '🔗 Montando almacenamiento de Waydroid...'
    if command -v bindfs &>/dev/null; then
      sudo bindfs --mirror=\$(id -u) \$HOME/.local/share/waydroid/data/media/0 /mnt/waydroid
    else
      sudo mount --bind \$HOME/.local/share/waydroid/data/media/0 /mnt/waydroid
    fi

    mkdir -p \$HOME/Descargas/Waydroid_Fotos

    echo '📂 Sincronizando imágenes...'
    # Desde bindfs (almacenamiento compartido)
    rsync -av --include='*/' --include='*.jpg' --include='*.jpeg' --include='*.png' --include='*.gif' --include='*.webp' --include='*.bmp' --exclude='*' /mnt/waydroid/DCIM/ \$HOME/Descargas/Waydroid_Fotos/DCIM/ 2>/dev/null
    rsync -av --include='*/' --include='*.jpg' --include='*.jpeg' --include='*.png' --include='*.gif' --include='*.webp' --include='*.bmp' --exclude='*' /mnt/waydroid/Pictures/ \$HOME/Descargas/Waydroid_Fotos/Pictures/ 2>/dev/null
    rsync -av --include='*/' --include='*.jpg' --include='*.jpeg' --include='*.png' --include='*.gif' --include='*.webp' --include='*.bmp' --exclude='*' /mnt/waydroid/Download/ \$HOME/Descargas/Waydroid_Fotos/Download/ 2>/dev/null
    rsync -av --include='*/' --include='*.jpg' --include='*.jpeg' --include='*.png' --include='*.gif' --include='*.webp' --include='*.bmp' --exclude='*' '/mnt/waydroid/WhatsApp/Media/WhatsApp Images/' \$HOME/Descargas/Waydroid_Fotos/WhatsApp/ 2>/dev/null
    rsync -av --include='*/' --include='*.jpg' --include='*.jpeg' --include='*.png' --include='*.gif' --include='*.webp' --include='*.bmp' --exclude='*' '/mnt/waydroid/Android/media/com.whatsapp/WhatsApp/Media/.Statuses/' \$HOME/Descargas/Waydroid_Fotos/Statuses/ 2>/dev/null
    rsync -av --include='*/' --include='*.jpg' --include='*.jpeg' --include='*.png' --include='*.gif' --include='*.webp' --include='*.bmp' --exclude='*' '/mnt/waydroid/Pictures/Screenshots/' \$HOME/Descargas/Waydroid_Fotos/Screenshots/ 2>/dev/null

    echo '🧹 Limpiando bindfs...'
    sudo umount /mnt/waydroid

    echo '📂 Sincronizando ViewOnce (datos privados, requiere sudo)...'
    sudo mkdir -p \$HOME/Descargas/Waydroid_Fotos/ViewOnce
    sudo rsync -av --include='*/' --include='*.jpg' --include='*.jpeg' --include='*.png' --include='*.gif' --include='*.webp' --exclude='*' \$HOME/.local/share/waydroid/data/data/com.whatsapp/files/ViewOnce/ \$HOME/Descargas/Waydroid_Fotos/ViewOnce/ 2>/dev/null
    sudo chown -R \$USER:\$USER \$HOME/Descargas/Waydroid_Fotos/ViewOnce/ 2>/dev/null

    echo ''
    echo '✅ Imágenes sincronizadas en ~/Descargas/Waydroid_Fotos/'
    xdg-open \$HOME/Descargas/Waydroid_Fotos/
  "
  ;;
"")
  sh ~/scripts/power_management.sh
  ;;
"󱓞")
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
"")
  PID=$(pgrep -x hypridle | head -1)
  if [ -n "$PID" ]; then
    STATE=$(ps -o state= -p "$PID" 2>/dev/null | head -c1)
    if [ "$STATE" = "T" ]; then
      pkill -CONT hypridle
      notify-send " Hypridle" "Reanudado" -i /home/diego/.local/share/icons/Hyprland_logo.png
    else
      pkill -STOP hypridle
      notify-send " Hypridle" "Detenido (congelado)" -i /home/diego/.local/share/icons/Hyprland_logo.png
    fi
  else
    systemctl --user start hypridle
    notify-send " Hypridle" "Iniciado" -i /home/diego/.local/share/icons/Hyprland_logo.png
  fi
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
"󰮮")
  hyprctl dispatch exec "[float; size 800 600; center] kitty -- sh -c 'sudo ~/.local/bin/clean-boot; read -p \"Presiona Enter para cerrar...\"'"
  ;;
"")
  hyprctl dispatch exec "[float; size 1000 700; center] kitty -- sh -c '~/.local/bin/nixconf-rebuild; read -p \"Presiona Enter para cerrar...\"'"
  ;;
"")
  sh ~/scripts/git_clean.sh
  ;;
"󰜫")
  if [ -x ~/omarchy-arch-bin/omarchy-webapp-install ]; then
    kitty -e ~/omarchy-arch-bin/omarchy-webapp-install
  else
    notify-send "system-control" "omarchy-webapp-install: script no encontrado en ~/omarchy-arch-bin/"
  fi
  ;;
"")
  if [ -x ~/omarchy-arch-bin/omarchy-pkg-install ]; then
    kitty -e ~/omarchy-arch-bin/omarchy-pkg-install
  else
    notify-send "system-control" "omarchy-pkg-install: script no encontrado en ~/omarchy-arch-bin/"
  fi
  ;;
"󰣇")
  if [ -x ~/omarchy-arch-bin/omarchy-pkg-aur-install ]; then
    kitty -e ~/omarchy-arch-bin/omarchy-pkg-aur-install
  else
    notify-send "system-control" "AUR (omarchy) solo disponible en Arch/CachyOS"
  fi
  ;;
"")
  kitty -e ~/scripts/show_githelp.sh
  ;;
"󰬺")
  if is_arch; then
    kitty -e ~/HYPER-arch-INSTALL.sh
  else
    notify-send "system-control" "Hyprland install (Arch) — NixOS usa flake en su lugar"
  fi
  ;;
"󰬻")
  if is_arch; then
    kitty -e ~/fase2-HyprInstall-full.sh
  else
    notify-send "system-control" "Hyprland install (Arch) — NixOS usa flake en su lugar"
  fi
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
" ")
  kitty -e ~/scripts/waydroid-scripts-launcher.sh
  ;;
*)
  exit 1
  ;;
esac
