# ⚡ dhardi.dev

Portafolio personal con identidad visual completa — hero con slideshow, timeline de experiencia, grid de servicios, tech stack interactivo, galería de setup y más. Construido con **Astro 7 + React + TypeScript + Tailwind CSS v4**.

> **Live Demo:** [dhardi.dev](https://dhardi.dev)

---

## 🛠️ Stack

- **Frontend:** Astro 7, React 19, TypeScript, Tailwind CSS v4
- **Build:** Vite 8 (Astro), npm
- **Deploy:** Vercel (adapter-vercel, serverless functions)
- **i18n:** ES / EN / DE (data-i18n attributes + switchLanguage JS)
- **Animaciones:** CSS keyframes (fadeInUp, float, kenburns, stagger, modalIn) + Intersection Observer
- **Formulario:** Resend API para contacto

## 🚀 Características

- **Hero con slideshow** — 8 imágenes de fondo con ken burns, drag scroll, swipe táctil y teclado (flechas)
- **Vibe indicator** — título, icono y contador sincronizados por slide
- **Timeline de experiencia** — 3 entradas con timeline-dot y stagger-child animations
- **Grid de servicios** — 8 servicios (Full-Stack, Design Systems, Auth, Real-time, DB, Admin, API, DevOps)
- **Tech Stack interactivo** — 16 tecnologías con click popup y descripciones técnicas
- **Galería de setup** — System Control, Blueprints, Scripts, dotfiles
- **i18n completo** — Español, Inglés y Alemán con switch dinámico
- **Theme toggle** — Dark/Light con CSS variables y persistencia en localStorage
- **Modal system** — CV preview overlay con animación modalIn
- **Scroll reveal** — Animaciones fadeInUp con Intersection Observer
- **Scroll spy** — Navegación activa por sección
- **Mobile responsive** — Menú hamburguesa con animación, nav adaptativo
- **Formulario de contacto** — Resend API + validación

## 📂 Estructura del Proyecto

```
dhardi.dev/
├── src/
│   ├── layouts/
│   │   └── Layout.astro         # Layout global (data-theme, head, scripts)
│   ├── pages/
│   │   ├── index.astro          # Hero + todas las secciones + modales + i18n + JS cliente
│   │   └── ProyectDetail/
│   │       └── [id].astro       # Página detalle de proyecto (SSR)
│   ├── components/
│   │   ├── Header.astro         # Nav completo (theme, lang, mobile, badges)
│   │   ├── SectionExperience.astro  # Timeline experiencia
│   │   ├── SectionServicios.astro   # Grid servicios 2×4
│   │   ├── SectionTechStack.astro   # Tech icons con popup
│   │   ├── SectionSetup.astro       # Setup cards
│   │   ├── SectionProyects.astro    # Grid proyectos + featured
│   │   ├── Proyect.astro            # Card de proyecto
│   │   ├── BreadCrumb.astro         # Tech badge pill
│   │   ├── icons/                   # 31 iconos SVG inline
│   │   └── ui/                      # Animaciones (BlurFade)
│   ├── lib/
│   │   ├── projects.ts          # Datos de proyectos (7 entradas)
│   │   └── skills.ts            # Skills lookup (colores + iconos)
│   └── styles/
│       └── global.css           # Sistema temas + animaciones + utilidades
├── public/                      # Imágenes, favicon, CV
├── astro.config.mjs             # Vercel adapter + Tailwind plugin
└── package.json                 # Astro 7, React 19, Tailwind v4
```

## 🏃‍♂️ Desarrollo Local

```bash
npm install
npm run dev          # → http://localhost:4321
npm run build       # → dist/
npm run preview     # Vista previa de producción
```

## 🚢 Deploy

Conecta el repo a [Vercel](https://vercel.com) — el adapter ya está configurado en `astro.config.mjs`. Vercel detecta automáticamente Astro y corre `npm run build`.

## 📜 Licencia

MIT
