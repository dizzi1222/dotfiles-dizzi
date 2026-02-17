#!/bin/bash
fusermount -u ~/mi_gdmusica 2>/dev/null
mkdir -p ~/mi_gdmusica
rclone mount gd-musica:/ ~/mi_gdmusica --vfs-cache-mode full &
