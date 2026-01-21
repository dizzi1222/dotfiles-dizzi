#!/usr/bin/env bash
# niri-colorpicker.sh - Fix definitivo con historial

check() {
  command -v "$1" >/dev/null 2>&1
}

notify() {
  if check notify-send; then
    # notify-send -a "Color Picker" "$@"
  else
    echo "$@"
  fi
}

# Verificar dependencias
check hyprpicker || {
  # notify "❌ hyprpicker no instalado" "Instala: yay -S hyprpicker"
  exit 1
}

# Limpiar procesos previos
killall -q hyprpicker

# Capturar color
color=$(hyprpicker -a)

# Validar formato
if [[ -n "$color" && "$color" =~ ^#[0-9A-Fa-f]{6}$ ]]; then

  # 📋 MÉTODO 1: Copiar al clipboard (múltiples intentos)
  clipboard_ok=false

  # Intento 1: wl-copy directo
  if check wl-copy; then
    if printf "%s" "$color" | wl-copy 2>/dev/null; then
      clipboard_ok=true
    fi
  fi

  # Intento 2: wl-copy con --primary
  if [[ "$clipboard_ok" = false ]] && check wl-copy; then
    printf "%s" "$color" | wl-copy --primary 2>/dev/null && clipboard_ok=true
  fi

  # 📁 MÉTODO 2: Guardar en archivo de historial
  history_file="$HOME/.cache/colorpicker_history"
  mkdir -p "$(dirname "$history_file")"

  # Agregar color al inicio del archivo (máximo 20 colores)
  {
    echo "$color"
    if [ -f "$history_file" ]; then
      grep -v "^$color$" "$history_file" | head -n 19
    fi
  } >"$history_file.tmp"
  mv "$history_file.tmp" "$history_file"

  # 🔔 Notificar
  if [[ "$clipboard_ok" = true ]]; then
    # notify "✅ Color copiado" "$color" -t 3000
  else
    # notify "📝 Color guardado" "$color (clipboard falló)" -t 3000
  fi

  # 📊 Mostrar en rofi/fuzzel (opcional)
  if check rofi && [[ "$1" = "--show" ]]; then
    cat "$history_file" | rofi -dmenu -p "Historial de colores" -theme-str 'window {width: 300px;}'
  fi

else
  # notify "❌ Selección cancelada" "No se capturó ningún color"
fi
