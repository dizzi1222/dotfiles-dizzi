#!/bin/bash
# Script para ejecutar waydroid_script con entorno virtual
# Creado para facilitar la ejecución desde el menú rofi

SCRIPT_DIR="$HOME/waydroid_script/"
VENV_DIR="$SCRIPT_DIR/venv"

# ─────────────────────────────────────────────────────────────
# FIX AUTOMÁTICO: EndeavourOS / Arch con nftables
# El script waydroid-net.sh falla al detectar nft/iptables-legacy
# en sistemas que usan nftables moderno (común en EndeavourOS)
# ─────────────────────────────────────────────────────────────
WAYDROID_NET="/usr/lib/waydroid/data/scripts/waydroid-net.sh"

apply_net_fix() {
  echo "🔧 Aplicando fix de red para nftables..."
  sudo sed -i~ -E 's/=.\$\(command -v (nft|ip6?tables-legacy).*/=/g' "$WAYDROID_NET" &&
    echo "✅ Fix aplicado correctamente." ||
    echo "⚠️  No se pudo aplicar el fix (¿ya estaba aplicado?)."
}

if [ -f "$WAYDROID_NET" ]; then
  # Detectar si es EndeavourOS
  if grep -qi "endeavouros" /etc/os-release 2>/dev/null; then
    echo "🐧 Sistema detectado: EndeavourOS"
    apply_net_fix

  # O si usa nftables (más genérico, aplica a cualquier Arch-based)
  elif command -v nft &>/dev/null && ! command -v iptables-legacy &>/dev/null; then
    echo "🐧 Sistema con nftables detectado (sin iptables-legacy)"
    apply_net_fix

  else
    echo "✅ Sistema compatible con iptables estándar, no se necesita fix."
  fi
else
  echo "⚠️  No se encontró $WAYDROID_NET — ¿Waydroid instalado?"
fi

echo ""

# ─────────────────────────────────────────────────────────────
# CLONAR REPO SI NO EXISTE
# ─────────────────────────────────────────────────────────────
if [ ! -d "$SCRIPT_DIR" ]; then
  echo "No se encuentra el directorio $SCRIPT_DIR"
  echo "Clonando repositorio..."
  git clone https://github.com/casualsnek/waydroid_script.git "$SCRIPT_DIR" || {
    echo "Error al clonar el repositorio."
    read -p "Presiona Enter para salir..."
    exit 1
  }
fi

cd "$SCRIPT_DIR" || exit 1

# ─────────────────────────────────────────────────────────────
# ENTORNO VIRTUAL
# ─────────────────────────────────────────────────────────────
if [ ! -d "$VENV_DIR" ]; then
  echo "Creando entorno virtual..."
  python -m venv venv

  echo "Activando entorno virtual..."
  source venv/bin/activate

  echo "Instalando dependencias..."
  pip install --upgrade pip
  pip install inquirerpy requests tqdm

  if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
  fi
else
  echo "Activando entorno virtual existente..."
  source venv/bin/activate
fi

# ─────────────────────────────────────────────────────────────
# EJECUTAR SCRIPT PRINCIPAL
# ─────────────────────────────────────────────────────────────
echo "Ejecutando waydroid_script..."
echo "=========================================="
sudo venv/bin/python main.py

deactivate

echo "=========================================="
echo "Script finalizado. Presiona Enter para salir..."

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║  💡 TIP: Para obtener el Android ID:                 ║"
echo "║                                                      ║"
echo "║  1. waydroid session stop                            ║"
echo "║  2. sudo systemctl stop waydroid-container           ║"
echo "║  3. sudo systemctl start waydroid-container          ║"
echo "║  4. waydroid session start  (espera ~10s)            ║"
echo "║  5. sudo waydroid shell                              ║"
echo "║  6. settings get secure android_id                   ║"
echo "║                                                      ║"
echo "║  Luego: https://google.com/android/uncertified       ║"
echo "╚══════════════════════════════════════════════════════╝"
read
