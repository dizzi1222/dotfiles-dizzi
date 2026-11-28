#!/usr/bin/env bash
# test-arzopa-seat.sh — prueba el reparto de arzopa-seat.sh sobre un /sys
# simulado con el hardware real de la X1E2 (Compx/RK61, G305, receptor c542…).
# No toca seats reales: loginctl, udevadm y bluetoothctl son stubs.
# uso: bash home/scripts/arzopa/test-arzopa-seat.sh
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
PASS=0 FAIL=0 OUT="" RC=0 CALLS=""

# shellcheck source=arzopa-seat.sh
source "$HERE/arzopa-seat.sh"

#Stubs

declare -A BT_ICON=()
udevadm() {
  local p real
  case "$1" in
    info)
      if [ "$2" = -q ]; then # info -q property -p DEV
        cat "${*: -1}/.udev" 2>/dev/null
      else # info DEV… → bloques "P: devpath" + "E: KEY=VAL", como el real
        shift
        for p in "$@"; do
          real=$(readlink -f "$p")
          [ -e "$real/.udev" ] || continue
          printf 'P: %s\n' "${real#"$SYS"}"
          sed 's/^/E: /' "$real/.udev"
          echo
        done
      fi
      ;;
    trigger) printf 'trigger %s %s\n' "${3#--action=}" "${4##*/}" >>"$CALLS" ;;
  esac
  return 0
}
loginctl() {
  case "$1" in
    attach)
      if [ "$ATTACH_FAIL" = 1 ]; then
        printf 'attach %s %s FALLA\n' "$2" "${3##*/}" >>"$CALLS"
        return 1
      fi
      printf 'attach %s %s\n' "$2" "${3##*/}" >>"$CALLS"
      set_seat "$3" "$2"
      ;;
    seat-status) seat_status "$2" ;;
    show-seat) printf '%s\n' "${ACTIVE_SID-2}" ;;
    show-session) printf 'Desktop=%s\nState=%s\n' "$ACTIVE_DESKTOP" "$ACTIVE_STATE" ;;
  esac
}
# Como `loginctl seat-status`: cada línea termina con la ruta /sys del dispositivo
seat_status() {
  local d real s
  for d in "$SYS"/class/input/input* "$SYS"/class/drm/card[0-9]*; do
    [ -e "$d" ] || continue
    real=$(readlink -f "$d")
    s=$(sed -n 's/^ID_SEAT=//p' "$real/.udev" 2>/dev/null)
    [ "${s:-seat0}" = "$1" ] && printf '         ├─%s\n' "$real"
  done
  return 0
}
bluetoothctl() {
  [ "$1" = info ] && [ -n "${BT_ICON[$2]:-}" ] && printf '\tIcon: %s\n' "${BT_ICON[$2]}"
  return 0
}
timeout() { shift; "$@"; }
sleep() { :; }

# Refleja el seat nuevo en el /sys simulado (inputN o cardN y sus eventN)
set_seat() {
  local f
  for f in "$1/.udev" "$1"/event*/.udev; do
    [ -e "$f" ] || continue
    sed -i '/^ID_SEAT=/d' "$f"
    echo "ID_SEAT=$2" >>"$f"
  done
}

#Fixture

# input <eventN> <inputN> <padre bajo devices/> <bustype> <nombre> [props udev...]
input() {
  local ev="$1" in="$2" dir="$SYS/devices/$3/input/$2" bus="$4" name="$5"
  shift 5
  mkdir -p "$dir/id" "$dir/$ev"
  printf '%s\n' "$name" >"$dir/name"
  printf '%s\n' "$bus" >"$dir/id/bustype"
  : >"$dir/.udev"
  printf '%s\n' "$@" >"$dir/$ev/.udev"
  ln -s .. "$dir/$ev/device"
  ln -s "$dir" "$SYS/class/input/$in"
  ln -s "$dir/$ev" "$SYS/class/input/$ev"
}

iface() { # iface <ruta bajo devices/> <subclase> <protocolo>
  local d="$SYS/devices/$1"
  mkdir -p "$d"
  echo 03 >"$d/bInterfaceClass"
  echo "$2" >"$d/bInterfaceSubClass"
  echo "$3" >"$d/bInterfaceProtocol"
}

