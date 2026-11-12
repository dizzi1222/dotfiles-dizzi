# Wofi System Control

Menú de control del sistema (reemplaza al viejo eww/rofi) hecho con **wofi**.

## Qué hace
- **Categorías** (grid 3 col): Apps, Trigger, Style, Setup, System, Audio, Herramientas, About, Android, Multimedia, Instalar, Sistema + **"Todos"** (búsqueda recursiva en los 75 ítems).
- **Items** (grid 2 col): cada acción con icono, nombre y chevron ` ` a la derecha.
- **Búsqueda recursiva**: escribe `nixconf cleanup` y encuentra **Nix Cleanup** (keywords ocultas vía pango markup).
- **Navegación**: Tab/Enter/flchas. wofi en grid navega por filas/columnas (el `↓` a veces va a la derecha el primer paso — comportamiento nativo del FlowBox de GTK).

## Archivos
| Archivo | Rol |
|---|---|
| `home/scripts/system_control.sh` | Script principal: drill-down 2 pasos + case de 75 acciones |
| `wofi/.config/wofi/system-control.conf` | Config dedicada (grid, matching fuzzy, allow_markup, centrado) |
| `wofi/.config/wofi/system-control.css` | GTK CSS con paleta wal (hover/selected, Nerd Font) |
| `eww/.config/eww/scripts/system-menu-manifest.tsv` | Fuente única: categoría / icono / label (75 ítems) |
| `eww/.config/eww/scripts/system-menu-kw.tsv` | Keywords por icono para búsqueda recursiva |
| `eww/.config/eww/scripts/toggle-game-mode.sh` | Configuración visual del modo gaming |
| `eww/.config/eww/scripts/power-modes-fuzzel.sh` | Orquestación de perfiles y carga TLP |
| `home/omarchy-arch-bin/omarchy-nix-pkg-install` | Selector Television para abrir shells temporales con paquetes de nixpkgs |
| `home/scripts/fedora-pkg-install` | Buscador TUI de paquetes Fedora/Bazzite: `dnf5 repoquery` + `gum filter` + `rpm-ostree` |
| `~/bazzite-install.sh` | Instalador personal de Bazzite (lo mantiene la otra LLM; el menú solo lo ejecuta) |
| `home/scripts/jobcopilot-install` | Instalador selectivo de JobCopilot Free (3 componentes, fuente por componente) |
| `home/scripts/spicetify-native-apply.sh` | Copia Spotify RPM al usuario y aplica Spicetify + Marketplace sin escribir en `/usr` |
| `home/scripts/spotify-spicetify-launch.sh` | Abre la copia modificada desde el lanzador Spotify (fallback al RPM si aún no existe) |

## Añadir un ítem
1. Edita `system-menu-manifest.tsv` → nueva línea `Categoría<TAB>icono<TAB>Label`
2. Si querés keywords de búsqueda, agrégalas en `system-menu-kw.tsv`
3. Crea el handler en `system_control.sh` (bloque `case "$ICON"`)

## Orden por uso reciente en "Todos"

`system_control.sh` guarda los iconos invocados en
`${XDG_STATE_HOME:-$HOME/.local/state}/system-control/recent`, con el más
reciente primero y un máximo de 32. Al abrir **Todos**, los ítems usados
recientemente aparecen arriba; el resto conserva el orden del manifest. Las
demás categorías no se reordenan.

El historial se actualiza al seleccionar una acción, tanto desde wofi como
desde el menú de eww. Cancelar no registra nada. Para borrarlo:

```bash
rm -f "${XDG_STATE_HOME:-$HOME/.local/state}/system-control/recent"
```

Wofi respeta el orden de entrada solo cuando no hay búsqueda; al escribir,
reordena por coincidencia fuzzy y el historial deja de influir en el orden.

El historial usa el icono como identificador, igual que el menú. Las entradas
que comparten icono también comparten posición: `Nix GC` es la misma acción y
las dos capturas (`Captura Pantalla`/`Captura Región`) se mueven juntas.

