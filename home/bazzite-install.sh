#!/usr/bin/env bash
# Bazzite KDE - capa nativa y ajustes que requieren root.
# Uso: bash ~/bazzite-install.sh
# No lo ejecutes con sudo: el script pide sudo cuando lo necesita.

set -euo pipefail

if [ "${EUID}" -eq 0 ]; then
  echo "Ejecuta este script como tu usuario, NO con sudo:"
  echo "  bash ~/bazzite-install.sh"
  exit 1
fi

unset SUDO_ASKPASS SSH_ASKPASS

echo "== Bazzite: preparando permisos =="
sudo -v

echo
echo "== Deshabilitando updates-archive (404 en Fedora 45) =="
sudo install -d /etc/dnf/repos.override.d
sudo tee /etc/dnf/repos.override.d/99-disable-updates-archive.conf >/dev/null <<'CONF'
[updates-archive]
enabled=0
CONF

echo
echo "== Limpiando transacciones y metadatos =="
sudo rpm-ostree cleanup -p 2>/dev/null || true
sudo rpm-ostree cleanup -m 2>/dev/null || true

AVAIL_KB=$(df -Pk /var/home | awk 'NR==2 {print $4}')
AVAIL_GIB=$((AVAIL_KB / 1024 / 1024))
echo "Espacio libre en /var/home: ${AVAIL_GIB} GiB"

if [ "${AVAIL_KB}" -lt $((12 * 1024 * 1024)) ]; then
  echo
  echo "Hay menos de 12 GiB libres. El deployment de rollback ocupa espacio."
  read -r -p "¿Eliminar el rollback antiguo para liberar espacio? [S/n] " answer
  case "${answer:-S}" in
    s|S|y|Y) sudo rpm-ostree cleanup -r ;;
    *) echo "Sin espacio suficiente: se conserva el rollback y se aborta. Vuelve a ejecutar y elige S."; exit 1 ;;
  esac
fi

echo
echo "== Instalando capa nativa =="
# du-dust aporta el binario `dust` (Fedora no tiene un paquete llamado "dust")
sudo rpm-ostree install --idempotent \
  nemo nautilus thunar qt5ct qt6ct lxappearance rofi wofi bindfs xclip \
  waybar sassc ollama loupe ncdu du-dust antimicrox

# Paquetes opcionales (no en Fedora repos; requieren flatpak/brew/directo)
echo
echo "== Paquetes opcionales =="
if gum confirm "¿Instalar Antigravity CLI (agy)?"; then
  echo "Descargando instalador oficial de Google..."
  if curl -fsSL https://antigravity.google/cli/install.sh | bash; then
    echo "✓ agy instalado en ~/.local/bin/agy"
    echo "  Ejecuta 'source ~/.zshrc' o reinicia la terminal"
  else
    echo "⚠️  Falló; descarga manual desde https://antigravity.google/cli/"
  fi
fi

if gum confirm "¿Instalar OpenAI Codex (codex)?"; then
  if command -v npm >/dev/null; then
    npm install -g @openai/codex
  elif command -v pipx >/dev/null; then
    pipx install codex
  else
    echo "⚠️  Requiere npm o pipx; instala uno primero"
  fi
fi

if gum confirm "¿Instalar opencommit (oco) para commits con IA?"; then
  if command -v npm >/dev/null; then
    npm install -g opencommit
    echo "  ✓ opencommit instalado (usa 'oco' o 'opencommit')"
  else
    echo "⚠️  Requiere npm; instala npm primero"
  fi
fi

if gum confirm "¿Instalar PostgreSQL (incluye psql, pg_dump, pg_restore)?"; then
  rpm-ostree install --idempotent postgresql || echo "  ⚠️  Falló (¿espacio en disco?)"
  echo "  ⚠️  REQUERIDO: ejecuta 'systemctl reboot' para aplicar"
fi

# Neovim: Homebrew no genera .desktop en Linux; se crea a mano.
if [ -x /home/linuxbrew/.linuxbrew/bin/nvim ]; then
  echo
  echo "== Neovim: .desktop + icono =="
  mkdir -p "$HOME/.local/share/applications" "$HOME/.local/share/icons/hicolor/scalable/apps"
  cat > "$HOME/.local/share/applications/nvim.desktop" <<'DESKTOP'
[Desktop Entry]
Type=Application
Version=1.0
Name=Neovim
GenericName=Text Editor
Comment=Edit text files with Neovim
Keywords=nvim;vim;neovim;text;editor;code;
TryExec=/home/linuxbrew/.linuxbrew/bin/nvim
Exec=/home/diego/.local/bin/kitty --class nvim /home/linuxbrew/.linuxbrew/bin/nvim %F
Icon=nvim
Terminal=false
Categories=Utility;TextEditor;Development;
StartupNotify=true
MimeType=text/plain;
DESKTOP
  if [ ! -f "$HOME/.local/share/icons/hicolor/scalable/apps/nvim.svg" ]; then
    curl -fsSL 'https://cdn.simpleicons.org/neovim/57A143' \
      -o "$HOME/.local/share/icons/hicolor/scalable/apps/nvim.svg" || true
  fi
  gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
fi

# Flatpaks / AppImages opcionales
if command -v flatpak >/dev/null 2>&1; then
  echo
  echo "== Apps opcionales (Flatpak / AppImage) =="
  if gum confirm "¿Instalar Krita (flatpak)?"; then
    flatpak install -y flathub org.kde.krita
  fi

  if gum confirm "¿Instalar VLC (flatpak)?"; then
    flatpak install -y flathub org.videolan.VLC
  fi

  if gum confirm "¿Instalar Transmission (flatpak)?"; then
    flatpak install -y flathub com.transmissionbt.Transmission
  fi

  if gum confirm "¿Instalar Puddletag (flatpak)?"; then
    flatpak install -y flathub net.puddletag.puddletag
  fi

  if gum confirm "¿Instalar MegaSync / MEGA cloud (flatpak)?"; then
    flatpak install -y flathub com.tonikelope.MegaBasterd
    echo "  ✓ MegaBasterd (flatpak) instalado"
    echo "  Para gestión 'nativa' de MEGA: rpm-ostree install megasync-Fedora_45 (solo fuera de sesión Steam)"
  fi

  if gum confirm "¿Instalar Kew (terminal music player via cargo)?"; then
    echo "  Instalando Kew desde https://github.com/ravachol/kew.git ..."
    cargo install --git https://github.com/ravachol/kew.git --locked 2>/dev/null || \
    cargo install --git https://github.com/ravachol/kew.git
    echo "  ✓ Kew instalado en ~/.cargo/bin/kew"
  fi

  # =============================================================================
  # Wine (mínimo, para Wine Discord IPC Bridge + customrp en prefijo ~/.wine)
  # =============================================================================
  echo
  echo "== Wine =="
  echo "  Opciones en Bazzite (inmutable/Fedora):"
  echo "  1) wine (estándar Fedora, vía rpm-ostree) — RECOMENDADO para Bottles + ~/.wine"
  echo "  2) wine-staging (parches para juegos, vía rpm-ostree) — más riesgoso"
  echo "  3) Flatpak org.winehq.Wine — aislado, no se integra con ~/.wine ni Bottles"
  echo "  4) Runner soda de Bottles (fallback .NET 4.8 funcional sin reboot)"
  echo
  if gum confirm "¿Instalar wine (estándar Fedora) para Wine Discord IPC Bridge?"; then
    sudo rpm-ostree install --idempotent wine
    echo "  ✓ wine instalado (requiere reboot para aplicarse)"
  fi

  # Fallback: runner soda de Bottles (ya tiene .NET 4.8 funcional, sin reboot)
  if ! command -v wine &>/dev/null; then
    SODA_RUNNER="$HOME/.var/app/com.usebottles.bottles/data/bottles/runners/soda-11.0-10"
    if [ -x "$SODA_RUNNER/bin/wine" ]; then
      echo "  → wine del sistema no disponible; creando wrapper wine-soda (runner de Bottles)"
      cat > "$HOME/.local/bin/wine-soda" <<'WINE_SODA_EOF'
