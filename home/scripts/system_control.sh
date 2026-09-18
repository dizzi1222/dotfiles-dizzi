#!/bin/bash

# #######################################################################################
# CONFIG de ZENITIES- THEMES - hayyaoe
# #######################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/platform.sh"

# Los íconos se muestran, las descripciones son para búsqueda (invisibles con color transparente)

# Extraer solo el ícono (antes del meta tag)
# Modo dual: si se llama con un argumento (desde eww system-menu), se usa ese
# ícono directamente; sin argumentos abre el wofi grid con categorías.
if [ -n "$1" ]; then
  ICON="$1"
else
  MANIFEST="$HOME/.config/eww/scripts/system-menu-manifest.tsv"
  KW_FILE="$HOME/.config/eww/scripts/system-menu-kw.tsv"
  WOFI_CONF="$HOME/.config/wofi/system-control.conf"
  WOFI_STYLE="$HOME/.config/wofi/system-control.css"

  # Keywords invisibles (búsqueda recursiva como el \0meta de rofi): el texto
  # viaja en la línea pero se renderiza transparente vía pango markup
  # (requiere allow_markup=true en system-control.conf).
  kw_span() {
    local icon="$1"
    local kw
    kw=$(awk -F'\t' -v i="$icon" '$1==i {print $2; exit}' "$KW_FILE" 2>/dev/null)
    [ -n "$kw" ] && printf '<span alpha="1" font_size="1">%s</span>' "$kw"
  }

  # Iconos por categoría para el primer grid (wofi --columns 3)
  CATEGORY_ICONS="Todos:󰁍
Apps:󰀄
Trigger:󰳾
Style:󰑐
Setup:󰒓
System:󰣇
Audio:󰓃
About:󰊖
Herramientas:󰊢
Android:󰀲
Multimedia:󰝚
Instalar:󰌓
Sistema:󰠅"

  cat_icon() {
    echo "$CATEGORY_ICONS" | awk -F: -v c="$1" '$1==c {print $2; exit}'
  }

  # Paso 1 — elegir categoría (grid 3 columnas). "Todos" = búsqueda recursiva.
  # Cada categoría lleva chevron ' ' a la derecha (estilo Omarchy).
  CAT_LIST=$(printf 'Todos\n'; awk -F'\t' '!seen[$1]++ {print $1}' "$MANIFEST")
  CHOICE=$(printf '%s\n' "$CAT_LIST" | while read -r cat; do
    [ -n "$cat" ] && printf '%s\t%s\t<span letter_spacing="40000"> </span>%s\n' "$(cat_icon "$cat")" "$cat" ""
  done | wofi --dmenu -m -l center --conf "$WOFI_CONF" --style "$WOFI_STYLE" --columns 3 --prompt "󱍕 󰣇 Categoría")
  [ -z "$CHOICE" ] && exit 0
  CATEGORY=$(echo "$CHOICE" | awk -F'\t' '{print $2}')

# Paso 2 — elegir item (grid 2 columnas). Con keywords invisibles para
  # búsqueda recursiva ("nixconf cleanup" encuentra "Nix Cleanup").
  # Cada entrada lleva el chevron ' ' a la derecha (estilo Omarchy).
  CHOICE=$(awk -F'\t' -v c="$CATEGORY" '
    $1==c || c=="Todos" { printf "%s\t%s\t%s\n", $2, $3, "KW" }
  ' "$MANIFEST" | while IFS=$'\t' read -r icon label _; do
    printf '%s\t%s %s %s\n' "$icon" "$label" "" "$(kw_span "$icon")"
  done | wofi --dmenu -m -l center --conf "$WOFI_CONF" --style "$WOFI_STYLE" --columns 2 --prompt "󱍕 $CATEGORY")
  [ -z "$CHOICE" ] && exit 0
  ICON=$(echo "$CHOICE" | awk -F'\t' '{print $1}')
