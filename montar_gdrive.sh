#!/bin/bash

# Desmontar si ya está montado
fusermount -u ~/mi_gdrive 2>/dev/null

# Crear carpeta de montaje si no existe
mkdir -p ~/mi_gdrive

# Montar Google Drive
rclone mount gdrive:/ ~/mi_gdrive --vfs-cache-mode full &
