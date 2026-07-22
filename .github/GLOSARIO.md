# GLOSARIO DEL SISTEMA DE DISEÑO — PTD-TALENTO

> Brandkit Cincinnatus — Referencia para desarrollo frontend.

---

## Colores principales (Regla 60-30-10)

| Porcentaje | Tipo | Colores |
|---|---|---|
| **60%** | Neutros | `#1A1A1A` (texto), `#666666` (secundario), `#999999` (muted), `#E6E6E6` (bordes), `#F7F7F7` (fondos suaves), `#FFFFFF` (fondos) |
| **30%** | Turquesa | `#00B3A7` — detalles, tabs activos, links, iconos, focus |
| **10%** | Lime | `#A3D848` — CTAs, botones principales, acciones clave |

## Variantes de marca

| Color | HEX | Uso |
|---|---|---|
| Hover turquesa | `#00857C` | Secondary hover |
| Turquesa oscuro | `#004F4A` | Secondary dark, texto sobre fondos claros |
| Dark green | `#6C9E00` | Hover del lime, success |
| Light green | `#D0ED58` | Highlights, badges |
| Aqua | `#A2EAC3` | Fondos suaves, empty states |

## Tipografía

| Fuente | Uso |
|---|---|
| **Inter** (sans-serif) | Fuente principal UI: títulos, body, botones, tablas, formularios |
| **Getboreg** | Solo títulos decorativos de marca (hero, encabezados principales) |
| **Volksans** | Textos institucionales, subtítulos (no usar en UI core) |

### Escala tipográfica

| Nivel | Tamaño | Peso |
|---|---|---|
| H1 | 32px | 700 |
| H2 | 24px | 600 |
| H3 | 20px | 600 |
| Body | 16px | 400 |
| Small | 14px | 400 |
| Caption | 12px | 400 |

## Componentes base (System UI Kit)

| Componente | Radio | Estilos |
|---|---|---|
| **Botones** | radius-md (8px) | primary=lime, secondary=outline turquesa |
| **Cards** | radius-lg (16px) | border suave `#E6E6E6`, shadow-1 o shadow-2 |
| **Inputs** | radius-md (8px) | border visible `#CCCCCC`, focus border `#00B3A7` |
| **Modales/Drawers** | radius-lg (16px) | elevation-4 |
| **Badges/Pills** | radius-full (999px) | usar colores semánticos |
| **Tabs** | — | active indicator `#00B3A7`, sin underline por defecto |

## Reglas visuales

- **Sentence case** en toda la interfaz ("Guardar cambios", NO "GUARDAR CAMBIOS")
- **Espaciado base:** 8px (múltiplos de 8 para layout, 4 para ajustes finos)
- **Sombras:** shadow-1 (cards), shadow-2 (dropdowns), shadow-4 (modales)
- **Iconos:** Lucide Icons, estilo outline, tamaños 16/20/24px
- **Grid:** 12 columnas desktop, 6-8 tablet, 1 columna mobile
- **Breakpoints:** mobile ≤768px, tablet 769-1024px, desktop >1024px

## Referencias

- Brand Kit-Cincinnatus.pdf
- Figma (System UI Kit): https://www.figma.com/design/xJf08uRY7A8G3lXt90dn5u/PTD-Talento-Marketplace
- PTD- UI/UX Estandar (Excel)
- CIC Styles
- design.md (local: `/home/diego/Escritorio/PTD-Talento Material Diego/design.md`)
- Frontend branch activa: `feat/m3-cat-ui-global`
