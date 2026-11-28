#!/usr/bin/env bash
# arzopa-seat.sh — reparte card0, el teclado interno y el touchpad entre seat0
# (Game Mode) y seat-arzopa (cage en la Arzopa). setup-via-a-arzopa.sh lo
# instala como root en dos nombres; el nombre con que se invoca elige el modo:
#   /usr/local/bin/arzopa-attach   ExecStartPre de Game Mode y del servicio Zen
#   /usr/local/bin/arzopa-detach   ExecStopPost y reset al arrancar el equipo
#
# Reparto (arzopa-attach sin flags):
#   - card0 (NVIDIA) sale de seat0 siempre en Game Mode: tiene que hacerlo
#     antes de que gamescope tome el seat (ver README, DRM master).
#   - Teclado interno → Arzopa solo si hay monitor en card0 Y un teclado
#     externo (dongle/USB o Bluetooth) para el juego.
#   - Touchpad → Arzopa solo si hay monitor en card0 Y un mouse externo
#     encendido para el juego.
#   - Si falta algo, se quedan en la laptop (o vuelven a seat0).
#
# uso: arzopa-attach [--dry-run] [--keyboard-only]
#      arzopa-detach [--dry-run] [--inputs | --keyboard-only]
#   --keyboard-only  fuerza solo el teclado interno (toggle del menú)
#   --inputs         devuelve los inputs y deja card0 en seat-arzopa
#   --keyboard       alias antiguo de attach: el reparto automático ya decide
#
# Sin `set -e`: un fallo de loginctl no debe cortar el resto del reparto.
# Corre antes de que arranque gamescope, así que evita forks en los bucles:
# los helpers devuelven por nameref (`helper VAR …`) en vez de por $(…).
set -u

# Rutas fijas (corre como root vía sudo); los tests las cambian tras `source`.
SYS=/sys
RULES_DIR=/etc/udev/rules.d
ARZOPA_SEAT="seat-arzopa"
CARD=card0
DRY_RUN=0
HID_RE='^[0-9A-F]{4}:[0-9A-F]{4}:[0-9A-F]{4}\.[0-9A-F]{4}$'
USB_IFACE_RE='^[0-9]+-[0-9.]+:[0-9]+\.[0-9]+$'
MAC_RE='^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$'
LOCK=/run/arzopa-seat.lock
# Vendors USB con interfaz boot de teclado que no son teclados: Yubico (OTP),
# Valve (dongle del Steam Controller en lizard mode)
FAKE_KBD_VIDS=" 1050 28de "
declare -A UDEV_CACHE=() REAL=()

log() { printf 'arzopa: %s\n' "$*"; }

# rd VAR FILE — primera línea de un atributo sysfs (vacío si no existe)
rd() {
  local -n _rd=$1
  _rd=""
  [ -r "$2" ] && IFS= read -r _rd <"$2"
  return 0
}

# real_of VAR PATH — ruta real; usa lo que resolvió udev_load
real_of() {
  local -n _ro=$1
  case "$2" in "$SYS"/devices/*) _ro=$2; return 0 ;; esac
  _ro=${REAL[$2]-}
  [ -n "$_ro" ] || _ro=$(readlink -f "$2")
}

#Udev y seats

# Rutas reales y propiedades udev de inputs y tarjetas DRM en dos llamadas
# (una consulta suelta de udevadm cuesta ≈7 ms y aquí habría ~80)
udev_load() {
  local -a devs=() reals=()
  local d i line key=""
  UDEV_CACHE=() REAL=()
  for d in "$SYS"/class/input/input* "$SYS"/class/input/event* "$SYS"/class/drm/card[0-9]*; do
    [ -e "$d" ] && devs+=("$d")
  done
  [ "${#devs[@]}" -gt 0 ] || return 0
  mapfile -t reals < <(readlink -f -- "${devs[@]}" 2>/dev/null)
  if [ "${#reals[@]}" -eq "${#devs[@]}" ]; then
    for i in "${!devs[@]}"; do REAL[${devs[$i]}]=${reals[$i]}; done
  fi
  while IFS= read -r line; do
    case "$line" in
      "P: "*) key="$SYS${line#P: }"; UDEV_CACHE[$key]="" ;;
      "E: "*) [ -n "$key" ] && UDEV_CACHE[$key]+="${line#E: }"$'\n' ;;
    esac
  done < <(udevadm info "${devs[@]}" 2>/dev/null |
    grep -E '^(P: |E: (ID_SEAT|ID_INPUT_KEYBOARD|ID_INPUT_MOUSE|ID_INPUT_TOUCHPAD|ID_INPUT_JOYSTICK)=)')
}

# props_of VAR DEV — propiedades udev (KEY=VAL por línea)
props_of() {
  local -n _po=$1
  local real
  real_of real "$2"
  if [ -n "${UDEV_CACHE[$real]+x}" ]; then
    _po=${UDEV_CACHE[$real]}
  else
    _po=$(udevadm info -q property -p "$real" 2>/dev/null)
  fi
}

has_prop() { [[ $'\n'$1$'\n' == *$'\n'"$2=1"$'\n'* ]]; }

# seat_of VAR DEV — seat actual (ID_SEAT vacío = seat0)
seat_of() {
  local -n _so=$1
  local props s
  props_of props "$2"
  props=$'\n'$props
  s=${props#*$'\n'ID_SEAT=}
  if [ "$s" = "$props" ]; then s=""; else s=${s%%$'\n'*}; fi
  _so=${s:-seat0}
}

label() {
  case "$1" in
    */drm/*) printf '%s' "${1##*/}" ;;
    *) cat "$1/name" 2>/dev/null || printf '%s' "${1##*/}" ;;
  esac
}