new_fixture() { # new_fixture <nombre> [driver de card0]
  SYS="$TMP/$1/sys" RULES_DIR="$TMP/$1/rules" CALLS="$TMP/$1/calls"
  ACTIVE_DESKTOP=gamescope ACTIVE_STATE=active ATTACH_FAIL=0
  BT_ICON=()
  mkdir -p "$SYS/class/input" "$SYS/class/drm" "$SYS/bus/pci/drivers/${2:-nvidia}" "$RULES_DIR"
  : >"$CALLS"
  local pci="$SYS/devices/pci0000:00/0000:00:01.0/0000:01:00.0" c
  mkdir -p "$pci/drm/card0"
  : >"$pci/drm/card0/.udev"
  ln -s "$SYS/bus/pci/drivers/${2:-nvidia}" "$pci/driver"
  ln -s ../.. "$pci/drm/card0/device"
  ln -s "$pci/drm/card0" "$SYS/class/drm/card0"
  for c in HDMI-A-1 DP-1; do
    mkdir -p "$pci/drm/card0/card0-$c"
    echo disconnected >"$pci/drm/card0/card0-$c/status"
    : >"$pci/drm/card0/card0-$c/edid"
    ln -s "$pci/drm/card0/card0-$c" "$SYS/class/drm/card0-$c"
  done
  # Laptop: teclado i8042, touchpad RMI, TrackPoint y virtuales (Espanso, Steam)
  input event3 input3 platform/i8042/serio0 0011 "AT Translated Set 2 keyboard" ID_INPUT_KEY=1 ID_INPUT_KEYBOARD=1
  input event9 input35 pci0000:00/0000:00:1f.4/i2c-11/11-002c/rmi4-00 001d "Synaptics TM3512-010" ID_INPUT_TOUCHPAD=1
  input event21 input36 pci0000:00/0000:00:1f.4/i2c-11/11-002c/rmi4-00/rmi4-00.fn03/serio3 0011 "TPPS/2 Elan TrackPoint" ID_INPUT_MOUSE=1
  input event23 input38 virtual 0003 "Espanso virtual device" ID_INPUT_KEY=1 ID_INPUT_KEYBOARD=1
  input event25 input45 virtual 0003 "libvirtualhid Keyboard" ID_INPUT_MOUSE=1 ID_INPUT_KEY=1 ID_INPUT_KEYBOARD=1
}

monitor() { # monitor [sin-edid]
  local c="$SYS/class/drm/card0-HDMI-A-1"
  echo connected >"$c/status"
  [ "${1:-}" = sin-edid ] || head -c 256 /dev/zero | tr '\0' 'E' >"$c/edid"
}

compx() { # dongle 2.4G del RK61 Plus: interfaz boot teclado + interfaz boot "mouse"
  local u=pci0000:00/0000:00:14.0/usb1/1-7/1-7.1/1-7.1.1
  iface "$u/1-7.1.1:1.0" 01 01
  iface "$u/1-7.1.1:1.1" 01 02
  input event13 input41 "$u/1-7.1.1:1.0/0003:25A7:FA70.0009" 0003 "Compx 2.4G Wireless Receiver" ID_INPUT_KEY=1 ID_INPUT_KEYBOARD=1
  input event14 input42 "$u/1-7.1.1:1.1/0003:25A7:FA70.000A" 0003 "Compx 2.4G Wireless Receiver Mouse" ID_INPUT_MOUSE=1
  input event16 input44 "$u/1-7.1.1:1.1/0003:25A7:FA70.000A" 0003 "Compx 2.4G Wireless Receiver Keyboard" ID_INPUT_KEY=1 ID_INPUT_KEYBOARD=1
}

