#!/usr/bin/env bash
# setup-via-a-arzopa.sh — Instala "Zen en la Arzopa" para SteamOS Game Mode.
#
# Diseño:
#   1. ExecStartPre del unit de gamescope mueve card0 a seat-arzopa ANTES de
#      que gamescope haga TakeControl de seat0. Así logind no toma el DRM
#      master de card0.
#   2. Un servicio de usuario lanza cage (LIBSEAT_BACKEND=noop) en card0.
#   3. ExecStopPost devuelve card0 a seat0 al volver a Desktop Mode.
#
# Estado: WIP. Requiere reiniciar la sesión de Game Mode para validar que card0
# queda sin DRM master. Ver README-arzopa-gamemode.md.
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  printf 'Este instalador requiere sudo:\n  sudo %s\n' "$0" >&2
  exit 1
fi

USER_NAME="${SUDO_USER:-diego}"
USER_HOME="$(getent passwd "$USER_NAME" | cut -d: -f6)"
USER_GROUP="$(id -gn "$USER_NAME")"
USER_UID="$(id -u "$USER_NAME")"
USER_RUNTIME="/run/user/$USER_UID"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 0. Shim de libseat: que libinput use seat-arzopa en vez de seat0 -----------
install -d /usr/local/lib
gcc -shared -fPIC -O2 -o /usr/local/lib/libseat-seat-arzopa.so \
    "$SCRIPT_DIR/libseat-seat-arzopa.c"

# 1. Helpers root de attach/detach ------------------------------------------
cat > /usr/local/bin/arzopa-attach <<'EOF'
#!/usr/bin/env bash
# uso: arzopa-attach [--keyboard] [--keyboard-only]
#   sin flags      → card0 + puntero
#   --keyboard     → card0 + puntero + teclado interno
#   --keyboard-only→ solo teclado interno (toggle desde system-control)
set -euo pipefail

WITH_KEYBOARD=0
ONLY_KEYBOARD=0
for arg in "$@"; do
  case "$arg" in
    --keyboard) WITH_KEYBOARD=1 ;;
    --keyboard-only) ONLY_KEYBOARD=1 ;;
  esac
done

find_event_parent() {
  local e name wanted
  for wanted in "$@"; do
    for e in /sys/class/input/event*; do
      name="$(cat "$e/device/name" 2>/dev/null || true)"
      case "$name" in
        *"$wanted"*) dirname "$(readlink -f "$e")"; return 0 ;;
      esac
    done
  done
  return 1
}

KEYBOARD="$(find_event_parent "AT Translated Set 2 keyboard" || true)"

if [ "$ONLY_KEYBOARD" = 1 ]; then
  [ -n "$KEYBOARD" ] && loginctl attach seat-arzopa "$KEYBOARD"
  exit 0
fi

CARD="$(readlink -f /sys/class/drm/card0)"
loginctl attach seat-arzopa "$CARD"

# Puntero dedicado: USB Lenovo → G203 → touchpad (fallback).
DEV="$(find_event_parent \
  "Logitech Lenovo USB Optical Mouse" \
  "G203" \
  "Synaptics TM3512-010" || true)"
if [ -n "$DEV" ]; then
  loginctl attach seat-arzopa "$DEV"
fi

if [ "$WITH_KEYBOARD" = 1 ] && [ -n "$KEYBOARD" ]; then
  loginctl attach seat-arzopa "$KEYBOARD"
fi
EOF
chmod 755 /usr/local/bin/arzopa-attach

cat > /usr/local/bin/arzopa-detach <<'EOF'
#!/usr/bin/env bash
# uso: arzopa-detach [--keyboard-only]
#   sin flags      → devuelve card0 + puntero + teclado a seat0
#   --keyboard-only→ solo devuelve el teclado interno
set -euo pipefail

ONLY_KEYBOARD=0
[ "${1:-}" = "--keyboard-only" ] && ONLY_KEYBOARD=1

find_event_parent() {
  local e name wanted
  for wanted in "$@"; do
    for e in /sys/class/input/event*; do
      name="$(cat "$e/device/name" 2>/dev/null || true)"
      case "$name" in
        *"$wanted"*) dirname "$(readlink -f "$e")"; return 0 ;;
      esac
    done
  done
  return 1
}

KEYBOARD="$(find_event_parent "AT Translated Set 2 keyboard" || true)"
if [ -n "$KEYBOARD" ]; then
  loginctl detach seat-arzopa "$KEYBOARD" 2>/dev/null || true
  loginctl attach seat0 "$KEYBOARD" 2>/dev/null || true
fi
[ "$ONLY_KEYBOARD" = 1 ] && exit 0