# libinput ignora los "change" que emite loginctl attach: solo atiende add y
# remove. Un remove sintético hace que cage (backend noop) suelte el nodo y un
# add hace que el compositor del seat destino lo tome sin reiniciarse.
retrigger() {
  local action="$1" dev="$2" ev
  for ev in "$dev"/event*; do
    [ -e "$ev" ] && udevadm trigger -w --action="$action" "$ev" >/dev/null 2>&1
  done
  return 0
}

# Espera (≈1 s como mucho) a que logind liste el dispositivo en el seat destino:
# si el compositor pide el nodo antes, TakeDevice responde EPERM. seat-status
# termina cada línea con la ruta /sys (sufijo exacto: input3 ≠ input35).
wait_logind() {
  local i
  for i in 1 2 3 4 5 6; do
    loginctl seat-status "$1" --full 2>/dev/null |
      awk -v d="$2" 'substr($0, length($0) - length(d) + 1) == d { f = 1 } END { exit !f }' &&
      return 0
    sleep 0.1
  done
  return 1
}

# move DEV SEAT — idempotente
move() {
  local dev="$1" target="$2" cur ev
  [ -n "$dev" ] || return 0
  seat_of cur "$dev"
  [ "$cur" = "$target" ] && return 0
  log "$(label "$dev"): $cur → $target"
  [ "$DRY_RUN" = 1 ] && return 0
  # Sale de la Arzopa: el remove hace que cage suelte el nodo (seat0 → Arzopa
  # no lo necesita: logind revoca el fd de gamescope al cambiar de seat)
  [ "$cur" = "$ARZOPA_SEAT" ] && retrigger remove "$dev"
  if ! loginctl attach "$target" "$dev"; then
    log "ERROR: loginctl attach $target $dev"
    # El remove ya borró el nodo de la base de udev: sin este add nadie lo
    # vuelve a tomar y el teclado queda muerto en los dos seats
    [ "$cur" = "$ARZOPA_SEAT" ] && retrigger add "$dev"
    return 1
  fi
  unset "UDEV_CACHE[$dev]"
  for ev in "$dev"/event*; do unset "UDEV_CACHE[$ev]"; done
  udevadm settle --timeout=3 >/dev/null 2>&1 || true
  wait_logind "$target" "$dev" || log "aviso: logind no lista $(label "$dev") en $target"
  retrigger add "$dev"
}

# Dispositivos en seat-arzopa: inputN y, con "all", también tarjetas DRM
in_arzopa() {
  local d real seat
  for d in "$SYS"/class/input/input*; do
    [ -e "$d" ] || continue
    real_of real "$d"
    seat_of seat "$real"
    [ "$seat" = "$ARZOPA_SEAT" ] && printf '%s\n' "$real"
  done
  [ "$1" = all ] || return 0
  for d in "$SYS"/class/drm/card[0-9]*; do
    case "${d##*/}" in *-*) continue ;; esac # conectores (card0-HDMI-A-1)
    real_of real "$d"
    seat_of seat "$real"
    [ "$seat" = "$ARZOPA_SEAT" ] && printf '%s\n' "$real"
  done
}

