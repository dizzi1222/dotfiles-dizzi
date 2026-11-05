#!/usr/bin/env bash
# Montaje de gdrive: con diagnóstico visible antes de dejar rclone en segundo plano.
set -euo pipefail

mountpoint="$HOME/mi_gdrive"
log_dir="${XDG_STATE_HOME:-$HOME/.local/state}/rclone"
log_file="$log_dir/gdrive-mount.log"
mkdir -p "$mountpoint" "$log_dir"

if mountpoint -q "$mountpoint"; then
  echo "Google Drive ya está montado en $mountpoint"
  exit 0
fi

# Un 401 de OAuth ocurría dentro del proceso en background y el script decía
# que había montado Drive aunque el proceso terminara inmediatamente.
if ! rclone lsd gdrive: --max-depth 1 > /dev/null 2> "$log_file"; then
  echo "No se pudo autenticar gdrive:. Diagnóstico: $log_file" >&2
  if grep -qE 'Error 401|Invalid Credentials|invalid_grant' "$log_file"; then
    echo 'Credenciales de Google Drive inválidas: ejecuta rclone config reconnect gdrive: y vuelve a intentar.' >&2
  else
    tail -n 8 "$log_file" >&2
  fi
  exit 1
fi

if ! rclone mount gdrive: "$mountpoint" --vfs-cache-mode full \
  --daemon --daemon-wait 20s --log-file "$log_file" --log-level INFO; then
  echo "Falló el montaje. Consulta $log_file" >&2
  tail -n 8 "$log_file" >&2
  exit 1
fi

echo "Google Drive montado en $mountpoint"
