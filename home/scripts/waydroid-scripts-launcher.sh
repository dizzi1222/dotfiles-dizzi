#!/bin/bash
# Script para ejecutar waydroid_script con entorno virtual
# Creado para facilitar la ejecución desde el menú rofi

SCRIPT_DIR="$HOME/waydroid_script/"
VENV_DIR="$SCRIPT_DIR/venv"

# Verificar si el directorio existe
if [ ! -d "$SCRIPT_DIR" ]; then
  echo "Error: No se encuentra el directorio $SCRIPT_DIR"
  echo "Por favor, clona el repositorio primero:"
  echo "git clone https://github.com/casualsnek/waydroid_script.git ~/Descargas/waydroid_script"
  read -p "Presiona Enter para salir..."
  exit 1
fi

cd "$SCRIPT_DIR" || exit 1

# Verificar si el entorno virtual existe
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

# Ejecutar el script principal
echo "Ejecutando waydroid_script..."
echo "=========================================="
sudo venv/bin/python main.py

# Desactivar el entorno virtual al salir
deactivate

echo "=========================================="
echo "Script finalizado. Presiona Enter para salir..."
read
