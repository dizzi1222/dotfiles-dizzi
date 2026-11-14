/* libseat-seat-arzopa.c — fuerza que libinput use seat-arzopa.
 *
 * libseat con backend "noop" siempre devuelve "seat0". Eso hace que cage
 * enumere los dispositivos de seat0 (teclado/touchpad de gamescope) si se
 * habilita libinput. Este shim devuelve "seat-arzopa" para que cage solo vea
 * el mouse que attachamos a ese seat.
 *
 * Uso: LD_PRELOAD=/usr/local/lib/libseat-seat-arzopa.so cage ...
 */
#include <stddef.h>

const char *libseat_seat_name(void *seat) {
    (void)seat;
    return "seat-arzopa";
}
