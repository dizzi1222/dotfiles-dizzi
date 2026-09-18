#!/usr/bin/env bash
# Cicla el foco entre TODAS las ventanas del workspace actual (incl. flotantes).
# Equivalente a Hyprland `bind = CONTROL, TAB, cyclenext, all`.
set -euo pipefail

mode="${1:-next}"
case "$mode" in
  next | prev) ;;
  *) echo "uso: $(basename "$0") [next|prev]" >&2 && exit 1 ;;
esac

focused="$(niri msg focused-window 2>/dev/null)" || exit 0
current_id="$(printf '%s\n' "$focused" | awk '/^Window ID / { gsub(":", "", $3); print $3; exit }')"
ws="$(printf '%s\n' "$focused" | awk '/^  Workspace ID: / { print $3; exit }')"
[ -n "$current_id" ] && [ -n "$ws" ] || exit 0

mapfile -t ids < <(niri msg windows | awk -v ws="$ws" '
  /^Window ID / { id = $3; sub(":", "", id); app = ""; f = 1; next }
  f && /^  App ID: / { app = $3; gsub("\"", "", app); next }
  f && /^  Workspace ID: / {
    if ($3 == ws && tolower(app) !~ /desktop/) print id
    f = 0
  }
')

n="${#ids[@]}"
[ "$n" -gt 0 ] || exit 0

idx=-1
for i in "${!ids[@]}"; do
  if [ "${ids[$i]}" = "$current_id" ]; then idx=$i; break; fi
done
if [ "$idx" -eq -1 ]; then
  tgt="${ids[0]}"
elif [ "$mode" = "next" ]; then
  tgt="${ids[$(((idx + 1) % n))]}"
else
  tgt="${ids[$(((idx - 1 + n) % n))]}"
fi

niri msg action focus-window --id "$tgt" >/dev/null 2>&1 || true