#!/bin/bash
# Wrapper para runner soda de Bottles (tiene .NET 4.8 funcional)
R="$HOME/.var/app/com.usebottles.bottles/data/bottles/runners/soda-11.0-10"
export LD_LIBRARY_PATH="$R/lib:$R/lib/wine/x86_64-unix:$R/lib/wine/i386-unix${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
exec "$R/bin/wine" "$@"
WINE_SODA_EOF
      chmod +x "$HOME/.local/bin/wine-soda"
      export PATH="$HOME/.local/bin:$PATH"
      echo "  ✓ wine-soda creado en ~/.local/bin/ (usa runner soda de Bottles)"
    fi
  fi

  if gum confirm "¿Instalar Bottles (para Wine Discord IPC Bridge en botella)?"; then
    flatpak install -y flathub com.usebottles.bottles
    echo "  ✓ Bottles instalado"
  fi

  # =============================================================================
  # Discord nativo vía RPM Fusion (sin sandbox → /run/user/1000/discord-ipc-0 accesible)
  # Mantiene el patrón de NixOS: paquete nativo, no Flatpak. Los puentes rpc-bridge
  # / wine-discord-ipc-bridge funcionan sin override adicional.
  #
  # SECUENCIA CRÍTICA en Bazzite inmutable:
  #  1) Instalar .rpm de RPM Fusion (staging)
  #  2) REBOOT (obligatorio: activa el deployment y los repos)
  #  3) rpm-ostree install discord (ya ve los repos activos)
  #  4) REBOOT (aplica el layer de discord)
  #
  # dnf5 install NO funciona: /usr es de solo lectura en ostree.
  # =============================================================================
  echo
  echo "== Discord: instalación nativa vía RPM Fusion =="
  if ! rpm -q rpmfusion-free-release >/dev/null 2>&1 || ! rpm -q rpmfusion-nonfree-release >/dev/null 2>&1; then
    echo "  Instalando repos RPM Fusion free + nonfree (staging)…"
    rpm-ostree install --idempotent \
      "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
      "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm" \
      || { echo "  ⚠️  No se pudieron agregar los repos RPM Fusion; saltando Discord"; }
    echo "  ⚠️  REQUERIDO: ejecuta 'systemctl reboot' para activar el deployment de RPM Fusion."
    echo "     Luego ejecuta de nuevo bazzite-install.sh para completar con 'rpm-ostree install discord'."
  else
    echo "  Repos RPM Fusion ya activos. Instalando discord…"
    rpm-ostree install --idempotent discord \
      || { echo "  ⚠️  discord no se pudo instalar"; }
    echo "  ✓ Discord nativo instalado — rpc-bridge / wine-discord-ipc-bridge funcionan sin override"

    # HITO: finalizar el deployment AHORA (no esperar al apagado).
    # En Bazzite, el staged solo se finaliza al apagar; si el apagado no es
    # limpio (reset duro) o falla, el deployment se pierde y GRUB no lo ve.
    # `ostree admin finalize-staged` es el comando correcto (NO existe
    # `ostree-finalize-staged`): crea la entrada BLS, apunta el bootloader
    # al deployment nuevo y lo deja "pending".
    #
    # OJO: al finalizar se reescribe el bootloader y se BORRA
    # /boot/loader/entries/zz-bazzite-desktop.conf; por eso la entrada
    # "Bazzite Desktop" se crea DESPUÉS (sección GRUB más abajo del script).
    if gum confirm "¿Finalizar el deployment de Discord ahora (sin esperar al apagado)?"; then
      sudo ostree admin finalize-staged \
        || echo "  ⚠️  finalize-staged falló; se finalizará solo al apagar (apagado LIMPIO obligatorio)"
      ostree admin status 2>/dev/null | head -3
    fi
    echo "  ⚠️  REQUERIDO: ejecuta 'systemctl reboot' para arrancar el deployment con discord."
    echo "     Si no reinicias, discord NO aparece (rpm-ostree está idle/pending)."
  fi

  # =============================================================================
  # Discord IPC Bridge .exe (0e4ef622 / enderice2) — descargar si no están en Descargas
  # =============================================================================
  echo
  echo "== Discord IPC Bridge .exe =="

  # --- Descargar winediscordipcbridge.exe desde 0e4ef622/wine-discord-ipc-bridge ---
  if [ ! -f "$HOME/Descargas/winediscordipcbridge.exe" ]; then
    echo "  Descargando winediscordipcbridge.exe desde https://github.com/0e4ef622/wine-discord-ipc-bridge ..."
    DL_URL=$(curl -s "https://api.github.com/repos/0e4ef622/wine-discord-ipc-bridge/releases/latest" \
      | grep "browser_download_url.*winediscordipcbridge\.exe" \
      | head -1 | cut -d '"' -f 4)
    if [ -n "$DL_URL" ]; then
      mkdir -p "$HOME/Descargas"
      curl -sL -o "$HOME/Descargas/winediscordipcbridge.exe" "$DL_URL"
      echo "  ✓ Descargado winediscordipcbridge.exe"
    else
      echo "  ⚠️  No se encontró el asset en GitHub releases"
    fi
  fi

  # --- Descargar bridge.exe desde enderice2/rpc-bridge ---
  if [ ! -f "$HOME/Descargas/bridge/bridge.exe" ]; then
    echo "  Descargando bridge.exe desde https://github.com/enderice2/rpc-bridge ..."
    DL_URL=$(curl -s "https://api.github.com/repos/enderice2/rpc-bridge/releases/latest" \
      | grep "browser_download_url.*bridge\.exe" \
      | head -1 | cut -d '"' -f 4)
    if [ -n "$DL_URL" ]; then
      mkdir -p "$HOME/Descargas/bridge"
      curl -sL -o "$HOME/Descargas/bridge/bridge.exe" "$DL_URL"
      echo "  ✓ Descargado bridge.exe"
    else
      echo "  ⚠️  No se encontró el asset en GitHub releases"
    fi
  fi

  # --- Copiar a ~/.local/bin y prefijos ---
  if [ -f "$HOME/Descargas/winediscordipcbridge.exe" ]; then
    cp "$HOME/Descargas/winediscordipcbridge.exe" "$HOME/.local/bin/winediscordipcbridge.exe"
    chmod +x "$HOME/.local/bin/winediscordipcbridge.exe"
    echo "  ✓ winediscordipcbridge.exe -> ~/.local/bin/"
  else
    echo "  ⚠️  winediscordipcbridge.exe no disponible"
  fi

  if [ -f "$HOME/Descargas/bridge/bridge.exe" ]; then
    cp "$HOME/Descargas/bridge/bridge.exe" "$HOME/.local/bin/bridge.exe"
    chmod +x "$HOME/.local/bin/bridge.exe"
    echo "  ✓ bridge.exe -> ~/.local/bin/"
  else
    echo "  ⚠️  bridge.exe no disponible"
  fi

  # Prefijo Wine nativo ~/.wine — config mínima completa:
  #   wineboot (si falta el prefijo) + winediscordipcbridge.exe + bridge.exe
  #   + lanzadores .desktop con icono propio (Wine y Bottles).
  echo
  echo "  -- Config del prefijo ~/.wine (wine-discord-ipc-bridge) --"
  if [ -f "$HOME/dotfiles-dizzi/home/scripts/setup-wine-discord-bridge.sh" ]; then
    bash "$HOME/dotfiles-dizzi/home/scripts/setup-wine-discord-bridge.sh" \
      || echo "  ⚠️  setup-wine-discord-bridge.sh falló (¿wine instalado?)"
  else
    echo "  ⚠️  No existe home/scripts/setup-wine-discord-bridge.sh"
  fi

  # Botella gaming de Bottles (si existe)
  BOTTLES_BASE=""
  for dir in \
    "$HOME/.var/app/com.usebottles.bottles/data/bottles/bottles" \
    "$HOME/.local/share/bottles/bottles" \
    "$HOME/.local/bottles"; do
    if [ -d "$dir/gaming/drive_c" ]; then
      BOTTLES_BASE="$dir"
      break
    fi
  done
  if [ -n "$BOTTLES_BASE" ]; then
    TARGET="$BOTTLES_BASE/gaming/drive_c/windows/system32/discord"
    mkdir -p "$TARGET"
    if [ -f "$HOME/.local/bin/winediscordipcbridge.exe" ]; then
      cp "$HOME/.local/bin/winediscordipcbridge.exe" "$TARGET/winediscordipcbridge.exe"
      echo "  ✓ winediscordipcbridge.exe -> Bottles gaming"
    fi
    if [ -f "$HOME/.local/bin/bridge.exe" ]; then
      cp "$HOME/.local/bin/bridge.exe" "$TARGET/bridge.exe"
      echo "  ✓ bridge.exe -> Bottles gaming"
    fi
  else
    echo "  ℹ️  Botella gaming de Bottles no encontrada (se creará al primer lanzamiento)"
  fi

  echo "  ✓ Discord IPC Bridge .exe instalados (rutas listas para los scripts .desktop)"

  if gum confirm "¿Instalar YouTube Music (Pear Desktop, AppImage)?"; then
    mkdir -p "$HOME/opt"
    ( cd "$HOME/opt" && gh release download -R pear-devs/pear-desktop --pattern 'YouTube-Music-*.AppImage' --clobber )
    chmod u+x "$HOME"/opt/YouTube-Music-*.AppImage
    ln -sfn "$(ls -1 "$HOME"/opt/YouTube-Music-*.AppImage | head -1)" "$HOME/.local/bin/youtube-music"
    cat > "$HOME/.local/share/applications/youtube-music.desktop" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=YouTube Music