CARD="$(readlink -f /sys/class/drm/card0)"
loginctl detach seat-arzopa "$CARD" 2>/dev/null || true
loginctl attach seat0 "$CARD" 2>/dev/null || true

DEV="$(find_event_parent \
  "Logitech Lenovo USB Optical Mouse" \
  "G203" \
  "Synaptics TM3512-010" || true)"
if [ -n "$DEV" ]; then
  loginctl detach seat-arzopa "$DEV" 2>/dev/null || true
  loginctl attach seat0 "$DEV" 2>/dev/null || true
fi
EOF
chmod 755 /usr/local/bin/arzopa-detach

# 2. sudoers sin contraseña solo para esos dos helpers ----------------------
cat > /etc/sudoers.d/arzopa-gamemode <<EOF
$USER_NAME ALL=(root) NOPASSWD: /usr/local/bin/arzopa-attach, /usr/local/bin/arzopa-detach
EOF
chmod 440 /etc/sudoers.d/arzopa-gamemode
visudo -cf /etc/sudoers.d/arzopa-gamemode >/dev/null

# 3. Acceso a card0 cuando está fuera de seat0 -------------------------------
cat > /etc/udev/rules.d/70-arzopa-card0.rules <<EOF
SUBSYSTEM=="drm", KERNEL=="card0", OWNER="$USER_NAME", MODE="0600"
EOF
udevadm control --reload-rules
udevadm trigger --sysname-match=card0 || true
chown "$USER_NAME" /dev/dri/card0 2>/dev/null || true

# 4. Drop-in del unit de gamescope ------------------------------------------
DROPIN_DIR="$USER_HOME/.config/systemd/user/gamescope-session-plus@ogui-steam.service.d"
install -d -o "$USER_NAME" -g "$USER_GROUP" "$DROPIN_DIR"
cat > "$DROPIN_DIR/arzopa.conf" <<'EOF'
[Service]
ExecStartPre=/usr/bin/sudo -n /usr/local/bin/arzopa-attach --keyboard
ExecStopPost=/usr/bin/sudo -n /usr/local/bin/arzopa-detach
EOF
chown "$USER_NAME:$USER_GROUP" "$DROPIN_DIR/arzopa.conf"

# 5. Servicio de usuario que lanza cage en card0 -----------------------------
USER_UNIT_DIR="$USER_HOME/.config/systemd/user"
install -d -o "$USER_NAME" -g "$USER_GROUP" "$USER_UNIT_DIR"
cat > "$USER_UNIT_DIR/arzopa-gamemode.service" <<EOF
[Unit]
Description=Zen Browser en Arzopa (Game Mode)
After=gamescope-session-plus@ogui-steam.service
PartOf=gamescope-session-plus@ogui-steam.service

[Service]
Type=simple
ExecStart=$SCRIPT_DIR/arzopa-gamemode.sh start
ExecStop=$SCRIPT_DIR/arzopa-gamemode.sh stop
Restart=on-failure
RestartSec=3

[Install]
WantedBy=gamescope-session-plus@ogui-steam.service
EOF
chown "$USER_NAME:$USER_GROUP" "$USER_UNIT_DIR/arzopa-gamemode.service"

# 6. Limpiar el intento anterior (unit de sistema roto) ----------------------
systemctl disable arzopa-gamemode.service 2>/dev/null || true
rm -f /etc/systemd/system/arzopa-gamemode.service
rm -f /etc/systemd/system/gamescope-session-plus@ogui-steam.service.wants/arzopa-gamemode.service
rmdir /etc/systemd/system/gamescope-session-plus@ogui-steam.service.wants 2>/dev/null || true
systemctl daemon-reload

# 7. Habilitar el servicio de usuario (sin arrancarlo ahora) ------------------
# En esta sesión card0 todavía tiene el master de logind; el arranque real debe
# ocurrir en una sesión nueva, después del ExecStartPre.
runuser -u "$USER_NAME" -- env XDG_RUNTIME_DIR="$USER_RUNTIME" systemctl --user daemon-reload
runuser -u "$USER_NAME" -- env XDG_RUNTIME_DIR="$USER_RUNTIME" systemctl --user enable arzopa-gamemode.service

printf '\n✅ Instalado.\n'
printf '⚠️  Reiniciá la sesión de Game Mode (o el equipo) para que card0 salga de\n'
printf '    seat0 ANTES de que gamescope tome control.\n'
printf 'ℹ️  Input: puntero (Lenovo → G203 → touchpad) y teclado interno se\n'
printf '    mueven a seat-arzopa; vuelven a seat0 al salir de Game Mode.\n'
printf 'ℹ️  Log: ~/.cache/arzopa-gamemode.log\n'
