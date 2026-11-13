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
  s | S | y | Y) sudo rpm-ostree cleanup -r ;;
  *)
    echo "Sin espacio suficiente: se conserva el rollback y se aborta. Vuelve a ejecutar y elige S."
    exit 1
    ;;
  esac
fi

echo
echo "== Instalando capa nativa =="
# Estas herramientas se necesitan en esta ejecución, antes de reiniciar.
BAZZITE_BOOTSTRAP=()
for tool in gum stow sassc jq; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    BAZZITE_BOOTSTRAP+=("$tool")
  fi
done
if [ "${#BAZZITE_BOOTSTRAP[@]}" -gt 0 ]; then
  sudo rpm-ostree install --idempotent --apply-live "${BAZZITE_BOOTSTRAP[@]}"
fi
# du-dust aporta el binario `dust` (Fedora no tiene un paquete llamado "dust")
sudo rpm-ostree install --idempotent \
  nemo nautilus thunar qt5ct qt6ct lxappearance rofi wofi bindfs xclip \
  waybar ollama loupe ncdu du-dust antimicrox ripgrep \
  rofimoji fuzzel gtk-murrine-engine playerctl

# =============================================================================
# Android: ADB + QtScrcpy
# ADB se instala con Homebrew (CLI recomendada en Bazzite). QtScrcpy se obtiene
# del AppImage Linux oficial disponible en v3.3.3; versiones posteriores no lo publican.
# =============================================================================
echo
echo "== Android: ADB + QtScrcpy =="
BREW_BIN="$(command -v brew || echo /home/linuxbrew/.linuxbrew/bin/brew)"
if [ -x "$BREW_BIN" ]; then
  env -u HOMEBREW_ASK "$BREW_BIN" install --cask android-platform-tools
else
  echo "  ⚠️  Homebrew no está disponible; instala android-platform-tools para obtener adb."
fi

QTSCRCPY_VERSION="3.3.3"
QTSCRCPY_APPIMAGE="$HOME/Applications/QtScrcpy.AppImage"
QTSCRCPY_SHA256="67e5d1ed99abef8595ceba83608cc551834e6914a1f187ad15a0e09d13bea611"
mkdir -p "$HOME/Applications" "$HOME/.local/share/applications"
if [ ! -x "$QTSCRCPY_APPIMAGE" ]; then
  QTSCRCPY_TMP="$(mktemp)"
  if curl -fL "https://github.com/barry-ran/QtScrcpy/releases/download/v${QTSCRCPY_VERSION}/QtScrcpy-ubuntu-20.04-gcc_64.AppImage" -o "$QTSCRCPY_TMP" && \
    printf '%s  %s\n' "$QTSCRCPY_SHA256" "$QTSCRCPY_TMP" | sha256sum --check --status; then
    install -m 0755 "$QTSCRCPY_TMP" "$QTSCRCPY_APPIMAGE"
    echo "  ✓ QtScrcpy ${QTSCRCPY_VERSION} instalado (SHA-256 verificado)."
  else
    rm -f "$QTSCRCPY_TMP"
    echo "  ⚠️  No se pudo descargar o verificar QtScrcpy; se omite su instalación." >&2
  fi
  rm -f "$QTSCRCPY_TMP"
fi
if [ -x "$QTSCRCPY_APPIMAGE" ]; then
  cat >"$HOME/.local/share/applications/qtscrcpy.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Version=1.0
Name=QtScrcpy
Comment=Android screen mirroring and control
TryExec=$QTSCRCPY_APPIMAGE
Exec=$QTSCRCPY_APPIMAGE
Icon=phone
Terminal=false
Categories=Utility;Network;
DESKTOP
fi

# =============================================================================
# Spotify nativo (RPM COPR) + Spicetify
# El paquete comunitario instala el cliente en /usr/share/spotify y crea
# /usr/bin/spotify. En Bazzite, rpm-ostree requiere reiniciar antes de usarlo;
# al volver a ejecutar este script, se configura Spicetify contra esa ruta.
# No se borra el perfil del Flatpak: solo se desinstala la aplicación.
# =============================================================================
if gum confirm "¿Instalar Spotify nativo desde COPR comunitario y configurar Spicetify?"; then
  SPOTIFY_ID="com.spotify.Client"
  SPOTIFY_FEDORA_VER="$(rpm -E %fedora)"
  SPOTIFY_COPR_REPO="/etc/yum.repos.d/_copr_zicstardust-spotify-client.repo"
  SPOTIFY_COPR_URL="https://copr.fedorainfracloud.org/coprs/zicstardust/spotify-client/repo/fedora-${SPOTIFY_FEDORA_VER}/zicstardust-spotify-client-fedora-${SPOTIFY_FEDORA_VER}.repo"
  SPOTIFY_RPM_READY=0

  if rpm -q spotify-client >/dev/null 2>&1 &&
    [ -x /usr/bin/spotify ] && [ -d /usr/share/spotify/Apps ]; then
    SPOTIFY_RPM_READY=1
    echo "  ✓ Spotify nativo ya está instalado."
  else
    echo "  Agregando el repo COPR zicstardust/spotify-client (Fedora ${SPOTIFY_FEDORA_VER})…"
    if sudo curl -fsSL -o "$SPOTIFY_COPR_REPO" "$SPOTIFY_COPR_URL"; then
      if sudo rpm-ostree install --idempotent spotify-client; then
        echo "  ✓ Spotify nativo quedó preparado en rpm-ostree."
        echo "  ⚠️  REQUERIDO: reinicia Bazzite y vuelve a ejecutar este script para Spicetify."
        SPOTIFY_RPM_READY=1
      else
        echo "  ⚠️  Falló rpm-ostree install de spotify-client; se conserva Spotify Flatpak."
      fi
    else
      echo "  ⚠️  No se pudo descargar el repo COPR; se conserva Spotify Flatpak."
    fi
  fi

  if [ "$SPOTIFY_RPM_READY" -eq 1 ] && command -v flatpak >/dev/null 2>&1; then
    if flatpak info --system "$SPOTIFY_ID" >/dev/null 2>&1; then
      sudo flatpak uninstall --system --assumeyes "$SPOTIFY_ID" ||
        echo "  ⚠️  No se pudo desinstalar Spotify Flatpak del sistema."
    fi
    if flatpak info --user "$SPOTIFY_ID" >/dev/null 2>&1; then
      flatpak uninstall --user --assumeyes "$SPOTIFY_ID" ||
        echo "  ⚠️  No se pudo desinstalar Spotify Flatpak del usuario."
    fi
    echo "  ✓ Se quitó Spotify Flatpak si estaba instalado (sus datos personales se conservan)."
  fi

  if [ "$SPOTIFY_RPM_READY" -eq 1 ] && rpm -q spotify-client >/dev/null 2>&1; then
    SPOTIFY_HELPER="$HOME/dotfiles-dizzi/home/scripts/spicetify-native-apply.sh"
    if [ -f "$SPOTIFY_HELPER" ]; then
      bash "$SPOTIFY_HELPER" ||
        echo "  ⚠️  No se aplicó Spicetify; cierra Spotify y ejecuta bash $SPOTIFY_HELPER"
    else
      echo "  ⚠️  Falta $SPOTIFY_HELPER para configurar Spicetify."
    fi
  fi
fi

# =============================================================================
# Music Presence — Discord Rich Presence para reproductores multimedia
# Se instala desde el RPM oficial de GitHub releases (no está en repos Fedora).
# Requiere rpm-ostree (layered package) → reboot obligatorio.
# =============================================================================
if gum confirm "¿Instalar Music Presence (Discord Rich Presence)?"; then
  MP_RPM="/tmp/musicpresence.rpm"
  MP_URL="https://github.com/ungive/discord-music-presence/releases/download/v2.3.6/musicpresence-2.3.6-linux-x86_64.rpm"
  echo "  Descargando Music Presence RPM…"
  if curl -L -o "$MP_RPM" "$MP_URL"; then
    echo "  Instalando con rpm-ostree…"
    sudo rpm-ostree install --idempotent "$MP_RPM" &&
      echo "  ✓ Music Presence instalado. REQUERIDO: systemctl reboot para aplicar." ||
      echo "  ⚠️  Falló rpm-ostree install del RPM de Music Presence."
  else
    echo "  ⚠️  Falló la descarga del RPM. Intenta manualmente:"
    echo "    curl -L -o /tmp/musicpresence.rpm $MP_URL"
    echo "    sudo rpm-ostree install /tmp/musicpresence.rpm"
  fi
