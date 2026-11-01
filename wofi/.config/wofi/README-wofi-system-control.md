# Wofi System Control

Menú de control del sistema (reemplaza al viejo eww/rofi) hecho con **wofi**.

## Qué hace
- **Categorías** (grid 3 col): Apps, Trigger, Style, Setup, System, Audio, Herramientas, About, Android, Multimedia, Instalar, Sistema + **"Todos"** (búsqueda recursiva en los 64 ítems).
- **Items** (grid 2 col): cada acción con icono, nombre y chevron ` ` a la derecha.
- **Búsqueda recursiva**: escribe `nixconf cleanup` y encuentra **Nix Cleanup** (keywords ocultas vía pango markup).
- **Navegación**: Tab/Enter/flchas. wofi en grid navega por filas/columnas (el `↓` a veces va a la derecha el primer paso — comportamiento nativo del FlowBox de GTK).

## Archivos
| Archivo | Rol |
|---|---|
| `home/scripts/system_control.sh` | Script principal: drill-down 2 pasos + case de 64 acciones |
| `wofi/.config/wofi/system-control.conf` | Config dedicada (grid, matching fuzzy, allow_markup, centrado) |
| `wofi/.config/wofi/system-control.css` | GTK CSS con paleta wal (hover/selected, Nerd Font) |
| `eww/.config/eww/scripts/system-menu-manifest.tsv` | Fuente única: categoría / icono / label (64 ítems) |
| `eww/.config/eww/scripts/system-menu-kw.tsv` | Keywords por icono para búsqueda recursiva |
| `eww/.config/eww/scripts/toggle-game-mode.sh` | Configuración visual del modo gaming |
| `eww/.config/eww/scripts/power-modes-fuzzel.sh` | Orquestación de perfiles y carga TLP |
| `home/omarchy-arch-bin/omarchy-nix-pkg-install` | Selector Television para abrir shells temporales con paquetes de nixpkgs |

## Añadir un ítem
1. Edita `system-menu-manifest.tsv` → nueva línea `Categoría<TAB>icono<TAB>Label`
2. Si querés keywords de búsqueda, agrégalas en `system-menu-kw.tsv`
3. Crea el handler en `system_control.sh` (bloque `case "$ICON"`)

## Modo gaming y carga TLP

La política persistente de NixOS está en `nixconf/nixos/base-configuration.nix` y
usa el perfil desktop `30/80`. `power-modes-fuzzel.sh` es el único orquestador de
TLP; `toggle-game-mode.sh` solo cambia la configuración visual de Hyprland.

| Opción | Efecto visual/CPU | Carga TLP |
|---|---|---|
| Modo Ahorro | `powersave` | `true` → `tlp fullcharge` (100%) |
| Modo Equilibrado | `powersave` | `false` → `tlp setcharge 30 80` |
| Modo Juego activo | `performance` + layout gaming | `true` → `tlp fullcharge` (100%) |
| Modo Juego desactivado/reset | `powersave` + layout desktop | `false` → `tlp setcharge 30 80` |

El selector usa `sudo -n`; si TLP o el permiso sudo no están disponibles, la
operación de carga se omite y el cambio de CPU/layout continúa sin bloquearse.

## Nix temporal

El ítem **Nix temporal** (``) usa el canal `tv nix` de Television, configurado
en `~/.config/television/cable/nix.toml`, para seleccionar uno o varios paquetes
de `nixpkgs` con preview. Después pregunta el alcance de la instalación:

| Opción | Comando | Alcance |
|---|---|---|
| **Shell temporal** | `nix shell --impure nixpkgs#paquete` | Disponible solo dentro de esa shell; desaparece al ejecutar `exit` |
| **Sesión temporal** | `nix profile add --impure --profile "$XDG_RUNTIME_DIR/nix-session-profile" nixpkgs#paquete` | Disponible en todas las terminales nuevas durante la sesión de usuario |

En el modo de sesión, `zsh/.zshrc` detecta el perfil temporal y añade su
directorio `bin` al `PATH` de cada terminal nueva. Las terminales que ya estaban
abiertas pueden recargarlo con `source ~/.zshrc`. El perfil vive en
`XDG_RUNTIME_DIR`, se limpia al cerrar sesión o reiniciar y no modifica el perfil
permanente de Nix.

El modo Shell termina al ejecutar `exit`. Ninguno de los dos modos modifica
`home-manager`, el flake ni el perfil permanente. Nix puede conservar los artefactos descargados en
`/nix/store` hasta que el garbage collector los elimine, pero eso no convierte
los paquetes en instalaciones permanentes.

Si una operación de Nix falla, conserva los detalles de `stderr` en
`${XDG_CACHE_HOME:-$HOME/.cache}/nix-temporary-install.log` sin enviar notificaciones.
El progreso se muestra en vivo mientras se escribe el mismo contenido en el log,
que también registra el modo, los paquetes elegidos y el espacio disponible. Las
operaciones temporales usan `--option min-free 0 --option max-free 0` para evitar
que el auto-GC del daemon bloquee la apertura; no cambian la configuración global.

La variable `NIXPKGS_ALLOW_UNFREE=1` y la opción `--impure` se aplican solo a
esa invocación para permitir paquetes como `unrar` sin cambiar la configuración
global.

## Atajos
- `Super+Z` → abre el menú

---
## Créditos

**dizzi1222** — autor del System Control, del script `system_control.sh`, de la migración eww→rofi→wofi, y del fix de los guards que pegaban el CSS. Creado el 2026-09-19.

> Menú inspirado en el estilo Omarchy (grid con chevrons), sin 8 horas de Quickshell 😉
