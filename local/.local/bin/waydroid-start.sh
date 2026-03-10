#!/bin/bash
CFG="/var/lib/waydroid/waydroid.cfg"

declare -A PRESETS=(
  [fullscreen]="1920x1080"
  [portrait]="926x809"
  [half]="960x540"
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

set_prop "persist.waydroid.width"         "$WIDTH"
set_prop "persist.waydroid.height"        "$HEIGHT"
set_prop "persist.waydroid.multi_windows" "false"
echo "✅ cfg actualizado"

# ─── Arrancar ─────────────────────────────────────────
sudo systemctl start waydroid-container
echo "⏳ Esperando contenedor..."
COUNT=0
while ! systemctl is-active --quiet waydroid-container; do
  sleep 1
  ((COUNT++ >= 30)) && echo "❌ Timeout" && exit 1
done

# ─── Lanzar UI ────────────────────────────────────────
waydroid show-full-ui &

# ─── Esperar servicio window ──────────────────────────
echo "⏳ Esperando servicio window..."
COUNT=0
until sudo waydroid shell service list 2>/dev/null | grep -q "window"; do
  sleep 1
  ((COUNT++ >= 40)) && echo "❌ Timeout window service" && break
done

# ─── Aplicar tamaño ───────────────────────────────────
if [[ "$INPUT" == "fullscreen" ]]; then
  echo "🖥️  Fullscreen: reseteando override..."
  sudo waydroid shell wm size reset
  sudo waydroid shell wm density reset
else
  echo "📏 Forzando wm size ${WIDTH}x${HEIGHT}..."
  sudo waydroid shell wm size "${WIDTH}x${HEIGHT}"
  sudo waydroid shell wm density 240
fi

echo "✅ Listo: ${WIDTH}x${HEIGHT}"
echo "📏 Tamaño actual: $(sudo waydroid shell wm size)"