fi

# =============================================================================
# Satty — herramienta de capturas y anotaciones para Wayland
# Se instala vía COPR (mineiro-hyprland) + rpm-ostree (layered package)
# → reboot obligatorio.
# =============================================================================
if gum confirm "¿Instalar Satty (capturas y anotaciones Wayland)?"; then
  echo "  Agregando repo COPR mineiro-hyprland…"
  FEDORA_VER="$(rpm -E %fedora)"
  sudo curl -Lo /etc/yum.repos.d/_copr_mineiro-hyprland.repo \
    "https://copr.fedorainfracloud.org/coprs/mineiro/hyprland/repo/fedora-${FEDORA_VER}/mineiro-hyprland-fedora-${FEDORA_VER}.repo" || \
    echo "  ⚠️  Falló descarga del repo COPR de satty."
  echo "  Instalando satty con rpm-ostree…"
  sudo rpm-ostree install --idempotent satty && \
    echo "  ✓ Satty instalado. REQUERIDO: systemctl reboot para aplicar." || \
    echo "  ⚠️  Falló rpm-ostree install de satty."
fi

# =============================================================================
# hyprpicker — cuentagotas Wayland (wlroots/Hyprland)
# NO requiere Hyprland: es un binario independiente. Solo necesita el COPR
# mineiro-hyprland por libhyprutils. En KWin no funciona (wlr-screencopy).
# Se instala vía rpm-ostree (layered package) → reboot obligatorio.
# =============================================================================
if gum confirm "¿Instalar hyprpicker (cuentagotas Wayland para Hyprland)?"; then
  FEDORA_VER="$(rpm -E %fedora)"
  if [ ! -f /etc/yum.repos.d/_copr_mineiro-hyprland.repo ]; then
    echo "  Agregando repo COPR mineiro-hyprland…"
    sudo curl -fsSL -o /etc/yum.repos.d/_copr_mineiro-hyprland.repo \
      "https://copr.fedorainfracloud.org/coprs/mineiro/hyprland/repo/fedora-${FEDORA_VER}/mineiro-hyprland-fedora-${FEDORA_VER}.repo" || \
      echo "  ⚠️  Falló descarga del repo COPR mineiro-hyprland."
  fi
  sudo rpm-ostree install --idempotent hyprpicker && \
    echo "  ✓ hyprpicker instalado. REQUERIDO: systemctl reboot para aplicar." || \
    echo "  ⚠️  Falló rpm-ostree install de hyprpicker."
fi

# =============================================================================
# grim + slurp — herramientas base para capturas Wayland (satty, scripts)
# Están en repos oficiales Fedora. Opcionales: solo si usas satty o scripts de captura.
# Requiere rpm-ostree (layered package) → reboot obligatorio.
# =============================================================================
if gum confirm "¿Instalar grim + slurp (capturas Wayland para satty/scripts)?"; then
  sudo rpm-ostree install --idempotent grim slurp && \
    echo "  ✓ grim + slurp instalados. REQUERIDO: systemctl reboot para aplicar." || \
    echo "  ⚠️  Falló rpm-ostree install de grim + slurp."
fi

# =============================================================================
# bluetui — TUI para gestión de Bluetooth
# Binario precompilado (musl) desde GitHub releases. No requiere rpm-ostree ni reboot.
# =============================================================================
if gum confirm "¿Instalar bluetui (Bluetooth TUI)?"; then
  BLUETUI_URL="https://github.com/pythops/bluetui/releases/latest/download/bluetui-x86_64-linux-musl"
  echo "  Descargando bluetui…"
  if curl -fL -o ~/.local/bin/bluetui "$BLUETUI_URL"; then
    chmod +x ~/.local/bin/bluetui
    echo "  ✓ bluetui instalado en ~/.local/bin/bluetui"
  else
    echo "  ⚠️  Falló la descarga. Intenta manualmente:"
    echo "    curl -fL -o ~/.local/bin/bluetui $BLUETUI_URL && chmod +x ~/.local/bin/bluetui"
  fi
fi

# =============================================================================
# wlctl — CLI Wi-Fi compatible con NetworkManager (fork de impala)
# Se instala via cargo (requiere Rust toolchain). No requiere rpm-ostree ni reboot.
# =============================================================================
if gum confirm "¿Instalar wlctl (Wi-Fi CLI compatible con NetworkManager)?"; then
  if command -v cargo >/dev/null 2>&1; then
    echo "  Instalando wlctl via cargo…"
    if cargo install wlctl; then
      echo "  ✓ wlctl instalado en ~/.cargo/bin/wlctl"
      grep -q 'cargo/bin' ~/.zshrc || echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.zshrc
      echo "  ℹ  Añadido ~/.cargo/bin al PATH en ~/.zshrc (reinicia la shell o ejecuta: source ~/.zshrc)"
    else
      echo "  ⚠️  Falló cargo install wlctl"
    fi
  else
    echo "  ⚠️  cargo no encontrado. Instala Rust primero: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
  fi
fi

# =============================================================================
# Stacer — optimizador y monitor de sistema (Dashboard tipo Ubuntu)
# Se instala desde el COPR quentium/Stacer (fork mantenido, builds Fedora).
# NO usar el RPM de GitHub: su CDN devuelve 504 y el asset no descarga.
# Requiere rpm-ostree (layered package) → reboot obligatorio.
# =============================================================================
if gum confirm "¿Instalar Stacer (optimizador de sistema)?"; then
  FEDORA_VER=$(rpm -E %fedora)
  STACER_REPO="/etc/yum.repos.d/quentium-Stacer.repo"
  if [ ! -f "$STACER_REPO" ]; then
    echo "  Habilitando COPR quentium/Stacer…"
    sudo curl -fsSL -o "$STACER_REPO" \
      "https://copr.fedorainfracloud.org/coprs/quentium/Stacer/repo/fedora-${FEDORA_VER}/quentium-Stacer-fedora-${FEDORA_VER}.repo" || \
      echo "  ⚠️  No se pudo habilitar el COPR de Stacer."
  fi
  echo "  Instalando Stacer con rpm-ostree…"
  sudo rpm-ostree install --idempotent stacer &&
    echo "  ✓ Stacer instalado. REQUERIDO: systemctl reboot para aplicar." || \
    echo "  ⚠️  Falló rpm-ostree install de Stacer."
fi

# =============================================================================
# OpenTabletDriver — controlador para tabletas de dibujo
# Se instala como Flatpak oficial de Flathub (el RPM de GitHub da 504).
# El Flatpak NO incluye reglas udev: se generan desde el código fuente y se
# instalan en /etc/udev/rules.d (sin esto la tableta no se detecta).
# No requiere reboot: queda disponible al terminar la instalación.
# =============================================================================
if gum confirm "¿Instalar OpenTabletDriver (tabletas de dibujo)?"; then
  OTD_VER="v0.6.8.1"
  echo "  Instalando OpenTabletDriver desde Flathub…"
  if sudo flatpak install -y --noninteractive flathub net.opentabletdriver.OpenTabletDriver; then
    echo "  ✓ OpenTabletDriver instalado (Flatpak)."
    if command -v jq >/dev/null 2>&1 && \
       curl -fsSL -o /tmp/otd-src.tar.gz "https://codeload.github.com/OpenTabletDriver/OpenTabletDriver/tar.gz/refs/tags/${OTD_VER}"; then
      rm -rf /tmp/otd-src && mkdir -p /tmp/otd-src
      tar xzf /tmp/otd-src.tar.gz -C /tmp/otd-src --strip-components=1
      bash /tmp/otd-src/generate-rules.sh \
        -c /tmp/otd-src/OpenTabletDriver.Configurations/Configurations \
        > /tmp/70-opentabletdriver.rules &&
        sudo install -m644 /tmp/70-opentabletdriver.rules /etc/udev/rules.d/70-opentabletdriver.rules &&
        sudo udevadm control --reload-rules && sudo udevadm trigger &&
        echo "  ✓ Reglas udev de OpenTabletDriver instaladas." || \
        echo "  ⚠️  No se pudieron instalar las reglas udev (la tableta podría no detectarse)."
    else
      echo "  ⚠️  Falta jq o falló la descarga; instala las reglas udev manualmente."
    fi
  else
    echo "  ⚠️  Falló la instalación de OpenTabletDriver."
  fi
