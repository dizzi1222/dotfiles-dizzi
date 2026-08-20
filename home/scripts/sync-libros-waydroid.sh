#!/bin/bash
# Sincroniza /home/diego/mi_gdlibros/📖Libros → Waydroid Documents
# Monta el almacenamiento de Waydroid con bindfs (uid propio), copia con rsync y desmonta.

SRC="/home/diego/mi_gdlibros/📖Libros"
MEDIA="/home/diego/.local/share/waydroid/data/media/0"
MOUNT="/mnt/waydroid"
DEST="/mnt/waydroid/Documents"

notify() { notify-send "Sync GD Libros → Waydroid" "$1" 2>/dev/null || true; }

# 1. Asegurar mi_gdlibros montado
if ! mountpoint -q /home/diego/mi_gdlibros; then
  echo "🔗 Montando mi_gdlibros (rclone)..."
  bash /home/diego/montar_gd-libros.sh
  sleep 3
fi

if [ ! -d "$SRC" ]; then
  echo "❌ No existe $SRC"
  notify "Fallo: no existe $SRC"
  exit 1
fi

# 2. Montar almacenamiento de Waydroid con permisos de usuario
echo "🔧 Preparando montaje de Waydroid..."
sudo mkdir -p "$MOUNT"
sudo umount "$MOUNT" 2>/dev/null
if command -v bindfs &>/dev/null; then
  sudo bindfs --mirror="$(id -u)" "$MEDIA" "$MOUNT"
else
  sudo mount --bind "$MEDIA" "$MOUNT"
fi

# 3. Sincronizar libros
echo "📂 Sincronizando libros..."
mkdir -p "$DEST"
rsync -av --human-readable "$SRC/" "$DEST/"

# 4. Desmontar
echo "🧹 Desmontando..."
sudo umount "$MOUNT"

echo ""
echo "✅ Libros sincronizados en Waydroid Documents"
notify "Libros sincronizados en Waydroid Documents"