# Escritorio de la sesión activa de seat0: "gamescope" en Game Mode (DesktopNames
# de la sesión de SDDM), "KDE" en Desktop Mode. Vacío si no hay sesión o si la
# que figura se está cerrando (cambio Desktop → Game Mode).
active_desktop() {
  local sid line desk="" state=""
  sid=$(loginctl show-seat seat0 -p ActiveSession --value 2>/dev/null)
  [ -n "$sid" ] || return 0
  while IFS= read -r line; do
    case "$line" in
      Desktop=*) desk=${line#Desktop=} ;;
      State=*) state=${line#State=} ;;
    esac
  done < <(loginctl show-session "$sid" -p Desktop -p State 2>/dev/null)
  [ "$state" = closing ] || printf '%s' "$desk"
}

#Monitor en card0

card_path() {
  local p
  real_of p "$SYS/class/drm/$CARD"
  printf '%s' "$p"
}

card_driver() {
  local d
  d=$(readlink -f "$SYS/class/drm/$CARD/device/driver" 2>/dev/null) || return 0
  printf '%s' "${d##*/}"
}

# Conector de card0 con monitor real (EDID); imprime p. ej. HDMI-A-1
monitor_on_card() {
  local c status
  for c in "$SYS/class/drm/$CARD"-*; do
    rd status "$c/status"
    [ "$status" = connected ] || continue
    [ "$(head -c 128 "$c/edid" 2>/dev/null | wc -c)" -ge 128 ] || continue
    printf '%s' "${c##*/"$CARD"-}"
    return 0
  done
  return 1
}

#Periféricos

# USB real (no uinput) o Bluetooth
is_external() {
  local real bus
  rd bus "$1/device/id/bustype"
  case "$bus" in
    0005) return 0 ;;
    0003)
      real_of real "$1"
      case "$real" in */devices/virtual/*) return 1 ;; */usb*) return 0 ;; esac
      ;;
  esac
  return 1
}

# ancestor_matching VAR PATH REGEX — primer ancestro cuyo nombre cumple el regex
ancestor_matching() {
  local -n _am=$1
  local d
  _am=""
  real_of d "$2"
  while [ -n "$d" ] && [ "$d" != / ]; do
    [[ ${d##*/} =~ $3 ]] && { _am=$d; return 0; }
    d=${d%/*}
  done
  return 1
}

# usb_boot_protocols VAR USBDEV — protocolos boot HID del aparato: " kbd mouse "
usb_boot_protocols() {
  local -n _ub=$1
  local i cls sub proto
  _ub=" "
  for i in "$2"/"${2##*/}":*; do
    rd cls "$i/bInterfaceClass"
    rd sub "$i/bInterfaceSubClass"
    [ "$cls$sub" = 0301 ] || continue
    rd proto "$i/bInterfaceProtocol"
    case "$proto" in
      01) _ub+="kbd " ;;
      02) _ub+="mouse " ;;
    esac
  done
}

# Batería HID++ de un HID: online=0 + status Unknown = apagado o fuera de
# alcance (hidpp_connect_event). Cargando da online=0 pero status Charging.
is_powered_off() {
  local ps online status
  for ps in "$1"/power_supply/*; do
    [ -e "$ps/online" ] || continue
    rd online "$ps/online"
    rd status "$ps/status"
    [ "$online" = 0 ] && [ "$status" = Unknown ] && return 0
  done
  return 1
}

# Aparato USB que expone teclado/mouse sin serlo: llave de seguridad, dongle de
# Steam o un mando (tiene un nodo joystick) con interfaz de teclado
usb_fake_input() {
  local vid ev props
  rd vid "$1/idVendor"
  [[ $FAKE_KBD_VIDS == *" $vid "* ]] && return 0
  for ev in "$1"/*/*/input/input*/event* "$1"/*/*/*/input/input*/event*; do
    [ -e "$ev" ] || continue
    props_of props "$ev"
    has_prop "$props" ID_INPUT_JOYSTICK && return 0
  done
  return 1
}

bt_icon() {
  [[ $1 =~ $MAC_RE ]] || return 0
  timeout 2 bluetoothctl info "$1" 2>/dev/null | sed -n 's/^[[:space:]]*Icon: //p' | head -n1
}

# bt_classify VAR MAC HAS_KBD HAS_MOUSE — se decide por aparato, no por nodo:
# un teclado BT suele traer una colección "Mouse" y un mouse BT una "Keyboard".
# BlueZ dice qué es; sin icono, un aparato con ambos tipos de nodo no cuenta.
bt_classify() {
  local -n _bt=$1
  _bt=""
  case "$(bt_icon "$2")" in
    input-keyboard) [ "$3" = 1 ] && _bt=kbd ;;
    input-mouse | input-tablet) [ "$4" = 1 ] && _bt=mouse ;;
    "") case "$3$4" in 10) _bt=kbd ;; 01) _bt=mouse ;; esac ;;
  esac
  return 0
}