fi

# =============================================================================
# Firewall nativo — firewalld (ya activo en Bazzite/Fedora, no entra en conflicto
# con sí mismo). Se configuran los puertos reales: SSH/web/dev, Syncthing,
# Sunshine/Moonlight. ufw NO se instala por defecto: pelearía con firewalld
# por nftables.
# =============================================================================
echo
echo "== Configurando firewalld (puertos) =="
sudo firewall-cmd --permanent --add-port={22,80,443,3000,5173,5050,8080,8384,8800,47984,47989,47990,48010}/tcp 2>/dev/null &&
  sudo firewall-cmd --permanent --add-port={21027,22000,47998,47999,48000,48002,48010}/udp 2>/dev/null &&
  sudo firewall-cmd --reload 2>/dev/null &&
  echo "  ✓ firewalld configurado" ||
  echo "  ⚠️  firewalld no se pudo configurar (¿sudo sin TTY?). Ejecuta manualmente:"
echo "    sudo firewall-cmd --permanent --add-port={22,80,443,3000,5173,5050,8080,8384,8800,47984,47989,47990,48010}/tcp"
echo "    sudo firewall-cmd --permanent --add-port={21027,22000,47998,47999,48000,48002,48010}/udp"
echo "    sudo firewall-cmd --reload"

# =============================================================================
# ufw opcional — SOLO si quieres reemplazar firewalld por ufw.
# ⚠️  ufw y firewalld compiten por nftables: no los uses a la vez.
# Requiere rpm-ostree (layered package) → reboot obligatorio.
# =============================================================================
if gum confirm "¿Instalar ufw (reemplaza firewalld, requiere reboot)?"; then
  echo "  ⚠️  Deshabilitando firewalld para evitar conflicto con ufw…"
  sudo systemctl disable --now firewalld 2>/dev/null || true
  sudo rpm-ostree install --idempotent ufw
  echo "  ✓ ufw instalado. REQUERIDO: systemctl reboot para aplicar el layer."
  echo "  Tras el reboot, configura ufw manualmente:"
  echo "    ufw default deny incoming"
  echo "    ufw default allow outgoing"
  echo "    ufw allow 22/tcp      # SSH"
  echo "    ufw allow 80/tcp      # HTTP"
  echo "    ufw allow 443/tcp     # HTTPS"
  echo "    ufw allow 3000/tcp    # Dev"
  echo "    ufw allow 5173/tcp    # Vite"
  echo "    ufw allow 5050/tcp    # ?"
  echo "    ufw allow 8080/tcp    # Alt HTTP"
  echo "    ufw allow 8384/tcp    # Syncthing GUI"
  echo "    ufw allow 8800/tcp    # ?"
  echo "    ufw allow 47984/tcp   # Sunshine/Moonlight"
  echo "    ufw allow 47989/tcp   # Sunshine/Moonlight"
  echo "    ufw allow 47990/tcp   # Sunshine/Moonlight"
  echo "    ufw allow 48010/tcp   # Sunshine/Moonlight"
  echo "    ufw allow 21027/udp   # Syncthing discovery"
  echo "    ufw allow 22000/tcp   # Syncthing sync"
  echo "    ufw allow 22000/udp   # Syncthing sync"
  echo "    ufw allow 47998/udp   # Sunshine/Moonlight"
  echo "    ufw allow 47999/udp   # Sunshine/Moonlight"
  echo "    ufw allow 48000/udp   # Sunshine/Moonlight"
  echo "    ufw allow 48002/udp   # Sunshine/Moonlight"
  echo "    ufw allow 48010/udp   # Sunshine/Moonlight"
  echo "    ufw enable"
  echo "  ⚠️  Docker/Podman saltan las reglas de ufw al publicar puertos."
  echo "  ⚠️  KVM/libvirt puede necesitar excepciones adicionales."