Comment=YouTube Music desktop app (Pear Desktop)
Exec=/home/diego/.local/bin/youtube-music %U
Icon=multimedia-audio-player
Terminal=false
Categories=AudioVideo;Audio;Player;
StartupWMClass=YouTube Music
DESKTOP
  fi

  if gum confirm "¿Instalar Ghostty (AppImage, sin layering)?"; then
    mkdir -p "$HOME/opt"
    ( cd "$HOME/opt" && gh release download -R pkgforge-dev/ghostty-appimage --pattern '*x86_64*.AppImage' --clobber )
    chmod u+x "$HOME"/opt/Ghostty-*.AppImage
    ln -sfn "$(ls -1 "$HOME"/opt/Ghostty-*.AppImage | head -1)" "$HOME/.local/bin/ghostty"
    cat > "$HOME/.local/share/applications/ghostty.desktop" <<'DESKTOP'
[Desktop Entry]
Name=Ghostty
Exec=/home/diego/.local/bin/ghostty
Type=Application
Icon=utilities-terminal
Categories=System;TerminalEmulator;
Terminal=false
DESKTOP
  fi
fi

# =============================================================================
# GRUB — entrada "Bazzite Desktop (Plasma)"
# Crea una entrada BLS que usa el deployment arrancado actualmente (leído de
# /proc/cmdline) añadiendo bazzite.session=desktop, más el helper/servicio que
# ajusta el autologin de SDDM a Plasma. Idempotente: el script se puede repetir.
# =============================================================================
echo
echo "== GRUB: entrada 'Bazzite Desktop (Plasma)' =="
GRUB_DESKTOP="$HOME/dotfiles-dizzi/home/scripts/bazzite-desktop-boot-entry.sh"
if [ -f "$GRUB_DESKTOP" ]; then
  sudo bash "$GRUB_DESKTOP" || echo "  ⚠️  No se pudo crear la entrada Desktop (¿deployment sin entrada BLS?)"
else
  echo "  ⚠️  No existe $GRUB_DESKTOP; se omite la entrada Desktop."
fi

# =============================================================================
# Espanso Wayland nativo (build .deb oficial v2.4.1, sin compilar en host)
#
# Por qué así:
#  - El espanso del repo es build X11: en Wayland solo copia al portapapeles.
#  - KWin NO soporta zwp_virtual_keyboard_v1 → wtype no sirve para inyectar.
#  - El inyector EVDEV no mapea acentos (teclas muertas) → backend Clipboard.
#  - keyboard_layout debe ser el REAL del sistema (aquí us, NO es; el locale
#    LANG=es_ES no implica layout es). Con es, Espanso no detecta ''a.
# =============================================================================
echo
echo "== Espanso Wayland nativo =="
ESPANSO_CONFIG="$HOME/.config/espanso/config/default.yml"
if [ -x "$HOME/.local/bin/espanso-wayland" ] && \
   [ -f "$HOME/.config/systemd/user/espanso.service" ] && \
   grep -q '^backend: Clipboard' "$ESPANSO_CONFIG" 2>/dev/null && \
   grep -q '^  layout: us' "$ESPANSO_CONFIG" 2>/dev/null; then
  echo "  ✓ Espanso Wayland ya instalado y configurado"
  systemctl --user enable --now espanso.service 2>/dev/null || true
