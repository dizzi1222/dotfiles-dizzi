#!/usr/bin/env bash
# zen-to-arzopa.sh — mueve Zen Browser al monitor Arzopa.
#
# En Steam Game Mode (gamescope) no hay un segundo monitor lógico: gamescope
# expone una sola salida. En Desktop Mode (KDE Plasma/Wayland) KWin sí ve la
# Arzopa como HDMI-A-1 y puede mover la ventana, sea Zen Wayland nativo o
# XWayland.
#
# Requiere: KDE Plasma 6, KWin, gdbus (glib2) o qdbus-qt6, flatpak.

set -euo pipefail

OUTPUT="${ZEN_OUTPUT:-HDMI-A-1}"
OUTPUT="$(printf '%s' "$OUTPUT" | tr -cd 'A-Za-z0-9._-')"
[ -n "$OUTPUT" ] || OUTPUT="HDMI-A-1"

LAUNCH=1
PRINT_SCRIPT=0
LAUNCHED=0

LOG="${XDG_CACHE_HOME:-$HOME/.cache}/zen-to-arzopa.log"
mkdir -p "${LOG%/*}" 2>/dev/null || true
log() {
  printf '[%s] %s\n' "$(date '+%F %T')" "$*" >>"$LOG" 2>/dev/null || true
}

notify() {
  local urgency="$1" title="$2" body="$3"
  log "notify[$urgency] $title: $body"
  if command -v notify-send >/dev/null 2>&1; then
    notify-send -a "Zen → Arzopa" -u "$urgency" -i web-browser "$title" "$body" 2>/dev/null || true
  fi
  printf '%s: %s\n' "$title" "$body" >&2
}

zen_pids() {
  pgrep -f 'app\.zen_browser\.zen|/app/zen/zen' 2>/dev/null | sort -n -u || true
}

launch_zen() {
  log "launching zen via flatpak"
  flatpak run app.zen_browser.zen >/dev/null 2>&1 &
  LAUNCHED=1
  local waited=0
  while [ $waited -lt 80 ] && [ -z "$(zen_pids)" ]; do
    sleep 0.1
    waited=$((waited + 1))
  done
  zen_pids
}

kwin_script() {
  cat <<'JS'
var client = null;
var targetOutput = "$OUTPUT";

function findZen() {
  var wins = workspace.windowList();
  for (var i = 0; i < wins.length; i++) {
    var w = wins[i];
    var caption = (w.caption || "").toLowerCase();
    var cls = (w.resourceClass || "").toLowerCase();
    if (caption.indexOf("zen") !== -1 || cls.indexOf("zen") !== -1 ||
        caption.indexOf("zen browser") !== -1) {
      return w;
    }
  }
  return null;
}

function moveToOutput(win, outputName) {
  var outputs = workspace.outputs();
  var target = null;
  for (var i = 0; i < outputs.length; i++) {
    if (outputs[i].name === outputName) {
      target = outputs[i];
      break;
    }
  }
  if (!target) {
    return "output '" + outputName + "' not found; available: " +
           outputs.map(function(o){return o.name;}).join(", ");
  }
  workspace.sendClientToScreen(win, target);
  return "moved to " + outputName;
}

var zen = findZen();
if (!zen) {
  print("NO_WINDOW");
} else {
  print(moveToOutput(zen, targetOutput));
}
JS
}

run_kwin_script() {
  local script
  script="$(kwin_script)"
  if [ "$PRINT_SCRIPT" -eq 1 ]; then
    printf '%s\n' "$script"
    return 0
  fi
  if command -v gdbus >/dev/null 2>&1; then
    gdbus call --session --dest org.kde.KWin \
      --object-path /Scripting \
      --method org.kde.kwin.Scripting.loadScript \
      "$script" "zen-to-arzopa-$(date +%s)" \
      2>/dev/null | grep -oE '^\(true,|\(false,' || true
  elif command -v qdbus-qt6 >/dev/null 2>&1; then
    qdbus-qt6 org.kde.KWin /Scripting org.kde.kwin.Scripting.loadScript \
      "$script" "zen-to-arzopa-$(date +%s)" 2>/dev/null || true
  else
    notify critical "Error" "Ni gdbus ni qdbus-qt6 disponibles"
    return 1
  fi
}

usage() {
  cat <<'USAGE'
zen-to-arzopa.sh — mueve Zen Browser al monitor Arzopa.

Uso:
  zen-to-arzopa.sh                  Mueve Zen; si no está abierto, lo abre.
  zen-to-arzopa.sh --no-launch      Solo mueve; no abre Zen.
  zen-to-arzopa.sh --print-script   Imprime el JS de KWin y sale (debug).
  ZEN_OUTPUT=DP-1 zen-to-arzopa.sh  Fuerza otra salida (por defecto HDMI-A-1).
  zen-to-arzopa.sh --help           Muestra esta ayuda.

En Steam Game Mode (gamescope) no hay segundo monitor lógico; usá Desktop Mode.
USAGE
}

case "${1:-}" in
  --no-launch) LAUNCH=0 ;;
  --print-script) PRINT_SCRIPT=1; kwin_script; exit 0 ;;
  -h|--help) usage; exit 0 ;;
  "") ;;
  *) printf 'Opción desconocida: %s\n' "$1" >&2; exit 2 ;;
esac

main() {
  log "start output=$OUTPUT launch=$LAUNCH"
  local pids
  pids="$(zen_pids)"
  if [ -z "$pids" ]; then
    if [ "$LAUNCH" -eq 1 ]; then
      notify normal "Zen Browser" "Abriendo y moviendo a $OUTPUT..."
      pids="$(launch_zen)"
    else
      notify normal "Zen Browser" "No hay proceso Zen corriendo (usa --no-launch para solo mover)."
      exit 0
    fi
  fi
  if [ -z "$pids" ]; then
    notify critical "Zen Browser" "No se pudo iniciar Zen"
    exit 1
  fi
  local result
  result="$(run_kwin_script)"
  log "kwin result: $result"
  case "$result" in
    *NO_WINDOW*)
      notify critical "Zen Browser" "No se encontró ventana Zen en KWin"
      exit 1
      ;;
    *not\ found*)
      notify critical "Zen → Arzopa" "$result"
      exit 1
      ;;
    *moved*)
      notify low "Zen → Arzopa" "Ventana movida a $OUTPUT"
      ;;
    *)
      notify normal "Zen → Arzopa" "Resultado: $result"
      ;;
  esac
}

main "$@"