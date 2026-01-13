#!/bin/bash
# fix-brave-keyring-v2.sh
# Arregla gnome-keyring en Brave (detecta automáticamente GDM/SDDM/LightDM)

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🔧 ARREGLANDO BRAVE GNOME-KEYRING 🔧          ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════╝${NC}"
echo

# ═══════════════════════════════════════════════════════════
# 0. DETECTAR DISPLAY MANAGER
# ═══════════════════════════════════════════════════════════
echo -e "${YELLOW}[0/6]${NC} Detectando display manager..."

DISPLAY_MANAGER=""

# Método 1: systemctl
if systemctl is-active --quiet gdm.service; then
  DISPLAY_MANAGER="gdm"
elif systemctl is-active --quiet sddm.service; then
  DISPLAY_MANAGER="sddm"
elif systemctl is-active --quiet lightdm.service; then
  DISPLAY_MANAGER="lightdm"
fi

# Método 2: Verificar archivos PAM
if [[ -z "$DISPLAY_MANAGER" ]]; then
  if [[ -f /etc/pam.d/gdm ]]; then
    DISPLAY_MANAGER="gdm"
  elif [[ -f /etc/pam.d/sddm ]]; then
    DISPLAY_MANAGER="sddm"
  elif [[ -f /etc/pam.d/lightdm ]]; then
    DISPLAY_MANAGER="lightdm"
  fi
fi

# Método 3: Verificar procesos
if [[ -z "$DISPLAY_MANAGER" ]]; then
  if pgrep -x gdm >/dev/null || pgrep -x gdm-wayland-ses >/dev/null; then
    DISPLAY_MANAGER="gdm"
  elif pgrep -x sddm >/dev/null; then
    DISPLAY_MANAGER="sddm"
  elif pgrep -x lightdm >/dev/null; then
    DISPLAY_MANAGER="lightdm"
  fi
fi

if [[ -z "$DISPLAY_MANAGER" ]]; then
  echo -e "${RED}❌ No se pudo detectar el display manager${NC}"
  echo -e "${YELLOW}Display managers comunes: gdm, sddm, lightdm${NC}"
  read -p "Introduce tu display manager manualmente: " DISPLAY_MANAGER
fi

echo -e "${GREEN}✓${NC} Display Manager detectado: ${BOLD}$DISPLAY_MANAGER${NC}"
echo

# ═══════════════════════════════════════════════════════════
# 1. INSTALAR GNOME-KEYRING
# ═══════════════════════════════════════════════════════════
echo -e "${YELLOW}[1/6]${NC} Verificando gnome-keyring..."

if ! pacman -Qi gnome-keyring &>/dev/null; then
  echo "Instalando gnome-keyring..."
  sudo pacman -S --needed --noconfirm gnome-keyring
else
  echo -e "${GREEN}✓${NC} gnome-keyring ya instalado"
fi

# También instalar libsecret (necesario para Brave)
if ! pacman -Qi libsecret &>/dev/null; then
  echo "Instalando libsecret..."
  sudo pacman -S --needed --noconfirm libsecret
else
  echo -e "${GREEN}✓${NC} libsecret ya instalado"
fi

# ═══════════════════════════════════════════════════════════
# 2. CONFIGURAR PAM SEGÚN EL DISPLAY MANAGER
# ═══════════════════════════════════════════════════════════
echo -e "${YELLOW}[2/6]${NC} Configurando PAM para $DISPLAY_MANAGER..."

PAM_FILE="/etc/pam.d/$DISPLAY_MANAGER"

if [[ ! -f "$PAM_FILE" ]]; then
  echo -e "${RED}❌ Archivo PAM no encontrado: $PAM_FILE${NC}"
  echo -e "${YELLOW}⚠️  Saltando configuración de PAM...${NC}"
