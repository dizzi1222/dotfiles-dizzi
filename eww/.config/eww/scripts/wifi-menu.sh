#!/bin/bash
# Menú WiFi: lista redes con nmcli y conecta a la seleccionada vía rofi.

export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
export XDG_RUNTIME_DIR="/run/user/$(id -u)"

SELECTED=$(nmcli -t -f SSID,SECURITY,BARS device wifi list --rescan yes 2>/dev/null | \
  awk -F: '{
    ssid=$1; sec=$2; bars=$3
    if (sec=="") sec="open"
    printf "%s  [%s]  %s\n", ssid, sec, bars
  }' | \
  rofi -dmenu -p "Seleccionar Red:" -config ~/.config/rofi/config-power.rasi -i -no-custom 2>/dev/null)

[ -z "$SELECTED" ] && exit 0

# Extraer el SSID (la parte antes de "  [")
SSID=$(echo "$SELECTED" | sed 's/  \[.*//')
[ -z "$SSID" ] && exit 0

# Intentar conectar; si pide contraseña usa rofi para el prompt
if nmcli --terse device wifi connect "$SSID" 2>/dev/null; then
  notify-send "󰖩 WiFi Conectado" "$SSID"
else
  PASSWORD=$(rofi -dmenu -p "Contraseña para $SSID:" -config ~/.config/rofi/config-power.rasi -password 2>/dev/null)
  [ -z "$PASSWORD" ] && exit 0
  if nmcli device wifi connect "$SSID" password "$PASSWORD" 2>/dev/null; then
    notify-send "󰖩 WiFi Conectado" "$SSID"
  else
    notify-send -u critical "󰖩 Error WiFi" "No se pudo conectar a $SSID"
  fi
fi
