# Wofi System Control

Menú de control del sistema (reemplaza al viejo eww/rofi) hecho con **wofi**.

## Qué hace
- **Categorías** (grid 3 col): Apps, Trigger, Style, Setup, System, Audio, Herramientas, About, Android, Multimedia, Instalar, Sistema + **"Todos"** (búsqueda recursiva en los 61 ítems).
- **Items** (grid 2 col): cada acción con icono, nombre y chevron ` ` a la derecha.
- **Búsqueda recursiva**: escribe `nixconf cleanup` y encuentra **Nix Cleanup** (keywords ocultas vía pango markup).
- **Navegación**: Tab/Enter/flchas. wofi en grid navega por filas/columnas (el `↓` a veces va a la derecha el primer paso — comportamiento nativo del FlowBox de GTK).

## Archivos
| Archivo | Rol |
|---|---|
| `home/scripts/system_control.sh` | Script principal: drill-down 2 pasos + case de 61 acciones |
| `wofi/.config/wofi/system-control.conf` | Config dedicada (grid, matching fuzzy, allow_markup, centrado) |
| `wofi/.config/wofi/system-control.css` | GTK CSS con paleta wal (hover/selected, Nerd Font) |
| `eww/.config/eww/scripts/system-menu-manifest.tsv` | Fuente única: categoría / icono / label (61 ítems) |
| `eww/.config/eww/scripts/system-menu-kw.tsv` | Keywords por icono para búsqueda recursiva |

## Añadir un ítem
1. Edita `system-menu-manifest.tsv` → nueva línea `Categoría<TAB>icono<TAB>Label`
2. Si querés keywords de búsqueda, agrégalas en `system-menu-kw.tsv`
3. Crea el handler en `system_control.sh` (bloque `case "$ICON"`)

## Atajos
- `Super+Z` → abre el menú

---
## Créditos

**dizzi1222** — autor del System Control, del script `system_control.sh`, de la migración eww→rofi→wofi, y del fix de los guards que pegaban el CSS. Creado el 2026-09-19.

> Menú inspirado en el estilo Omarchy (grid con chevrons), sin 8 horas de Quickshell 😉