#!/bin/bash
# ~/fix-ydotool.sh
echo -e "\033[96m${BOLD}🔧 Configurando ydotool...\033[0m"

# Detener servicios viejos
systemctl --user stop ydotool ydotool.socket 2>/dev/null

# Crear directorio para socket si no existe
mkdir -p /tmp

# Crear socket unit correcta
cat >~/.config/systemd/user/ydotool.socket <<'EOF'
[Unit]
Description=YDotool socket

[Socket]
ListenStream=/tmp/.ydotool_socket
SocketMode=0600

[Install]
WantedBy=sockets.target
EOF

# Crear service unit
cat >~/.config/systemd/user/ydotool.service <<'EOF'
[Unit]
Description=YDotool daemon
Requires=ydotool.socket

[Service]
Type=simple
ExecStart=/usr/bin/ydotoold --socket-path=/tmp/.ydotool_socket
Restart=on-failure
RestartSec=3

[Install]
WantedBy=default.target
EOF

# Recargar e iniciar
systemctl --user daemon-reload
systemctl --user enable --now ydotool.socket
systemctl --user enable --now ydotool

# Esperar y verificar
sleep 2

echo -e "\n\033[92m✅ Verificación:\033[0m"
echo "Socket: $(ls -la /tmp/.ydotool_socket 2>/dev/null | awk '{print $1" "$NF}')"
echo "Estado: $(systemctl --user is-active ydotool)"

# Agregar al shell
echo 'export YDOTOOL_SOCKET=/tmp/.ydotool_socket' >>~/.zshrc
echo 'alias ydover="ydotool version"' >>~/.zshrc

# Probar
echo -e "\n\033[93m🔍 Probando ydotool...\033[0m"
if timeout 2 bash -c 'until ydotool version 2>/dev/null; do sleep 0.1; done'; then
  echo -e "\033[92m✅ ydotool funcionando!\033[0m"
else
  echo -e "\033[91m❌ Error. Intenta manualmente:\033[0m"
  echo "  systemctl --user restart ydotool"
fi
systemctl --user restart ydotool
