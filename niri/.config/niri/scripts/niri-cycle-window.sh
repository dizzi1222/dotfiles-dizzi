#!/usr/bin/env bash
# Cicla el foco entre TODAS las ventanas del workspace actual (incl. flotantes).
# Equivalente a Hyprland `bind = CONTROL, TAB, cyclenext, all`.
set -euo pipefail

mode="${1:-next}"
case "$mode" in
  next | prev) ;;
  *) echo "uso: $(basename "$0") [next|prev]" >&2 && exit 1 ;;
esac

# App-ids de la capa "desktop" (no son ventanas reales, se ignoran).
desktop_ids='["nemo-desktop","plasmashell","org.kde.plasmashell","caelestia-shell"]'

info="$(niri msg -j focused-window 2>/dev/null || true)"
[ -n "$info" ] || exit 0

current_id="$(printf '%s' "$info" | jq -r '.id // empty')"
ws="$(printf '%s' "$info" | jq -r '.workspace_id // empty')"
[ -n "$current_id" ] && [ -n "$ws" ] || exit 0

# Orden estable: tiled por (columna, tile) y luego flotantes por posicion.
mapfile -t ids < <(
  niri msg -j windows | jq -r --argjson skip "$desktop_ids" --arg ws "$ws" '
    [ .[]
      | select((.workspace_id | tostring) == $ws)
      | select(((.app_id // "") | ascii_downcase) as $a | ($skip | index($a)) == null)
    ]
    | sort_by(
        if .is_floating
        then [1, (.layout.tile_pos_in_workspace_view[0] // 0), (.layout.tile_pos_in_workspace_view[1] // 0), .id]
        else [0, (.layout.pos_in_scrolling_layout[0] // 0), (.layout.pos_in_scrolling_layout[1] // 0), .id]
        end
      )
    | .[].id | tostring
  '
)

n="${#ids[@]}"
[ "$n" -gt 0 ] || exit 0

idx=-1
for i in "${!ids[@]}"; do
  if [ "${ids[$i]}" = "$current_id" ]; then idx=$i; break; fi
done

if [ "$idx" -eq -1 ]; then
  if [ "$mode" = "next" ]; then
    tgt="${ids[0]}"
  else
    tgt="${ids[n - 1]}"
  fi
elif [ "$mode" = "next" ]; then
  tgt="${ids[$(((idx + 1) % n))]}"
else
  tgt="${ids[$(((idx - 1 + n) % n))]}"
fi

niri msg action focus-window --id "$tgt" >/dev/null 2>&1 || true