g305() { # g305 <on|off> — hijo DJ del receptor LIGHTSPEED con batería HID++
  local u=pci0000:00/0000:00:14.0/usb1/1-1 hid ps
  iface "$u/1-1:1.0" 01 01
  iface "$u/1-1:1.1" 01 02
  iface "$u/1-1:1.2" 00 00
  hid="$u/1-1:1.2/0003:046D:C53F.0003/0003:046D:4074.0007"
  input event5 input25 "$hid" 0003 "Logitech G305" ID_INPUT_MOUSE=1 ID_INPUT_KEY=1 ID_INPUT_KEYBOARD=1
  ps="$SYS/devices/$hid/power_supply/hidpp_battery_0"
  mkdir -p "$ps"
  if [ "$1" = on ]; then echo 1 >"$ps/online"; echo Discharging >"$ps/status"
  else echo 0 >"$ps/online"; echo Unknown >"$ps/status"; fi
}

c542() { # receptor Logitech nano (sin HID++): cuenta mientras esté enchufado
  local u=pci0000:00/0000:00:14.0/usb1/1-7/1-7.3
  iface "$u/1-7.3:1.0" 01 02
  input event12 input40 "$u/1-7.3:1.0/0003:046D:C542.0008" 0003 "Logitech Wireless Receiver Mouse" ID_INPUT_MOUSE=1
}

g203() { # mouse gamer cableado: interfaz boot mouse + interfaz de macros "Keyboard"
  local u=pci0000:00/0000:00:14.0/usb1/1-2
  iface "$u/1-2:1.0" 01 02
  iface "$u/1-2:1.1" 00 00
  input event30 input50 "$u/1-2:1.0/0003:046D:C092.0010" 0003 "Logitech G203 LIGHTSYNC Gaming Mouse" ID_INPUT_MOUSE=1
  input event31 input51 "$u/1-2:1.1/0003:046D:C092.0011" 0003 "Logitech G203 LIGHTSYNC Gaming Mouse Keyboard" ID_INPUT_KEY=1 ID_INPUT_KEYBOARD=1
}

bt_rk61() { # bt_rk61 [sin-icono] — RK61 por Bluetooth (uhid) con una colección "Mouse" extra
  local h=virtual/misc/uhid/0005:05AC:024F.0020 mac=e7:1f:bc:c1:ce:85
  input event40 input60 "$h" 0005 "RK61Plus5.0" ID_INPUT_KEY=1 ID_INPUT_KEYBOARD=1
  input event41 input61 "$h" 0005 "RK61Plus5.0 Mouse" ID_INPUT_MOUSE=1
  echo "$mac" >"$SYS/devices/$h/input/input60/uniq"
  echo "$mac" >"$SYS/devices/$h/input/input61/uniq"
  [ "${1:-}" = sin-icono ] || BT_ICON[$mac]=input-keyboard
}

yubikey() { # llave OTP: interfaz boot de teclado, vendor 1050
  local u=pci0000:00/0000:00:14.0/usb1/1-3
  iface "$u/1-3:1.0" 01 01
  echo 1050 >"$SYS/devices/$u/idVendor"
  input event32 input52 "$u/1-3:1.0/0003:1050:0407.0012" 0003 "Yubico YubiKey OTP+FIDO+CCID" ID_INPUT_KEY=1 ID_INPUT_KEYBOARD=1
}

mando_kbd() { # mando con interfaz boot de teclado además del joystick
  local u=pci0000:00/0000:00:14.0/usb1/1-4
  iface "$u/1-4:1.0" 00 00
  iface "$u/1-4:1.1" 01 01
  echo 2dc8 >"$SYS/devices/$u/idVendor"
  input event33 input53 "$u/1-4:1.0/0003:2DC8:3106.0013" 0003 "8BitDo Ultimate 2C" ID_INPUT_JOYSTICK=1
  input event34 input54 "$u/1-4:1.1/0003:2DC8:3106.0014" 0003 "8BitDo Ultimate 2C Keyboard" ID_INPUT_KEY=1 ID_INPUT_KEYBOARD=1
}

touchpad_virtual() { # uinput con capacidades de touchpad y eventN menor que el Synaptics
  input event2 input5 virtual 0006 "Virtual Touchpad" ID_INPUT_TOUCHPAD=1
}

in_seat() { # in_seat <inputN|card0> <seat> — estado inicial
  local d
  d=$(readlink -f "$SYS/class/input/$1" 2>/dev/null)
  [ -d "$d" ] || d=$(readlink -f "$SYS/class/drm/$1")
  set_seat "$d" "$2"
}

