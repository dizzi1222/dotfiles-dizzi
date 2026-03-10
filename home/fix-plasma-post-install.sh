#!/bin/bash
# ═══════════════════════════════════════════════════════════
# FIX PLASMA POST-INSTALL — fixes recopilados de troubleshooting
# Encadenar en fase2-HyprInstall-full.sh con:
#   [[ "$p" =~ ^[Ss]$ ]] && ... && bash ~/fix-plasma-post-install.sh
# ═══════════════════════════════════════════════════════════

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
echo -e "${CYAN}[PLASMA FIX] Aplicando fixes post-instalación...${NC}"

# ── 1. SDDM: asegurar instalado y habilitado ───────────────
sudo pacman -S --needed --noconfirm sddm \
  qt6-svg qt6-virtualkeyboard qt6-multimedia qt6-multimedia-ffmpeg
sudo systemctl enable sddm
sudo systemctl disable gdm lightdm 2>/dev/null || true
sudo systemctl set-default graphical.target

# ── 2. Paquetes Qt que suelen faltar ──────────────────────
sudo pacman -S --needed --noconfirm \
  qt5-wayland qt6-wayland \
  qt6-svg qt6-virtualkeyboard \
  xdg-desktop-portal-kde \
  plasma-desktop plasma-workspace kwin \
  kde-cli-tools powerdevil systemsettings \
  kscreen plasma-nm plasma-pa bluedevil \
  plasma-systemmonitor qt5-tools

# ── 3. CRÍTICO: SDDM Wayland env — causa raíz del cascade ─
# Sin esto, los servicios KDE no encuentran el DBus session bus
# y plasma-kcminit → ksmserver → kded6 → plasmashell hacen timeout
sudo mkdir -p /etc/sddm.conf.d
sudo tee /etc/sddm.conf.d/wayland-env.conf >/dev/null <<'EOF'
[Wayland]
SessionDir=/usr/share/wayland-sessions
EOF

# ── 4. KWin: deshabilitar compositing problemático ─────────
mkdir -p ~/.config/plasma-workspace/env
cat >~/.config/plasma-workspace/env/kwin.env <<'EOF'
KWIN_COMPOSE=N
KWIN_DRM_NO_AMS=1
EOF

# ── 5. KSplash: OFF (causa timeouts en boot) ───────────────
kwriteconfig6 --file ksplashrc --group KSplash --key Engine "none" 2>/dev/null ||
  kwriteconfig5 --file ksplashrc --group KSplash --key Engine "none" 2>/dev/null || true

# ── 6. xdg-desktop-portal: forzar backend KDE ─────────────
# hyprland-portals.conf se usa en sesión Hyprland
# portals.conf se usa en sesión Plasma
mkdir -p ~/.config/xdg-desktop-portal
cat >~/.config/xdg-desktop-portal/portals.conf <<'EOF'
[preferred]
default=kde
org.freedesktop.impl.portal.Settings=kde
org.freedesktop.impl.portal.Lockdown=kde
org.freedesktop.impl.portal.Screenshot=kde
org.freedesktop.impl.portal.ScreenCast=kde
EOF

# hyprland-portals.conf separado (solo aplica en sesión Hyprland)
cat >~/.config/xdg-desktop-portal/hyprland-portals.conf <<'EOF'
[preferred]
default=hyprland;gtk
org.freedesktop.impl.portal.Screenshot=hyprland
org.freedesktop.impl.portal.ScreenCast=hyprland
EOF

# ── 7. Espanso: desacoplar de systemd ─────────────────────
# Crashea sin compositor → bucle infinito → bloquea arranque Plasma
# systemctl --user disable espanso.service 2>/dev/null || true
# systemctl --user stop espanso.service 2>/dev/null || true
echo -e "${YELLOW}[INFO] Espanso desacoplado — lanzar desde hyprland.conf:${NC}"
echo -e "       exec-once = sleep 5 && espanso start"

# ── 8. eww update-cover-loop: deshabilitar servicio duplicado ──
# El defpoll en eww.yuck ya lo maneja, el .service lo duplica
# systemctl --user disable update-cover.loop.service 2>/dev/null || true
# systemctl --user stop update-cover.loop.service 2>/dev/null || true

# ── 9. Autostart: quitar +x (genera warnings en log) ──────
for f in \
  ~/.config/autostart/input-remapper.desktop \
  ~/.config/autostart/montar_gdrive.desktop \
  ~/.config/autostart/easyeffects.desktop \
  ~/.config/autostart/montar_gdmusica.desktop; do
  [ -f "$f" ] && chmod -x "$f"
done

# ── 10. montar_gdmusica.desktop: borrar si el .sh no existe ──
if [ ! -f ~/montar_gdmusica.sh ] && [ -f ~/.config/autostart/montar_gdmusica.desktop ]; then
  rm -f ~/.config/autostart/montar_gdmusica.desktop
fi

# ── 11. Plasma configs corruptas: limpiar ─────────────────
rm -f ~/.config/plasma-org.kde.plasma.desktop-appletsrc
rm -f ~/.config/plasmashellrc
rm -f ~/.config/ksmserverrc

# ── 12. Baloo + servicios pesados: deshabilitar en Hyprland ──
systemctl --user disable kde-baloo.service 2>/dev/null || true
systemctl --user disable plasma-powerdevil.service 2>/dev/null || true
systemctl --user disable plasma-kdeconnect.service 2>/dev/null || true

# ── 13. swaync: ocultar del autostart de Plasma ───────────
mkdir -p ~/.config/autostart
cat >~/.config/autostart/swaync.desktop <<'EOF'
[Desktop Entry]
Hidden=true
EOF

# ── 14. drkonqi: limpiar crashes acumulados ───────────────
rm -rf ~/.cache/drkonqi/ 2>/dev/null || true

# ── 15. Verificar que hyprland.desktop existe y con permisos ──
if [ -f /usr/share/wayland-sessions/hyprland.desktop ]; then
  sudo chmod 644 /usr/share/wayland-sessions/hyprland.desktop
  echo -e "${GREEN}[OK] hyprland.desktop con permisos correctos${NC}"
else
  echo -e "${YELLOW}[WARN] hyprland.desktop no encontrado — reinstala hyprland si es necesario${NC}"
fi

# ── 16. display-manager symlink: apuntar a sddm ───────────
if [ -f /usr/lib/systemd/system/sddm.service ]; then
  sudo ln -sf /usr/lib/systemd/system/sddm.service \
    /etc/systemd/system/display-manager.service
  echo -e "${GREEN}[OK] display-manager.service → sddm${NC}"
fi

echo
echo -e "${GREEN}[PLASMA FIX] ✓ Todos los fixes aplicados.${NC}"
echo -e "${CYAN}→ Reinicia y selecciona 'Plasma (Wayland)' en SDDM.${NC}"
echo -e "${CYAN}→ Si sigue fallando: journalctl -b0 --user | grep -iE 'kwin|plasma|portal|timeout|fail' | tail -40${NC}"
# ── 17. Agregar al final del fix (paso 17) ──────────────────────
# Agregar al final del fix (paso 17)
systemctl --user start xdg-desktop-portal-hyprland
systemctl --user restart xdg-desktop-portal