fi

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
  cat >"$HOME/.local/share/applications/nvim.desktop" <<'DESKTOP'
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
  for app_id in io.github.prateekmedia.appimagepool dev.lizardbyte.app.Sunshine; do
    if ! flatpak info --system "$app_id" >/dev/null 2>&1; then
      echo "  Instalando $app_id en Flatpak del sistema…"
      sudo flatpak install --system -y flathub "$app_id"
    else
      echo "  ✓ $app_id ya está instalado en Flatpak del sistema."
    fi
  done

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

  if gum confirm "¿Instalar AntiMicroX (flatpak) — mapeo de gamepad a teclado/ratón?"; then
    flatpak install -y flathub io.github.antimicrox.antimicrox
  fi

  if gum confirm "¿Instalar Syncthing Tray (flatpak) — bandeja para Syncthing?"; then
    flatpak install -y flathub io.github.martchus.syncthingtray
  fi

  if gum confirm "¿Instalar MegaSync / MEGA cloud (flatpak)?"; then
    flatpak install -y flathub com.tonikelope.MegaBasterd
    echo "  ✓ MegaBasterd (flatpak) instalado"
    echo "  Para gestión 'nativa' de MEGA: rpm-ostree install megasync-Fedora_45 (solo fuera de sesión Steam)"
  fi

  if gum confirm "¿Instalar Kew (terminal music player)?"; then
    BREW_BIN="$(command -v brew || echo /home/linuxbrew/.linuxbrew/bin/brew)"
    if [ -x "$BREW_BIN" ] && env -u HOMEBREW_ASK "$BREW_BIN" install kew; then
      echo "  ✓ Kew instalado vía Homebrew"
    else
      echo "  Homebrew no disponible o falló; probando Flatpak oficial..."
      KEW_TMP="$(mktemp -d)"
      if (cd "$KEW_TMP" && gh release download -R ravachol/kew --pattern '*.flatpak') &&
        flatpak install --user -y "$KEW_TMP"/*.flatpak; then
        KEW_ID="$(flatpak list --app --columns=application | grep -i kew | head -1)"
        if [ -n "$KEW_ID" ]; then
          mkdir -p "$HOME/.local/bin"
          printf '#!/bin/sh\nexec flatpak run %s "$@"\n' "$KEW_ID" >"$HOME/.local/bin/kew"
          chmod +x "$HOME/.local/bin/kew"
          echo "  ✓ Kew (flatpak $KEW_ID) -> ~/.local/bin/kew"
        fi
      else
        echo "  ⚠️  Falló; descarga manual: https://github.com/ravachol/kew/releases/latest"
      fi
      rm -rf "$KEW_TMP"
    fi
  fi

  # =============================================================================
  # Iriun Webcam — usar el móvil como webcam (alternativa a DroidCam)
  # El RPM oficial instala /usr/local/bin/iriunwebcam; en Bazzite /usr/local es
  # un symlink y rpm-ostree falla con "opendir(local)". Se repaqueta el RPM
  # moviendo el binario a /usr/bin y parcheando el .desktop.
  # Requiere podman (incluido en Bazzite) y reboot.
  # =============================================================================
  if gum confirm "¿Instalar Iriun Webcam (móvil como webcam, alternativa a DroidCam)?"; then
    IRIUN_VER="2.9.3"
    IRIUN_TMP="$(mktemp -d)"
    IRIUN_RPM="$IRIUN_TMP/iriunwebcam-${IRIUN_VER}.rpm"

    echo "  Descargando RPM beta de Iriun Webcam v${IRIUN_VER}…"
    if curl -fL -o "$IRIUN_RPM" "https://iriun.com/iriunwebcam-${IRIUN_VER}.rpm"; then
      if ! command -v podman >/dev/null 2>&1; then
        echo "  ⚠️  podman no está disponible; no se puede repaquetar el RPM."
      else
        echo "  Repaquetando para /usr/bin (evita el bug de /usr/local)…"
        mkdir -p "$IRIUN_TMP/extract"
        if (cd "$IRIUN_TMP/extract" && rpm2cpio "$IRIUN_RPM" | cpio -idm --quiet); then
          cat > "$IRIUN_TMP/iriunwebcam.spec" <<'SPEC'
Name:           iriunwebcam
Version:        2.9.3
Release:        1
Summary:        Iriun Webcam for Linux
License:        Proprietary
URL:            https://iriun.com
Requires:       v4l2loopback
BuildArch:      x86_64

%description
Use your phone's camera as a wireless webcam in PC.

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}
cp -a /work/extract/usr %{buildroot}/
cp -a /work/extract/etc %{buildroot}/
rm -rf %{buildroot}/usr/lib/.build-id
mkdir -p %{buildroot}/usr/bin
mv %{buildroot}/usr/local/bin/iriunwebcam %{buildroot}/usr/bin/iriunwebcam
rmdir %{buildroot}/usr/local/bin %{buildroot}/usr/local 2>/dev/null || true
sed -i 's|/usr/local/bin/iriunwebcam|/usr/bin/iriunwebcam|' %{buildroot}/usr/share/applications/iriunwebcam.desktop

%files
%attr(0755,root,root) /usr/bin/iriunwebcam
%attr(0755,root,root) /usr/lib64/spa-0.2/iriunaudio/libspa-iriunaudio.so
%config(noreplace) /etc/modprobe.d/iriunwebcam-options.conf
%config(noreplace) /etc/modules-load.d/iriunwebcam.conf
/usr/share/applications/iriunwebcam.desktop
%config(noreplace) /usr/share/pipewire/pipewire.conf.d/iriunaudio.conf
/usr/share/pixmaps/iriunwebcam.png
SPEC
          sed -i "s/^Version:.*/Version:        ${IRIUN_VER}/" "$IRIUN_TMP/iriunwebcam.spec"

          FEDORA_VER="$(rpm -E %fedora)"
          if podman run --rm -v "$IRIUN_TMP:/work:Z" -w /work \
            "registry.fedoraproject.org/fedora:${FEDORA_VER}" \
            bash -c 'dnf -y install rpm-build >/dev/null 2>&1 && rpmbuild -bb --define "_topdir /work/rpmbuild" iriunwebcam.spec' \
            >"$IRIUN_TMP/build.log" 2>&1; then
            IRIUN_PATCHED="$IRIUN_TMP/rpmbuild/RPMS/x86_64/iriunwebcam-${IRIUN_VER}-1.x86_64.rpm"
            if [ -f "$IRIUN_PATCHED" ]; then
              echo "  Instalando RPM repaquetado con rpm-ostree…"
              if sudo rpm-ostree install --idempotent "$IRIUN_PATCHED"; then
                echo "  ✓ Iriun Webcam instalado. REQUERIDO: systemctl reboot para aplicar."
              else
                echo "  ⚠️  Falló rpm-ostree install de Iriun Webcam."
              fi
            else
              echo "  ⚠️  No se generó el RPM repaquetado."
            fi
          else
            echo "  ⚠️  Falló el repaquetado con podman/rpmbuild."
            tail -10 "$IRIUN_TMP/build.log" 2>/dev/null | sed 's/^/    /'
          fi
        else
          echo "  ⚠️  Falló la extracción del RPM."
        fi
      fi
    else
      echo "  ⚠️  Falló la descarga. Intenta manualmente:"
      echo "    curl -fL -o /tmp/iriunwebcam-${IRIUN_VER}.rpm https://iriun.com/iriunwebcam-${IRIUN_VER}.rpm"
    fi

    rm -rf "$IRIUN_TMP"
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
      cat >"$HOME/.local/bin/wine-soda" <<'WINE_SODA_EOF'
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
      "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm" ||
      { echo "  ⚠️  No se pudieron agregar los repos RPM Fusion; saltando Discord"; }
    echo "  ⚠️  REQUERIDO: ejecuta 'systemctl reboot' para activar el deployment de RPM Fusion."
    echo "     Luego ejecuta de nuevo bazzite-install.sh para completar con 'rpm-ostree install discord'."
  else
    echo "  Repos RPM Fusion ya activos. Instalando discord…"
    rpm-ostree install --idempotent discord ||
      { echo "  ⚠️  discord no se pudo instalar"; }
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
      sudo ostree admin finalize-staged ||
        echo "  ⚠️  finalize-staged falló; se finalizará solo al apagar (apagado LIMPIO obligatorio)"
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
    DL_URL=$(curl -s "https://api.github.com/repos/0e4ef622/wine-discord-ipc-bridge/releases/latest" |
      grep "browser_download_url.*winediscordipcbridge\.exe" |
      head -1 | cut -d '"' -f 4)
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
    DL_URL=$(curl -s "https://api.github.com/repos/enderice2/rpc-bridge/releases/latest" |
      grep "browser_download_url.*bridge\.exe" |
      head -1 | cut -d '"' -f 4)
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
    bash "$HOME/dotfiles-dizzi/home/scripts/setup-wine-discord-bridge.sh" ||
      echo "  ⚠️  setup-wine-discord-bridge.sh falló (¿wine instalado?)"
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
    (cd "$HOME/opt" && gh release download -R pear-devs/pear-desktop --pattern 'YouTube-Music-*.AppImage' --clobber)
    chmod u+x "$HOME"/opt/YouTube-Music-*.AppImage
    ln -sfn "$(ls -1 "$HOME"/opt/YouTube-Music-*.AppImage | head -1)" "$HOME/.local/bin/youtube-music"
    cat >"$HOME/.local/share/applications/youtube-music.desktop" <<'DESKTOP'
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
    (cd "$HOME/opt" && gh release download -R pkgforge-dev/ghostty-appimage --pattern '*x86_64*.AppImage' --clobber)
    chmod u+x "$HOME"/opt/Ghostty-*.AppImage
    ln -sfn "$(ls -1 "$HOME"/opt/Ghostty-*.AppImage | head -1)" "$HOME/.local/bin/ghostty"
    cat >"$HOME/.local/share/applications/ghostty.desktop" <<'DESKTOP'
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
# Waywallen — wallpapers de Wallpaper Engine en Plasma
#
# Wallpaper Engine es solo Windows, pero Waywallen (sucesor del antiguo plugin
# catsout/wallpaper-engine-kde-plugin, archivado en 2026) reproduce los
# wallpapers suscritos en el Workshop. Se instala como Flatpak (no toca Steam).
#
# El Flatpak es solo el daemon: para dibujar el fondo en Plasma hace falta el
# kpackage org.waywallen.kde de waywallen-display (se instala en el usuario).
# Requiere tener Wallpaper Engine comprado en Steam para los assets.
# No requiere rpm-ostree ni reboot.
# =============================================================================
echo
echo "== Waywallen (wallpapers de Wallpaper Engine) =="
if gum confirm "¿Instalar Waywallen (Flatpak) + plugin de Plasma para Wallpaper Engine?"; then
  if ! command -v flatpak >/dev/null 2>&1; then
    echo "  ⚠️  flatpak no está disponible; se omite Waywallen."
  else
    if flatpak info --system org.waywallen.waywallen >/dev/null 2>&1; then
      echo "  ✓ Waywallen ya está instalado (Flatpak del sistema)."
    else
      echo "  Instalando Waywallen desde Flathub…"
      sudo flatpak install --system -y --noninteractive flathub org.waywallen.waywallen ||
        echo "  ⚠️  Falló la instalación de Waywallen."
    fi

    # Plugin de escritorio (Plasma 6 kpackage). Sin él, el daemon corre pero
    # Plasma no puede mostrar la superficie como fondo de pantalla.
    WAYWALLEN_KDE_DIR="$HOME/.local/share/plasma/wallpapers/org.waywallen.kde"
    if ! command -v kpackagetool6 >/dev/null 2>&1; then
      echo "  ⚠️  kpackagetool6 no disponible; instala el plugin de Plasma a mano:"
      echo "    https://github.com/waywallen/waywallen-display/releases"
    elif [ -f "$WAYWALLEN_KDE_DIR/metadata.json" ]; then
      echo "  ✓ Plugin org.waywallen.kde ya instalado en Plasma."
    else
      # El asset del release es waywallen-kde-<ver>-<arch>.zip (Linux x86_64).
      WAYWALLEN_DISPLAY_VER="$(curl -fsSL \
        https://api.github.com/repos/waywallen/waywallen-display/releases/latest 2>/dev/null |
        grep -m1 '"tag_name"' | cut -d '"' -f 4 | sed 's/^v//' || true)"
      : "${WAYWALLEN_DISPLAY_VER:=0.4.6}"
      case "$(uname -m)" in
      aarch64 | arm64) WAYWALLEN_ARCH="aarch64" ;;
      *) WAYWALLEN_ARCH="x86_64" ;;
      esac
      WAYWALLEN_URL="https://github.com/waywallen/waywallen-display/releases/download/v${WAYWALLEN_DISPLAY_VER}/waywallen-kde-${WAYWALLEN_DISPLAY_VER}-${WAYWALLEN_ARCH}.zip"
      WAYWALLEN_TMP="$(mktemp -d)"
      echo "  Instalando plugin de Plasma (waywallen-display ${WAYWALLEN_DISPLAY_VER})…"
      if curl -fsSL -o "$WAYWALLEN_TMP/plugin.zip" "$WAYWALLEN_URL" &&
        (cd "$WAYWALLEN_TMP" && unzip -q plugin.zip) &&
        kpackagetool6 --type Plasma/Wallpaper -i "$WAYWALLEN_TMP/org.waywallen.kde"; then
        echo "  ✓ Plugin Waywallen instalado para Plasma."
      else
        echo "  ⚠️  No se pudo instalar el plugin. Descárgalo manualmente de:"
        echo "    https://github.com/waywallen/waywallen-display/releases"
      fi
      rm -rf "$WAYWALLEN_TMP"
    fi

    # Override Flatpak para bibliotecas de Steam en ubicaciones no estándar
    # (ej. /var/mnt/games-swap/SteamLibrary). El manifiesto base solo ve
    # ~/.steam, ~/.local/share/Steam y ~/.var/app/com.valvesoftware.Steam.
    STEAM_LIB_CUSTOM="/var/mnt/games-swap/SteamLibrary"
    if [ -d "$STEAM_LIB_CUSTOM/steamapps/workshop/content/431960" ]; then
      if gum confirm "¿Añadir biblioteca Steam personalizada ($STEAM_LIB_CUSTOM) a Waywallen?"; then
        sudo flatpak override --system --filesystem="$STEAM_LIB_CUSTOM" org.waywallen.waywallen
        echo "  ✓ Override añadido. Reinicia Waywallen para que surta efecto."
      fi
    fi

    # Configurar backend de display: layer-shell detecta todos los monitores
    # en KWin (incluyendo HDMI-A-1, DP-1, etc.). El backend 'kde-plasma'
    # a veces solo ve eDP-1 en setups híbridos Intel/NVIDIA.
    WAYWALLEN_CONFIG_DIR="$HOME/.var/app/org.waywallen.waywallen/config/waywallen"
    if [ ! -f "$WAYWALLEN_CONFIG_DIR/config.toml" ] || ! grep -q 'backend = "layer-shell"' "$WAYWALLEN_CONFIG_DIR/config.toml" 2>/dev/null; then
      if gum confirm "¿Usar backend 'layer-shell' para detectar todos los monitores (HDMI-A-1, DP-1, etc.)?"; then
        mkdir -p "$WAYWALLEN_CONFIG_DIR"
        cat >"$WAYWALLEN_CONFIG_DIR/config.toml" <<'WW_CONFIG_EOF'