# classify VAR EVENT PROPS — VAR = kbd, mouse o vacío (no cuenta / ambiguo)
classify() {
  local -n _cl=$1
  local ev="$2" kbd=0 mouse=0 bus hid parent iface protos
  _cl=""
  has_prop "$3" ID_INPUT_KEYBOARD && kbd=1
  has_prop "$3" ID_INPUT_MOUSE && mouse=1
  [ "$kbd$mouse" = 00 ] && return 0

  # Bluetooth sin MAC en uniq (raro): solo nodos de un único tipo
  rd bus "$ev/device/id/bustype"
  if [ "$bus" = 0005 ]; then
    case "$kbd$mouse" in 10) _cl=kbd ;; 01) _cl=mouse ;; esac
    return 0
  fi

  # Receptor Logitech (DJ): cada periférico emparejado es un HID hijo
  ancestor_matching hid "$ev" "$HID_RE"
  parent=${hid%/*}
  if [ -n "$hid" ] && [[ ${parent##*/} =~ $HID_RE ]]; then
    is_powered_off "$hid" && return 0
    if [ "$mouse" = 1 ]; then _cl=mouse; else _cl=kbd; fi
    return 0
  fi

  # USB directo: el protocolo boot del aparato dice qué es. Un dongle de
  # teclado (Compx) también expone una interfaz Mouse y un mouse gamer (G203)
  # una interfaz Keyboard para macros: esas no cuentan.
  ancestor_matching iface "$ev" "$USB_IFACE_RE" || return 0
  usb_fake_input "${iface%/*}" && return 0
  usb_boot_protocols protos "${iface%/*}"
  if [ "$kbd$mouse" = 10 ] && [[ $protos == *" kbd "* ]]; then
    _cl=kbd
  elif [ "$mouse" = 1 ] && [[ $protos == *" mouse "* && $protos != *" kbd "* ]]; then
    _cl=mouse
  fi
}

# add_unique VAR ITEM — agrega a una lista "a, b" sin repetir
add_unique() {
  local -n _au=$1
  case ", $_au, " in *", $2, "*) ;; *) _au="${_au:+$_au, }$2" ;; esac
}

