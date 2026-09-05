#!/bin/bash

# #######################################################################################
# CONFIG de ZENITIES- THEMES - hayyaoe
# #######################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/platform.sh"

CHOICE=$(printf "󰋚\0meta\x1fhistorial, history, HISTORIAL, history commands, zsh, bash, terminal\n󰣇\0meta\x1faur yay instalar paquetes arch\n\0meta\x1fpkg instalar paquetes pacman\n󰜫\0meta\x1fwebapp instalar aplicaciones web\n󰳾\0meta\x1fautoclick, mouse, macro, tinytask god\n\0meta\x1fpulse audio control volumen\n󰂜\0meta\x1fdnd notificaciones do not disturb\n\0meta\x1fgit clean limpiar repositorio\n\0meta\x1flimpiar cache limpieza\n󰮮\0meta\x1flimpiar boot clean-boot reconstruir\n\0meta\x1fnix os nixos nixconf rebuild build config home-manager\n󰌌 󱊮\0meta\x1fautopress de tecla, teclado, keyboard macro, auto\n\0meta\x1fred network wifi ethernet, network & internet\n\0meta\x1fbluetooth bluetuith conexion\n\n\0meta\x1fgame modo juego gaming\n󱓞\0meta\x1fpower perfomance optimizar rendimiento energia bateria\n\0meta\x1fgyazo captura screenshot menu\n󰩫\0meta\x1fgyazo captura recortar screenshot clipboard\n\0meta\x1fnight noche modo nocturno oscuro night toggle hypr sunset\n\0meta\x1fhypridle toggle stop start idle daemon\n\0meta\x1faudio mute silenciar volumen\n\0meta\x1fmicrofono mic mute toggle\n󰬺\0meta\x1fhyprland install fase1 root instalacion arch\n󰬻\0meta\x1fhyprland install fase2 user instalacion arch\n󰋊󰬼\0meta\x1fInstalar CachyOS, fase2-HyprInstall-CachyOS-Edition, cachyos, cachy os Cachy OS\n󱄲󰖳\0meta\x1fbottles wine windows instalar
󱦥\0meta\x1fsunshine audio local loopback aurifonos headphones streaming\n\0meta\x1ffix de ydotool, para macros, autoclick, systemd\n 󱕴\0meta\x1fgnome, keyring, Gnome Keyring, llaves, reparar para GDM, SDDM [Brave] mejor que KDE\n󰺐\0meta\x1fscrcpy android telefono\n\0meta\x1fimagenes fotos pictures dcim whatsapp exportar waydroid sync\n󰗃\0meta\x1fsoundbound musica canciones sync waydroid exportar\n \0meta\x1fwaydroid scripts gapps gms magisk ROOT android 13 11\n\0meta\x1fwidgets eww lanzar\n\0meta\x1fgit ayuda help comandos\n\0meta\x1fXDG xdg Portal Fix del GDM/SDDM Desktop Env\n🦙\0meta\x1fOllama, ollama, llama, local, cloud\n\0meta\x1fgtk font fuente nerd icons iconos refresh cache fix\n󰐫\0meta\x1fdesign extract blueprint colores palette css tokens prompt ia imagen\n󱛍\0meta\x1fwifi wifi.docx lista redes\n☠\0meta\x1fsave point restore restore restore, checkpoint, dev, save, revert, rollback, recovery, undertale, cuphead, ffx, final fantasy\n󰋋\0meta\x1fkz az09 audifonos earbuds a2dp fix bluetooth audio\n\0meta\x1faicommitconfig, commits, cambiar de modelo, IA\n\0meta\x1fkill, gamescope, Gamescope, Kill, matar waydroid, stop session, container, contenedor\n󰊢\0meta\x1fgitflow, Gitflow, git, dotfiles\n\0meta\x1fDocker, docker, Desktop, desktop\n\0meta\x1fgoogle drive rclone montar mount gdrive gd-musica\n󱛟\0meta\x1fmontar wine bottles montar mount disco externo install\n󰟝\0meta\x1finstalar juego bottles iso disco externo wine\n󰋌\0meta\x1flibros waydroid sync gdlibros epub pdf Documentos\n\0meta\x1fsuwayomi backup tachidesk sync renombrar google drive\n\0meta\x1fzoom, zoom menu, nivel de zoom, escalar, scale, resolución, escala monitor\n\0meta\x1ftelevision, tv, fuzzy, buscar, channel, picker, files, git\n\0meta\x1fnix gc, nix-collect-garbage, nix-store optimise, optimizar, garbage, deduplicar, perezoso, limpiar generaciones\n\0meta\x1fnixconf-cleanup, cleanup, limpiar cache, limpieza nix, trash, basura" | rofi -dmenu -p "󱍕         " -replace -config ~/.config/rofi/config-power-grid.rasi)

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
"")
  kitty -e tv
  ;;