## Gamescope (cursor confinado)

`Apps → 󰊴 Gamescope` abre un selector **fuzzel** (o wofi con
`GAMESCOPE_PICKER=wofi`) con todas las apps de `~/.local/share/applications`
(y de los exports de Flatpak) y lanza la elegida dentro de Gamescope a pantalla
completa con `--force-grab-cursor`: el puntero queda en modo relativo dentro de
la ventana, sin escaparse al escritorio.

| Archivo | Rol |
|---|---|
| `home/scripts/gamescope-launcher.sh` | Selector fuzzel/wofi, detección de resolución y aviso de errores |
| `home/scripts/lib/desktop_apps.py` | Parsea los `.desktop` y construye el comando (sin `eval`) |

Por qué fuzzel por defecto: ya es el launcher de apps del ecosistema, arranca
más rápido y su fuzzy es mejor para listas largas (~190 apps). El estilo sale
de `~/.config/fuzzel/fuzzel.ini`; con `GAMESCOPE_PICKER=wofi` se usa el mismo
`system-control.conf/css` del resto del menú.

La lista que recibe fuzzel tiene 3 columnas por línea (`glifo`, `nombre`,
`keywords`). Se muestran las dos primeras con `--with-nth="{1} {2}"`, se
devuelve solo el nombre con `--accept-nth=2` y el matching usa
`--match-nth="{2} {3}"`, así las keywords siguen funcionando sin markup.

Qué resuelve el helper:

- Expande los códigos de campo de `Exec` (`%f`, `%F`, `%u`, `%U`, `%i`, `%c`,
  `%k`, `%%`) y respeta `Path=` y `Terminal=true` (usa kitty).
- Omite entradas con `Hidden=true`, `NoDisplay=true` o `TryExec` inexistente.
- Si el `Exec` ya trae Gamescope (por ejemplo GeForce NOW), le quita el wrapper
  externo para no anidar Gamescope dentro de Gamescope.
- Desambigua nombres repetidos con el nombre del archivo (sufijo `· archivo`).
- Si el `Exec` usa operadores de shell (`||`, `&&`, `;`), lo ejecuta con
  `bash -c`; en el resto de casos usa argumentos directos.

Flags de Gamescope realmente usadas (ver `gamescope --help`):

| Flag | Efecto |
|---|---|
| `-f` | Ventana a pantalla completa |
| `-W/-H` + `-w/-h` | Resolución de salida y anidada (detectada del monitor) |
| `--force-grab-cursor` | Confina el cursor (modo relativo) dentro de la ventana |
| `--grab` | Opcional: captura también el teclado (`GAMESCOPE_GRAB_KEYBOARD=1`) |

> En Gamescope 3.17 `--grab`/`-g` captura el **teclado**, no el ratón. El
> confinamiento del cursor es `--force-grab-cursor`. Por eso el ítem del menú
> **no** captura el teclado por defecto: así `Alt+F4` y los atajos del
> compositor siguen funcionando para salir. `Super+F` alterna pantalla completa
> y `Super+G` alterna el grab de teclado si se habilitó.

Uso y ajustes:

```bash
~/scripts/gamescope-launcher.sh              # selector fuzzel (wofi como fallback)
~/scripts/gamescope-launcher.sh steam        # atajo directo por nombre
~/scripts/gamescope-launcher.sh "Buckshot Roulette"

GAMESCOPE_WIDTH=2560 GAMESCOPE_HEIGHT=1440 ~/scripts/gamescope-launcher.sh
GAMESCOPE_EXTRA_ARGS="-s 1.5 --mangoapp" ~/scripts/gamescope-launcher.sh
GAMESCOPE_GRAB_KEYBOARD=1 ~/scripts/gamescope-launcher.sh
GAMESCOPE_NO_CURSOR_GRAB=1 ~/scripts/gamescope-launcher.sh   # sin confinar
GAMESCOPE_PICKER=wofi ~/scripts/gamescope-launcher.sh        # selector wofi
GAMESCOPE_APP_DIRS="$HOME/.local/share/applications" ~/scripts/gamescope-launcher.sh
```

