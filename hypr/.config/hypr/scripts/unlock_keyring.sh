#!/bin/bash

# Este script intenta desbloquear el llavero automáticamente si tu contraseña de usuario es la misma.
# gnome-keyring-daemon ya debería estar corriendo si lo iniciaste con exec-once.
# Este comando le indica a systemd (o al sistema de inicio) que active el servicio para el llavero.
# password-dialog es una herramienta gráfica para pedir la contraseña si es necesario.

# Intenta desbloquear el llavero por defecto
if pgrep -x gnome-keyring-daemon >/dev/null; then
  # Intenta desbloquear el llavero usando la contraseña de PAM (tu contraseña de inicio de sesión)
  # Esto evita que te pida la contraseña si ya has iniciado sesión
  echo "$(echo YOUR_PASSWORD_HERE | gnome-keyring-daemon --unlock)" # REEMPLAZA YOUR_PASSWORD_HERE CON TU CONTRASEÑA REAL O BUSCA UN MÉTODO MÁS SEGURO
  # Un método más seguro es usar gnome-keyring-daemon --unlock directamente y dejar que te pida la contraseña graficamente.
  # gnome-keyring-daemon --unlock # Esto abrirá la ventana de contraseña si es necesario.

  # Es mejor simplemente asegurarse de que el agente está corriendo y la app se conecta.
  # A menudo, el problema es que el agente no está iniciado correctamente.
  # El password-dialog debería aparecer automáticamente si una app lo necesita y no está desbloqueado.
fi

# Puedes también ejecutar esto si tienes gnome-keyring-tools
# gnome-keyring-daemon --replace --daemonize --components=secrets,ssh
# eval $(gnome-keyring-daemon --start --components=secrets,ssh)

# Una forma común de iniciar el agente:
# /usr/lib/gnome-keyring/gnome-keyring-daemon --daemonize --replace --display="$DISPLAY" --components=pkcs11,secrets,ssh,gpg
# export SSH_AUTH_SOCK GNOME_KEYRING_CONTROL GNOME_KEYRING_PID

# Para Wayland, a menudo basta con el exec-once y que la contraseña del llavero sea la misma que la de login.
# La primera aplicación que necesite una clave hará que te pida la contraseña.
# Después de eso, debería permanecer desbloqueado para la sesión.
