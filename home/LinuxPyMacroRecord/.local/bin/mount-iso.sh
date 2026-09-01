#!/bin/bash
OUTPUT=$(udisksctl loop-setup -f "$1")
# Extrae el loop device del output: "Mapped file ... as /dev/loop0."
LOOP=$(echo "$OUTPUT" | grep -oP '/dev/loop\d+')

if [ -n "$LOOP" ]; then
    udisksctl mount -b "$LOOP"
    # Busca donde se montó y abre la carpeta
    MOUNT_POINT=$(lsblk -o MOUNTPOINT -nr "$LOOP" | head -1)
    [ -n "$MOUNT_POINT" ] && xdg-open "$MOUNT_POINT"
fi