Si ya hay un Gamescope abierto, el selector pregunta si cerrarlo antes de
lanzar el siguiente. Para cerrar el actual: `Alt+F4` o `Trigger → 󰊢 Kill
Gamescope`. Los errores de arranque se muestran con `notify-send` y el comando
completo queda en `~/.cache/gamescope-launcher.log`.

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

## Flatpak / Flathub

El ítem **Flatpak Pkg** (`󰏓`) busca e instala aplicaciones de Flathub.
Usa `flatpak remote-ls flathub` + `gum filter` + `flatpak install --user`.

Flujo del script `home/scripts/flatpak-pkg-install`:
1. Caché 24h (`~/.cache/flatpak-pkg-index.txt`)
2. `gum input` → `grep -i` → `gum filter` (latencia instantánea)
3. `flatpak install --user flathub <paquetes>`

Flags:
- `--refresh`  fuerza re-indexado
- `--system`   instala system-wide (requiere sudo)


## Fedora / Bazzite (dnf5 + gum)

El ítem **Fedora Pkg** (``) es el equivalente terminal a TV + gum de Nix/Omarchy,
pero para RPM. No usa Bazaar: Bazaar es una tienda Flatpak con interfaz gráfica.

Flujo del script `home/scripts/fedora-pkg-install`:

1. `dnf5 repoquery --available` genera un índice con nombre, versión, repo y resumen.
2. `gum filter` abre la búsqueda fuzzy; `TAB` permite seleccionar varios paquetes.
3. Muestra los paquetes elegidos, omite los ya instalados y pide confirmación.
4. En Bazzite ejecuta `sudo rpm-ostree install ...` y ofrece reiniciar. En Fedora
   normal ejecuta `sudo dnf5 install ...`.

Notas:

- En Bazzite la instalación es una **capa de rpm-ostree**: queda permanente y
  requiere reinicio, igual que cualquier `rpm-ostree install`.
- `rpm-ostree` en el host no acepta `--disablerepo` (solo en container build).
  Si `updates-archive` da 404, el script ofrece crear
  `/etc/yum.repos.d/fedora-updates-archive.repo` con `enabled=0` y reintenta.
- Requiere `gum`, `dnf5` y, en Bazzite, `rpm-ostree`.
- El ítem abre `kitty -e ~/scripts/fedora-pkg-install`.
- Si el script no existe en `~/scripts`, el handler avisa con `notify-send`.

## Instalador personal de Bazzite

El ítem **Bazzite Install** (`󰒓`) ejecuta el instalador personal que mantiene la
otra LLM. El menú **no lo crea ni lo modifica**: solo lo lanza.

- Busca primero `~/bazzite-install.sh`.
- Si no existe, usa `~/dotfiles-dizzi/home/bazzite-install.sh`.
- Lo abre con `kitty --hold --title "Bazzite Install" -e bash ...` para que los
  mensajes de error y los prompts de `sudo` queden visibles.
- Si no encuentra ninguno de los dos, avisa con `notify-send`.

### Spotify nativo + Spicetify en Bazzite

**Instalar →  Spicetify** abre `spicetify-native-apply.sh` en Kitty con
`--hold` para mostrar el resultado o los errores. También aparece al buscar
`spicetify`, `spotify` o `marketplace` desde **Todos**. Cierra Spotify antes de
elegirlo: el helper se detiene si el reproductor está abierto.

`home/bazzite-install.sh` instala `spotify-client` del COPR comunitario
`zicstardust/spotify-client` con `rpm-ostree` y desinstala Spotify Flatpak sin
borrar los datos de usuario. El RPM aparece tras reiniciar. Abre Spotify una vez
e inicia sesión para generar `~/.config/spotify/prefs`; después ciérralo y ejecuta:

