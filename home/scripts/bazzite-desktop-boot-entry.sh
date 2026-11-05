#!/usr/bin/env bash
# bazzite-desktop-boot-entry.sh — añade entrada BLS "Bazzite Desktop (Plasma)"
#
# Crea una entrada de arranque que usa el MISMO deployment/kernel que se va a
# arrancar, pero añadiendo el kernel arg `bazzite.session=desktop`.
# Un servicio oneshot (bazzite-session-cmdline.service) lee /proc/cmdline y
# ajusta el autologin de SDDM a Plasma cuando detecta ese argumento.
#
# Si hay un deployment PENDIENTE (staged ya finalizado, pendiente de reboot),
# la entrada se genera a partir de ÉL y no del deployment en ejecución, para
# que "Bazzite Desktop" arranque el deployment nuevo (p. ej. con Discord).
#
# Uso:  sudo bash ~/scripts/bazzite-desktop-boot-entry.sh
set -euo pipefail
[ "$EUID" -eq 0 ] || { echo "Ejecuta con sudo." >&2; exit 1; }

ENTRIES=/boot/loader/entries
DST="$ENTRIES/zz-bazzite-desktop.conf"

# ---- 1) helper que decide la sesión SDDM según /proc/cmdline ----
cat > /usr/local/bin/bazzite-session-cmdline <<'EOS'
#!/bin/bash
set -eu
conf=/etc/sddm.conf.d/zz-holo-autologin.conf
mkdir -p /etc/sddm.conf.d
mkdir -p /etc/bazzite
if grep -q 'bazzite.session=desktop' /proc/cmdline; then
  s=plasma.desktop
  touch /etc/bazzite/desktop_autologin
else
  s=gamescope-session-ogui-steam.desktop
  rm -f /etc/bazzite/desktop_autologin
fi
printf '[Autologin]\nSession=%s\n' "$s" > "$conf"
EOS
chmod 755 /usr/local/bin/bazzite-session-cmdline

# ---- 2) servicio oneshot antes del display manager ----
cat > /etc/systemd/system/bazzite-session-cmdline.service <<'EOS'
[Unit]
Description=Selecciona sesión SDDM según kernel cmdline
After=bazzite-autologin.service local-fs.target
Before=display-manager.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/bazzite-session-cmdline

[Install]
WantedBy=multi-user.target
EOS
systemctl daemon-reload
systemctl enable bazzite-session-cmdline.service >/dev/null

# ---- 3) deployment objetivo: pendiente (próximo boot) o el actual ----
# ostree admin status: "* default X" = en ejecución; "  default Y (pending)" = próximo
PENDING=$(ostree admin status 2>/dev/null \
  | sed -n 's/^  default \([0-9a-f]\{64\}\)\.0[[:space:]]*(pending).*/\1/p' | head -1)

# csum del deployment al que apunta una entrada BLS (resuelve el symlink)
entry_csum() {
  local opt
  opt=$(sed -n 's/^options .*ostree=\([^ ]*\).*/\1/p' "$1")
  [ -n "$opt" ] || return 1
  readlink -f "/$opt" 2>/dev/null \
    | sed -n 's#.*/deploy/\([0-9a-f]\{64\}\)\.0#\1#p'
}

CUR_OSTREE=$(tr ' ' '\n' < /proc/cmdline | sed -n 's/^ostree=//p' | head -1)
[ -n "${CUR_OSTREE:-}" ] || { echo "No se pudo leer ostree= de /proc/cmdline" >&2; exit 1; }

SRC=""
if [ -n "${PENDING:-}" ]; then
  for f in "$ENTRIES"/*.conf; do
    [ -f "$f" ] || continue
    case "$f" in */zz-bazzite-desktop.conf) continue;; esac
    if [ "$(entry_csum "$f" || true)" = "$PENDING" ]; then
      SRC="$f"
      break
    fi
  done
  [ -n "$SRC" ] && echo "Deployment pendiente detectado: ${PENDING:0:12}…"
fi

if [ -z "$SRC" ]; then
  for f in "$ENTRIES"/*.conf; do
    [ -f "$f" ] || continue
    case "$f" in */zz-bazzite-desktop.conf) continue;; esac
    if grep -q "ostree=${CUR_OSTREE}\b" "$f"; then
      SRC="$f"
      break
    fi
  done
fi

if [ -z "$SRC" ]; then
  echo "No encontré la entrada BLS para el deployment actual ($CUR_OSTREE)" >&2
  echo "Entradas disponibles:" >&2
  grep -H '^options' "$ENTRIES"/*.conf >&2
  exit 1
fi

# ---- 4) generar la entrada Desktop a partir de la actual ----
sed -e 's/^title .*/title Bazzite Desktop (Plasma)/' \
    -e 's/^version .*/version 99/' \
    -e 's/^options /options bazzite.session=desktop /' \
    "$SRC" > "$DST"

echo "Base:   $SRC"
echo "Creada: $DST"
grep -E '^title|^version|^options' "$DST"