"")
  wm_spawn "1000 700" kitty --title "NixGC" -- sh -c 'sudo nix-collect-garbage -d && sudo nix-store --optimise; read -p "Presiona Enter para cerrar..."'
  ;;
"")
  wm_spawn "1000 700" kitty --title "NixCleanup" -- sh -c 'nixconf-cleanup; read -p "Presiona Enter para cerrar..."'
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
  wm_spawn "800 600" kitty --title "CleanBoot" -- sh -c 'sudo ~/.local/bin/clean-boot; read -p "Presiona Enter para cerrar..."'
  ;;
"")
  wm_spawn "1000 700" kitty --title "NixRebuild" -- sh -c '~/.local/bin/nixconf-rebuild; read -p "Presiona Enter para cerrar..."'
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
  if is_arch; then
    kitty -e ~/fase2-HyprInstall-CachyOS-Edition.sh
  else
    notify-send "system-control" "CachyOS install — solo disponible en Arch"
  fi
  ;;
"󱄲󰖳")
  kitty -e ~/install-bottles.sh
  ;;
"󱦥")
  sh ~/scripts/sunshine-local-audio.sh on
  ;;
"󰳾")
  kitty -e ~/wrapper/autoclicker-menu
  ;;
"󰌌 󱊮")
  kitty -e ~/wrapper/autopress-menu
  ;;
"")
  if is_arch; then
    kitty -e ~/fix-ydotool.sh
  else
    bash -c "
      if ydotool click 0xC0 &>/dev/null; then
        notify-send 'ydotool' '✅ ydotool funciona en modo directo (sin daemon)'
      else
        notify-send 'ydotool' '⚠️  ydotool no disponible'
      fi
    "
  fi
  ;;
" 󱕴")
  if is_arch; then
    kitty -e ~/fix-brave-keyring-gnomev2.sh
  else
    notify-send "system-control" "Gnome keyring — en NixOS se configura en flake"
  fi
  ;;
" ")
  kitty -e ~/scripts/waydroid-scripts-launcher.sh
  ;;
"󰋚")
  if is_arch; then
    kitty -e nvim ~/.zsh_history
  else
    kitty -e nvim ~/.local/share/fish/fish_history
  fi
  ;;
"")
  if is_arch; then
    kitty -e ~/fix-plasma-post-install.sh
  else
    notify-send "system-control" "XDG Portal — configurado en NixOS via flake"
  fi
  ;;
"🦙")
  if is_arch; then
    kitty -e ~/instalar-ollamaCloud.sh
  else
    kitty --hold -e bash -c "echo '🤖  Ollama — Instalado via flake'; echo; ollama list 2>/dev/null || echo 'No hay modelos descargados'; echo; echo 'Usa: ollama pull <modelo>'; echo; read -p 'Presiona Enter para cerrar...'"
  fi
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
  if is_arch; then
    kitty --hold -e zsh -is -c "sleep 0.5; cd ~/dotfiles-dizzi/ && gitflow"
  elif command -v git-flow &>/dev/null; then
    kitty --hold -e bash -c "cd ~/dotfiles-dizzi/ && git flow"
  else
    notify-send "system-control" "gitflow — instalar con: nix shell nixpkgs#gitflow"
  fi
  ;;