[display]
backend = "layer-shell"
WW_CONFIG_EOF
        echo "  ✓ Config layer-shell escrita. Reinicia Waywallen."
      fi
    fi

    # Tokens para plugins de terceros (Sketchfab, Wallhaven)
    # Se leen desde ~/.api-keys.sh si existe.
    if [ -f "$HOME/.api-keys.sh" ]; then
      grep -q 'SKETCHFAB_TOKEN' "$HOME/.api-keys.sh" && echo "  ✓ SKETCHFAB_TOKEN encontrado en ~/.api-keys.sh"
      grep -q 'WALLHAVEN_API_KEY' "$HOME/.api-keys.sh" && echo "  ✓ WALLHAVEN_API_KEY encontrado en ~/.api-keys.sh"
    fi

    # En GPUs NVIDIA el backend EGL es inestable para plasmashell; el propio
    # proyecto recomienda Vulkan. Bazzite aquí es híbrida Intel + NVIDIA.
    PLASMASHELL_DROPIN="$HOME/.config/systemd/user/plasma-plasmashell.service.d/override.conf"
    if gum confirm "¿Forzar el backend Vulkan en plasmashell (recomendado con NVIDIA)?"; then
      mkdir -p "$(dirname "$PLASMASHELL_DROPIN")"
      cat >"$PLASMASHELL_DROPIN" <<'PLASMASHELL_EOF'
[Service]
Environment=QSG_RHI_BACKEND=vulkan
PLASMASHELL_EOF
      systemctl --user daemon-reload
      echo "  ✓ Drop-in creado: $PLASMASHELL_DROPIN"
    fi

    # Reiniciar plasmashell y daemon de Waywallen para cargar todo.
    if gum confirm "¿Reiniciar plasmashell y Waywallen ahora?"; then
      flatpak kill org.waywallen.waywallen 2>/dev/null || true
      systemctl --user restart plasma-plasmashell.service 2>/dev/null ||
        echo "  ⚠️  No se pudo reiniciar plasmashell; ciérralo y vuelve a entrar en la sesión."
      flatpak run org.waywallen.waywallen &
      sleep 2
      echo "  ✓ plasmashell y Waywallen reiniciados."
      echo "  ℹ  En Waywallen → Displays → ⟳ Refresh para detectar HDMI-A-1, DP-1, etc."
      echo "  ℹ  En Waywallen → Wallpapers → Auto detect libraries → selecciona tu Steam Library."
    else
      echo "  ℹ  Ejecuta manualmente:"
      echo "     flatpak kill org.waywallen.waywallen"
      echo "     systemctl --user restart plasma-plasmashell.service"
      echo "     flatpak run org.waywallen.waywallen"
    fi

    echo "  ℹ  Pasos finales en Waywallen:"
    echo "     1. Displays → ⟳ Refresh (deben aparecer eDP-1 y HDMI-A-1/DP-1)"
    echo "     2. Wallpapers → Auto detect libraries → Add Library → /var/mnt/games-swap/SteamLibrary"
    echo "     3. Selecciona wallpaper → Set as wallpaper → elige monitor"
    echo "     4. Configuración de escritorio → Fondo de pantalla → Waywallen"
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
if [ -x "$HOME/.local/bin/espanso-wayland" ] &&
  [ -f "$HOME/.config/systemd/user/espanso.service" ] &&
  grep -q '^backend: Clipboard' "$ESPANSO_CONFIG" 2>/dev/null &&
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
      (dnf5 download --destdir /tmp/espanso-deps wtype >/dev/null 2>&1 || true)
      if ls /tmp/espanso-deps/wtype-*.rpm >/dev/null 2>&1; then
        (cd /tmp/espanso-deps && rpm2cpio wtype-*.rpm | cpio -idm >/dev/null 2>&1 || true)
        [ -f /tmp/espanso-deps/usr/bin/wtype ] &&
          cp /tmp/espanso-deps/usr/bin/wtype "$HOME/.local/bin/wtype" &&
          chmod +x "$HOME/.local/bin/wtype"
      fi
      rm -rf /tmp/espanso-deps
    fi

    # Wrapper: el binario Wayland necesita sus libs locales
    cat >"$HOME/.local/bin/espanso" <<'ESP_WRAPPER_EOF'
#!/bin/sh
ESPANSO_LIB="$HOME/.local/lib/espanso-wayland"
export LD_LIBRARY_PATH="$ESPANSO_LIB${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export PATH="$HOME/.local/bin:$PATH"
exec "$HOME/.local/bin/espanso-wayland" "$@"
ESP_WRAPPER_EOF
    chmod +x "$HOME/.local/bin/espanso"

    # Servicio systemd user (Wayland nativo)
    mkdir -p "$HOME/.config/systemd/user"
    cat >"$HOME/.config/systemd/user/espanso.service" <<'ESP_SERVICE_EOF'
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
    cat >"$ESPANSO_CONFIG" <<'ESP_CONFIG_EOF'
# Espanso config — Bazzite Wayland
toggle_key: OFF
keyboard_layout:
  layout: us
  variant: ""
