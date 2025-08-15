#!/bin/bash

format() {
  if [ "$1" -eq 0 ]; then
    echo '-'
  else
    echo "$1"
  fi
}

# Conteo de actualizaciones
updates_arch=$(checkupdates 2>/dev/null | tee /tmp/arch_updates.txt | wc -l)
updates_aur=$(yay -Qum 2>/dev/null | tee /tmp/aur_updates.txt | wc -l)
updates_total=$((updates_arch + updates_aur))

# Icono y color según updates
if [ "$updates_total" -gt 0 ]; then
  icon=""
  color="#FF5555"
else
  icon=""

  color="#50FA7B"
fi

# Listas de paquetes para tooltip
arch_list=$(cat /tmp/arch_updates.txt | tr '\n' ', ' | sed 's/, $//')
aur_list=$(cat /tmp/aur_updates.txt | tr '\n' ', ' | sed 's/, $//')

# Tooltip seguro para JSON
tooltip="Arch ($updates_arch): $arch_list | AUR ($updates_aur): $aur_list"
tooltip_escaped=$(python3 -c "import json,sys; print(json.dumps('$tooltip'))")

# Salida JSON para Waybar
#
echo "{\"text\":\"$icon   $updates_total\",\"tooltip\":$tooltip_escaped,\"class\":\"custom-updates\",\"color\":\"$color\"}"
