#!/usr/bin/env bash
set -uo pipefail

LIVE_LUTRIS="${HOME}/.local/share/lutris"
DOT_LUTRIS="${HOME}/dotfiles-dizzi/local/.local/share/lutris"
LIVE_HICOLOR="${HOME}/.local/share/icons/hicolor"
DOT_HICOLOR="${HOME}/dotfiles-dizzi/local/.local/share/icons/hicolor"
ICON_SIZE="128x128"
ICON_DIR="${ICON_SIZE}/apps"

fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

command -v python3 >/dev/null 2>&1 || fail "python3 no está instalado"
command -v magick >/dev/null 2>&1 || command -v convert >/dev/null 2>&1 || fail "ImageMagick (magick/convert) no está instalado"

test -f "${LIVE_LUTRIS}/pga.db" || fail "No existe ${LIVE_LUTRIS}/pga.db"

declare -A WINE_ICON
WINE_ICON["3040_Stardew_0.0.png"]="stardew-valley"
WINE_ICON["9390_Res4-2.0.png"]="resident-evil-4"
WINE_ICON["C714_Res4-2.0.png"]="resident-evil-4"
WINE_ICON["3A99_sekiro-2.0.png"]="sekiro-shadows-die-twice"
WINE_ICON["FD8B_SparkingZERO.0.png"]="dragon-ball-sparking-zero"
WINE_ICON["3102_Cuphead.0.png"]="cuphead"
WINE_ICON["04C7_Hollow Knight Silksong.0.png"]="hollow-knight-silksong"
WINE_ICON["E012_hollow_knight.0.png"]="hollow-knight"
WINE_ICON["1AD0_Blasphemous.0.png"]="blasphemous"
WINE_ICON["2FAC_Mp3tag.0.png"]="mp3tag"
WINE_ICON["F394_PokeMMO.0.png"]="pokemmo"
WINE_ICON["169C_NS3FB_launcher.0.png"]="naruto-shippuden-ultimate-ninja-storm-3"
WINE_ICON["B531_NSUNS4.0.png"]="naruto-shippuden-ultimate-ninja-storm-4"
WINE_ICON["FE6F_Shadow PC.0.png"]="shadow-of-the-colossus"

CONVERT="$(command -v magick || command -v convert)"
PIXEL() {
  local src="$1" out="$2"
  "${CONVERT}" "${src}" -background none -resize "128x128^" -gravity center -extent 128x128 "${out}" 2>/dev/null
}
INSTALL() {
  local src="$1" live_out="$2" dot_out="$3"
  PIXEL "${src}" "${live_out}" || return 1
  if test "${live_out}" -ef "${dot_out}"; then return 0; fi
  mkdir -p "$(dirname "${dot_out}")" || return 1
  cp -f "${live_out}" "${dot_out}"
}

python3 - "${LIVE_LUTRIS}" <<'PY' > /tmp/lutris-slugs.txt
import sqlite3, sys
conn = sqlite3.connect(f"{sys.argv[1]}/pga.db")
conn.execute("PRAGMA query_only = ON")
slugs = sorted({r[0] for r in conn.execute("SELECT slug FROM games").fetchall()})
print("\n".join(slugs))
conn.close()
PY

HAS_ICON() {
  local slug="$1" live="$2"
  local hit
  hit="$(find "${live}" -path "*/apps/lutris_${slug}.png" -o -path "*/apps/lutris_${slug}.jpg" 2>/dev/null | head -n1)"
  test -n "${hit}" && return 0 || return 1
}

mapfile -t SLUGS < /tmp/lutris-slugs.txt
MISSING=()
for s in "${SLUGS[@]}"; do
  test -z "${s}" && continue
  HAS_ICON "${s}" "${LIVE_HICOLOR}" || MISSING+=("${s}")
done

FROM_WINE=()
FROM_ART=()
PENDING=()

for s in "${MISSING[@]}"; do
  out_name="lutris_${s}.png"
  live_out="${LIVE_HICOLOR}/${ICON_DIR}/${out_name}"
  dot_out="${DOT_HICOLOR}/${ICON_DIR}/${out_name}"
  resolved=""

  for sz in "256x256" "128x128"; do
    for name in "${!WINE_ICON[@]}"; do
      test "${WINE_ICON[$name]}" = "${s}" || continue
      src="${LIVE_HICOLOR}/${sz}/apps/${name}"
      if test -f "${src}"; then
        mkdir -p "$(dirname "${live_out}")"
        INSTALL "${src}" "${live_out}" "${dot_out}" && resolved="wine"
        break 2
      fi
    done
  done

  if test -z "${resolved}"; then
    for base in "banners" "coverart"; do
      for ext in png jpg; do
        src="${LIVE_LUTRIS}/${base}/${s}.${ext}"
        if test -f "${src}"; then
          mkdir -p "$(dirname "${live_out}")"
          INSTALL "${src}" "${live_out}" "${dot_out}" && resolved="${base}"
          break 2
        fi
      done
    done
  fi

  case "${resolved}" in
    wine)      FROM_WINE+=("${s}") ;;
    banners|coverart) FROM_ART+=("${s}") ;;
    *)         PENDING+=("${s}") ;;
  esac
done

RECONCILE=()
for s in "${SLUGS[@]}"; do
  HAS_ICON "${s}" "${LIVE_HICOLOR}" && RECONCILE+=("${s}")
done

if test "${#RECONCILE[@]}" -gt 0; then
  python3 - "${LIVE_LUTRIS}" "${RECONCILE[@]}" <<'PY'
import sqlite3, sys
path, slugs = sys.argv[1], sys.argv[2:]
conn = sqlite3.connect(f"{path}/pga.db", timeout=10)
cur = conn.cursor()
placeholders = ",".join("?" * len(slugs))
cur.execute(f"UPDATE games SET has_custom_icon = 1 WHERE (has_custom_icon IS NULL OR has_custom_icon != 1) AND slug IN ({placeholders})", slugs)
conn.commit()
print(f"pga.db: {cur.rowcount} filas marcadas con has_custom_icon=1")
conn.close()
PY
fi

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f -t "${LIVE_HICOLOR}" >/dev/null 2>&1 || true
fi

printf '\n=== Reporte fill-lutris-icons ===\n'
printf 'Juegos en BD: %s  |  Faltantes detectados: %s\n' "${#SLUGS[@]}" "${#MISSING[@]}"
printf 'Llenados desde icono Wine: %s\n' "${#FROM_WINE[@]}"
printf 'Llenados desde banner/cover: %s\n' "${#FROM_ART[@]}"
printf 'Pendientes (sin fuente): %s\n' "${#PENDING[@]}"
for s in "${FROM_WINE[@]}"; do printf '  [wine]   %s\n' "${s}"; done
for s in "${FROM_ART[@]}"; do printf '  [art]    %s\n' "${s}"; done
for s in "${PENDING[@]}"; do printf '  [pend]   %s\n' "${s}"; done