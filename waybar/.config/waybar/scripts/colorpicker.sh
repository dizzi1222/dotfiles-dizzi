#!/usr/bin/env bash

check() {
  command -v "$1" 1>/dev/null
}

notify() {
  check notify-send && {
    notify-send -a "Color Picker" "$@"
    return
  }
  echo "$@"
}

loc="$HOME/.cache/colorpicker"
[ -d "$loc" ] || mkdir -p "$loc"
[ -f "$loc/colors" ] || touch "$loc/colors"

limit=10

[[ $# -eq 1 && $1 = "-l" ]] && {
  cat "$loc/colors"
  exit
}

[[ $# -eq 1 && $1 = "-j" ]] && {
  text="$(head -n 1 "$loc/colors")"
  mapfile -t allcolors < <(tail -n +2 "$loc/colors")

  # 🔧 FIX: Si text está vacío, usar color por defecto
  if [[ -z "$text" ]]; then
    text="#808080" # Gris por defecto
  fi

  tooltip="<b>   COLORS</b>\n\n"
  tooltip+="-> <b>$text</b>  <span color='$text'></span>  \n"

  for i in "${allcolors[@]}"; do
    # 🔧 FIX: Validar que el color no esté vacío
    if [[ -n "$i" && "$i" =~ ^#[0-9A-Fa-f]{6}$ ]]; then
      tooltip+="   <b>$i</b>  <span color='$i'></span>  \n"
    fi
  done

  cat <<EOF
{ "text":"<span color='$text'></span>", "tooltip":"$tooltip"}  
EOF
  exit
}

check hyprpicker || {
  notify "hyprpicker is not installed"
  exit
}

killall -q hyprpicker
color=$(hyprpicker)

# 🔧 FIX: Validar que el color sea válido antes de guardarlo
if [[ -n "$color" && "$color" =~ ^#[0-9A-Fa-f]{6}$ ]]; then
  check wl-copy && {
    echo "$color" | sed -z 's/\n//g' | wl-copy
  }

  prevColors=$(head -n $((limit - 1)) "$loc/colors")
  echo "$color" >"$loc/colors"
  echo "$prevColors" >>"$loc/colors"
  sed -i '/^$/d' "$loc/colors"

  pkill -RTMIN+1 waybar
else
  notify "Color inválido o cancelado"
fi