else
  # Backup
  sudo cp "$PAM_FILE" "${PAM_FILE}.backup" 2>/dev/null || true

  # Verificar si ya está configurado
  if ! grep -q "pam_gnome_keyring.so" "$PAM_FILE"; then
    echo "Configurando PAM..."

    # Agregar auth opcional
    if grep -q "^auth.*include.*system-login" "$PAM_FILE"; then
      # Estilo SDDM/Arch (usa includes)
      sudo sed -i '/^auth.*include.*system-login/a auth       optional     pam_gnome_keyring.so' "$PAM_FILE"
    elif grep -q "^auth.*pam_unix.so" "$PAM_FILE"; then
      # Estilo GDM (configuración directa)
      sudo sed -i '/^auth.*pam_unix.so/a auth       optional     pam_gnome_keyring.so' "$PAM_FILE"
    else
      # Fallback: agregar al final de la sección auth
      sudo sed -i '/^auth/a auth       optional     pam_gnome_keyring.so' "$PAM_FILE"
    fi

    # Agregar session opcional
    if grep -q "^session.*include.*system-login" "$PAM_FILE"; then
      # Estilo SDDM/Arch
      sudo sed -i '/^session.*include.*system-login/a session    optional     pam_gnome_keyring.so auto_start' "$PAM_FILE"
    elif grep -q "^session.*pam_unix.so" "$PAM_FILE"; then
      # Estilo GDM
      sudo sed -i '/^session.*pam_unix.so/a session    optional     pam_gnome_keyring.so auto_start' "$PAM_FILE"
    else
      # Fallback: agregar al final
      echo "session    optional     pam_gnome_keyring.so auto_start" | sudo tee -a "$PAM_FILE" >/dev/null
    fi

    echo -e "${GREEN}✓${NC} PAM configurado"
  else
    echo -e "${GREEN}✓${NC} PAM ya configurado"
  fi
fi

# ═══════════════════════════════════════════════════════════
# 3. CONFIGURAR AUTOSTART
# ═══════════════════════════════════════════════════════════
echo -e "${YELLOW}[3/6]${NC} Configurando autostart..."

mkdir -p ~/.config/autostart

cat >~/.config/autostart/gnome-keyring.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=GNOME Keyring (Secrets)
Exec=/usr/bin/gnome-keyring-daemon --start --components=secrets
OnlyShowIn=Hyprland;GNOME;KDE;
X-GNOME-Autostart-enabled=true
NoDisplay=true
EOF

echo -e "${GREEN}✓${NC} Autostart configurado"

# ═══════════════════════════════════════════════════════════
# 4. CONFIGURAR HYPRLAND
# ═══════════════════════════════════════════════════════════
echo -e "${YELLOW}[4/6]${NC} Configurando Hyprland..."

HYPR_CONF=~/.config/hypr/hyprland.conf

if [[ -f "$HYPR_CONF" ]]; then
  if ! grep -q "gnome-keyring-daemon.*secrets" "$HYPR_CONF"; then
    cat >>~/.config/hypr/hyprland.conf <<'EOF'

# ═══════════════════════════════════════════════════════════
# GNOME KEYRING (para Brave, Chrome, VSCode, etc)
# ═══════════════════════════════════════════════════════════
exec-once = dbus-update-activation-environment --all
exec-once = gnome-keyring-daemon --start --components=secrets
EOF
    echo -e "${GREEN}✓${NC} Hyprland configurado"
  else
    echo -e "${GREEN}✓${NC} Hyprland ya configurado"
  fi
fi

# ═══════════════════════════════════════════════════════════
# 5. CONFIGURAR VARIABLES DE ENTORNO GLOBALES
# ═══════════════════════════════════════════════════════════
echo -e "${YELLOW}[5/6]${NC} Configurando variables de entorno..."

# Agregar a .zshrc
if [[ -f ~/.zshrc ]] && ! grep -q "GNOME_KEYRING_CONTROL" ~/.zshrc; then
  cat >>~/.zshrc <<'EOF'