```bash
bash ~/dotfiles-dizzi/home/scripts/spicetify-native-apply.sh
```

En Bazzite `/usr/share/spotify/Apps` es **inmutable** incluso si el RPM le da
permisos `777`: `spicetify backup apply` sobre esa ruta termina en
`unlinkat /usr/share/spotify/Apps: read-only file system`. El helper copia el
cliente RPM a `~/.local/share/spotify-spicetify`, apunta allí `spotify_path`,
usa `~/.config/spotify/prefs`, aplica Spicetify e instala Marketplace. No
requiere `sudo`, `chmod` sobre `/usr` ni `rpm-ostree usroverlay`.

El `spotify.desktop` del repo llama a `spotify-spicetify-launch.sh`: al abrir
**Spotify** desde el menú de aplicaciones se usa la copia modificada y se
conservan los flags y variables del RPM. Si todavía no existe la copia, usa
`/usr/bin/spotify` (sin modificaciones). No abras el mod con el comando
`/usr/bin/spotify` directamente; este inicia el cliente original.

Tras una actualización del RPM, la copia antigua permanece intacta y el helper
se detiene si detecta otra versión; no sobrescribe tus cambios. Revisa la nueva
versión antes de reemplazar esa copia y volver a ejecutar el helper.

## Re stow (dotfiles)

**System →  Re stow** ejecuta en Kitty con `--hold`:

```bash
cd ~/dotfiles-dizzi && stow local --adopt
```

Reenlaza el paquete `local` del repo hacia `$HOME`; `--adopt` adopta los
archivos existentes antes de crear los symlinks. No usa `sudo`. Si `stow` no
está instalado, el menú avisa con `notify-send` en vez de abrir una terminal.

## JobCopilot Free (instalación selectiva)

El ítem **JobCopilot Free** (`󰅴`) agrupa los tres proyectos gratuitos de
búsqueda de empleo, pero **no instala todo de golpe**: abre un menú donde elegís
un componente y su fuente. Los componentes son independientes y se pueden
reinstalar o desinstalar por separado.

| Componente | Qué instala | Fuente | Requisitos |
|---|---|---|---|
| `swissdevjobs` | `sdj` / `swissdevjobs` + `swissdevjobs-mcp` (9 tableros, 8 países, salario) | GitHub `Stupidoodle/swissdevjobs-cli@v0.9.2` | `uv` |
| `career` | App Electron + FastAPI (10 tableros, scoring, Kanban, CV ATS) | GitHub `SyedmaazSaif/career-copilot` | Node >= 18, Python (uv baja 3.12) |
| `aijob` | Stack de 16 agentes (FastAPI + React + Postgres + Neo4j + Qdrant + Redis + Ollama) | **Google Drive `gd-musica`** | `docker compose` o `podman-compose` |

**Por qué la fuente cambia:** `swissdevjobs-cli` y `career-copilot` son
públicos y se bajan de GitHub. `ai-job-copilot` vive en el Drive personal
(`~/mi_gdmusica/JobCopilot-Free/CLIs/ai-job-copilot`, cuenta
`diegosamuel@gmail.com`) como proyecto propio; el script lo copia con `rsync`
al disco local antes de tocarlo, porque operar `git`/`npm` sobre el montaje
rclone es lentísimo. GitHub queda solo como respaldo si pedís
`--source internet`.

### Uso

```sh
jobcopilot-install                    # menú interactivo
jobcopilot-install --status           # qué está instalado, versiones, runtime
jobcopilot-install --list             # componentes y requisitos
jobcopilot-install --component swissdevjobs
jobcopilot-install --component career
jobcopilot-install --component aijob
jobcopilot-install --all              # los tres, en orden
jobcopilot-install --source drive     # forzar copia local del Drive
jobcopilot-install --dry-run          # imprimir comandos sin ejecutar
```

