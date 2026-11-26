#!/usr/bin/env bash
# ============================================================
# premid-activity.sh — carga las actividades de PreMiD (Exercism, Mimo, CodeCrafters...)
# ============================================================
# Lo llama system_control.sh (menú wofi/eww → Apps → PreMiD Actividades) con `all`. Pasos:
#   1. Servidor de actividades en ws://localhost:3021: el servicio de usuario
#      premid-dev (systemd), que manda TODAS sus actividades a la extensión en
#      cuanto se conecta. Sin la unidad (o con otro PREMID_PORT) arranca
#      ~/workspace/systemd/premid-serve.mjs en segundo plano.
#   2. Con una actividad concreta abre su web en el navegador por defecto (Zen);
#      con `all` no abre nada: cada actividad se activa sola al abrir su web.
#   3. Espera a que la extensión PreMiD se conecte y lo avisa con notify-send.
#
# La extensión solo se conecta con «Activity Developer» activado, y PreMiD lo
# apaga cada vez que arranca el navegador (no hay forma de activarlo desde
# fuera). Si no se conecta, la notificación dice dónde activarlo y el script
# sigue esperando la conexión hasta PREMID_WAIT_MAX segundos. Un lanzamiento
# nuevo termina al anterior que siguiera esperando y reutiliza su notificación.
#
# Uso:
#   premid-activity.sh all                         # todas las del servicio (lo usa el menú)
#   premid-activity.sh <Actividad> [--no-open]     # Exercism, Mimo, "Speedrun Ethereum"...
#
# Variables opcionales: PREMID_DIR (clon de PreMiD/Activities), PREMID_PORT
# (3021), PREMID_WAIT_CONNECT (12 s), PREMID_WAIT_MAX (180 s).
# Salida: 0 conectada · 1 error · 2 la extensión no se conectó a tiempo.
set -euo pipefail

# == Configuración ==

WORKSPACE_DIR="$HOME/workspace"
PREMID_DIR="${PREMID_DIR:-$WORKSPACE_DIR/premid-activities}"
SERVE="$WORKSPACE_DIR/systemd/premid-serve.mjs"
UNIT_SRC="$WORKSPACE_DIR/systemd/premid-dev.service"
UNIT="premid-dev.service"
PORT="${PREMID_PORT:-3021}"
WAIT_CONNECT="${PREMID_WAIT_CONNECT:-12}"
WAIT_MAX="${PREMID_WAIT_MAX:-180}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/premid-dev"
PIDFILE="$STATE_DIR/launcher.pid"
NOTIFY_ID_FILE="$STATE_DIR/notify.id"
# Logo de PreMiD para las notificaciones de `all` (se descarga una vez a la caché).
PREMID_LOGO_URL="https://github.com/PreMiD.png?size=256"
# node de Homebrew (el menú no carga el PATH de zsh). Al final: brew trae su propio
# notify-send/curl y no debe tapar los del sistema.
export PATH="$PATH:/home/linuxbrew/.linuxbrew/bin"

# Página de inicio por actividad; las demás abren la `url` de su metadata.json.
declare -A START_URLS=(
  [Exercism]="https://exercism.org/dashboard"
  [Mimo]="https://mimo.org/web/redirect-to-active-section"
  [CodeCrafters]="https://app.codecrafters.io/catalog"
  [CryptoZombies]="https://cryptozombies.io/en/course"
  ["Speedrun Ethereum"]="https://speedrunethereum.com/start"
)

NAME=""
TITLE="PreMiD"
ICON="applications-development"
NOTIFY_ID=""
# 1 con `all`: todas las actividades del servicio, sin abrir ninguna web.
ALL=0
# Actividades que se cargan (con `all`, las del servicio; si no, la pedida).
ACTIVITIES=()

# == Utilidades ==