backend: Clipboard
ESP_CONFIG_EOF

    # Matches de acentos (ASCII directo, no-ASCII vía wl-copy + Shift+Insert)
    mkdir -p "$HOME/.config/espanso/match"
    cat >"$HOME/.config/espanso/match/base.yml" <<'ESP_MATCHES_EOF'
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
  fi # fi para if [ "$ESPANSO_DL" -eq 1 ]
fi   # fi para if [ ... ] (línea 338)

# =============================================================================
# ANTI ZURDO, ANTI MILEI, VIVA EL KIRCHNERISMO AGUANTE PERON,KUKAS DE MIERDA y el peronismo. SteamOS me discrimina. Mouse zurdo global (udev, sin input-remapper) — COMENTADO
# No funcionó en SteamOS/Game Mode; se configura por juego. Dejado comentado
# por si se quiere reactivar en el futuro.
# LIBINPUT_CALIBRATION_MATRIX invierte X/Y a nivel libinput: aplica en Plasma,
# en SteamOS/Game Mode y en TTY, sin daemon ni servicio extra.
# =============================================================================
# echo
# echo "== Mouse zurdo global (udev) =="
# LEFTY_RULE=/etc/udev/rules.d/99-mouse-lefty.rules
# if [ -f "$LEFTY_RULE" ] && grep -q 'Compx 2.4G Wireless Receiver Mouse' "$LEFTY_RULE"; then
#   echo "  ✓ Regla udev del mouse zurdo ya existe"
# else
#   sudo tee "$LEFTY_RULE" >/dev/null <<'UDEV_EOF'
# ACTION=="add|change", SUBSYSTEM=="input", ATTRS{name}=="Compx 2.4G Wireless Receiver Mouse", \
#   ENV{LIBINPUT_CALIBRATION_MATRIX}="-1 0 1 0 -1 1 0 0 1"
# UDEV_EOF
#   echo "  ✓ Regla udev creada: $LEFTY_RULE"
# fi
# sudo udevadm control --reload
# sudo udevadm trigger
#
# # input-remapper puede reescribir el mouse: deshabilitarlo (config se conserva)
# systemctl --user disable --now input-remapper.service 2>/dev/null || true
# sudo systemctl disable --now input-remapper.service 2>/dev/null || true
# echo "  ✓ input-remapper deshabilitado (config conservada en ~/.config/input-remapper-2)"

# SwayNC 0.11.0 corrige que actualizar un botón toggle dispare también su acción.
SWAYNC_VERSION="0.11.0"
SWAYNC_TAG="v${SWAYNC_VERSION}"
SWAYNC_BIN="$HOME/.local/bin/swaync"
SWAYNC_SOURCE="$HOME/build-swaync"
SWAYNC_CURRENT_VERSION=""
if [ -x "$SWAYNC_BIN" ]; then
  SWAYNC_CURRENT_VERSION=$(timeout 5 "$SWAYNC_BIN" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)
fi

if [ "$SWAYNC_CURRENT_VERSION" != "$SWAYNC_VERSION" ] || [ ! -x "$HOME/.local/bin/swaync-client" ]; then
  if ! command -v distrobox >/dev/null 2>&1; then
    echo "  ⚠️  Instala distrobox para actualizar SwayNC a ${SWAYNC_VERSION}."
  elif gum confirm "¿Compilar SwayNC ${SWAYNC_VERSION} en distrobox 'build'?"; then
    if ! distrobox list | awk -F '|' '$2 ~ /build/ {found = 1} END {exit !found}'; then
      distrobox create --name build --image registry.fedoraproject.org/fedora:45 --yes
    fi
    if [ ! -d "$SWAYNC_SOURCE/.git" ]; then
      git clone --depth 1 --branch "$SWAYNC_TAG" \
        https://github.com/ErikReider/SwayNotificationCenter.git "$SWAYNC_SOURCE"
    else
      if [ -n "$(git -C "$SWAYNC_SOURCE" status --porcelain)" ]; then
        echo "  ❌ $SWAYNC_SOURCE tiene cambios locales; no se actualizará SwayNC." >&2
        exit 1
      fi
      git -C "$SWAYNC_SOURCE" fetch --depth 1 origin \
        "refs/tags/${SWAYNC_TAG}:refs/tags/${SWAYNC_TAG}"
      git -C "$SWAYNC_SOURCE" checkout --detach "$SWAYNC_TAG"
    fi
    distrobox enter build -- bash -lc 'sudo dnf install -y vala meson sassc gtk3-devel gtk-layer-shell-devel libgee-devel json-glib-devel libhandy-devel granite-devel scdoc gobject-introspection-devel pulseaudio-libs-devel && cd ~/build-swaync && rm -rf build && meson setup build --prefix=$HOME/.local -Dsystemd-service=false -Dman-pages=false -Dzsh-completions=false -Dbash-completions=false -Dfish-completions=false && ninja -C build && ninja -C build install'
    mkdir -p "$HOME/.local/lib/swaync"
    distrobox enter build -- bash -lc \
      'cp -a /usr/lib64/libgranite.so.6* /usr/lib64/libgee-0.8.so.2* ~/.local/lib/swaync/'
    for SWAYNC_APP in swaync swaync-client; do
      SWAYNC_APP_BIN="$HOME/.local/bin/${SWAYNC_APP}"
      SWAYNC_REAL_BIN="${SWAYNC_APP_BIN}.real"
      if [ ! -x "$SWAYNC_APP_BIN" ]; then
        echo "  ❌ La compilación no produjo $SWAYNC_APP_BIN." >&2
        exit 1
      fi
      mv -f "$SWAYNC_APP_BIN" "$SWAYNC_REAL_BIN"
      SWAYNC_WRAPPER_TMP="$HOME/.local/bin/.${SWAYNC_APP}-wrapper.$$"
      printf '%s\n' \
        '#!/bin/sh' \
        '# Añade los datos y bibliotecas instalados en ~/.local para SwayNC.' \
        'export XDG_CONFIG_DIRS="$HOME/.local/etc/xdg${XDG_CONFIG_DIRS:+:$XDG_CONFIG_DIRS}"' \
        'export LD_LIBRARY_PATH="$HOME/.local/lib/swaync${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"' \
        "exec \"\$HOME/.local/bin/${SWAYNC_APP}.real\" \"\$@\"" >"$SWAYNC_WRAPPER_TMP"
      chmod +x "$SWAYNC_WRAPPER_TMP"
      mv -f "$SWAYNC_WRAPPER_TMP" "$SWAYNC_APP_BIN"
      # swaync-client necesita el daemon en D-Bus incluso para --version.
      # Ambos ejecutables se construyen desde el mismo tag fijado arriba.
      if ! SWAYNC_LINKS=$(LD_LIBRARY_PATH="$HOME/.local/lib/swaync${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" ldd "$SWAYNC_REAL_BIN") ||
        grep -Fq 'not found' <<<"$SWAYNC_LINKS"; then
        echo "  ❌ No se pudieron resolver las bibliotecas de $SWAYNC_APP." >&2
        printf '%s\n' "$SWAYNC_LINKS" >&2
        exit 1
      fi
    done
    SWAYNC_CURRENT_VERSION="$SWAYNC_VERSION"
    echo "  ✓ SwayNC ${SWAYNC_VERSION} y swaync-client instalados."
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
  sed -e 's|GRUB_DISTRIBUTOR="Arch"|GRUB_DISTRIBUTOR="Bazzite"|' -e '/^GRUB_CMDLINE_LINUX=/d' -e '/^GRUB_CMDLINE_LINUX_DEFAULT=/d' "$GRUB_SRC" >"$TMP"
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

# =============================================================================
# Hibernación — habilitar resume=UUID en kernel cmdline
# Usa una partición swap activa en disco para la imagen de hibernación.
# =============================================================================
if gum confirm "¿Habilitar hibernación (agregar resume=UUID a kernel cmdline)?"; then
  SWAP_DEVICE=$(swapon --noheadings --raw --show=NAME,TYPE |
    awk '$2 == "partition" && $1 !~ /^\/dev\/zram/ && !found { print $1; found = 1 }')
  SWAP_UUID=""
  if [ -n "$SWAP_DEVICE" ]; then
    SWAP_UUID=$(sudo blkid -s UUID -o value "$SWAP_DEVICE" || true)
  fi
  if [ -n "$SWAP_UUID" ]; then
    echo "  Swap detectado: $SWAP_DEVICE (UUID=$SWAP_UUID)"
    if sudo rpm-ostree kargs --append-if-missing="resume=UUID=$SWAP_UUID"; then
      echo "  ✓ Parámetro de reanudación preparado. Arranca el despliegue nuevo de Bazzite."
      echo "  Verifica resume= en /proc/cmdline y regenera la entrada Desktop para ese despliegue."
    else
      echo "  ⚠️  Falló rpm-ostree kargs."
    fi
  else
    echo "  ⚠️  No se encontró una partición swap activa en disco con UUID."
  fi
