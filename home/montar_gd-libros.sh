#!/bin/bash
fusermount -u ~/mi_gdlibros 2>/dev/null
mkdir -p ~/mi_gdlibros
rclone mount gd-libros:/ ~/mi_gdlibros --vfs-cache-mode full &
