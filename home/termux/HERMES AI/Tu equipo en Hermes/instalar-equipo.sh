#!/bin/bash
# Tu equipo en Hermes · Julio Barroeta (@julio.tomoko)
# Crea los cuatro agentes (presupuestos, cobros, agenda, contenido) copiando el cerebro y las claves del agente
# principal, como hace el botón «New Agent» de la app. No toca el agente principal ni los agentes que ya existan.
set -u
PACK="$(cd "$(dirname "$0")" && pwd)"
HH="${EQUIPO_HERMES_HOME:-$HOME/.hermes}"

HERMES="$(command -v hermes || true)"
for c in "$HOME/.local/bin/hermes" "$HH/hermes-agent/.hermes/bin/hermes" "$HH/hermes-agent/venv/bin/hermes"; do
  [ -z "$HERMES" ] && [ -x "$c" ] && HERMES="$c"
done
if [ -z "$HERMES" ]; then
  echo "No encuentro el programa de Hermes en este ordenador. ¿Está instalado y abierto al menos una vez?"
  exit 1
fi

crear() {  # nombre · descripción
  local n="$1" d="$2" dir="$HH/profiles/$1"
  if [ -e "$dir" ]; then
    echo "· $n: ya existía, no lo toco."
    return
  fi
  if ! HERMES_HOME="$HH" "$HERMES" profile create "$n" --clone-from default --no-alias --description "$d" >/dev/null 2>&1; then
    echo "· $n: no se ha podido crear (prueba a crearlo desde Bots → New Agent)."
    return
  fi
  cp "$PACK/agentes/$n/SOUL.md" "$dir/SOUL.md"
  rm -rf "$dir/skills" && mkdir -p "$dir/skills/negocio"
  cp -R "$PACK/agentes/$n/skills/." "$dir/skills/negocio/"
  HERMES_HOME="$dir" "$HERMES" config set agent.disabled_toolsets \
    '["terminal","browser","code_execution","computer_use","delegation","image_gen","video","video_gen","kanban"]' >/dev/null 2>&1 \
    || echo "  (aviso: quítale a mano la terminal y el navegador en Bots → $n → herramientas)"
  echo "· $n: creado."
}

echo "Creando tu equipo en $HH ..."
crear presupuestos "Presupuestos y atención al cliente"
crear cobros "Facturas pendientes y recordatorios de cobro"
crear agenda "Resumen de la semana y lo que falta por cerrar"
crear contenido "Publicaciones para redes y respuestas a reseñas"
echo "Listo. Abre la pestaña Bots de Hermes (o recarga la app) para verlos."
