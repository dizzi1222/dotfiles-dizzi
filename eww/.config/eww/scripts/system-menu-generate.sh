#!/bin/bash
# system-menu-generate.sh [QUERY] [ID_WINDOW]
# Genera el cuerpo YUCK del grid del System Menu a partir del manifiesto TSV
# y lo publica en eww vía `eww update system-menu-body="..."`.
# El filtrado por búsqueda se hace AQUÍ en bash (grep -i sobre label/icono)
# porque eww 0.6 NO puede filtrar dinámicamente en `:visible` (rompe el parseo
# de TODA la config). El widget lo renderiza con `(literal :content body)`.
#
# Usos:
#   system-menu-generate.sh ""          # grid completo (sin filtrar)
#   system-menu-generate.sh "dock"      # filtra por label/icono
#
# El valor multi-línea se pasa a eww por archivo auxiliar (las comillas/espacios
# de un $(...) inline rompen el update). Siempre publica con `eww update`.

MANIFEST="$(dirname "$0")/system-menu-manifest.tsv"
QUERY="${1:-}"

BODY_FILE="$(mktemp --suffix=.menu-body)"

# Emitir el árbol YUCK (callback) directamente al archivo temporal.
# CRITICO: debe ser UN SOLO widget raíz (box wrapper) porque `literal` exige un
# único nodo — si emitís label+box hermanos, eww muestra el yuck como texto.
emit() {
  printf '(box :orientation "vertical" :class "sys-grid" :space-evenly "false"\n'
  awk -F '\t' -v q="$QUERY" '
    BEGIN { printed_any = 0 }
    {
      cat=$1; icon=$2; label=$3
      if (q != "") {
        if (tolower(label) !~ tolower(q) && tolower(icon) !~ tolower(q)) next
      }
      if (icon == "") next
      if (cat != lastcat) {
        if (printed_any) print "    )"
        print "    (label :class \"sys-cat\" :text \"" cat "\")"
        print "    (box :class \"sys-row\" :orientation \"horizontal\" :space-evenly \"true\""
        lastcat = cat
      }
      printed_any = 1
      printf "      (button :class \"sys-btn\" :onclick \"~/.config/eww/scripts/system-menu-click.sh %s\"\n", icon
      print "        (box :class \"sys-btn-box\" :orientation \"horizontal\" :space-evenly \"false\""
      printf "          (label :class \"sys-btn-icon\" :text \"%s\")\n", icon
      printf "          (label :class \"sys-btn-label\" :text \"%s\" :hexpand \"true\" :halign \"start\")\n", label
      print "          (label :class \"sys-btn-chev\" :text \"\uf0da\" :halign \"end\")))"
    }
    END { if (printed_any) print "    )" }
  ' "$MANIFEST"
  printf ')\n'
}

emit

# Publicar en eww. Asegura que el daemon exista (si no, `eww daemon` lo crea;
# si ya corre, `eww daemon` responde "already running" y no pasa nada).
if command -v eww >/dev/null 2>&1; then
  eww daemon 2>/dev/null || true
  # Capturar el árbol yuck (una sola raíz) y pasarlo a eww por archivo auxiliar
  # (el valor multi-línea con comillas/unicode inline rompe el update).
  emit > "$BODY_FILE"
  eww update "system-menu-body='$(cat "$BODY_FILE")'" 2>/dev/null || true
fi

rm -f "$BODY_FILE"