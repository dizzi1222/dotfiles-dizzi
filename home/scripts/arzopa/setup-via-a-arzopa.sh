#!/usr/bin/env bash
# setup-via-a-arzopa.sh — Instala "Zen en la Arzopa" para SteamOS Game Mode.
#
# Diseño:
#   1. ExecStartPre del unit de gamescope mueve card0 a seat-arzopa ANTES de
#      que gamescope haga TakeControl de seat0. Así logind no toma el DRM
#      master de card0. El teclado interno y el touchpad solo pasan a la
#      Arzopa si hay monitor y teclado/mouse externos (arzopa-seat.sh).
#   2. Un servicio de usuario lanza cage (LIBSEAT_BACKEND=noop) en card0 si
#      hay un monitor conectado.
#   3. ExecStopPost devuelve todo a seat0 al volver a Desktop Mode, y un
#      servicio de sistema repite eso en cada arranque por si Game Mode se
#      cerró mal.
#
# Ver README-arzopa-gamemode.md.
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
# Misma fuente (arzopa-seat.sh); el nombre con que se invoca elige el modo.
# Se copian como root: la copia instalada no depende del repo (editable por
# el usuario) y sudoers solo autoriza estas rutas.
for helper in arzopa-attach arzopa-detach; do
  install -m 755 -o root -g root "$SCRIPT_DIR/arzopa-seat.sh" "/usr/local/bin/$helper"
done

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
# '-': si el reparto falla, Game Mode arranca igual y todo queda en la laptop
ExecStartPre=-/usr/bin/sudo -n /usr/local/bin/arzopa-attach
ExecStopPost=-/usr/bin/sudo -n /usr/local/bin/arzopa-detach
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
# Si cage falla 3 veces en un minuto se deja de reintentar (antes: bucle)
StartLimitIntervalSec=60
StartLimitBurst=3

[Service]
Type=simple
# Sin monitor en card0 la unidad queda omitida y no lanza cage
ExecCondition=$SCRIPT_DIR/arzopa-gamemode.sh check
ExecStart=$SCRIPT_DIR/arzopa-gamemode.sh start
ExecStop=$SCRIPT_DIR/arzopa-gamemode.sh stop
Restart=on-failure
RestartSec=3

[Install]
WantedBy=gamescope-session-plus@ogui-steam.service
EOF
chown "$USER_NAME:$USER_GROUP" "$USER_UNIT_DIR/arzopa-gamemode.service"

# 6. Reset al arrancar --------------------------------------------------------
# loginctl attach deja reglas persistentes en /etc/udev/rules.d: si Game Mode
# se cierra mal (corte de luz, cuelgue), teclado y touchpad seguirían en
# seat-arzopa en el próximo arranque, también en Desktop Mode.
cat > /etc/systemd/system/arzopa-seat-reset.service <<'EOF'
[Unit]
Description=Arzopa: devolver card0, teclado y touchpad a seat0 al arrancar
After=systemd-logind.service systemd-udev-trigger.service
Before=display-manager.service

[Service]
Type=oneshot
# '-': si udev tarda más de 10 s (dock, eGPU), el reset igual se ejecuta
ExecStartPre=-/usr/bin/udevadm settle --timeout=10
ExecStart=/usr/local/bin/arzopa-detach

[Install]
WantedBy=multi-user.target
EOF

# 7. Limpiar el intento anterior (unit de sistema roto) ----------------------
systemctl disable arzopa-gamemode.service 2>/dev/null || true
rm -f /etc/systemd/system/arzopa-gamemode.service
rm -f /etc/systemd/system/gamescope-session-plus@ogui-steam.service.wants/arzopa-gamemode.service
rmdir /etc/systemd/system/gamescope-session-plus@ogui-steam.service.wants 2>/dev/null || true
systemctl daemon-reload
systemctl enable arzopa-seat-reset.service

# 8. Habilitar el servicio de usuario (sin arrancarlo ahora) ------------------
# En esta sesión card0 todavía tiene el master de logind; el arranque real debe
# ocurrir en una sesión nueva, después del ExecStartPre.
runuser -u "$USER_NAME" -- env XDG_RUNTIME_DIR="$USER_RUNTIME" systemctl --user daemon-reload
runuser -u "$USER_NAME" -- env XDG_RUNTIME_DIR="$USER_RUNTIME" systemctl --user enable arzopa-gamemode.service

printf '\n✅ Instalado.\n'
printf '⚠️  Reiniciá la sesión de Game Mode (o el equipo) para que card0 salga de\n'
printf '    seat0 ANTES de que gamescope tome control.\n'
printf 'ℹ️  Input: teclado interno y touchpad pasan a seat-arzopa solo si hay monitor\n'
printf '    en card0 y teclado/mouse externos; si no, se quedan en la laptop.\n'
printf '    Ver qué haría ahora: sudo /usr/local/bin/arzopa-attach --dry-run\n'
printf 'ℹ️  Log: ~/.cache/arzopa-gamemode.log y\n'
printf '    journalctl --user -u gamescope-session-plus@ogui-steam -u arzopa-gamemode\n'
