#!/usr/bin/env bash
# Tu equipo en Hermes · Julio Barroeta (@julio.tomoko)
# Crea cuatro perfiles desde default, comparte sus credenciales y agrega sus
# instrucciones/skills. No toca default ni perfiles que ya existan.
set -euo pipefail

PACK="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
HH="${EQUIPO_HERMES_HOME:-${HOME:?}/.hermes}"
HERMES="$(command -v hermes || true)"
for candidate in "$HOME/.local/bin/hermes" "$HH/hermes-agent/.hermes/bin/hermes" "$HH/hermes-agent/venv/bin/hermes"; do
  if [[ -z "$HERMES" && -x "$candidate" ]]; then
    HERMES="$candidate"
  fi
done
if [[ -z "$HERMES" ]]; then
  printf 'No encuentro Hermes. Instálalo y ábrelo al menos una vez antes de crear perfiles.\n' >&2
  exit 1
fi

create_agent() {
  local name="$1" description="$2" profile_dir="$HH/profiles/$1"
  if [[ -e "$profile_dir" ]]; then
    printf '· %s: ya existe; se conserva.\n' "$name"
    return 0
  fi
  if ! HERMES_HOME="$HH" "$HERMES" profile create "$name" \
    --clone-from default --no-alias --description "$description"; then
    printf '· %s: Hermes no pudo crear el perfil.\n' "$name" >&2
    return 1
  fi
  cp -- "$PACK/agentes/$name/SOUL.md" "$profile_dir/SOUL.md"
  mkdir -p -- "$profile_dir/skills/negocio"
  cp -R -- "$PACK/agentes/$name/skills/." "$profile_dir/skills/negocio/"
  if ! HERMES_HOME="$profile_dir" "$HERMES" config set agent.disabled_toolsets \
    '["terminal","browser","code_execution","computer_use","delegation","image_gen","video","video_gen","kanban"]' >/dev/null; then
    printf '  Aviso: no se pudieron fijar los toolsets para %s; Home Manager/enlace local aplicará el config del repo.\n' "$name" >&2
  fi
  printf '· %s: creado.\n' "$name"
}

printf 'Creando perfiles Hermes en %s ...\n' "$HH"
failed=0
create_agent presupuestos 'Presupuestos y atención al cliente' || failed=1
create_agent cobros 'Facturas pendientes y recordatorios de cobro' || failed=1
create_agent agenda 'Resumen de la semana y lo que falta por cerrar' || failed=1
create_agent contenido 'Publicaciones para redes y respuestas a reseñas' || failed=1
if (( failed )); then
  printf 'Uno o más perfiles fallaron; revisa el mensaje de Hermes y vuelve a ejecutar el instalador.\n' >&2
  exit 1
fi
printf 'Listo. Revisa los perfiles con: hermes profile list\n'
