#!/bin/bash
# ══════════════════════════════════════════════════════
#  waydroid-start.sh — Lanzador Waydroid con presets
#  Uso: waydroid-start.sh [fullscreen|portrait|half|WxH]
#  Wayland nativo: usa waydroid show-full-ui directo
#  X11 (Cinnamon etc): usa cage como compositor anidado
# ══════════════════════════════════════════════════════

CFG="/var/lib/waydroid/waydroid.cfg"

declare -A PRESETS=(
  [fullscreen]="1920x1080"
  [portrait]="926x809"
  [half]="960x540"
  [arzopa]="1080x1920"
)

INPUT="${1:-fullscreen}"

if [[ -v PRESETS[$INPUT] ]]; then
  SIZE="${PRESETS[$INPUT]}"
elif [[ "$INPUT" =~ ^[0-9]+x[0-9]+$ ]]; then
  SIZE="$INPUT"
else
  echo "❌ Inválido. Usa: fullscreen | portrait | half | WxH"
  exit 1
fi

WIDTH="${SIZE%x*}"
HEIGHT="${SIZE#*x}"
echo "📐 Target: ${WIDTH}x${HEIGHT}"

# ─── Parar sin suicidarse ─────────────────────────────
waydroid session stop 2>/dev/null
sudo systemctl stop waydroid-container 2>/dev/null
sudo pkill -9 -f "waydroid session" 2>/dev/null
sudo pkill -9 -f "waydroid show" 2>/dev/null
sleep 2

# ─── Props en cfg ─────────────────────────────────────
set_prop() {
  local key="$1" val="$2"
  if sudo grep -q "^${key}" "$CFG"; then
    sudo sed -i "s|^${key}.*|${key} = ${val}|" "$CFG"
  else
    echo "${key} = ${val}" | sudo tee -a "$CFG" >/dev/null
  fi
}

set_prop "persist.waydroid.width" "$WIDTH"
set_prop "persist.waydroid.height" "$HEIGHT"
set_prop "persist.waydroid.multi_windows" "false"
echo "✅ cfg actualizado"

# ─── Arrancar contenedor ──────────────────────────────
sudo systemctl start waydroid-container
echo "⏳ Esperando contenedor..."
COUNT=0
while ! systemctl is-active --quiet waydroid-container; do
  sleep 1
  ((COUNT++ >= 30)) && echo "❌ Timeout contenedor" && exit 1
done

# ─── Función: esperar window + aplicar tamaño ─────────
apply_size() {
  echo "⏳ Esperando servicio window..."
  COUNT=0
  until sudo waydroid shell service list 2>/dev/null | grep -q "window"; do
    sleep 1
    ((COUNT++ >= 40)) && echo "❌ Timeout window service" && break
  done

  if [[ "$INPUT" == "fullscreen" ]]; then
    echo "🖥️  Fullscreen: reseteando override..."
    sudo waydroid shell wm size reset
    sudo waydroid shell wm density reset
  else
    echo "📏 Forzando wm size ${WIDTH}x${HEIGHT}..."
    sudo waydroid shell wm size "${WIDTH}x${HEIGHT}"
    local density=240
    [[ "$INPUT" == "arzopa" ]] && density=320
    sudo waydroid shell wm density $density
  fi

  echo "✅ Listo: ${WIDTH}x${HEIGHT}"
  echo "📏 Tamaño actual: $(sudo waydroid shell wm size 2>/dev/null)"
}

# ─── X11: cage como compositor anidado ────────────────
if [ -z "$WAYLAND_DISPLAY" ]; then
  echo "⚠️  X11 detectado — usando cage como compositor anidado..."

  CAGE_BIN=$(which cage 2>/dev/null)
  if [ -z "$CAGE_BIN" ]; then
    echo "❌ cage no encontrado. Instala: sudo pacman -S cage"
    exit 1
  fi

  # cage lanza waydroid directamente (es compositor + runner)
  # El tamaño Android lo controla wm size después del boot
  DISPLAY=$DISPLAY "$CAGE_BIN" -- waydroid show-full-ui &
  CAGE_PID=$!

  # Esperar y aplicar resolución Android
  apply_size

  # Mantener el script vivo hasta que cage termine
  wait $CAGE_PID
  exit 0
fi

# ─── Función: fullscreen Waydroid en monitor específico ───
focus_on_monitor() {
  local monitor="$1"
  echo "🔍 Esperando ventana Waydroid en Hyprland..."
  local addr=""
  local tries=0
  while [[ -z "$addr" && $tries -lt 30 ]]; do
    sleep 1
    addr=$(hyprctl clients -j 2>/dev/null |
      jq -r '[.[] | select(.class | test("waydroid"; "i"))][0].address // empty')
    ((tries++))
  done

  if [[ -z "$addr" ]]; then
    echo "⚠️  No se encontró ventana Waydroid para mover"
    return
  fi

  echo "🖥️  Moviendo $addr → $monitor y poniendo fullscreen..."
  hyprctl dispatch focuswindow "address:$addr"
  hyprctl dispatch movewindow "mon:$monitor"
  hyprctl dispatch fullscreen 0
  echo "✅ Waydroid fullscreen en $monitor"
}

# ─── Wayland nativo: flujo normal ─────────────────────
echo "✅ Wayland detectado ($WAYLAND_DISPLAY)"
waydroid show-full-ui &
apply_size

if [[ "$INPUT" == "arzopa" ]]; then
  focus_on_monitor "DP-1"
fi