fi

echo
echo "== Estado final =="
sudo rpm-ostree status
echo
echo "Hitos aplicados:"
echo "  • Capa nativa: nemo/nautilus/thunar/ollama/loupe/ncdu/dust(du-dust)/wine"
echo "  • Spotify nativo (RPM COPR) + Spicetify (requiere reinicio y nueva ejecución si quedó staged)"
echo "  • Discord nativo (RPM Fusion) staged/finalizado"
echo "  • Entrada GRUB 'Bazzite Desktop (Plasma)' (usa el deployment que va a arrancar)"
echo "  • Espanso Wayland nativo (layout us, backend Clipboard)"
echo "  • Mouse zurdo global por udev (input-remapper solo deshabilitado)"
echo "  • Wine Discord IPC Bridge: prefijo ~/.wine + .desktop con icono"
echo "  • Waywallen (Flatpak) + plugin org.waywallen.kde para Wallpaper Engine en Plasma"
echo "    - Flatpak override para Steam Library custom (/var/mnt/games-swap/SteamLibrary)"
echo "    - Backend display: layer-shell (detecta HDMI-A-1, DP-1, eDP-1)"
echo "    - Vulkan en plasmashell (QSG_RHI_BACKEND=vulkan) para NVIDIA"
echo "    - Tokens Sketchfab/Wallhaven desde ~/.api-keys.sh"
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
s | S)
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
    codex --no-folding; do
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
    stow -t "$HOME" --adopt --ignore='net\.local\.(swaync|toggle-monitor)\.desktop$' local || true
  fi
fi

# En una sesión nueva, Plasma ya puede haber creado sus propios archivos.
# Respalda los conflictos de estos atajos y enlaza la versión del repo.
link_bazzite_dotfile() {
  local source="$1" target="$2" backup=""
  local source_path
  source_path=$(realpath -e "$source") || return 1
  if [ "$(realpath -e "$target" 2>/dev/null || true)" = "$source_path" ]; then
    return 0
  fi
  mkdir -p "$(dirname "$target")"
  if [ -e "$target" ] || [ -L "$target" ]; then
    backup=$(mktemp -d "${target}.pre-bazzite.XXXXXX") || return 1
    mv -T -- "$target" "$backup/original" || return 1
    echo "  Respaldo de $target en $backup/original"
  fi
  if ! ln -sT -- "$source" "$target"; then
    if [ -n "$backup" ]; then
      mv -T -- "$backup/original" "$target"
    fi
    return 1
  fi
}

DOTFILES="$HOME/dotfiles-dizzi"
link_bazzite_dotfile "$DOTFILES/home/scripts" "$HOME/scripts"
link_bazzite_dotfile "$DOTFILES/global-keyboard-shortcutsrc/.config/kglobalshortcutsrc" "$HOME/.config/kglobalshortcutsrc"
for launcher in net.local.swaync.desktop net.local.toggle-monitor.desktop; do
  link_bazzite_dotfile "$DOTFILES/local/.local/share/applications/$launcher" "$HOME/.local/share/applications/$launcher"
done

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
    echo '{"focusURLBar":{"modifiers":"alt","key":"S"}}' >"$DEFAULT_PROFILE/customKeys.json"
    echo "  customKeys.json restaurado (backup en .bak)"
  fi
fi

# =============================================================================
# alternar-a-windows.service — boot automático a Windows al reiniciar/apagar
# Equivalente a remote-control.nix T3 (ping-pong NixOS -> Windows -> NixOS).
# Se ejecuta antes del apagado o reinicio y fuerza el próximo boot a Windows vía
# efibootmgr --bootnext Boot0001 (one-shot, se borra solo tras usarse).
# El servicio usa una copia estable en /usr/local/bin; el origen mantenido
# está en home/scripts/alternar-windows-bazzite.sh.
# =============================================================================
echo
echo "== alternar-a-windows.service (dual boot NixOS <-> Windows) =="
# Copiar script a ubicación accesible por root (systemd corre como root)
sudo install -m 0755 "$HOME/dotfiles-dizzi/home/scripts/alternar-windows-bazzite.sh" /usr/local/bin/alternar-windows-bazzite.sh

sudo install -m 0644 "$HOME/dotfiles-dizzi/home/systemd/alternar-a-windows.service" \
  /etc/systemd/system/alternar-a-windows.service
sudo systemctl daemon-reload
sudo systemctl reenable alternar-a-windows.service
echo "  ✓ alternar-a-windows.service habilitado"

# Regla sudoers NOPASSWD para no pedir contraseña al ejecutar el script
echo "diego ALL=(ALL) NOPASSWD: /usr/local/bin/alternar-windows-bazzite.sh" | sudo tee /etc/sudoers.d/90-winboot >/dev/null
sudo chmod 0440 /etc/sudoers.d/90-winboot
sudo visudo -c -f /etc/sudoers.d/90-winboot >/dev/null 2>&1 && echo "  ✓ Regla sudoers NOPASSWD configurada" || echo "  ⚠️  Regla sudoers no se pudo validar"

echo
echo "== Retirando plasma-shortcuts-fix.service obsoleto =="
systemctl --user disable --now plasma-shortcuts-fix.service 2>/dev/null || true
SHORTCUT_FIX_UNIT="$HOME/.config/systemd/user/plasma-shortcuts-fix.service"
SHORTCUT_FIX_DROPIN="$HOME/.config/systemd/user/plasma-kwin_wayland.service.d/plasma-shortcuts-fix.conf"
for obsolete_file in "$SHORTCUT_FIX_UNIT" "$SHORTCUT_FIX_DROPIN"; do
  if [ -f "$obsolete_file" ] || [ -L "$obsolete_file" ]; then
    unlink "$obsolete_file"
  fi
done
rmdir "$HOME/.config/systemd/user/plasma-kwin_wayland.service.d" 2>/dev/null || true
systemctl --user daemon-reload
echo "  ✓ Servicio y drop-in obsoletos retirados; los atajos quedan bajo Plasma."

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
  cat >"$service_file" <<EOF
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

# SwayNC sigue el ciclo de vida de Plasma Wayland.
if [ "$SWAYNC_CURRENT_VERSION" = "$SWAYNC_VERSION" ] && [ -x "$HOME/.local/bin/swaync-client" ]; then
  SWAYNC_PLASMA_DIR="$HOME/.config/swaync-bazzite"
  mkdir -p "$SWAYNC_PLASMA_DIR" "$HOME/.config/systemd/user"
  SWAYNC_PLASMA_TMP=$(mktemp "$SWAYNC_PLASMA_DIR/config.json.XXXXXX")
  if ! jq --arg home "$HOME" -f "$DOTFILES/home/scripts/swaync-bazzite-config.jq" \
    "$DOTFILES/swaync/.config/swaync/config.json" >"$SWAYNC_PLASMA_TMP"; then
    unlink "$SWAYNC_PLASMA_TMP"
    exit 1
  fi
  mv -T "$SWAYNC_PLASMA_TMP" "$SWAYNC_PLASMA_DIR/config.json"
  cat >"$HOME/.config/systemd/user/swaync.service" <<'SWAYNC_UNIT'
[Unit]
Description=Sway Notification Center
PartOf=graphical-session.target
After=graphical-session.target
ConditionEnvironment=XDG_CURRENT_DESKTOP=KDE
ConditionEnvironment=WAYLAND_DISPLAY
ConditionPathExists=%h/.config/swaync-bazzite/config.json

[Service]
Type=dbus
BusName=org.freedesktop.Notifications
ExecStart=%h/.local/bin/swaync --config %h/.config/swaync-bazzite/config.json
Restart=on-failure
RestartSec=3

