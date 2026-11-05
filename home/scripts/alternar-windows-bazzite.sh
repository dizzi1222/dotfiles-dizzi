#!/usr/bin/env bash
# =============================================================================
# alternar-windows-bazzite.sh — Fuerza boot a Windows en el próximo arranque
# =============================================================================
# En Bazzite (inmutable / ostree) grub2-reboot NO puede persistir next_entry
# en grubenv ( /boot es gestionado por ostree y es read-only ). Se usa
# efibootmgr --bootnext en su lugar, que escribe en la NVRAM UEFI y sí
# persiste entre reboots. Es one-shot: solo afecta al próximo boot, luego
# vuelve al default (Bazzite).
#
# Uso:
#   sudo alternar-windows-bazzite.sh        # usa Boot0001 (Windows)
#   sudo alternar-windows-bazzite.sh 0004   # especifica otro número de boot
#
# Pre-requisito: sudo (efibootmgr escribe NVRAM UEFI).
# =============================================================================

set -euo pipefail

WINDOWS_NUM="${1:-0001}"

if ! command -v efibootmgr >/dev/null 2>&1; then
  echo "alternar-windows-bazzite: efibootmgr no encontrado" >&2
  exit 1
fi

if [ "$EUID" -ne 0 ]; then
  echo "alternar-windows-bazzite: se requiere sudo para escribir NVRAM UEFI" >&2
  exit 1
fi

# Verificar que la entrada exista en NVRAM UEFI
if ! efibootmgr | grep -q "Boot${WINDOWS_NUM}\*"; then
  echo "alternar-windows-bazzite: entrada Boot${WINDOWS_NUM} no encontrada en NVRAM UEFI" >&2
  echo "Entradas disponibles:" >&2
  efibootmgr | grep -iE "windows|bazzite|fedora|linux|nixos" || true
  exit 1
fi

echo "alternar-windows-bazzite: próximo boot → Windows (Boot${WINDOWS_NUM})"
efibootmgr --bootnext "$WINDOWS_NUM"
echo "  Reinicia para bootear a Windows. Al volver a Bazzite se restaura el default automáticamente."