else
  WORKDIR=$(mktemp -d)
  ESPANSO_DL=0
  # El subshell hereda `set -e`: cualquier fallo de descarga/extracción lo aborta
  # sin tumbar el resto del instalador.
  if (
    cd "$WORKDIR"
    echo "  Descargando espanso Wayland v2.4.1 (.deb oficial)…"
    curl -fsSL -o espanso-wayland.deb \
      "https://github.com/espanso/espanso/releases/download/v2.4.1/espanso-debian-wayland-amd64.deb"
    mkdir -p ext && cd ext && ar x ../espanso-wayland.deb
    for f in data.tar.*; do tar xf "$f"; done

    # Libs wxGTK3.2 empaquetadas en ~/.local/lib/espanso-wayland
    LIBDIR="$HOME/.local/lib/espanso-wayland"
    mkdir -p "$LIBDIR"
    find usr/lib -name 'libwx_*.so.*' -exec cp -t "$LIBDIR" {} +

    # Binario Wayland
    mkdir -p "$HOME/.local/bin"
    cp usr/bin/espanso "$HOME/.local/bin/espanso-wayland"
    chmod +x "$HOME/.local/bin/espanso-wayland"
  ); then
    ESPANSO_DL=1
  fi
  rm -rf "$WORKDIR"

  if [ "$ESPANSO_DL" -eq 1 ]; then
  # wtype (solo hace falta si se usa backend Inject; el setup usa Clipboard)
  if [ ! -x "$HOME/.local/bin/wtype" ] && command -v dnf5 >/dev/null 2>&1; then
    mkdir -p /tmp/espanso-deps
    ( dnf5 download --destdir /tmp/espanso-deps wtype >/dev/null 2>&1 || true )
    if ls /tmp/espanso-deps/wtype-*.rpm >/dev/null 2>&1; then
      ( cd /tmp/espanso-deps && rpm2cpio wtype-*.rpm | cpio -idm >/dev/null 2>&1 || true )
      [ -f /tmp/espanso-deps/usr/bin/wtype ] && \
        cp /tmp/espanso-deps/usr/bin/wtype "$HOME/.local/bin/wtype" && \
        chmod +x "$HOME/.local/bin/wtype"
    fi
    rm -rf /tmp/espanso-deps
  fi

  # Wrapper: el binario Wayland necesita sus libs locales
  cat > "$HOME/.local/bin/espanso" <<'ESP_WRAPPER_EOF'
#!/bin/sh
ESPANSO_LIB="$HOME/.local/lib/espanso-wayland"
export LD_LIBRARY_PATH="$ESPANSO_LIB${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export PATH="$HOME/.local/bin:$PATH"
exec "$HOME/.local/bin/espanso-wayland" "$@"
ESP_WRAPPER_EOF
  chmod +x "$HOME/.local/bin/espanso"

  # Servicio systemd user (Wayland nativo)
  mkdir -p "$HOME/.config/systemd/user"
  cat > "$HOME/.config/systemd/user/espanso.service" <<'ESP_SERVICE_EOF'
[Unit]
Description=espanso text expander (Wayland nativo)
After=graphical-session.target
PartOf=graphical-session.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=%h/.local/bin/espanso service start --unmanaged
ExecStop=%h/.local/bin/espanso service stop
Restart=on-failure
RestartSec=3

[Install]
WantedBy=default.target
ESP_SERVICE_EOF

  # Config: layout REAL del sistema (us) + backend Clipboard para no-ASCII
  mkdir -p "$HOME/.config/espanso/config"
  cat > "$ESPANSO_CONFIG" <<'ESP_CONFIG_EOF'
# Espanso config — Bazzite Wayland
toggle_key: OFF
keyboard_layout:
  layout: us
  variant: ""
backend: Clipboard
ESP_CONFIG_EOF

  # Matches de acentos (ASCII directo, no-ASCII vía wl-copy + Shift+Insert)
  mkdir -p "$HOME/.config/espanso/match"
  cat > "$HOME/.config/espanso/match/base.yml" <<'ESP_MATCHES_EOF'
matches:
  - trigger: "''a"
    replace: "á"
    propagate_case: true
  - trigger: "''e"
    replace: "é"
    propagate_case: true
  - trigger: "''i"
    replace: "í"
    propagate_case: true
  - trigger: "''o"
    replace: "ó"
    propagate_case: true
  - trigger: "''u"
    replace: "ú"
    propagate_case: true
  - trigger: '""a'
    replace: "ä"
    propagate_case: true
  - trigger: '""e'
    replace: "ë"
    propagate_case: true
  - trigger: '""i'
    replace: "ï"
    propagate_case: true
  - trigger: '""o'
    replace: "ö"
    propagate_case: true
  - trigger: '""u'
    replace: "ü"
    propagate_case: true
  - trigger: "''n"
    replace: "ñ"
    propagate_case: true
  - triggers: ["''s", '""s']
    replace: "ß"
  - triggers: ["''?", '""?']
    replace: "¿"
  - triggers: ["''!", '""!']
    replace: "¡"
ESP_MATCHES_EOF

  # Silenciar el aviso "EVDEV backend without capabilities"
  sudo setcap cap_dac_override+p "$HOME/.local/bin/espanso-wayland" 2>/dev/null || true

  systemctl --user daemon-reload
  systemctl --user enable --now espanso.service 2>/dev/null || true
  echo "  ✓ Espanso Wayland nativo instalado y activado (espanso log para verificar)"
  fi  # fi para if [ "$ESPANSO_DL" -eq 1 ]
fi  # fi para if [ ... ] (línea 338)

# =============================================================================
# Mouse zurdo global (udev, sin input-remapper)
# LIBINPUT_CALIBRATION_MATRIX invierte X/Y a nivel libinput: aplica en Plasma,
# en SteamOS/Game Mode y en TTY, sin daemon ni servicio extra.
# =============================================================================
echo
echo "== Mouse zurdo global (udev) =="
LEFTY_RULE=/etc/udev/rules.d/99-mouse-lefty.rules
if [ -f "$LEFTY_RULE" ] && grep -q 'Compx 2.4G Wireless Receiver Mouse' "$LEFTY_RULE"; then
  echo "  ✓ Regla udev del mouse zurdo ya existe"
else
  sudo tee "$LEFTY_RULE" >/dev/null <<'UDEV_EOF'
ACTION=="add|change", SUBSYSTEM=="input", ATTRS{name}=="Compx 2.4G Wireless Receiver Mouse", \
  ENV{LIBINPUT_CALIBRATION_MATRIX}="-1 0 1 0 -1 1 0 0 1"
UDEV_EOF
  echo "  ✓ Regla udev creada: $LEFTY_RULE"
fi
sudo udevadm control --reload
sudo udevadm trigger

# input-remapper puede reescribir el mouse: deshabilitarlo (config se conserva)
systemctl --user disable --now input-remapper.service 2>/dev/null || true
sudo systemctl disable --now input-remapper.service 2>/dev/null || true
echo "  ✓ input-remapper deshabilitado (config conservada en ~/.config/input-remapper-2)"