[Install]
WantedBy=graphical-session.target
SWAYNC_UNIT
  systemctl --user daemon-reload
  systemctl --user reenable swaync.service
  if systemctl --user is-active --quiet graphical-session.target; then
    systemctl --user restart swaync.service
  fi
  echo "  ✓ swaync.service habilitado para Plasma Wayland."
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
# GTK Themes — Colloid-Pink-Dark + iconos Colloid-Pink-Dark + Kafka cursor
# =============================================================================
echo
echo "== GTK Themes =="
if gum confirm "¿Instalar temas GTK e iconos Colloid-Pink-Dark con cursor Kafka?"; then
  COLLOID_TMPDIR=$(mktemp -d)
  echo "  Instalando Colloid-Pink-Dark desde los repositorios upstream..."
  git clone --depth 1 https://github.com/vinceliuice/Colloid-gtk-theme.git "$COLLOID_TMPDIR/Colloid-gtk"
  "$COLLOID_TMPDIR/Colloid-gtk/install.sh" --theme pink --color dark \
    --dest "$HOME/.themes" --libadwaita fixed
  git clone --depth 1 https://github.com/vinceliuice/Colloid-icon-theme.git "$COLLOID_TMPDIR/Colloid-icons"
  "$COLLOID_TMPDIR/Colloid-icons/install.sh" --theme pink --dest "$HOME/.local/share/icons"
  if [ ! -f "$HOME/.themes/Colloid-Pink-Dark/gtk-3.0/gtk.css" ] || \
    [ ! -f "$HOME/.local/share/icons/Colloid-Pink-Dark/index.theme" ]; then
    echo "  ❌ No se generaron los archivos esperados de Colloid-Pink-Dark." >&2
    exit 1
  fi
  # Fedora no incluye xcur2png en los repos base. nwg-look lo usa para las vistas previas.
  if ! command -v xcur2png >/dev/null 2>&1 && [ "$(uname -m)" = x86_64 ]; then
    XCUR2PNG_RPM="$COLLOID_TMPDIR/xcur2png.rpm"
    XCUR2PNG_URL="https://download.copr.fedorainfracloud.org/results/lionheartp/Hyprland/fedora-45-x86_64/10194250-xcur2png/xcur2png-0.7.1-2.fc45.x86_64.rpm"
    XCUR2PNG_SHA256="91112fa5be081392662d6411c54982f6acff717efb81d56dbf2356bedab3cac7"
    if curl -fsSL "$XCUR2PNG_URL" -o "$XCUR2PNG_RPM" &&
      printf '%s  %s\n' "$XCUR2PNG_SHA256" "$XCUR2PNG_RPM" | sha256sum --check --status &&
      rpm2cpio "$XCUR2PNG_RPM" | cpio --quiet -i --to-stdout './usr/bin/xcur2png' >"$COLLOID_TMPDIR/xcur2png" &&
      install -Dm0755 "$COLLOID_TMPDIR/xcur2png" "$HOME/.local/bin/xcur2png"; then
      echo "  ✓ xcur2png instalado para nwg-look."
    else
      echo "  ⚠️  No se pudo instalar xcur2png; las vistas previas de cursores pueden faltar." >&2
    fi
  fi
  rm -rf "$COLLOID_TMPDIR"

  # Stow normalmente enlaza Kafka desde local; usa el mismo tema si aún falta.
  if [ ! -r "/usr/share/icons/Kafka/index.theme" ] &&
    [ ! -r "$HOME/.local/share/icons/Kafka/index.theme" ] &&
    [ ! -r "$HOME/.icons/Kafka/index.theme" ]; then
    KAFKA_SOURCE="$HOME/dotfiles-dizzi/local/.local/share/icons/Kafka"
    if [ ! -r "$KAFKA_SOURCE/index.theme" ]; then
      echo "  ❌ No se encontró el tema Kafka en el repo." >&2
      exit 1
    fi
    mkdir -p "$HOME/.local/share/icons"
    ln -sT "$KAFKA_SOURCE" "$HOME/.local/share/icons/Kafka"
  fi

  # Actualiza solo las claves administradas y conserva otros settings.ini.
  set_gtk_setting() {
    local file="$1"
    local key="$2"
    local value="$3"
    mkdir -p "$(dirname "$file")"
    if [ ! -f "$file" ]; then
      printf '[Settings]\n' >"$file"
    elif ! grep -Fqx '[Settings]' "$file"; then
      printf '\n[Settings]\n' >>"$file"
    fi
    if grep -Eq "^${key}[[:blank:]]*=" "$file"; then
      sed --follow-symlinks -i "s|^${key}[[:blank:]]*=.*|${key}=${value}|" "$file"
    else
      sed --follow-symlinks -i "/^\[Settings\]$/a ${key}=${value}" "$file"
    fi
  }

  for gtk_version in 2.0 3.0 4.0; do
    settings_file="$HOME/.config/gtk-${gtk_version}/settings.ini"
    set_gtk_setting "$settings_file" gtk-theme-name Colloid-Pink-Dark
    set_gtk_setting "$settings_file" gtk-icon-theme-name Colloid-Pink-Dark
    set_gtk_setting "$settings_file" gtk-font-name 'Noto Sans 11'
    set_gtk_setting "$settings_file" gtk-cursor-theme-name Kafka
    set_gtk_setting "$settings_file" gtk-cursor-theme-size 24
  done

  # gtk-2.0 (para apps legacy)
  cat >"$HOME/.gtkrc-2.0.mine" <<'GTK2'
gtk-theme-name="Colloid-Pink-Dark"
gtk-icon-theme-name="Colloid-Pink-Dark"
gtk-font-name="Noto Sans 11"
gtk-cursor-theme-name="Kafka"
gtk-cursor-theme-size=24
GTK2

  if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface gtk-theme 'Colloid-Pink-Dark'
    gsettings set org.gnome.desktop.interface icon-theme 'Colloid-Pink-Dark'
    gsettings set org.gnome.desktop.interface cursor-theme 'Kafka'
    gsettings set org.gnome.desktop.interface cursor-size 24
    gsettings set org.gnome.desktop.interface font-name 'Noto Sans 11'
  fi
  if command -v kwriteconfig6 >/dev/null 2>&1; then
    kwriteconfig6 --file "$HOME/.config/kdeglobals" --group General --key font 'Noto Sans,11,-1,5,50,0,0,0,0,0'
    kwriteconfig6 --file "$HOME/.config/kdeglobals" --group Icons --key Theme Colloid-Pink-Dark
  fi
  if [[ "${XDG_CURRENT_DESKTOP:-}" == *KDE* ]] && command -v plasma-apply-cursortheme >/dev/null 2>&1; then
    plasma-apply-cursortheme Kafka --size 24
    kwriteconfig6 --file kcminputrc --group Mouse --key cursorSize 24
  fi
  echo "  ✓ Colloid-Pink-Dark, Kafka y Noto Sans 11 configurados para GTK y Plasma."
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
    FEDORA_VER=$(rpm -E %fedora)
    if [ ! -f /etc/yum.repos.d/_copr_mineiro-hyprland.repo ]; then
      sudo curl -fsSL -o /etc/yum.repos.d/_copr_mineiro-hyprland.repo \
        "https://copr.fedorainfracloud.org/coprs/mineiro/hyprland/repo/fedora-${FEDORA_VER}/mineiro-hyprland-fedora-${FEDORA_VER}.repo"
    fi
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
cat >"$HOME/.local/bin/wine-staging" <<'WINE_STAGING_EOF'
#!/bin/bash
R="$HOME/.var/app/com.usebottles.bottles/data/bottles/runners/GE-Proton8-26"
export LD_LIBRARY_PATH="$R/lib:$R/lib/wine/x86_64-unix:$R/lib/wine/i386-unix${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export WINEPREFIX="${WINEPREFIX:-$HOME/.wine}"
exec "$R/bin/wine" "$@"
WINE_STAGING_EOF
chmod +x "$HOME/.local/bin/wine-staging"
echo "  ✓ wine-staging wrapper creado en ~/.local/bin/"

# Launcher customrp-discord.sh
cat >"$HOME/.local/bin/juegos/customrp-discord.sh" <<'CUSTOMRP_DISCORD_EOF'
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