# Muestra la notificación de esta ejecución (reemplaza la anterior) y la imprime.
#   $1 urgencia (low|normal|critical) · $2 texto
notify() {
  local id
  printf '%s — %s\n' "$TITLE" "$2"
  command -v notify-send >/dev/null 2>&1 || return 0
  if id=$(notify-send -a PreMiD -u "$1" -i "$ICON" -p ${NOTIFY_ID:+-r "$NOTIFY_ID"} "$TITLE" "$2" 2>/dev/null); then
    NOTIFY_ID="$id"
    { printf '%s\n' "$id" >"$NOTIFY_ID_FILE"; } 2>/dev/null || true
  fi
}

# Avisa del error y termina.
#   $1 texto
fail() {
  notify critical "$1"
  exit 1
}

# Une nombres en español: «A, B y C».
#   $@ nombres
join_names() {
  local out="" i
  for ((i = 1; i <= $#; i++)); do
    if [ "$i" = 1 ]; then
      out="${!i}"
    elif [ "$i" = "$#" ]; then
      out="$out y ${!i}"
    else
      out="$out, ${!i}"
    fi
  done
  printf '%s' "$out"
}

# ¿Hay un servidor escuchando en el puerto de las actividades?
server_listening() {
  [ -n "$(ss -Htln "( sport = :$PORT )" 2>/dev/null)" ]
}

# ¿Hay una conexión abierta hacia el servidor (la extensión del navegador)?
extension_connected() {
  [ -n "$(ss -Htn state established "( dport = :$PORT )" 2>/dev/null)" ]
}

# Espera hasta N segundos a que una comprobación se cumpla.
#   $1 función de comprobación · $2 segundos
wait_for() {
  local i
  for ((i = 0; i < $2 * 2; i++)); do
    "$1" && return 0
    sleep 0.5
  done
  "$1"
}

# Carpeta de una actividad, sin distinguir mayúsculas: websites/<letra>/<Actividad>.
#   $1 nombre
activity_dir() {
  find "$PREMID_DIR/websites" -mindepth 2 -maxdepth 2 -type d -iname "$1" -print -quit
}

# Campo de metadata.json de la actividad (si es una lista, el primer valor).
#   $1 campo (url, logo...)
meta() {
  python3 -I - "$ACT_DIR/metadata.json" "$1" <<'EOF'
import json, sys
value = json.load(open(sys.argv[1], encoding='utf-8')).get(sys.argv[2], '')
print(value[0] if isinstance(value, list) else value)
EOF
}

# Logo para las notificaciones (se descarga una vez a la caché).
#   $1 nombre en la caché · $2 URL del logo
cached_icon() {
  local cache="${XDG_CACHE_HOME:-$HOME/.cache}/premid-activity/$1.png"
  if [ ! -s "$cache" ]; then
    mkdir -p "${cache%/*}"
    if [ -z "$2" ] || ! curl -sfL --max-time 4 -o "$cache" "$2"; then
      rm -f "$cache"
    fi
  fi
  if [ -s "$cache" ]; then printf '%s' "$cache"; else printf '%s' "$ICON"; fi
}

# Actividades que sirve una unidad de premid-dev (argumentos de su ExecStart).
#   stdin: texto de la unidad
unit_activities() {
  # Una por línea; xargs respeta las comillas de systemd ("Speedrun Ethereum"). Sin `q` en
  # sed ni `grep -q` en quien la usa: salir antes de leerlo todo daría SIGPIPE con pipefail.
  sed -n '/^ExecStart=.*premid-serve\.mjs/s/^ExecStart=.*premid-serve\.mjs[[:space:]]*//p' |
    xargs -r printf '%s\n'
}

# Actividades que se sirven: las de la unidad instalada si el servidor es ese servicio;
# si no, las de la unidad del workspace (las que lanza el modo sin systemd).
served_activities() {
  if [ "$PORT" = 3021 ] && systemctl --user cat "$UNIT" >/dev/null 2>&1; then
    systemctl --user cat "$UNIT" 2>/dev/null | unit_activities
  else
    unit_activities <"$UNIT_SRC"
  fi
}

# ¿La unidad instalada de premid-dev sirve esta actividad?
unit_serves_activity() {
  systemctl --user cat "$UNIT" 2>/dev/null | unit_activities | grep -Fx -- "$NAME" >/dev/null
}

# Un solo lanzador a la vez: termina al anterior si sigue esperando a la extensión y
# hereda su notificación (la reemplaza en vez de apilar otra).
take_over() {
  local old cmd
  old=$(cat "$PIDFILE" 2>/dev/null) || old=""
  if [ -n "$old" ] && [ "$old" != "$$" ]; then
    cmd=$(tr '\0' ' ' <"/proc/$old/cmdline" 2>/dev/null) || cmd=""
    if [[ "$cmd" == *premid-activity.sh* ]] && kill "$old" 2>/dev/null; then
      NOTIFY_ID=$(cat "$NOTIFY_ID_FILE" 2>/dev/null) || NOTIFY_ID=""
    fi
  fi
  # El id guardado solo vale para la notificación del lanzador que acabamos de terminar.
  rm -f "$NOTIFY_ID_FILE"
  printf '%s\n' "$$" >"$PIDFILE"
  trap release EXIT
  trap 'exit 143' TERM
  trap 'exit 130' INT
}

# Al salir, libera el pidfile si sigue siendo nuestro.
release() {
  if [ "$(cat "$PIDFILE" 2>/dev/null)" = "$$" ]; then
    rm -f "$PIDFILE"
  fi
  return 0
}

# == Servidor ==

# Arranca el servidor si nadie escucha en el puerto: el servicio premid-dev si la
# unidad está instalada (y el puerto es el suyo); si no, premid-serve.mjs en segundo
# plano con las actividades de la unidad del workspace (más la pedida, si falta).
ensure_server() {
  server_listening && return 0
  if [ "$PORT" = 3021 ] && systemctl --user cat "$UNIT" >/dev/null 2>&1; then
    systemctl --user start "$UNIT" || fail "No se pudo arrancar $UNIT. Mira: journalctl --user -u premid-dev"
  else
    local -a list=()
    mapfile -t list < <(unit_activities 2>/dev/null <"$UNIT_SRC" || true)
    if [ "$ALL" = 0 ] && ! printf '%s\n' "${list[@]}" | grep -Fx -- "$NAME" >/dev/null; then
      list+=("$NAME")
    fi
    [ -f "$SERVE" ] || fail "Falta $SERVE: clona ~/workspace con sus submódulos"
    command -v node >/dev/null 2>&1 || fail "Falta node (brew install node)"
    (cd "$PREMID_DIR" && PREMID_PORT="$PORT" setsid -f node "$SERVE" "${list[@]}" >>"$STATE_DIR/serve.log" 2>&1 </dev/null) ||
      fail "No se pudo lanzar premid-serve.mjs"
  fi
  # La primera vez compila (pmd build) antes de escuchar: puede tardar.
  wait_for server_listening 60 ||
    fail "Nada escucha en :$PORT. Mira: journalctl --user -u premid-dev o $STATE_DIR/serve.log"
}

# == Principal ==

OPEN=1
for arg in "$@"; do
  case "$arg" in
  --no-open) OPEN=0 ;;
  -h | --help)
    echo "Uso: ${0##*/} all | <Actividad> [--no-open]   (p. ej. Exercism, Mimo, \"Speedrun Ethereum\")"
    exit 0
    ;;
  -*) fail "Opción desconocida: $arg" ;;
  *) NAME="$arg" ;;
  esac
