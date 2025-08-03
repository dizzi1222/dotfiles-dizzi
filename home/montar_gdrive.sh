#!/bin/bash

mkdir -p ~/mi_gdrive
mkdir -p ~/mi_gdmusica

# Montar Google Drive
rclone mount gdrive:/ ~/mi_gdrive --vfs-cache-mode full &
rclone mount gd-musica:/ ~/mi_gdmusica --vfs-cache-mode full &
