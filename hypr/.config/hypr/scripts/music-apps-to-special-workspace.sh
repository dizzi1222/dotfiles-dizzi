#!/bin/bash
# Script para mover automáticamente apps de música al workspace special:music
# Autor: Diego (dizzi)
# Ubicación: ~/.config/hypr/scripts/music-apps-to-special-workspace.sh
# Versión: 0.6
# ===== WORKSPACE SPECIAL:MUSIC =====
# Todas las alternativas de Spotify + reproductores locales
#########################################################
# === REPRODUCTORES [SPECIAL MUSIC WORKSPACE rules] ===
#########################################################

# Esperar a que Hyprland esté completamente iniciado
sleep 2

# Lista de clases de aplicaciones de música a monitorear (SIN kitty)
MUSIC_APPS=(
  "spotify"
  "Spotify"
  "spotube"
  "dev.alextren.Spot"
  "audacious"
  "Audacious"
  "org.gnome.Rhythmbox3"
  "strawberry"
  "org.gnome.Lollypop"
  "youtube-music"
  "com.github.th_ch.youtube_music"
  "GLava"
)

# Función para mover y enfocar una ventana al workspace special:music
move_to_music_workspace() {
  local window_class="$1"
  local addr=$(hyprctl clients -j | jq -r ".[] | select(.class == \"$window_class\") | .address")

  if [ -n "$addr" ]; then
    hyprctl dispatch movetoworkspacesilent special:music,address:"$addr"
    sleep 0.1 # Esperar a que el movimiento se complete
    hyprctl dispatch togglespecialworkspace music
    sleep 0.1 # Esperar a que el workspace se muestre
    hyprctl dispatch focuswindow address:"$addr"
    echo "[$(date '+%H:%M:%S')] ✓ Movido y enfocado $window_class ($addr) → special:music"
  fi
}

# Monitorear eventos de Hyprland
echo "[$(date '+%H:%M:%S')] 🎵 Iniciando monitor de apps de música..."

socat -u UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" - | while read -r line; do
  # Verificar si es un evento de ventana nueva
  if echo "$line" | grep -q "openwindow>>"; then
    # Extraer la clase de la ventana del evento
    # Formato: openwindow>>ADDRESS,WORKSPACE,CLASS,TITLE
    window_class=$(echo "$line" | cut -d',' -f3)
    window_title=$(echo "$line" | cut -d',' -f4-)

    # Flag para evitar procesar dos veces la misma ventana
    moved=false

    # Verificar si la clase está en la lista de apps de música
    for music_app in "${MUSIC_APPS[@]}"; do
      if [ "$window_class" = "$music_app" ]; then
        # Esperar a que la ventana termine de abrirse
        sleep 0.5
        move_to_music_workspace "$window_class"
        moved=true
        break
      fi
    done

    # Solo verificar por título si NO se movió ya por clase
    if [ "$moved" = false ]; then
      # Caso especial: kew corre en kitty, solo mover si el título ES kew
      if [ "$window_class" = "kitty" ] && echo "$window_title" | grep -qE "^kew$"; then
        sleep 0.3
        addr=$(hyprctl clients -j | jq -r '.[-1].address')
        if [ -n "$addr" ]; then
          hyprctl dispatch movetoworkspacesilent special:music,address:"$addr"
          sleep 0.1
          hyprctl dispatch togglespecialworkspace music
          sleep 0.1
          hyprctl dispatch focuswindow address:"$addr"
          echo "[$(date '+%H:%M:%S')] ✓ Movido y enfocado kew en kitty ($addr) → special:music"
        fi
      # Otros reproductores TUI (que NO sean kitty genérico)
      elif [ "$window_class" != "kitty" ] && echo "$window_title" | grep -qiE "(spotify|ncspot|cmus|ncmpcpp|musikcube|spotify.?player|spt|YouTube Music|youtube-music|youtube.?music|SoundCloud|cava|Spotube|Psst)"; then
        sleep 0.3
        addr=$(hyprctl clients -j | jq -r '.[-1].address')
        if [ -n "$addr" ]; then
          hyprctl dispatch movetoworkspacesilent special:music,address:"$addr"
          sleep 0.1
          hyprctl dispatch togglespecialworkspace music
          sleep 0.1
          hyprctl dispatch focuswindow address:"$addr"
          echo "[$(date '+%H:%M:%S')] ✓ Movido y enfocado por título: $window_title ($addr) → special:music"
        fi
      fi
    fi
  fi
done

##############################################
# === FIN [SPECIAL MUSIC WORKSPACE rules] ===
##############################################
