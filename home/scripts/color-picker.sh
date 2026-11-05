#!/bin/bash
# Cuentagotas nativo de KWin (Plasma 6) — captura un píxel de la pantalla,
# copia el color como #RRGGBB al portapapeles, notifica y abre la GUI con
# ese color ya cargado (KColorChooser).
# Uso: color-picker.sh [--gui=kde|gcolor3|none] [--no-copy] [--no-notify]

set -uo pipefail

COPY=1
NOTIFY=1
GUI="kde"
for arg in "$@"; do
  case "$arg" in
    --gui=kde)     GUI="kde" ;;
    --gui=gcolor3) GUI="gcolor3" ;;
    --gui=none)    GUI="none" ;;
    --no-gui)      GUI="none" ;;
    --no-copy)     COPY=0 ;;
    --no-notify)   NOTIFY=0 ;;
    -h|--help)
      sed -n '2,7p' "$0"; exit 0 ;;
  esac
done

# pick devuelve (uint32 4283215696) con el valor QRgb (0xAARRGGBB)
raw=$(gdbus call --session \
        --dest org.kde.KWin \
        --object-path /ColorPicker \
        --method org.kde.kwin.ColorPicker.pick 2>/dev/null)

val=$(printf '%s' "$raw" | sed -n 's/.*uint32 \([0-9][0-9]*\).*/\1/p')
if [ -z "${val:-}" ]; then
  echo "No se pudo obtener el color (¿cancelaste o KWin no expone ColorPicker?)" >&2
  exit 1
fi

hex=$(printf '#%06X' $(( val & 0xFFFFFF )))
printf '%s\n' "$hex"

if [ "$COPY" -eq 1 ] && command -v wl-copy >/dev/null 2>&1; then
  printf '%s' "$hex" | wl-copy
fi

if [ "$NOTIFY" -eq 1 ] && command -v notify-send >/dev/null 2>&1; then
  notify-send -a "Cuentagotas" -i color-management "Color copiado" "$hex"
fi

# Abrir la GUI con el color ya seleccionado
case "$GUI" in
  kde)
    setsid -f flatpak run org.kde.kcolorchooser --color "$hex" >/dev/null 2>&1
    ;;
  gcolor3)
    # GColor3 no acepta un color por CLI: solo abre la ventana
    setsid -f flatpak run nl.hjdskes.gcolor3 >/dev/null 2>&1
    ;;
esac