done
[ -n "$NAME" ] || fail "Uso: ${0##*/} all | <Actividad> [--no-open]"
TITLE="PreMiD · $NAME"
[ -d "$PREMID_DIR/websites" ] || fail "No existe $PREMID_DIR (submódulo premid-activities de ~/workspace)"
mkdir -p "$STATE_DIR"

if [ "${NAME,,}" = all ]; then
  ALL=1
  mapfile -t ACTIVITIES < <(served_activities 2>/dev/null || true)
  [ "${#ACTIVITIES[@]}" -gt 0 ] || fail "No hay actividades en el ExecStart de $UNIT_SRC"
  TITLE="PreMiD · ${#ACTIVITIES[@]} actividades"
else
  ACT_DIR=$(activity_dir "$NAME")
  [ -n "$ACT_DIR" ] && [ -f "$ACT_DIR/metadata.json" ] || fail "No existe la actividad «$NAME» en $PREMID_DIR/websites"
  NAME="${ACT_DIR##*/}"
  TITLE="PreMiD · $NAME"
  ACTIVITIES=("$NAME")
fi
take_over

# 1. Servidor (con lock: dos lanzamientos seguidos no arrancan dos servidores).
exec 9>"$STATE_DIR/launch.lock"
flock -w 90 9 || true
ensure_server
if [ "$ALL" = 0 ] && [ "$PORT" = 3021 ] && systemctl --user is-active --quiet "$UNIT" 2>/dev/null && ! unit_serves_activity; then
  fail "$UNIT no sirve $NAME: añádela al ExecStart de ~/workspace/systemd/premid-dev.service y ejecuta ~/workspace/systemd/premid-dev-install.sh"
