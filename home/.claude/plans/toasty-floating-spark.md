# Plan: Actualización de ambos portfolios

## Contexto

Diego tiene dos portfolios desplegados en Vercel que necesitan actualizaciones:
- **dhardi.dev** (Astro 7 + React + Tailwind v4) → `/home/diego/workspace/dhardi.dev`
- **Terminal Portfolio** (SvelteKit 2 + Svelte 5) → `/home/diego/workspace/portfolio-terminal-dhardi`

Ambos repos tienen cambios sin commitear. El objetivo es aplicar todas las mejoras pendientes, commitear y pushear.

---

## Fase 1: Fix interactivos rotos en dhardi.dev

> Los toggles y nav links ya funcionan según la exploración. El problema reportado puede haber sido resuelto en commits previos. **Verificar en dev server antes de tocar.**

### 1.1 Verificar que theme toggle, i18n toggle y nav links funcionan
- Archivo: `src/pages/index.astro` (funciones `switchTheme`, `switchLanguage`)
- Archivo: `src/components/Header.astro` (onclick handlers)
- Si hay bug: asegurar que los `<script>` en Astro son estándar (no `client:load`)

### 1.2 Eliminar `ButtonToggleTheme.jsx` (componente muerto)
- Archivo: `src/components/ButtonToggleTheme.jsx` — borrar
- Verificar que no se importa en ningún lado

### 1.3 Eliminar "Sobre mi" del nav
- Archivo: `src/components/Header.astro` — quitar link `#about` del nav desktop y mobile

---

## Fase 2: Nav dinámico + Certificaciones en nav (dhardi.dev)

### 2.1 Agregar "Certificaciones" al nav
- Archivo: `src/components/Header.astro` — agregar `#certifications` al nav

### 2.2 Nav dinámico estilo Sergio (hover dots tooltip)
- Inspirado en el portfolio de referencia de Sergio
- Dots background con hover tooltip en el nav
- Implementar en `Header.astro` + `global.css`

---

## Fase 3: Certificaciones hover-expand + CV modal + AboutMe i18n (dhardi.dev)

### 3.1 Certificaciones: consolidar bajo "CIC Associate Developer"
- Archivo: `src/components/SectionCertification.astro`
- Agrupar certs CIC bajo un heading "CIC Associate Developer"
- Hover expand por fila (click/hover muestra detalles)

### 3.2 CV Modal: placeholder → preview real
- Archivo: `src/pages/index.astro` — modal CV
- Cambiar placeholder por preview real del PDF (`/cv.pdf`)

### 3.3 AboutMe i18n
- Verificar que sección About usa `data-i18n` correctamente
- Si hay texto hardcodeado en ES, conectar al sistema i18n

---

## Fase 4: Material UI, VoltBuilder, badges, links (dhardi.dev)