#Runner

run() { # run <attach|detach> [args…]
  : >"$CALLS"
  OUT=$("cmd_$1" "${@:2}" 2>&1)
  RC=$?
}
attaches() { grep '^attach ' "$CALLS" | tr '\n' ';'; }
expect() { # expect <nombre> <obtenido> <esperado>
  if [ "$2" = "$3" ]; then
    PASS=$((PASS + 1))
    printf 'ok    %s\n' "$1"
  else
    FAIL=$((FAIL + 1))
    printf 'FALLA %s\n      esperado: %s\n      obtenido: %s\n' "$1" "$3" "$2"
    printf '%s\n' "$OUT" | sed 's/^/      | /'
  fi
}

A="seat-arzopa"
ALL="attach $A card0;attach $A input3;attach $A input35;"

#Escenarios: lo que pidió Diego

new_fixture nada
run attach
expect "sin monitor ni periféricos: teclado y touchpad se quedan" "$(attaches)" "attach $A card0;"

new_fixture sin-monitor
compx; g305 on
run attach
expect "periféricos sin monitor: teclado y touchpad se quedan" "$(attaches)" "attach $A card0;"

new_fixture monitor-solo
monitor
run attach
expect "monitor sin periféricos: teclado y touchpad se quedan" "$(attaches)" "attach $A card0;"

new_fixture todo
monitor; compx; g305 on
run attach
expect "monitor + dongle + G305: teclado y touchpad a la Arzopa" "$(attaches)" "$ALL"
expect "log con lo detectado" "$(grep -c 'teclado externo: Compx 2.4G Wireless Receiver, Compx 2.4G Wireless Receiver Keyboard · mouse externo: Logitech G305' <<<"$OUT")" 1
expect "espera a que logind liste cada dispositivo en su seat" "$(grep -c 'aviso: logind' <<<"$OUT")" 0
run attach
expect "segunda pasada: idempotente" "$(attaches)" ""

new_fixture g305-apagado
monitor; compx; g305 off
run attach
expect "G305 apagado: solo el teclado pasa, touchpad se queda" "$(attaches)" "attach $A card0;attach $A input3;"

new_fixture solo-mouse
monitor; g305 on
run attach
expect "sin teclado externo: solo el touchpad pasa" "$(attaches)" "attach $A card0;attach $A input35;"

#Escenarios: falsos positivos

new_fixture compx-mouse
monitor; compx
run attach
expect "la interfaz Mouse del dongle Compx no cuenta como mouse" "$(attaches)" "attach $A card0;attach $A input3;"

new_fixture g203
monitor; g203
run attach
expect "la interfaz Keyboard del G203 no cuenta como teclado" "$(attaches)" "attach $A card0;attach $A input35;"

new_fixture c542
monitor; c542
run attach
expect "receptor c542 cuenta como mouse" "$(attaches)" "attach $A card0;attach $A input35;"

new_fixture bt
monitor; bt_rk61
run attach
expect "RK61 por Bluetooth es teclado; su colección Mouse no es mouse" "$(attaches)" "attach $A card0;attach $A input3;"

new_fixture bt-sin-icono
monitor; bt_rk61 sin-icono
run attach
expect "RK61 BT sin icono de BlueZ (teclado + Mouse): no cuenta ni como mouse" "$(attaches)" "attach $A card0;"

new_fixture yubikey
monitor; yubikey
run attach
expect "una YubiKey (boot teclado, vendor 1050) no es teclado" "$(attaches)" "attach $A card0;"

new_fixture mando
monitor; mando_kbd
run attach
expect "un mando con interfaz de teclado no es teclado" "$(attaches)" "attach $A card0;"

new_fixture touchpad-virtual
monitor; g305 on; touchpad_virtual
run attach
expect "un touchpad uinput no reemplaza al Synaptics" "$(attaches)" "attach $A card0;attach $A input35;"

new_fixture sin-edid
monitor sin-edid; compx; g305 on
run attach
expect "conector 'connected' sin EDID no es monitor" "$(attaches)" "attach $A card0;"