# swaync v0.10.1 (no está en repos Fedora 45): build en distrobox + libs empaquetadas.
if [ ! -x "$HOME/.local/bin/swaync" ] && command -v distrobox >/dev/null 2>&1; then
  if gum confirm "¿Compilar swaync v0.10.1 en distrobox 'build'?"; then
    if [ ! -d "$HOME/build-swaync" ]; then
      git clone --depth 1 --branch v0.10.1 \
        https://github.com/ErikReider/SwayNotificationCenter.git "$HOME/build-swaync"
    fi
    distrobox enter build -- bash -lc 'sudo dnf install -y vala meson sassc gtk3-devel gtk-layer-shell-devel libgee-devel json-glib-devel libhandy-devel granite-devel scdoc gobject-introspection-devel pulseaudio-libs-devel && cd ~/build-swaync && rm -rf build && meson setup build --prefix=$HOME/.local -Dsystemd-service=false -Dman-pages=false -Dzsh-completions=false -Dbash-completions=false -Dfish-completions=false && ninja -C build && ninja -C build install'
    mkdir -p "$HOME/.local/lib/swaync"
    distrobox enter build -- bash -lc \
      'cp -a /usr/lib64/libgranite.so.6* /usr/lib64/libgee-0.8.so.2* ~/.local/lib/swaync/'
    if [ -x "$HOME/.local/bin/swaync" ] && [ ! -e "$HOME/.local/bin/swaync.real" ]; then
      mv -f "$HOME/.local/bin/swaync" "$HOME/.local/bin/swaync.real"
      printf '%s\n' \
        '#!/bin/sh' \
        'export LD_LIBRARY_PATH="$HOME/.local/lib/swaync${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"' \
        'exec "$HOME/.local/bin/swaync.real" "$@"' > "$HOME/.local/bin/swaync"
      chmod +x "$HOME/.local/bin/swaync"
    fi
  fi
fi


echo
echo "== Vicinae: permisos de entrada =="
VICINAE_INPUT="$HOME/.local/lib/vicinae/usr/libexec/vicinae/vicinae-input-server"
if [ -x "$VICINAE_INPUT" ]; then
  sudo setcap cap_dac_override=ep "$VICINAE_INPUT" || true
  echo uinput | sudo tee /etc/modules-load.d/vicinae-uinput.conf >/dev/null
  sudo modprobe uinput 2>/dev/null || true
  echo "Vicinae input server preparado."
fi

# Extensiones de Vicinae (equivalente declarativo al módulo de NixOS:
# bundles reales en ~/.local/share/vicinae/extensions/<id>).
# La lógica vive en ~/scripts/vicinae-ext-install y el manifiesto en
# ~/.config/vicinae/extensions.list (ambos stowed desde el repo).
install_vicinae_extensions() {
  local helper="$HOME/scripts/vicinae-ext-install"
  if [ ! -f "$helper" ]; then
    echo "  Sin helper vicinae-ext-install: se omiten extensiones."
    return 0
  fi
  chmod +x "$helper" 2>/dev/null || true
  bash "$helper" --sync || true
}


echo
echo "== Vicinae: extensiones =="
install_vicinae_extensions


echo
echo "== GRUB desde tu config =="
GRUB_SRC="$HOME/dotfiles-dizzi/etc/default/grub"
if [ -f "$GRUB_SRC" ]; then
  TMP="$(mktemp)"
  sed -e 's|GRUB_DISTRIBUTOR="Arch"|GRUB_DISTRIBUTOR="Bazzite"|'       -e '/^GRUB_CMDLINE_LINUX=/d'       -e '/^GRUB_CMDLINE_LINUX_DEFAULT=/d' "$GRUB_SRC" > "$TMP"
  if sudo test -f /boot/grub2/themes/minegrub/theme.txt; then
    sed -i 's|^GRUB_THEME=.*|GRUB_THEME=/boot/grub2/themes/minegrub/theme.txt|' "$TMP"
  else
    echo "Instalando tema minegrub..."
    TMPDIR="$(mktemp -d)"
    git clone --depth 1 https://github.com/Lxtharia/minegrub-theme.git "$TMPDIR/minegrub-theme"
    git clone --depth 1 https://github.com/Lxtharia/minegrub-world-selection.git "$TMPDIR/minegrub-world-selection"
    sudo mkdir -p /boot/grub2/themes
    sudo cp -r "$TMPDIR/minegrub-theme/minegrub" /boot/grub2/themes/
    sudo cp -r "$TMPDIR/minegrub-world-selection/minegrub-world-selection" /boot/grub2/themes/
    rm -rf "$TMPDIR"
    sed -i 's|^GRUB_THEME=.*|GRUB_THEME=/boot/grub2/themes/minegrub/theme.txt|' "$TMP"
  fi
  sudo cp -a /etc/default/grub "/etc/default/grub.bak.$(date +%s)" 2>/dev/null || true
  sudo install -m 0644 "$TMP" /etc/default/grub
  rm -f "$TMP"
  sudo bash -c 'source /usr/libexec/bazzite-boot-remount; remount_boot_rw; if [ -d /sys/firmware/efi ]; then grub2-mkconfig -o /etc/grub2-efi.cfg; else grub2-mkconfig -o /etc/grub2.cfg; fi; remount_boot_ro'
else
  echo "No existe $GRUB_SRC; salto GRUB."
fi

echo
echo "== Configurando zsh como login shell =="
ZSH_BIN=/home/linuxbrew/.linuxbrew/bin/zsh
if [ -x "${ZSH_BIN}" ]; then
  sudo sh -c "grep -qxF '${ZSH_BIN}' /etc/shells || echo '${ZSH_BIN}' >> /etc/shells"
  sudo usermod -s "${ZSH_BIN}" "${USER}"
  echo "Login shell: ${ZSH_BIN}"
else
  echo "ADVERTENCIA: ${ZSH_BIN} no existe; no cambio el login shell."
fi

echo
echo "== Estado final =="
sudo rpm-ostree status
echo
echo "Hitos aplicados:"
echo "  • Capa nativa: nemo/nautilus/thunar/ollama/loupe/ncdu/dust(du-dust)/wine"
echo "  • Discord nativo (RPM Fusion) staged/finalizado"
echo "  • Entrada GRUB 'Bazzite Desktop (Plasma)' (usa el deployment que va a arrancar)"
echo "  • Espanso Wayland nativo (layout us, backend Clipboard)"
echo "  • Mouse zurdo global por udev (input-remapper solo deshabilitado)"
echo "  • Wine Discord IPC Bridge: prefijo ~/.wine + .desktop con icono"
echo
echo "Capa nativa preparada. Reinicia para aplicarla:"
echo "  systemctl reboot"
echo
echo "Después del reboot verifica:"
echo "  ostree admin status | head -3      # el deployment nuevo debe ser '*'"
echo "  which discord && discord --version"
echo "  dust --version && ncdu --version && loupe --version"
echo "  bash ~/scripts/setup-wine-discord-bridge.sh        # inicializa ~/.wine con wine"
echo "  sudo bash ~/scripts/bazzite-desktop-boot-entry.sh   # recrear entrada Desktop"
echo "  grep -E '^title|^options' /boot/loader/entries/zz-bazzite-desktop.conf"