fi

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
        echo '❌ bindfs no disponible en NixOS. Instálalo con: nix shell nixpkgs#bindfs'
        read -p 'Presiona Enter para cerrar...'
        exit 1
      fi
    fi

    echo '🔧 Preparando montajes...'
    sudo mkdir -p /mnt/waydroid /mnt/waydroid-viewonce
    sudo mkdir -p \$HOME/.local/share/waydroid/data/data/com.whatsapp/files/ViewOnce
    sudo umount /mnt/waydroid 2>/dev/null
    sudo umount /mnt/waydroid-viewonce 2>/dev/null

    echo '🔗 Montando almacenamiento de Waydroid (mapeo de UIDs a usuario)...'
    # Mapea TODOS los UIDs/GIDs de Android (1023, 10141, 10154...) al usuario actual
    sudo bindfs --map=@/\$(id -u)/\$(id -g) \$HOME/.local/share/waydroid/data/media/0 /mnt/waydroid
    sudo bindfs --map=@/\$(id -u)/\$(id -g) \$HOME/.local/share/waydroid/data/data/com.whatsapp/files/ViewOnce /mnt/waydroid-viewonce

    mkdir -p \$HOME/Descargas/Waydroid_Fotos

    echo '📂 Sincronizando imágenes...'
    # Desde bindfs (almacenamiento compartido)
    rsync -av --include='*/' --include='*.jpg' --include='*.jpeg' --include='*.png' --include='*.gif' --include='*.webp' --include='*.bmp' --exclude='*' /mnt/waydroid/DCIM/ \$HOME/Descargas/Waydroid_Fotos/DCIM/ 2>/dev/null
    rsync -av --include='*/' --include='*.jpg' --include='*.jpeg' --include='*.png' --include='*.gif' --include='*.webp' --include='*.bmp' --exclude='*' /mnt/waydroid/Pictures/ \$HOME/Descargas/Waydroid_Fotos/Pictures/ 2>/dev/null
    rsync -av --include='*/' --include='*.jpg' --include='*.jpeg' --include='*.png' --include='*.gif' --include='*.webp' --include='*.bmp' --exclude='*' /mnt/waydroid/Download/ \$HOME/Descargas/Waydroid_Fotos/Download/ 2>/dev/null
    rsync -av --include='*/' --include='*.jpg' --include='*.jpeg' --include='*.png' --include='*.gif' --include='*.webp' --include='*.bmp' --exclude='*' '/mnt/waydroid/WhatsApp/Media/WhatsApp Images/' \$HOME/Descargas/Waydroid_Fotos/WhatsApp/ 2>/dev/null
    rsync -av --include='*/' --include='*.jpg' --include='*.jpeg' --include='*.png' --include='*.gif' --include='*.webp' --include='*.bmp' --include='*.mp4' --include='*.mkv' --exclude='*' '/mnt/waydroid/Android/media/com.whatsapp/WhatsApp/Media/.Statuses/' \$HOME/Descargas/Waydroid_Fotos/Statuses/ 2>/dev/null
    rsync -av --include='*/' --include='*.jpg' --include='*.jpeg' --include='*.png' --include='*.gif' --include='*.webp' --include='*.bmp' --exclude='*' '/mnt/waydroid/Pictures/Screenshots/' \$HOME/Descargas/Waydroid_Fotos/Screenshots/ 2>/dev/null

    echo '👁️  Sincronizando ViewOnce (vía bindfs, sin sudo)...'
    rsync -av --include='*/' --include='*.jpg' --include='*.jpeg' --include='*.png' --include='*.gif' --include='*.webp' --include='*.mp4' --include='*.mkv' --exclude='*' /mnt/waydroid-viewonce/ \$HOME/Descargas/Waydroid_Fotos/ViewOnce/ 2>/dev/null

    echo '🧹 Limpiando bindfs...'
    sudo umount /mnt/waydroid
    sudo umount /mnt/waydroid-viewonce

    echo '🔑 Asegurando permisos (sin candados en file explorer)...'
    chmod -R u+rwX \$HOME/Descargas/Waydroid_Fotos/ 2>/dev/null

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
  wm_spawn "1000 700" kitty --title "NixRebuild" -- sh -c '~/.local/bin/nixconf-rebuild 2>&1 | tee ~/.cache/nixconf-rebuild.log; read -p "Presiona Enter para cerrar..."'
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
"")
  kitty -e nvim ~/.config/wofi/README-wofi-system-control.md 2>/dev/null || zsh -c "sleep 0.5; cat ~/.config/wofi/README-wofi-system-control.md; read -p 'Presiona Enter para cerrar...'"
  ;;
"")
  kitty --hold -e bash -c 'cat ~/.config/wofi/README-wofi-system-control.md 2>/dev/null | grep -A30 "Créditos"; read -p "Presiona Enter para cerrar..."'
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
"󰝛")
  wm_spawn "1000 700" kitty --title "Convertir MP3 128kbps" -- sh -c '
    mkdir -p "$HOME/Descargas/128kbps"
    nix-shell -p ffmpeg --run "for f in \$HOME/Descargas/*.mp3; do [ -f \"\$f\" ] || continue; ffmpeg -i \"\$f\" -b:a 128k \"\$HOME/Descargas/128kbps/\$(basename \"\$f\")\"; done"
    echo ""
    read -p "Conversión finalizada. Presiona Enter para cerrar..."
'
  ;;
"󰊭")
  kitty --hold -e bash -c '~/scripts/antigravity-wipe-nuclear.sh'
  ;;

*)
  exit 1
  ;;
esac