#Escenarios: vuelta y seguridad

new_fixture vuelta
monitor; g305 on
in_seat input3 "$A"
run attach
expect "teclado quedó en la Arzopa y ya no hay dongle: vuelve" "$(attaches)" "attach $A card0;attach seat0 input3;attach $A input35;"
expect "vuelta con remove → attach → add (cage suelta, gamescope toma)" \
  "$(grep -E 'event3$|input3$' "$CALLS" | tr '\n' ';')" "trigger remove event3;attach seat0 input3;trigger add event3;"

new_fixture rollback
monitor; g305 on
in_seat input3 "$A"
ATTACH_FAIL=1
run attach
expect "attach falla tras el remove: add de vuelta (el teclado no queda muerto)" \
  "$(grep -E 'event3$|input3( FALLA)?$' "$CALLS" | tr '\n' ';')|$RC" "trigger remove event3;attach seat0 input3 FALLA;trigger add event3;|1"

new_fixture restos
monitor; compx; g305 on; c542
in_seat input40 "$A"
run attach
expect "un mouse que dejó la versión anterior en la Arzopa vuelve a seat0" "$(attaches)" "${ALL}attach seat0 input40;"

new_fixture egpu amdgpu
monitor; compx; g305 on
in_seat input3 "$A"; in_seat input35 "$A"
run attach
expect "card0 = eGPU AMD: no se toca y los inputs vuelven" "$(attaches)" "attach seat0 input3;attach seat0 input35;"

new_fixture escritorio
monitor; compx; g305 on
ACTIVE_DESKTOP=KDE
run attach
expect "Desktop Mode (KDE): no mueve nada" "$(attaches)" ""
run attach --dry-run
expect "Desktop Mode --dry-run muestra el plan sin aplicarlo" "$(attaches)|$(grep -c 'teclado interno → seat-arzopa' <<<"$OUT")" "|1"

new_fixture cambio-a-game-mode
monitor; compx; g305 on
ACTIVE_DESKTOP=KDE ACTIVE_STATE=closing
run attach
expect "sesión KDE cerrándose (Desktop → Game Mode) no bloquea el reparto" "$(attaches)" "$ALL"

new_fixture dry
monitor; compx; g305 on
run attach --dry-run
expect "--dry-run no llama a loginctl" "$(attaches)" ""

new_fixture alias
monitor; compx; g305 on
run attach --keyboard
expect "--keyboard (alias antiguo) = reparto automático" "$(attaches)" "$ALL"

new_fixture opcion
run attach --foo
expect "opción desconocida → exit 2" "$RC" 2

#Escenarios: toggles y detach

new_fixture toggle
run attach --keyboard-only
expect "toggle Teclado → Arzopa fuerza el teclado" "$(attaches)" "attach $A input3;"
run detach --keyboard-only
expect "toggle Teclado → Laptop" "$(attaches)" "attach seat0 input3;"

new_fixture detach-inputs
monitor; compx; g305 on
run attach
run detach --inputs
expect "detach --inputs devuelve inputs y deja card0" "$(attaches)" "attach seat0 input3;attach seat0 input35;"

new_fixture detach-total
monitor; c542
in_seat card0 "$A"; in_seat input3 "$A"; in_seat input35 "$A"; in_seat input40 "$A"
printf 'TAG=="seat", ENV{ID_FOR_SEAT}=="input-usb-viejo", ENV{ID_SEAT}="%s"\n' "$A" >"$RULES_DIR/72-seat-input-usb-viejo.rules"
printf 'TAG=="seat", ENV{ID_FOR_SEAT}=="input-otro", ENV{ID_SEAT}="seat0"\n' >"$RULES_DIR/72-seat-input-otro.rules"
run detach
expect "detach total: todo vuelve a seat0" "$(attaches)" "attach seat0 input3;attach seat0 input35;attach seat0 input40;attach seat0 card0;"
expect "detach total: borra la regla huérfana de seat-arzopa y deja las de seat0" \
  "$(for f in "$RULES_DIR"/*; do printf '%s ' "${f##*/}"; done)" "72-seat-input-otro.rules "

printf '\n%d ok, %d fallas\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