echo
echo "== Opcional: Rebase a bazzite-deck-nvidia =="
echo "  La imagen deck arranca en Gamescope (modo consola)."
echo "  En laptops híbridas (Intel + NVIDIA) puede dar problemas."
echo "  Para solo jugar Steam, basta con Steam en Plasma + gamemoderun."
echo
echo "  REVERSIBLE: sí, con otro rebase:"
echo "    rpm-ostree rebase ostree-image-signed:docker://ghcr.io/ublue-os/bazzite-nvidia:stable"
echo
read -r -p "¿Hacer rebase a bazzite-deck-nvidia? [s/N] " ans
case "${ans:-N}" in
  s|S)
    echo "Rebasing a bazzite-deck-nvidia..."
    rpm-ostree rebase ostree-image-signed:docker://ghcr.io/ublue-os/bazzite-deck-nvidia:stable
    echo "Rebase listo. Reinicia para aplicar."
    ;;
  *)
    echo "Se omite el rebase. Te quedas en bazzite-nvidia."
    ;;
esac

echo
echo "Capa nativa preparada. Reinicia para aplicarla:"
echo "  systemctl reboot"

echo
echo "== Secure Boot check =="
if command -v mokutil >/dev/null; then
  mokutil --sb-state
  if mokutil --sb-state | grep -q "enabled"; then
    echo "✅ Secure Boot: ACTIVADO"
  else
    echo "⚠️  Secure Boot: DESACTIVADO"
    if mokutil --list-new 2>/dev/null | grep -q .; then
      echo "   → Hay claves pendientes de enrolar en MOKManager al próximo reinicio"
      echo "   → En MOKManager: Enroll MOK → Continue → universalblue"
    fi
  fi
fi

