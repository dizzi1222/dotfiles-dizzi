#!/bin/bash
# 1. Parar todo
waydroid session stop
sudo systemctl stop waydroid-container

# 2. Iniciar solo el contenedor
sudo systemctl start waydroid-container

# 3. Setear props ANTES de la sesión
waydroid prop set persist.waydroid.width 1920
waydroid prop set persist.waydroid.height 1080
waydroid prop set persist.waydroid.multi_windows false

# 4. Iniciar sesión y UI
waydroid session start &
sleep 5
waydroid show-full-ui