Desde el menú: **Instalar → JobCopilot Free**, o `Super+Z` y buscar
`jobcopilot`. El script corre en `kitty` para que se vean los prompts y el
progreso. Todo queda registrado en
`~/.local/state/jobcopilot/install.log`.

Destino por defecto: `~/JobCopilot-Free` (se puede cambiar con
`JOBCOPILOT_HOME`). `swissdevjobs-cli` es la excepción: `uv tool` lo instala
en su propio entorno y deja los binarios en `~/.local/bin`.

### 1. swissdevjobs-cli (CLI + MCP)

- Instala con `uv tool install --force git+…@v0.9.2`.
- Deja tres comandos: `sdj`, `swissdevjobs` y `swissdevjobs-mcp`.
- Ofrece registrar el MCP en **OpenCode global**. Si aceptás, ejecuta
  `opencode mcp add swissdevjobs --global -- swissdevjobs-mcp` y
  opcionalmente carga `SDJ_NAME`, `SDJ_EMAIL` y `SDJ_CV` para aplicar.
  Si OpenCode ya estaba abierto, ejecutá `/reload` (o reiniciá) para que
  aparezca en `/mcps`.
- El MCP expone `search_jobs`, `list_boards`, `get_job`, `apply_to_job`
  (con gate de confirmación), `list_applications`, `mark_applied` y
  `top_technologies`.
- Prueba rápida:
  `sdj list --tech Python --remote --min-salary 90000 --sort salary`.

### 2. Career Copilot (opcional)

- Clona el repo en `~/JobCopilot-Free/Apps/career-copilot`.
- `npm ci` (Electron + Vite) y venv del backend con Python 3.12 vía `uv`.
- Crea el lanzador `~/.local/bin/career-copilot` y la entrada
  `~/.local/share/applications/career-copilot.desktop`.
- Logs de la app: `~/.career-copilot/logs/app.log`.
- Sin Ollama funciona igual; el modelo local solo mejora parsing/redacción.

### 3. AI Job Copilot (stack completo)

- Copia el proyecto del Drive a `~/JobCopilot-Free/CLIs/ai-job-copilot`.
- Genera `JWT_SECRET`, `ENCRYPTION_KEY` y `POSTGRES_PASSWORD` si están vacíos
  en `.env`.
- Detecta `docker compose`, `podman-compose` o `podman compose`. Si no hay
  runtime, ofrece instalar `podman-compose` con `uv tool install`.
- Pregunta antes de construir (2–3 GB de imágenes) y antes de bajar
  `qwen2.5:14b` (~9 GB). El modelo es opcional si usás un LLM en la nube.
- Servicios: frontend `:3000`, API `:8000/docs`, Qdrant `:6333`, Neo4j `:7474`,
  Ollama `:11434`.
- Para levantarlo después:
  `cd ~/JobCopilot-Free/CLIs/ai-job-copilot && docker compose up -d --build`.

### Desinstalar

```sh
# 1
uv tool uninstall swissdevjobs-cli

# 2
rm -rf ~/JobCopilot-Free/Apps/career-copilot \
       ~/.local/bin/career-copilot \
       ~/.local/share/applications/career-copilot.desktop

# 3 (primero bajar el stack y sus volúmenes)
cd ~/JobCopilot-Free/CLIs/ai-job-copilot && docker compose down -v
rm -rf ~/JobCopilot-Free/CLIs/ai-job-copilot
```

Para quitar el MCP de OpenCode, borrá la entrada `swissdevjobs` de
`mcp.servers` en `~/.config/opencode/opencode.json` (o usá `/mcps`).

## Atajos
- `Super+Z` → abre el menú

---
## Créditos

**dizzi1222** — autor del System Control, del script `system_control.sh`, de la migración eww→rofi→wofi, y del fix de los guards que pegaban el CSS. Creado el 2026-09-19.

> Menú inspirado en el estilo Omarchy (grid con chevrons), sin 8 horas de Quickshell 😉
