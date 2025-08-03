#!/bin/bash

# Crear carpeta de montaje si no existe
mkdir -p ~/mi_gdmusica
mkdir -p ~/mi_gdrive

# Montar Google Drive "gd-musica"
rclone mount gd-musica:/ ~/mi_gdmusica --vfs-cache-mode full &
rclone mount gdrive:/ ~/mi_gdrive --vfs-cache-mode full &
