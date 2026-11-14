# Zen Browser en la Arzopa durante SteamOS Game Mode

Documento de investigación y estado del intento de mostrar Zen Browser en el
monitor portátil ARZOPA mientras se juega en SteamOS Game Mode (gamescope).

## Objetivo

Tener Zen Browser visible en la Arzopa (`HDMI-A-1`, NVIDIA `card0`) mientras la
pantalla interna (`eDP-1`, Intel `card1`) la usa gamescope para el juego o la
interfaz de Steam. El equivalente Linux del proyecto
[`fse-multimonitor`](https://github.com/dizzi1222/fse-multimonitor) de Windows.

## Hardware y sesión

| Elemento | Valor |
|---|---|
| Sesión | `XDG_SESSION_TYPE=x11`, `XDG_CURRENT_DESKTOP=gamescope` |
| Compositor | gamescope `3.17.0-ogc1+` |
| GPU interna | Intel UHD 630 = `card1` → `eDP-1` 1920x1080@60 |
| GPU externa | NVIDIA GTX 1650 Max-Q = `card0` → `HDMI-A-1` (ARZOPA) 1920x1080@144 |
| Driver NVIDIA | `nvidia_drm.modeset=Y`, `nvidia_drm.fbdev=Y`, 615.78.08 |
| KWin (Desktop) | configura ambos monitores extendidos en `~/.config/kwinoutputconfig.json` |

gamescope arranca con `--prefer-output *,eDP-1` y **solo abre `/dev/dri/card1`**.
La Arzopa queda encendida a nivel DRM (`enabled`, `dpms=On`) pero fuera del
compositor.

## Por qué no basta con mover la ventana

gamescope es un compositor de **una sola salida lógica**. `wayland-info` en
`gamescope-0` muestra un único `wl_output` llamado `gamescope`; Xwayland `:0` y
`:1` reportan un solo monitor. Cualquier `xdotool`/`wmctrl` mueve la ventana
dentro del mismo framebuffer lógico, no a la Arzopa.

En Windows el overlay de `fse-multimonitor` funciona porque DWM expone
`DwmRegisterThumbnail` y permite una ventana borderless sobre el segundo
monitor. En Wayland/gamescope no existe un equivalente de DWM y gamescope retiene
el seat de entrada. La vía real es un **segundo compositor** en `card0`.

## Intentos y resultados

### Vía A — cage/wlroots en `card0`

```
LIBSEAT_BACKEND=logind WLR_DRM_DEVICES=/dev/dri/card0 WLR_BACKENDS=drm \
  cage -d -m last -- flatpak run app.zen_browser.zen
```

Resultado inicial: `libseat: Could not take control of session: Device or
resource busy`. gamescope ya había hecho `TakeControl()` de `seat0`, que incluye
`card0`.

Con `LIBSEAT_BACKEND=noop` se evita el conflicto de logind y cage llega a pedir
modeset en `HDMI-A-1`, pero falla el swapchain / `drmModeAtomicCommit`.

### Vía C — Xorg dedicado en `:2`

`Xorg.wrap: Only console users are allowed to run the X server`. Xwrapper de
Bazzite bloquea servidores X fuera de la consola física.

### Vía D — KMS directo (kmssink)

`drmModeSetPlane failed: Permission denied (13)`. Sin rol de DRM master no se
pueden tocar planos/CRTC.

## Causa raíz (2026-11-13)

El log de `/tmp/arzopa-test.log` muestra que `drmSetMaster` falla **incluso como
root**:

```
== drmSetMaster ANTES (como root, card0 en seat0) ==
/dev/dri/card0 SET_MASTER failed: 16 Device or resource busy

== moviendo card0 a seat-arzopa ==
...
== drmSetMaster DESPUÉS (root, card0 fuera de seat0) ==
/dev/dri/card0 SET_MASTER failed: 16 Device or resource busy
```

En el kernel actual (`drivers/gpu/drm/drm_auth.c`):

```c
int drm_setmaster_ioctl(...)
{
    ...
    ret = drm_master_check_perm(dev, file_priv);
    if (ret)
        return ret;

    if (drm_is_current_master_locked(file_priv))
        return ret;

    if (dev->master)
        return -EBUSY;   /* no hay bypass para root */
    ...
}
```

Es decir:

1. gamescope llama `TakeControl` sobre `seat0`; systemd-logind abre todos los
   dispositivos DRM del seat (incluida `card0`) y les pone **DRM master**.
2. `loginctl attach seat-arzopa card0` cambia la asignación de seat, pero **no
   libera el master** que logind ya tomó para la sesión activa.
3. Cualquier otro proceso —incluido root— recibe `EBUSY` al intentar
   `drmSetMaster`, porque `dev->master` sigue ocupado.
4. `nvidia_drm.fbdev=Y` es un factor adicional a descartar, pero no el único.

El `[MASTER]` que muestra `loginctl seat-status` es el "master device" del seat
(el dispositivo gráfico principal), no el DRM master del kernel; no confundirlos.

## Diseño corregido (pendiente de validar)

La clave es mover `card0` a `seat-arzopa` **antes** de que gamescope haga
`TakeControl` de `seat0`. Así logind nunca lo incluye y queda sin master.

1. **Drop-in del unit de gamescope**
   `~/.config/systemd/user/gamescope-session-plus@ogui-steam.service.d/arzopa.conf`:

   ```ini
   [Service]
   ExecStartPre=/usr/bin/sudo -n /usr/local/bin/arzopa-attach
   ExecStopPost=/usr/bin/sudo -n /usr/local/bin/arzopa-detach
   ```

2. **Helpers root** (`/usr/local/bin/arzopa-attach` y `arzopa-detach`) que hacen
   `loginctl attach seat-arzopa <card0>` y lo devuelven a `seat0`.

3. **Regla sudoers** sin contraseña solo para esos dos helpers.

4. **Servicio de usuario** `arzopa-gamemode.service` que lanza cage como
   `diego` (no root) con:

   ```
   LIBSEAT_BACKEND=noop
   WLR_BACKENDS=drm
   WLR_DRM_DEVICES=/dev/dri/card0
   WLR_LIBINPUT_NO_DEVICES=1
   ```

5. **Grupo `video`** para `diego`: al sacar `card0` de `seat0` desaparece la ACL
   de logind y el dispositivo queda `root:video 0660`.

6. **Input**: por ahora `WLR_LIBINPUT_NO_DEVICES=1`, o sea solo visual. Para
   controlar Zen habría que duplicar un dispositivo de entrada a `seat-arzopa`
   (por ejemplo con `evsieve`) o aceptar que el teclado/touchpad dejen de estar
   en `seat0`.

## Launcher genérico (nuevo)

`arzopa-menu.sh` es el único icono del system-control (categoría Setup):

1. **Abrir app en Arzopa** → `arzopa-launcher.sh` reutiliza
   `lib/desktop_apps.py` (el mismo selector que `gamescope-launcher.sh`) y
   lanza cualquier `.desktop` dentro de cage en `card0`.
2. **Zen en Arzopa (Game Mode)** → instala/activa el servicio y adjunta
   `card0` + touchpad a `seat-arzopa`.
3. **Zen → Arzopa (Desktop Mode)** → `zen-to-arzopa.sh` vía KWin.

`arzopa-gamescope-shim.sh` traduce los flags de gamescope a cage, para que el
helper de apps funcione sin cambios.

### Touchpad

El touchpad (`Synaptics TM3512-010`, `input34`) se mueve a `seat-arzopa` con
`loginctl attach`. El `event5` no tiene tag `seat`; el padre `input34` sí.
El shim `libseat-seat-arzopa.so` hace que libinput de cage use `seat-arzopa`
en vez del `seat0` que devuelve el backend `noop`.

## Estado

- [x] Diagnóstico de gamescope single-output.
- [x] Identificación de GPUs, conectores y rutas sysfs.
- [x] Prueba de cage/gamescope/KMS y lectura del error real (`EBUSY`).
- [x] Causa raíz documentada.
- [ ] Validar el diseño corregido tras reiniciar Game Mode.
- [ ] Input en la Arzopa (visual-only por ahora).
- [ ] Integración estable con el menú de System Control.

## Scripts

| Archivo | Rol |
|---|---|
| `home/scripts/setup-via-a-arzopa.sh` | Instalador del drop-in, helpers, sudoers y servicio de usuario |
| `home/scripts/arzopa-gamemode.sh` | Arranque/parada de cage en `card0` (WIP) |
| `home/scripts/zen-to-arzopa.sh` | Mueve Zen a la Arzopa en **Desktop Mode** vía KWin (funcional) |
| `home/scripts/test-via-a.sh` | Prueba manual antigua de cage (histórico) |

## Referencias

- Kernel: `drivers/gpu/drm/drm_auth.c`, `drm_setmaster_ioctl()`.
- Log del test: `/tmp/arzopa-test.log`, `/tmp/arzopa-gs.log`.
- Rutas sysfs correctas:
  - `/sys/devices/pci0000:00/0000:00:01.0/0000:01:00.0/drm/card0`
  - `/sys/devices/pci0000:00/0000:00:01.0/0000:01:00.0/drm/card0/card0-HDMI-A-1`
- Socket de Game Mode: `/run/user/1000/gamescope-0`.