fi
exec 9>&-

# 2. Web de la actividad (con `all`, ninguna).
if [ "$ALL" = 0 ]; then
  URL="${START_URLS[$NAME]:-}"
  if [ -z "$URL" ]; then
    host=$(meta url 2>/dev/null) || host=""
    [ -z "$host" ] || URL="https://$host/"
  fi
  if [ "$OPEN" = 1 ] && [ -n "$URL" ]; then
    setsid -f xdg-open "$URL" >/dev/null 2>&1 || true
  fi
fi

# 3. Conexión de la extensión.
if [ "$ALL" = 1 ]; then
  ICON=$(cached_icon PreMiD "$PREMID_LOGO_URL")
  LOADED="Actividades cargadas en la extensión: $(join_names "${ACTIVITIES[@]}"). Cada una se activa sola al abrir su web."
else
  ICON=$(cached_icon "$NAME" "$(meta logo 2>/dev/null || true)")
  LOADED="Actividad cargada en la extensión."
fi
PLACEHOLDER=()
for name in "${ACTIVITIES[@]}"; do
  dir=$(activity_dir "$name")
  if [ -n "$dir" ] && grep -Eq "clientId: *['\"]0+['\"]" "$dir/presence.ts" 2>/dev/null; then
    PLACEHOLDER+=("$name")
  fi
done
case "${#PLACEHOLDER[@]}" in
0) WARN="" ;;
1) WARN=" Ojo: ${PLACEHOLDER[0]} aún usa un App ID de Discord de relleno; Discord no la mostrará hasta poner el real en su presence.ts." ;;
*) WARN=" Ojo: $(join_names "${PLACEHOLDER[@]}") aún usan un App ID de Discord de relleno; Discord no las mostrará hasta poner el real en su presence.ts." ;;
esac
LEVEL=low
[ -z "$WARN" ] || LEVEL=normal

if wait_for extension_connected "$WAIT_CONNECT"; then
  notify "$LEVEL" "$LOADED$WARN"
  exit 0
fi
notify critical "La extensión no está conectada: en Zen abre PreMiD → Ajustes y activa «Activity Developer» (PreMiD lo apaga en cada arranque del navegador).$WARN"
if wait_for extension_connected "$((WAIT_MAX - WAIT_CONNECT))"; then
  notify "$LEVEL" "Conectada: ${LOADED,}$WARN"
  exit 0
fi
exit 2
