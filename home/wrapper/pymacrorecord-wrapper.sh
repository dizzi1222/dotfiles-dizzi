#!/bin/bash
# Wrapper DEFINITIVO para PyMacroRecord en Hyprland/Wayland
# Fuerza ejecución en XWayland (única forma que funciona)

PYMACRO_DIR=~/.local/share/pymacro

# ═══════════════════════════════════════════════════════════
# VERIFICAR INSTALACIÓN
# ═══════════════════════════════════════════════════════════
if [[ ! -d "$PYMACRO_DIR" ]]; then
  echo "❌ PyMacroRecord no encontrado en $PYMACRO_DIR"
  echo ""
  echo "📦 Instala primero con fase2-HyprInstall-full.sh"
  exit 1
fi

# ═══════════════════════════════════════════════════════════
# ENCONTRAR DISPLAY DE XWAYLAND
# ═══════════════════════════════════════════════════════════
find_xwayland_display() {
  # Método 1: Buscar en procesos activos
  local display=$(ps aux | grep -i xwayland | grep -oE ':[0-9]+' | head -1)

  # Método 2: Buscar sockets en /tmp
  if [[ -z "$display" ]]; then
    display=$(ls /tmp/.X11-unix/ 2>/dev/null | grep -oE 'X[0-9]+' | head -1 | sed 's/X/:/')
  fi

  # Método 3: Usar :0 por defecto
  if [[ -z "$display" ]]; then
    display=":0"
  fi

  echo "$display"
}

XWAYLAND_DISPLAY=$(find_xwayland_display)

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║          🎮 PYMACRORECORD - WRAPPER XWAYLAND 🎮          ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "🖥️  Display XWayland: $XWAYLAND_DISPLAY"

# ═══════════════════════════════════════════════════════════
# CONFIGURAR VARIABLES DE ENTORNO PARA XWAYLAND
# ═══════════════════════════════════════════════════════════
export DISPLAY="$XWAYLAND_DISPLAY"
export GDK_BACKEND=x11
export QT_QPA_PLATFORM=xcb
export XAUTHORITY="$HOME/.Xauthority"

# ═══════════════════════════════════════════════════════════
# VERIFICAR CONEXIÓN A XWAYLAND
# ═══════════════════════════════════════════════════════════
echo -n "🔍 Verificando conexión a XWayland... "
if xhost >/dev/null 2>&1; then
  echo "✅ OK"
else
  echo "⚠️  Configurando permisos..."
  xhost +si:localuser:$USER 2>/dev/null
fi

# ═══════════════════════════════════════════════════════════
# ACTIVAR ENTORNO VIRTUAL
# ═══════════════════════════════════════════════════════════
cd "$PYMACRO_DIR"

if [[ ! -d "venv" ]]; then
  echo ""
  echo "❌ Entorno virtual no encontrado"
  echo "💡 Reinstala PyMacroRecord con fase2-HyprInstall-full.sh"
  exit 1
fi

source venv/bin/activate
echo "🐍 Entorno virtual activado"

# ═══════════════════════════════════════════════════════════
# VERIFICAR PYTHON Y DEPENDENCIAS
# ═══════════════════════════════════════════════════════════
if ! python -c "import pynput, tkinter" 2>/dev/null; then
  echo ""
  echo "❌ Dependencias faltantes"
  echo "🔧 Instalando..."
  pip install pynput pillow pystray --quiet
fi

# ═══════════════════════════════════════════════════════════
# EJECUTAR PYMACRORECORD EN XWAYLAND
# ═══════════════════════════════════════════════════════════
cd src
echo ""
echo "🚀 INICIANDO PYMACRORECORD EN XWAYLAND..."
echo "═══════════════════════════════════════════════════════════"
echo ""

# Ejecutar con todas las variables configuradas
exec python main.py

# Si llegamos aquí, algo falló
echo ""
echo "❌ PyMacroRecord cerró inesperadamente"
echo "💡 Revisa errores arriba"