"")
  if is_arch; then
    kitty -e ~/scripts/setup-de-docker-desktop.sh
  else
    (
      if flatpak info com.docker.Desktop &>/dev/null 2>&1; then
        flatpak run com.docker.Desktop &
      elif command -v lazydocker &>/dev/null; then
        kitty -e lazydocker
      else
        notify-send "Docker" "⚠️  ni Docker Desktop flatpak ni lazydocker disponibles"
      fi
    ) &>/dev/null &
  fi
  ;;
"")
  # Google Drive rclone: montar los remotes gdrive y gd-musica
  kitty --hold -e bash -c "
    bash ~/montar_gdrive.sh
    bash ~/montar_gd-musica.sh
    sleep 2
    mount | grep -E 'mi_gdrive|mi_gdmusica' || echo '⚠️  no se montó ningún remote'
    read -p 'Presiona Enter para cerrar...'
  "
  ;;
"󱛟")
  # Disco externo (Seagate 500GB / JMicron): montar/desmontar particiones
  kitty -e ~/scripts/montar_disco_externo.sh
  ;;
"󰟝")
  # Instalar juegos desde ISOs del disco externo en la botella de Bottles
  kitty -e ~/scripts/instalar_juego.sh
  ;;
"󰋌")
  # Sync mi_gdlibros/📖Libros → Waydroid Documents
  kitty --hold -e bash ~/scripts/sync-libros-waydroid.sh
  ;;
"")
  # Suwayomi/Tachidesk backup: detectar org.suwayomi* en Descargas/Downloads, renombrar con timestamp y MOVER a GDrive
  kitty --hold -e bash -c '
    set -euo pipefail
    SRC_DIRS=("$HOME/Descargas" "$HOME/Downloads")
    DEST_DIR="$HOME/mi_gdrive/Mi unidad/[Documentos]"
    PREFIX="org.suwayomi"
    NEW_BASE="eu.PC.org.suwayomi.tachidesk"

    echo "🔍 Buscando archivos que empiecen por \"$PREFIX\" en Descargas/Downloads..."
    FOUND=()
    for dir in "${SRC_DIRS[@]}"; do
      if [ -d "$dir" ]; then
        while IFS= read -r -d "" file; do
          FOUND+=("$file")
        done < <(find "$dir" -maxdepth 1 -type f -name "${PREFIX}*" -print0 2>/dev/null)
      fi
    done

    if [ ${#FOUND[@]} -eq 0 ]; then
      echo "❌ No se encontraron archivos que empiecen por \"$PREFIX\""
      read -p "Presiona Enter para cerrar..."
      exit 0
    fi

    echo "📋 Archivos encontrados:"
    for f in "${FOUND[@]}"; do
      echo "  - $(basename "$f")"
    done

    if [ ! -d "$DEST_DIR" ]; then
      echo "❌ Directorio destino no existe o no está montado: $DEST_DIR"
      echo "   Asegúrate de haber montado Google Drive (󰋟 montar google drive rclone)"
      read -p "Presiona Enter para cerrar..."
      exit 1
    fi

    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M")
    for file in "${FOUND[@]}"; do
      EXT="${file##*.}"
      NEW_NAME="${NEW_BASE}._${TIMESTAMP}.${EXT}"
      echo "📦 Procesando: $(basename "$file") → $NEW_NAME"
      mv -f "$file" "$DEST_DIR/$NEW_NAME"
      echo "✅ Movido a $DEST_DIR/$NEW_NAME"
    done

    echo ""
    echo "🎉 Backup completado. Archivos en: $DEST_DIR"
    read -p "Presiona Enter para cerrar..."
  '
  ;;

"")
  bash ~/scripts/zoom_menu.sh
  ;;

*)
  exit 1
  ;;
esac