# ═══════════════════════════════════════════════════════════
# GNOME Keyring (protegido contra errores de glob)
# ═══════════════════════════════════════════════════════════
if [[ -d /run/user/$(id -u)/keyring ]]; then
  # Control socket
  _keyring_control=$(find /run/user/$(id -u)/keyring* -name control 2>/dev/null | head -1)
  [[ -n "$_keyring_control" ]] && export GNOME_KEYRING_CONTROL="$_keyring_control"
  
  # SSH socket
  _keyring_ssh=$(find /run/user/$(id -u)/keyring* -name ssh 2>/dev/null | head -1)
  [[ -n "$_keyring_ssh" ]] && export SSH_AUTH_SOCK="$_keyring_ssh"
  
  unset _keyring_control _keyring_ssh
fi

EOF
  echo -e "${GREEN}✓${NC} Variables agregadas a .zshrc"
else
  echo -e "${GREEN}✓${NC} Variables ya configuradas"
fi

# ═══════════════════════════════════════════════════════════
# 6. INICIAR GNOME-KEYRING AHORA
# ═══════════════════════════════════════════════════════════
echo -e "${YELLOW}[6/6]${NC} Iniciando gnome-keyring..."

# Matar instancias viejas
pkill -f gnome-keyring-daemon 2>/dev/null || true
sleep 1

# Iniciar nueva instancia
eval $(gnome-keyring-daemon --start --components=secrets 2>/dev/null)
export SSH_AUTH_SOCK
export GNOME_KEYRING_CONTROL

echo -e "${GREEN}✓${NC} gnome-keyring iniciado"

# ═══════════════════════════════════════════════════════════
# VERIFICACIÓN
# ═══════════════════════════════════════════════════════════
echo
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo -e "${CYAN}VERIFICACIÓN:${NC}"
echo

# Display Manager
echo -e "${GREEN}✓${NC} Display Manager: ${BOLD}$DISPLAY_MANAGER${NC}"

# Proceso
if pgrep -f gnome-keyring-daemon >/dev/null; then
  PID=$(pgrep -f gnome-keyring-daemon)
  echo -e "${GREEN}✓${NC} gnome-keyring-daemon corriendo (PID: $PID)"
else
  echo -e "${YELLOW}⚠${NC} gnome-keyring-daemon no detectado"
fi

# Socket/Control
KEYRING_CONTROL=$(ls /run/user/$(id -u)/keyring*/control 2>/dev/null | head -1)
if [[ -n "$KEYRING_CONTROL" ]]; then
  echo -e "${GREEN}✓${NC} Control socket: $KEYRING_CONTROL"
else
  echo -e "${YELLOW}⚠${NC} Control socket no encontrado"
fi

# PAM configurado
if grep -q "pam_gnome_keyring.so" "$PAM_FILE" 2>/dev/null; then
  echo -e "${GREEN}✓${NC} PAM configurado en $PAM_FILE"
else
  echo -e "${YELLOW}⚠${NC} PAM no pudo configurarse"
fi

echo
echo -e "${GREEN}${BOLD}✨ ARREGLO COMPLETADO ✨${NC}"
echo
echo -e "${CYAN}Próximos pasos:${NC}"
echo -e "  1. ${YELLOW}Reinicia el sistema${NC} (o al menos cierra sesión)"
echo -e "  2. ${YELLOW}Abre Brave${NC}"
echo -e "  3. ${YELLOW}Los errores de keyring deberían desaparecer${NC}"
echo
echo -e "${YELLOW}Nota:${NC} En el primer inicio, Brave puede pedir crear una contraseña"
echo -e "       para el keyring. Déjala vacía si no quieres contraseña."
echo
echo -e "${CYAN}Debug (si sigue fallando):${NC}"
echo -e "  ${YELLOW}journalctl --user -u gnome-keyring-secrets.service${NC}"
echo -e "  ${YELLOW}cat /etc/pam.d/$DISPLAY_MANAGER${NC}"
echo