echo
echo "== Stow de dotfiles =="
if command -v stow >/dev/null 2>&1; then
  cd "$HOME/dotfiles-dizzi"
  # TODOS los paquetes stow (98 paquetes) - solo los que existan
  for pkg in \
    zsh starship kitty ghostty fastfetch bottom htop tmux yazi kew nvim \
    qt5ct qt6ct mime fish dolphin-files global-keyboard-shortcutsrc \
    cursor Raycast-vicinae thunar rofi wofi \
    waybar swaync eww dunst wal sattyScreenshots fonts font icons \
    codex vscode antimicrox assets autostart caelestia cinnamon \
    easyeffects espanso fuzzel-glyphs-rofimoji ghostty \
    htop hypr ibus input-remapper kdenlive-compressor-editor kew \
    mcphub neofetch networkmanager-fuzzel niri nwg-gtk-3.0 nwg-gtk-4.0 \
    peazip pipewire polybar qtile quickshell sattyScreenshots \
    starship sunshine systemd television tmux wal wallpapers \
    wireplumber wofi yazi zellij zsh \
    Raycast-vicinae dolphin-files global-keyboard-shortcutsrc \
    opencode mcphub bottom fastfetch fonts font \
    nvim qt5ct qt6ct mime fish thunar rofi wofi \
    waybar swaync eww dunst wal sattyScreenshots icons \
    codex vscode autostart caelestia \
    easyeffects espanso fuzzel-glyphs-rofimoji \
    htop ibus kdenlive-compressor-editor mcphub \
    neofetch networkmanager-fuzzel niri nwg-gtk-3.0 nwg-gtk-4.0 \
    peazip pipewire polybar qtile quickshell \
    starship sunshine systemd television tmux \
    wal wallpapers wireplumber yazi zellij \
    Antigravity antimicrox assets autostart \
    kitty ghostty global-keyboard-shortcutsrc \
    local manual-ln mcphub mime \
    nixconf opencode peazip pipewire \
    polybar quickshell sattyScreenshots \
    sunshine television vscode wal wallpapers \
    waybar wireplumber zellij \
    codex --no-folding
  do
    if [[ -d "$pkg" ]]; then
      echo "  Stow: $pkg"
      stow -t "$HOME" --restow "$pkg" 2>/dev/null || true
    fi
  done
  # codex necesita --no-folding
  if [[ -d "codex" ]]; then
    stow -t "$HOME" --restow --no-folding codex 2>/dev/null || true
  fi
  # opencode ignora service.json
  if [[ -d "opencode" ]]; then
    stow -t "$HOME" --restow --ignore='service.json' opencode 2>/dev/null || true
  fi

  # `local` contiene estado de la máquina (binarios, Lutris, Steam, .desktop...).
  # --adopt incorpora lo que ya exista al repo en vez de abortar por conflictos.
  if [ -d "$HOME/dotfiles-dizzi/local" ]; then
    echo "== Stow local (--adopt) =="
    BACKUP="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP"
    cp -a "$HOME/dotfiles-dizzi/local" "$BACKUP/local-pre-adopt" 2>/dev/null || true

    # Los symlinks absolutos que ya apuntan al repo hacen que stow intente
    # mover un enlace dentro de sí mismo. Se eliminan; stow los recreará.
    REPO_REAL=$(readlink -f "$HOME/dotfiles-dizzi")
    find "$HOME/.local" -maxdepth 4 -type l 2>/dev/null | while IFS= read -r link; do
      target=$(readlink -f "$link" 2>/dev/null) || continue
      case "$target" in
        "$REPO_REAL"/local/*) rm -f "$link" ;;
      esac
    done
    stow -t "$HOME" --adopt local || true
  fi
fi
ln -sfn "$HOME/dotfiles-dizzi/home/scripts" "$HOME/scripts"

# opencode: symlink en ~/.local/bin (el binario oficial instala en ~/.opencode/bin/)
if [ -x "$HOME/.opencode/bin/opencode" ] && [ ! -e "$HOME/.local/bin/opencode" ]; then
  ln -sf "$HOME/.opencode/bin/opencode" "$HOME/.local/bin/opencode"
  echo "✓ opencode symlink creado en ~/.local/bin/opencode"
fi

# Refrescar la caché de aplicaciones de KDE (Flatpak + .desktop recién stoweados).
if command -v kbuildsycoca6 >/dev/null 2>&1; then
  kbuildsycoca6 --noincremental >/dev/null 2>&1 || true
fi

# Zen Browser: fix Alt+D (Open Location) — bug #15822 / customKeys.json roto
# El perfil por defecto suele tener focusURLBar2 en Alt+L y openFileKb en Ctrl+L,
# rompiendo Alt+D y Ctrl+L estándar. Restaurar defaults dejando solo focusURLBar en Alt+S si se quiere.
ZEN_PROFILE="$HOME/.var/app/app.zen_browser.zen/.zen"
if [ -d "$ZEN_PROFILE" ]; then
  # Buscar el perfil "Default (release)" real
  DEFAULT_PROFILE=$(find "$ZEN_PROFILE" -maxdepth 1 -type d -name '*Default*' | head -1)
  if [ -n "$DEFAULT_PROFILE" ] && [ -f "$DEFAULT_PROFILE/customKeys.json" ]; then
    echo "== Zen Browser: fix Alt+D =="
    cp "$DEFAULT_PROFILE/customKeys.json" "$DEFAULT_PROFILE/customKeys.json.bak.$(date +%s)" 2>/dev/null || true
    # Dejar solo focusURLBar en Alt+S (workaround del usuario), borrar focusURLBar2 y openFileKb
    echo '{"focusURLBar":{"modifiers":"alt","key":"S"}}' > "$DEFAULT_PROFILE/customKeys.json"
    echo "  customKeys.json restaurado (backup en .bak)"
  fi
fi

# =============================================================================
# Systemd User Services — registrar/activar servicios user
# =============================================================================
create_systemd_user_service() {
  local name="$1"
  local exec_start="$2"
  local description="${3:-$name}"
  local wanted_by="${4:-default.target}"
  local service_dir="$HOME/.config/systemd/user"
  local service_file="$service_dir/$name.service"

  mkdir -p "$service_dir"
  cat > "$service_file" <<EOF
[Unit]
Description=$description
# Solo en sesión Plasma/KDE: evita el bucle de reinicios en Steam Game Mode
ConditionEnvironment=XDG_CURRENT_DESKTOP=KDE

[Service]
ExecStart=$exec_start
Restart=on-failure
RestartSec=3

[Install]
WantedBy=$wanted_by
EOF
  systemctl --user daemon-reload
  systemctl --user enable --now "$name.service" 2>/dev/null || true
  echo "  ✓ $name.service creado y activado"
}

echo
echo "== Systemd User Services =="

# espanso (ya tiene service register, pero nos aseguramos)
if command -v espanso >/dev/null 2>&1; then
  if [ ! -f "$HOME/.config/systemd/user/espanso.service" ]; then
    create_systemd_user_service "espanso" "$HOME/.local/bin/espanso launcher" "espanso text expander"
  else
    systemctl --user enable --now espanso.service 2>/dev/null || true
    echo "  ✓ espanso.service ya existe, activado"
  fi
fi

# eww daemon
if [ -x "$HOME/.local/bin/eww" ]; then
  create_systemd_user_service "eww-daemon" "$HOME/.local/bin/eww daemon" "Eww daemon (widgets)"
fi

# swaync (usa wrapper con LD_LIBRARY_PATH)
if [ -x "$HOME/.local/bin/swaync" ]; then
  create_systemd_user_service "swaync" "$HOME/.local/bin/swaync" "Sway Notification Center"
fi

# waybar (instalado vía rpm-ostree)
if command -v waybar >/dev/null 2>&1; then
  create_systemd_user_service "waybar" "/usr/bin/waybar" "Waybar status bar"
fi

# quickshell (opcional, flatpak/rpm-ostree)
if command -v quickshell >/dev/null 2>&1; then
  create_systemd_user_service "quickshell" "/usr/bin/quickshell" "Quickshell desktop widgets"
fi

# =============================================================================
# GTK Themes — Colloid-Pink-Dark + Gruvbox-Plus-Dark + Kafka cursor
# =============================================================================
echo
echo "== GTK Themes =="
if gum confirm "¿Instalar temas GTK (Colloid-Pink-Dark, Gruvbox-Plus-Dark, Kafka cursor)?"; then
  # Colloid theme
  if [ ! -d "/usr/share/themes/Colloid-Pink-Dark" ] && [ ! -d "$HOME/.local/share/themes/Colloid-Pink-Dark" ] && [ ! -d "$HOME/.themes/Colloid-Pink-Dark" ]; then
    echo "  Instalando Colloid-Pink-Dark..."
    TMPDIR=$(mktemp -d)
    git clone --depth 1 https://github.com/vinceliuice/Colloid-gtk-theme.git "$TMPDIR/Colloid"
    "$TMPDIR/Colloid/install.sh" -c pink -t dark --dest "$HOME/.local/share/themes" 2>/dev/null || \
    "$TMPDIR/Colloid/install.sh" -c pink -t dark --dest "$HOME/.themes" 2>/dev/null || true
    rm -rf "$TMPDIR"
  else
    echo "  ✓ Colloid-Pink-Dark ya instalado"
  fi

  # Gruvbox-Plus-Dark icons (desde SylEleuth/gruvbox-plus-icon-pack)
  if [ ! -d "/usr/share/icons/Gruvbox-Plus-Dark" ] && [ ! -d "$HOME/.local/share/icons/Gruvbox-Plus-Dark" ] && [ ! -d "$HOME/.icons/Gruvbox-Plus-Dark" ]; then
    echo "  Instalando Gruvbox-Plus-Dark icons..."
    TMPDIR=$(mktemp -d)
    git clone --depth 1 https://github.com/SylEleuth/gruvbox-plus-icon-pack.git "$TMPDIR/gruvbox-plus-icon-pack"
    if [ -d "$TMPDIR/gruvbox-plus-icon-pack/Gruvbox-Plus-Dark" ]; then
      mkdir -p "$HOME/.local/share/icons"
      cp -rv "$TMPDIR/gruvbox-plus-icon-pack/Gruvbox-Plus-Dark" "$HOME/.local/share/icons/"
      gtk-update-icon-cache -f -t "$HOME/.local/share/icons/Gruvbox-Plus-Dark" 2>/dev/null || true
    else
      echo "  ⚠️  Directorio Gruvbox-Plus-Dark no encontrado en el repo"
    fi
    rm -rf "$TMPDIR"
  else
    echo "  ✓ Gruvbox-Plus-Dark ya instalado"
  fi

  # Kafka cursor
  if [ ! -d "/usr/share/icons/Kafka" ] && [ ! -d "$HOME/.local/share/icons/Kafka" ] && [ ! -d "$HOME/.icons/Kafka" ]; then
    echo "  Instalando Kafka cursor..."
    TMPDIR=$(mktemp -d)
    git clone --depth 1 https://github.com/ful1e5/Kafka_Cursor.git "$TMPDIR/Kafka"
    "$TMPDIR/Kafka/install.sh" --dest "$HOME/.local/share/icons" 2>/dev/null || \
    "$TMPDIR/Kafka/install.sh" --dest "$HOME/.icons" 2>/dev/null || true
    rm -rf "$TMPDIR"
  else
    echo "  ✓ Kafka cursor ya instalado"
  fi

  # Configurar GTK settings (gtk-3.0 y gtk-4.0)
  mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
  cat > "$HOME/.config/gtk-3.0/settings.ini" <<'GTK3'
[Settings]
gtk-theme-name=Colloid-Pink-Dark
gtk-icon-theme-name=Gruvbox-Plus-Dark
gtk-font-name=Noto Sans 10
gtk-cursor-theme-name=Kafka
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=true
GTK3
  cat > "$HOME/.config/gtk-4.0/settings.ini" <<'GTK4'
[Settings]
gtk-theme-name=Colloid-Pink-Dark
gtk-icon-theme-name=Gruvbox-Plus-Dark
gtk-font-name=Noto Sans 10
gtk-cursor-theme-name=Kafka
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=true
GTK4
  # gtk-2.0 (para apps legacy)
  cat > "$HOME/.gtkrc-2.0.mine" <<'GTK2'
include "/home/diego/.gtkrc-2.0.mine"
gtk-theme-name="Colloid-Pink-Dark"
gtk-icon-theme-name="Gruvbox-Plus-Dark"
gtk-font-name="Noto Sans 10"
gtk-cursor-theme-name="Kafka"
GTK2
  # También en .config/gtk-2.0 para compatibilidad
  mkdir -p "$HOME/.config/gtk-2.0"
  cat > "$HOME/.config/gtk-2.0/settings.ini" <<'GTK2INI'
[Settings]
gtk-theme-name=Colloid-Pink-Dark
gtk-icon-theme-name=Gruvbox-Plus-Dark
gtk-font-name=Noto Sans 10
gtk-cursor-theme-name=Kafka
GTK2INI

  # Forzar recarga de temas en Plasma
  if command -v plasma-apply-desktoptheme >/dev/null 2>&1; then
    plasma-apply-desktoptheme 2>/dev/null || true
  fi
  echo "  ✓ GTK themes configurados (requiere relogin para aplicar completamente)"
fi

# =============================================================================
# Window Managers OPCIONALES — WARNING: rompen/reemplazan Plasma KDE
# =============================================================================
echo
echo "== Window Managers OPCIONALES =="
echo "⚠️  ADVERTENCIA: hyprland y niri SON COMPOSITORES WAYLAND EXCLUYENTES."
echo "   Reemplazan a KWin (Plasma). NO se pueden ejecutar junto a Plasma."
echo "   cinnamon reemplaza el shell de Plasma pero mantiene KWin."
echo

if gum confirm "¿Instalar Cinnamon Desktop (reemplaza Plasma Shell, mantiene KWin)?"; then
  sudo rpm-ostree install --idempotent cinnamon
  echo "  ✓ Cinnamon instalado. Selecciona 'Cinnamon' en SDDM al login."
fi

if gum confirm "⚠️  ¿Instalar Hyprland (ROMPE PLASMA - compositor Wayland tiling exclusivo)?"; then
  echo "  ESTO REEMPLAZA KWIN. Plasma no funcionará hasta que vuelvas a sesión Plasma."
  if gum confirm "¿ESTÁS SEGURO? Esto rompe tu sesión Plasma actual [s/N]"; then
    sudo rpm-ostree install --idempotent hyprland hyprpaper hyprlock hypridle waybar wofi
    echo "  ✓ Hyprland instalado. Selecciona 'Hyprland' en SDDM."
  fi
fi

if gum confirm "⚠️  ¿Instalar Niri (ROMPE PLASMA - compositor Wayland scrollable-tiling)?"; then
  echo "  ESTO REEMPLAZA KWIN. Plasma no funcionará hasta que vuelvas a sesión Plasma."
  if gum confirm "¿ESTÁS SEGURO? Esto rompe tu sesión Plasma actual [s/N]"; then
    sudo rpm-ostree install --idempotent niri
    echo "  ✓ Niri instalado. Selecciona 'Niri' en SDDM."
  fi
fi

# =============================================================================
# GE-Proton (wine-staging) runner para AF_UNIX sockets (Discord IPC bridge)
# =============================================================================
echo
echo "== GE-Proton runner (wine-staging) para Discord IPC =="
GE_RUNNER="$HOME/.var/app/com.usebottles.bottles/data/bottles/runners/GE-Proton8-26"
if [ ! -d "$GE_RUNNER" ]; then
  echo "  Descargando GE-Proton8-26 (wine-staging)..."
  cd /tmp
  curl -fsSL -o wine-ge.tar.xz "https://github.com/GloriousEggroll/wine-ge-custom/releases/download/GE-Proton8-26/wine-lutris-GE-Proton8-26-x86_64.tar.xz"
  mkdir -p wine-ge && tar -xf wine-ge.tar.xz -C wine-ge
  mkdir -p "$GE_RUNNER"
  cp -r /tmp/wine-ge/lutris-GE-Proton8-26-x86_64/* "$GE_RUNNER/"
  echo "  ✓ GE-Proton8-26 instalado"
else
  echo "  ✓ GE-Proton8-26 ya instalado"
fi

# Wrapper wine-staging
cat > "$HOME/.local/bin/wine-staging" <<'WINE_STAGING_EOF'
#!/bin/bash
R="$HOME/.var/app/com.usebottles.bottles/data/bottles/runners/GE-Proton8-26"
export LD_LIBRARY_PATH="$R/lib:$R/lib/wine/x86_64-unix:$R/lib/wine/i386-unix${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export WINEPREFIX="${WINEPREFIX:-$HOME/.wine}"
exec "$R/bin/wine" "$@"
WINE_STAGING_EOF
chmod +x "$HOME/.local/bin/wine-staging"
echo "  ✓ wine-staging wrapper creado en ~/.local/bin/"

# Launcher customrp-discord.sh
cat > "$HOME/.local/bin/juegos/customrp-discord.sh" <<'CUSTOMRP_DISCORD_EOF'
#!/bin/bash
# customrp-discord.sh — Lanza CustomRP con bridge IPC para Discord
set -euo pipefail
MODE="${1:-wine}"
STAGING_RUNNER="$HOME/.var/app/com.usebottles.bottles/data/bottles/runners/GE-Proton8-26"
SODA_RUNNER="$HOME/.var/app/com.usebottles.bottles/data/bottles/runners/soda-11.0-10"

kill_old_bridges() {
  pkill -f "bridge.exe" 2>/dev/null || true
  pkill -f "winediscordipcbridge" 2>/dev/null || true
  sleep 1
}

wait_for_socket() {
  local timeout=10 elapsed=0
  while [ ! -S "/run/user/1000/discord-ipc-0" ] && [ $elapsed -lt $timeout ]; do sleep 0.5; elapsed=$((elapsed+1)); done
  [ -S "/run/user/1000/discord-ipc-0" ]
}

case "${1:-wine}" in
  wine)
    echo "=== Modo Wine (~/.wine) con wine-staging ==="
    kill_old_bridges
    export WINEPREFIX="$HOME/.wine"
    export LD_LIBRARY_PATH="$STAGING_RUNNER/lib:$STAGING_RUNNER/lib/wine/x86_64-unix:$STAGING_RUNNER/lib/wine/i386-unix"
    echo "Iniciando bridge.exe (wine-staging)..."
    "$STAGING_RUNNER/bin/wine" "$WINEPREFIX/drive_c/windows/system32/discord/bridge.exe" >/tmp/bridge-wine.log 2>&1 &
    BRIDGE_PID=$!
    if wait_for_socket; then
      echo "Iniciando CustomRP..."
      "$STAGING_RUNNER/bin/wine" "$WINEPREFIX/drive_c/users/diego/AppData/Roaming/CustomRP/CustomRP.exe"
    else
      kill $BRIDGE_PID 2>/dev/null || true; exit 1
    fi
    ;;
  bottles)
    echo "=== Modo Bottles (botella gaming) ==="
    kill_old_bridges
    flatpak run --command=bottles-cli com.usebottles.bottles run -b gaming -e "C:\\windows\\system32\\discord\\bridge.exe" >/tmp/bridge-bottles.log 2>&1 &
    BRIDGE_PID=$!
    if wait_for_socket; then
      flatpak run --command=bottles-cli com.usebottles.bottles run -b gaming -e "C:\\Users\\diego\\AppData\\Roaming\\CustomRP\\CustomRP.exe"
    else
      kill $BRIDGE_PID 2>/dev/null || true; exit 1
    fi
    ;;
  *) echo "Uso: $0 {wine|bottles}"; exit 1 ;;
esac
CUSTOMRP_DISCORD_EOF
chmod +x "$HOME/.local/bin/juegos/customrp-discord.sh"
echo "  ✓ customrp-discord.sh creado"

