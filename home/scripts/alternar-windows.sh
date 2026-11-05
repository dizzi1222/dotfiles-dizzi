#!/bin/bash
# alternar-windows.sh — Fuerza GRUB a bootear Windows en el próximo arranque.
# Detecta el índice REAL de la entrada de Windows (os-prober) en grub.cfg en
# lugar de hardcodear "2": tras rebuilds, NixOS agrega entries de configuración
# (0=NixOS, 1-3=configs, 4=Windows…) y el índice se desplaza. grub-reboot escribe
# next_entry=INDICE → one-shot; la extraConfig lo respeta y en el siguiente boot
# vuelve a saved_entry (NixOS).
set -euo pipefail

GRUB_CFG=/boot/grub/grub.cfg

if [ ! -r "$GRUB_CFG" ]; then
  echo "alternar-windows: no se puede leer $GRUB_CFG" >&2
  exit 1
fi

# La entrada de Windows de os-prober tiene --class windows. Tomar el número de
# índice = cuántas menuentry hay ANTES de esa línea (0-based).
win_line=$(awk '/menuentry .*--class windows/ { print NR; exit }' "$GRUB_CFG")
if [ -z "$win_line" ]; then
  echo "alternar-windows: entrada de Windows (os-prober) no encontrada en grub.cfg" >&2
  exit 1
fi

idx=$(awk -v line="$win_line" 'NR < line && /menuentry / { c++ } END { print c }' "$GRUB_CFG")

echo "alternar-windows: Windows en índice $idx (línea $win_line)"
exec /run/current-system/sw/bin/grub-reboot "$idx"