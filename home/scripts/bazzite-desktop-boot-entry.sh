#!/usr/bin/env bash
# bazzite-desktop-boot-entry.sh — añade entrada BLS "Bazzite Desktop (Plasma)"
#
# Crea una entrada de arranque que usa el MISMO deployment/kernel que se va a
# arrancar, pero añadiendo el kernel arg `bazzite.session=desktop`.
# Un servicio oneshot (bazzite-session-cmdline.service) lee /proc/cmdline y
# ajusta el autologin de SDDM a Plasma cuando detecta ese argumento.
#
# IMPORTANTE: ejecútalo DESPUÉS de reiniciar y aplicar cualquier deployment
# staged. Antes del reboot ese deployment aún no tiene entrada BLS propia
# (comparte kernel con el actual) y sus rutas ostree= no existen todavía.
# El script copia la entrada real generada por rpm-ostree; nunca inventa
# rutas de kernel/initrd.
#
# Uso:  sudo bash ~/scripts/bazzite-desktop-boot-entry.sh
set -euo pipefail
[ "$EUID" -eq 0 ] || { echo "Ejecuta con sudo." >&2; exit 1; }

ENTRIES=/boot/loader/entries
DST="$ENTRIES/zz-bazzite-desktop.conf"

# La entrada se regenera completa: si este script aborta, mejor no dejar una
# entrada vieja apuntando a un kernel que ya no existe.
rm -f "$DST"

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

# ---- 3) elegir la entrada BLS real del deployment objetivo ----
# No se inventan rutas: se copia una entrada generada por rpm-ostree.
# Si hay un deployment staged que aún no tiene entrada propia (comparte
# kernel con el actual), hay que reiniciar primero: hasta el reboot, su
# ostree= todavía no existe en /ostree/boot.*.

# csum del deployment que arrancará en el próximo boot:
#   "(staged)"  = aún sin entrada BLS (hay que reiniciar)
#   "(pending)" = ya finalizado con `ostree admin finalize-staged` (sí tiene)
NEXT=$(ostree admin status 2>/dev/null \
  | sed -n 's/^  default \([0-9a-f]\{64\}\)\.0 \((staged\|pending)\).*/\1/p' | head -1)
IS_STAGED=$(ostree admin status 2>/dev/null \
  | sed -n 's/^  default \([0-9a-f]\{64\}\)\.0 (staged).*/\1/p' | head -1)
BOOTED=$(ostree admin status 2>/dev/null \
  | sed -n 's/^\* default \([0-9a-f]\{64\}\)\.0.*/\1/p' | head -1)

# csum del deployment al que apunta una entrada BLS (resuelve el symlink)
entry_csum() {
  local opt
  opt=$(sed -n 's/^options .*ostree=\([^ ]*\).*/\1/p' "$1")
  [ -n "$opt" ] || return 1
  readlink -f "/$opt" 2>/dev/null \
    | sed -n 's#.*/deploy/\([0-9a-f]\{64\}\)\.0#\1#p'
}

find_entry_for() {
  local want=$1 f
  [ -n "$want" ] || return 1
  for f in "$ENTRIES"/ostree*.conf; do
    [ -f "$f" ] || continue
    if [ "$(entry_csum "$f" || true)" = "$want" ]; then
      printf '%s\n' "$f"
      return 0
    fi
  done
  return 1
}

if [ -n "$NEXT" ]; then
  if SRC=$(find_entry_for "$NEXT"); then
    echo "Deployment pendiente detectado: ${NEXT:0:12}…"
  elif [ -n "$IS_STAGED" ]; then
    echo "Hay un deployment staged (${NEXT:0:12}…) que aún no tiene entrada BLS." >&2
    echo "Reinicia para aplicarlo y vuelve a ejecutar este script." >&2
    exit 1
  else
    echo "No se encontró entrada BLS para el deployment pendiente (${NEXT:0:12}…)." >&2
    exit 1
  fi
else
  SRC=$(find_entry_for "$BOOTED") || {
    echo "No se encontró entrada BLS para el deployment en ejecución (${BOOTED:0:12}…)." >&2
    exit 1
  }
fi

# La entrada base debe apuntar a kernel/initrd que existan de verdad
while read -r p; do
  [ -e "/boot$p" ] || { echo "Entrada base inválida: falta /boot$p en $SRC" >&2; exit 1; }
done < <(sed -n 's/^\(linux\|initrd\) //p' "$SRC")

# ---- 4) generar la entrada Desktop a partir de la base ----
TMP=$(mktemp "${ENTRIES}/.zz-bazzite-desktop.XXXXXX")
trap 'rm -f "$TMP"' EXIT
sed -e 's/^title .*/title Bazzite Desktop (Plasma)/' \
    -e 's/^options /options bazzite.session=desktop /' \
    "$SRC" > "$TMP"
mv -f "$TMP" "$DST"
trap - EXIT

echo "Base:   $SRC"
echo "Creada: $DST"
grep -E '^title|^version|^options' "$DST"