# Llena KBD_INT, TOUCHPAD (rutas inputN), EXT_KBDS y EXT_MICE (nombres)
scan_inputs() {
  local ev props kind name bus uniq real mac
  local -A bt_kbd=() bt_mouse=() bt_name=()
  KBD_INT="" TOUCHPAD="" EXT_KBDS="" EXT_MICE=""
  for ev in "$SYS"/class/input/event*; do
    [ -e "$ev" ] || continue
    props_of props "$ev"
    rd bus "$ev/device/id/bustype"
    if is_external "$ev"; then
      rd name "$ev/device/name"
      if [ "$bus" = 0005 ]; then
        rd uniq "$ev/device/uniq"
        if [[ $uniq =~ $MAC_RE ]]; then
          has_prop "$props" ID_INPUT_KEYBOARD && bt_kbd[$uniq]=1
          has_prop "$props" ID_INPUT_MOUSE && bt_mouse[$uniq]=1
          [ -n "${bt_name[$uniq]-}" ] || bt_name[$uniq]=$name
          continue
        fi
      fi
      classify kind "$ev" "$props"
      case "$kind" in
        kbd) add_unique EXT_KBDS "$name" ;;
        mouse) add_unique EXT_MICE "$name" ;;
      esac
      continue
    fi
    # Teclado y touchpad de la laptop (un uinput con esas capacidades no cuenta)
    real_of real "$ev"
    case "$real" in */devices/virtual/*) continue ;; esac
    if [ -z "$KBD_INT" ] && [ "$bus" = 0011 ] && has_prop "$props" ID_INPUT_KEYBOARD; then
      KBD_INT=${real%/*}
    elif [ -z "$TOUCHPAD" ] && has_prop "$props" ID_INPUT_TOUCHPAD; then
      TOUCHPAD=${real%/*}
    fi
  done
  for mac in "${!bt_name[@]}"; do
    bt_classify kind "$mac" "${bt_kbd[$mac]-0}" "${bt_mouse[$mac]-0}"
    case "$kind" in
      kbd) add_unique EXT_KBDS "${bt_name[$mac]}" ;;
      mouse) add_unique EXT_MICE "${bt_name[$mac]}" ;;
    esac
  done
}

#Modos

cmd_attach() {
  local only_kbd=0 arg desk drv monitor want_kbd=seat0 want_tp=seat0 rc=0 dev
  for arg in "$@"; do
    case "$arg" in
      --keyboard-only) only_kbd=1 ;;
      --keyboard) ;;
      --dry-run) DRY_RUN=1 ;;
      *) log "opción desconocida: $arg"; return 2 ;;
    esac
  done

  # En Desktop Mode, seat-arzopa no tiene compositor: mover algo ahí lo mata
  desk=$(active_desktop)
  if [ -n "$desk" ] && [ "$desk" != gamescope ]; then
    log "sesión de escritorio activa en seat0 ($desk): no se mueve nada a $ARZOPA_SEAT"
    [ "$DRY_RUN" = 1 ] || return 0
  fi

  udev_load
  scan_inputs
  if [ "$only_kbd" = 1 ]; then
    move "$KBD_INT" "$ARZOPA_SEAT"
    return
  fi

  drv=$(card_driver)
  if [ "$drv" != nvidia ]; then
    log "$CARD usa '${drv:-?}', no la NVIDIA (¿eGPU conectada?): todo queda en seat0"
    cmd_detach
    return
  fi

  monitor=$(monitor_on_card) || monitor=""
  log "monitor en $CARD: ${monitor:-ninguno} · teclado externo: ${EXT_KBDS:-ninguno} · mouse externo: ${EXT_MICE:-ninguno}"
  if [ -n "$monitor" ]; then
    [ -n "$EXT_KBDS" ] && want_kbd=$ARZOPA_SEAT
    [ -n "$EXT_MICE" ] && want_tp=$ARZOPA_SEAT
  fi

  # card0 sale aunque no haya monitor: así, si conectas la Arzopa con Game Mode
  # ya iniciado, cage puede tomarla sin reiniciar la sesión
  move "$(card_path)" "$ARZOPA_SEAT" || rc=1
  move "$KBD_INT" "$want_kbd" || rc=1
  move "$TOUCHPAD" "$want_tp" || rc=1
  # Otros inputs que quedaron en la Arzopa (p. ej. el mouse que movía la versión anterior)
  while IFS= read -r dev; do
    [ "$dev" = "$KBD_INT" ] || [ "$dev" = "$TOUCHPAD" ] || move "$dev" seat0 || rc=1
  done < <(in_arzopa inputs)
  log "teclado interno → $want_kbd · touchpad → $want_tp"
  return "$rc"
}

# Reglas 72-seat-*.rules que siguen apuntando a seat-arzopa (dispositivo
# ausente): si no se borran, ese aparato vuelve a la Arzopa al reconectarlo
prune_rules() {
  local f
  for f in "$RULES_DIR"/72-seat-*.rules; do
    [ -e "$f" ] || continue
    grep -qF "ENV{ID_SEAT}=\"$ARZOPA_SEAT\"" "$f" || continue
    log "regla huérfana: ${f##*/}"
    [ "$DRY_RUN" = 1 ] || rm -f -- "$f"
  done
  [ "$DRY_RUN" = 1 ] || udevadm control --reload >/dev/null 2>&1 || true
}

cmd_detach() {
  local scope=all arg dev rc=0
  for arg in "$@"; do
    case "$arg" in
      --inputs) scope=inputs ;;
      --keyboard-only) scope=keyboard ;;
      --dry-run) DRY_RUN=1 ;;
      *) log "opción desconocida: $arg"; return 2 ;;
    esac
  done
  udev_load
  if [ "$scope" = keyboard ]; then
    scan_inputs
    move "$KBD_INT" seat0
    return
  fi
  while IFS= read -r dev; do
    move "$dev" seat0 || rc=1
  done < <(in_arzopa "$scope")
  [ "$scope" = all ] && prune_rules
  return "$rc"
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  # Serializa ejecuciones concurrentes (servicio Zen, launcher, toggles del menú)
  if { exec 9>>"$LOCK"; } 2>/dev/null; then
    flock -w 10 9 || log "aviso: otro reparto sigue en curso; continúo sin lock"
  fi
  case "${0##*/}" in
    *detach*) cmd_detach "$@" ;;
    *) cmd_attach "$@" ;;
  esac
fi
