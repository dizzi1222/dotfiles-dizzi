# QtScrcpy (config versionada)

Config del QtScrcpy (mirroring Android) en dotfiles, para que el **Wireless IP
10.0.0.6:5555** quede fijo y no se pierda al reiniciar la app.

## Por qué hace falta esto

El AppImage trae un `AppRun.wrapped` que **fuerza** `QTSCRCPY_CONFIG_PATH` a
`$HERE/usr/share/config`, es decir dentro del squashfs (solo lectura). Resultado:
QtScrcpy arranca siempre con los valores por defecto (`192.168.0.1`) y **nunca
guarda** lo que se escribe en el panel.

Solución aplicada:

1. AppImage extraído de forma permanente en `~/Applications/QtScrcpy/`
   (ya no se ejecuta el `.AppImage` montado).
2. `~/Applications/QtScrcpy/AppRun.wrapped` parcheado a
   `export QTSCRCPY_CONFIG_PATH="${QTSCRCPY_CONFIG_PATH:-$HERE/usr/share/config}"`
   → respeta la variable si viene definida.
3. El `.desktop` define la variable apuntando a este directorio:
   `dotfiles-dizzi/qtscrcpy/.config/QtScrcpy`.

## Archivos

| Archivo | Contenido |
| --- | --- |
| `.config/QtScrcpy/config.ini` | Ajustes generales (`[common]`), copia del template del AppImage |
| `.config/QtScrcpy/userdata.ini` | `IpHistory=10.0.0.6` y `PortHistory=5555` (combos del panel Wireless) |
| `backup/qtscrcpy.desktop.orig` | Copia literal del `.desktop` antes de tocarlo |
| `../local/.local/share/applications/qtscrcpy.desktop` | Lanzador gestionado (symlink en `~/.local/share/applications`) |

## Actualizar QtScrcpy

`~/.local/bin/qtscrcpy-update` re-extrae el AppImage y vuelve a aplicar el parche.

## Notas

- `IpHistory` se muestra en el combo de IP y la primera entrada queda
  seleccionada, así que `10.0.0.6` aparece solo al abrir la app.
- El puerto 5555 ya es el placeholder por defecto; se guarda en `PortHistory`.
- La IP se guarda **sin** puerto (`10.0.0.6`), igual que lo hace la app al
  conectar (`addr.split(":")`).