### 4.1 Material UI tech skill + icono SVG
- Crear `src/components/icons/IconMaterialUI.astro` con SVG oficial
- Agregar a `src/lib/skills.ts` con descripción i18n (ES/EN/DE, color #007fff)
- Agregar a `SectionTechStack.astro`

### 4.2 VoltBuilder a SectionTechStack grid
- Ya existe `IconVoltBuilder.astro` (untracked) — asegurar export en `icons/index.ts`
- Agregar a skills y al grid

### 4.3 Colores badges en Projects
- Archivo: `src/components/Proyect.astro` — dar colores distintivos a cada tech badge

### 4.4 i18n descriptions techs faltantes
- Revisar que todas las techs en skills.ts tengan descripción en ES/EN/DE

---

## Fase 5: Detalle proyecto modal + Servicios rediseño (dhardi.dev)

### 5.1 Detalle proyecto: transición modal maximizado
- Estilo reactivo tipo Sergio (sin navegar a otra página)
- Modal que se expande desde la card del proyecto
- Archivo: `src/components/Proyect.astro` + `index.astro`

### 5.2 Servicios: animaciones/conceptos abstractos (estilo Eric)
- Archivo: `src/components/SectionServicios.astro`
- Rediseñar con animaciones más dinámicas

---

## Fase 6: 404, canonical, cleanup (dhardi.dev)

### 6.1 404 page
- Crear `src/pages/404.astro` con diseño coherente

### 6.2 Canonical URL + scroll-to-top
- Layout.astro: agregar `<link rel="canonical">`
- Agregar botón scroll-to-top flotante

### 6.3 README: npm → pnpm
- Actualizar README.md

---

## Fase 7: Terminal Portfolio (8 cambios)

### 7.1 Eliminar Canvas de TechStack grid (solo en Design)
- Archivo: `src/lib/components/TechStack.svelte` — mover Canvas solo a Design
- Archivo: `src/lib/components/Design.svelte` — verificar que Canvas está ahí

### 7.2 Agregar Material UI como tech skill
- Archivo: `src/lib/components/TechStack.svelte` — agregar SVG path + color #007fff
- Archivo: `src/lib/i18n/index.ts` — agregar descripciones ES/EN/DE

### 7.3 Fix "Versión Comercial" link
- Archivo: `src/lib/components/Footer.svelte` línea ~28
- Cambiar `github.io` → `dhardidev.vercel.app`

### 7.4 Material UI badge SVG en proyectos
- Archivo: `src/lib/data/projects.ts` — agregar "Material UI" a tags de PTD-Talento (si no está ya)
- Verificar que el badge se renderiza con color correcto

### 7.5 Hover "View Code" = estilo "Live Preview"
- Archivo: `src/app.css` o componente Projects — unificar hover de ambos botones

### 7.6 README: npm → pnpm

### 7.7 Dotfiles: enlace a dotfiles-wsl-dizzi + hover bonito
- Archivo: `src/lib/data/projects.ts` — actualizar URL dotfiles
- Agregar hover con tooltip descriptivo

### 7.8 Nvim: enlace a branch termux + hover bonito
- Archivo: `src/lib/data/projects.ts` — agregar link a branch termux
- Hover con tooltip

---

## Fase 8: Push y sesión

### 8.1 Commit y push dhardi.dev
```bash
cd ~/workspace/dhardi.dev
git add -A && git commit -m "feat: ..." && git push
```

### 8.2 Commit y push terminal portfolio
```bash
cd ~/workspace/portfolio-terminal-dhardi
git add -A && git commit -m "feat: ..." && git push
```

### 8.3 Guardar sesión con engram
```bash
engram save "Portfolio Updates Session" "Resumen de cambios..." --type lesson --project portfolio
```

---

## Archivos clave a modificar

### dhardi.dev
| Archivo | Cambios |
|---------|---------|
| `src/components/Header.astro` | Quitar #about, agregar #certifications, nav dots |
| `src/components/ButtonToggleTheme.jsx` | ELIMINAR |
| `src/components/SectionCertification.astro` | Consolidar CIC, hover-expand |
| `src/components/SectionTechStack.astro` | Material UI, VoltBuilder |
| `src/components/SectionServicios.astro` | Rediseño animado |
| `src/components/Proyect.astro` | Badges color, modal expand |
| `src/components/icons/IconMaterialUI.astro` | CREAR |
| `src/lib/skills.ts` | Material UI, VoltBuilder entries |
| `src/pages/index.astro` | CV modal real, project modal, i18n fixes |
| `src/pages/404.astro` | CREAR |
| `src/styles/global.css` | Nav dots, scroll-to-top, animaciones |
| `src/layouts/Layout.astro` | Canonical URL |

### Terminal Portfolio
| Archivo | Cambios |
|---------|---------|
| `src/lib/components/TechStack.svelte` | -Canvas, +Material UI |
| `src/lib/components/Footer.svelte` | Fix link comercial |
| `src/lib/components/Projects.svelte` | View Code hover |
| `src/lib/data/projects.ts` | Dotfiles URL, Nvim termux, badges |
| `src/lib/i18n/index.ts` | Material UI descriptions |
| `src/app.css` | Unificar hover botones |
| `README.md` | npm → pnpm |

---

## Verificación

1. `cd ~/workspace/dhardi.dev && pnpm dev` → verificar en localhost:4321
   - Theme toggle funciona (dark/light)
   - i18n toggle funciona (ES/EN/DE)
   - Nav links navegan correctamente
   - Certificaciones visible desde nav
   - Modal CV muestra preview real
   - Badges de proyectos con colores
2. `cd ~/workspace/portfolio-terminal-dhardi && pnpm dev` → verificar en localhost:5173
   - Canvas NO está en TechStack (sí en Design)
   - Material UI aparece en TechStack
   - "Versión Comercial" apunta a dhardidev.vercel.app
   - View Code hover = Live Preview hover
3. Push a ambos repos → Vercel autodeploy
