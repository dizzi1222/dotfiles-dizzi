# #######################################################################################
# CONFIG de ZENITIES- THEMES - hayyaoe
# #######################################################################################

CHOICE=$(printf "󰋚\0meta\x1fhistorial, history, HISTORIAL, history commands, zsh, bash, terminal\n󰣇\0meta\x1faur yay instalar paquetes arch\n\0meta\x1fpkg instalar paquetes pacman\n󰜫\0meta\x1fwebapp instalar aplicaciones web\n󰳾\0meta\x1fautoclick, mouse, macro, tinytask god\n\0meta\x1fpulse audio control volumen\n󰂜\0meta\x1fdnd notificaciones do not disturb\n\0meta\x1fgit clean limpiar repositorio\n\0meta\x1flimpiar cache limpieza\n󰌌 󱊮\0meta\x1fautopress de tecla, teclado, keyboard macro, auto\n\0meta\x1fred network wifi ethernet, network & internet\n\0meta\x1fbluetooth bluetuith conexion\n\n\0meta\x1fgame modo juego gaming\n\0meta\x1fpower perfomance optimizar rendimiento energia bateria\n\0meta\x1fgyazo captura screenshot menu\n󰩫\0meta\x1fgyazo captura recortar screenshot clipboard\n\0meta\x1fnight noche modo nocturno oscuro night toggle hypr sunset\n\0meta\x1fhypridle toggle stop start idle daemon\n\0meta\x1faudio mute silenciar volumen\n\0meta\x1fmicrofono mic mute toggle\n󰬺\0meta\x1fhyprland install fase1 root instalacion arch\n󰬻\0meta\x1fhyprland install fase2 user instalacion arch\n󰋊󰬼\0meta\x1fInstalar CachyOS, fase2-HyprInstall-CachyOS-Edition, cachyos, cachy os Cachy OS\n󱄲󰖳\0meta\x1fbottles wine windows instalar
󱦥\0meta\x1fsunshine audio local loopback aurifonos headphones streaming\n\0meta\x1ffix de ydotool, para macros, autoclick, systemd\n 󱕴\0meta\x1fgnome, keyring, Gnome Keyring, llaves, reparar para GDM, SDDM [Brave] mejor que KDE\n󰺐\0meta\x1fscrcpy android telefono\n\0meta\x1fimagenes fotos pictures dcim whatsapp exportar waydroid sync\n󰗃\0meta\x1fsoundbound musica canciones sync waydroid exportar\n \0meta\x1fwaydroid scripts gapps gms magisk ROOT android 13 11\n\0meta\x1fwidgets eww lanzar\n\0meta\x1fgit ayuda help comandos\n\0meta\x1fXDG xdg Portal Fix del GDM/SDDM Desktop Env\n🦙\0meta\x1fOllama, ollama, llama, local, cloud\n\0meta\x1fgtk font fuente nerd icons iconos refresh cache fix\n󰐫\0meta\x1fdesign extract blueprint colores palette css tokens prompt ia imagen\n󱛍\0meta\x1fwifi wifi.docx lista redes\n☠\0meta\x1fsave point restore restore restore, checkpoint, dev, save, revert, rollback, recovery, undertale, cuphead, ffx, final fantasy\n󰋋\0meta\x1fkz az09 audifonos earbuds a2dp fix bluetooth audio\n\0meta\x1faicommitconfig, commits, cambiar de modelo, IA\n\0meta\x1fkill, gamescope, Gamescope, Kill, matar waydroid, stop session, container, contenedor\n󰊢\0meta\x1fgitflow, Gitflow, git, dotfiles\n\0meta\x1fDocker, docker, Desktop, desktop" | rofi -dmenu -p "󱍕         " -replace -config ~/.config/rofi/config-power-grid.rasi)

# Los íconos se muestran, las descripciones son para búsqueda (invisibles con color transparente)

# Extraer solo el ícono (antes del meta tag)
ICON=$(echo "$CHOICE" | awk -F '\0meta' '{print $1}')

case "$ICON" in
"")
  nohup pavucontrol >/dev/null 2>&1 &
  ;;
"")
  # networkmanager_dmenu
  kitty -e impala # Mejor para gestionar redes
  ;;
"☠")
  kitty -e ~/scripts/save-point.sh
  ;;
"󱛍")
  for path in "$HOME/mi_gdrive/Mi unidad/[Documentos]/wifi.docx" "$HOME/Descargas/wifi.docx" "$HOME/Downloads/wifi.docx"; do
    if [ -f "$path" ]; then
      libreoffice "$path"
      break
    fi
  done
  ;;
"󰋋")
  # Fix Bluetooth - Auto-detecta KZ/Vogek y fuerza A2DP
  sh ~/scripts/fix-bt.sh
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
      echo '📦 Instalando bindfs...'
      yay -S bindfs --noconfirm
    fi

    echo '🔧 Preparando montaje...'
    sudo mkdir -p /mnt/waydroid
    sudo umount /mnt/waydroid 2>/dev/null

    echo '🔗 Montando almacenamiento de Waydroid con bindfs...'
    sudo bindfs --mirror=\$(id -u) \$HOME/.local/share/waydroid/data/media/0 /mnt/waydroid

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
      echo '📦 Instalando bindfs...'
      yay -S bindfs --noconfirm
    fi

    echo '🔧 Preparando montaje...'
    sudo mkdir -p /mnt/waydroid
    sudo umount /mnt/waydroid 2>/dev/null

    echo '🔗 Montando almacenamiento de Waydroid con bindfs...'
    sudo bindfs --mirror=\$(id -u) \$HOME/.local/share/waydroid/data/media/0 /mnt/waydroid

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
"󰬺")
  # Fase 1 de la instalación de Hyprland, en ROOT
  kitty -e ~/HYPER-arch-INSTALL.sh
  ;;
"󰬻")
  # Fase 2 de la instalación de Hyprland, con usuario normal
  # su diego
  kitty -e ~/fase2-HyprInstall-full.sh
  ;;
"󰋊󰬼")
  # Es el mismo que el fase 2 pero post particion para Instalar cachyOs
  # su diego
  kitty -e ~/fase2-HyprInstall-CachyOS-Edition.sh
  ;;
"󱄲󰖳")
  kitty -e ~/install-bottles.sh
  ;;
"󱦥")
  sh ~/scripts/sunshine-local-audio.sh
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
"󰋚")
  kitty -e nvim ~/.zsh_history
  ;;
"")
  kitty -e ~/fix-plasma-post-install.sh
  ;;
"🦙")
  kitty -e ~/instalar-ollamaCloud.sh
  ;;
"")
  sh ~/scripts/fix-gtk-fonts-icons.sh
  ;;
"󰐫")
  kitty --hold -e bash ~/scripts/design-extract-gum
  ;;
"")
  kitty --hold -e zsh -is -c "sleep 0.5; aicommitconfig"
  ;;
"")
  kitty -e ~/scripts/kill-gamescope
  ;;
"󰊢")
  kitty --hold -e zsh -is -c "sleep 0.5; cd ~/dotfiles-dizzi/ && gitflow"
  ;;
"")
  kitty -e ~/scripts/setup-de-docker-desktop.sh
  ;;
*)
  exit 1
  ;;
esac
