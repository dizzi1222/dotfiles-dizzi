#!/bin/bash
# ═══════════════════════════════════════════════════════════
# FIX PLASMA POST-INSTALL — fixes recopilados de troubleshooting
# Encadenar en fase2-HyprInstall-full.sh con:
#   [[ "$p" =~ ^[Ss]$ ]] && ... && bash fix-plasma-post-install.sh
# ═══════════════════════════════════════════════════════════

CYAN='\033[0;36m'; GREEN='\033[0;32m'; NC='\033[0m'
echo -e "${CYAN}[PLASMA FIX] Aplicando fixes post-instalación...${NC}"

# ── 1. SDDM: asegurar que está instalado y habilitado ──────
sudo pacman -S --needed --noconfirm sddm
sudo systemctl enable sddm
sudo systemctl disable gdm 2>/dev/null || true

# ── 2. Plasma: paquetes que suelen faltar ──────────────────
sudo pacman -S --needed --noconfirm \
  plasma-desktop plasma-workspace kwin \
  xdg-desktop-portal-kde eos-settings-plasma \
  kde-cli-tools powerdevil systemsettings \
  kscreen plasma-nm plasma-pa bluedevil \
  plasma-systemmonitor qt5-tools \
  qt5-wayland qt6-wayland \
  qt6-svg qt6-virtualkeyboard

# ── 3. KWin: deshabilitar compositing problemático ─────────
mkdir -p ~/.config/plasma-workspace/env
cat > ~/.config/plasma-workspace/env/kwin.env << 'EOF'
KWIN_COMPOSE=N
KWIN_DRM_NO_AMS=1
EOF

# ── 4. KSplash: deshabilitar (causa timeouts en boot) ──────
kwriteconfig6 --file ksplashrc --group KSplash --key Engine "none" 2>/dev/null || \
kwriteconfig5 --file ksplashrc --group KSplash --key Engine "none" 2>/dev/null || true

# ── 5. xdg-desktop-portal: forzar backend KDE en Plasma ───
mkdir -p ~/.config/xdg-desktop-portal
cat > ~/.config/xdg-desktop-portal/portals.conf << 'EOF'
[preferred]
default=kde
org.freedesktop.impl.portal.Settings=kde
org.freedesktop.impl.portal.Lockdown=kde
EOF

# ── 6. Espanso: NO lanzar con systemd (crashea sin compositor) ─
systemctl --user disable espanso.service 2>/dev/null || true
systemctl --user stop espanso.service 2>/dev/null || true
# Espanso se lanza desde hyprland.conf con: exec-once = sleep 5 && espanso start

# ── 7. eww update-cover-loop: deshabilitar servicio duplicado ──
systemctl --user disable update-cover.loop.service 2>/dev/null || true
systemctl --user stop update-cover.loop.service 2>/dev/null || true

# ── 8. Autostart: quitar +x de .desktop files (warnings en log) ─
for f in \
  ~/.config/autostart/input-remapper.desktop \
  ~/.config/autostart/montar_gdrive.desktop \
  ~/.config/autostart/easyeffects.desktop; do
  [ -f "$f" ] && chmod -x "$f"
done

# ── 9. montar_gdmusica.desktop: borrar si el .sh no existe ────
if [ ! -f ~/montar_gdmusica.sh ] && [ -f ~/.config/autostart/montar_gdmusica.desktop ]; then
  rm -f ~/.config/autostart/montar_gdmusica.desktop
fi

# ── 10. Plasma configs: limpiar configs corruptas acumuladas ───
rm -f ~/.config/plasma-org.kde.plasma.desktop-appletsrc
rm -f ~/.config/plasmashellrc
rm -f ~/.config/ksmserverrc

# ── 11. Baloo + KDE Connect: deshabilitar en Hyprland ─────────
systemctl --user disable kde-baloo.service 2>/dev/null || true
systemctl --user disable plasma-powerdevil.service 2>/dev/null || true
systemctl --user disable plasma-kdeconnect.service 2>/dev/null || true

# ── 12. swaync: ocultar del autostart de Plasma ───────────────
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/swaync.desktop << 'EOF'
[Desktop Entry]
Hidden=true
EOF

# ── 13. drkonqi: limpiar crashes acumulados ───────────────────
rm -rf ~/.cache/drkonqi/ 2>/dev/null || true

echo -e "${GREEN}[PLASMA FIX] ✓ Todos los fixes aplicados.${NC}"
echo -e "${CYAN}→ Reinicia y selecciona 'Plasma (Wayland)' en SDDM.${NC}"
