# Plan: Portfolio Fixes — dhardi.dev + portfolio-terminal-dhardi

## Status: PLANNING

---

## Phase 1 — CRITICAL BUG: main.js (dhardi.dev)

**Problem:** `index.astro` has a `<script>` block (module-scoped) with all interactive functions. `Header.astro` calls them via `onclick="switchTheme(...)"` etc. Module scripts don't expose to `window`, so onclick fails.

**Fix:**
1. Create `/home/diego/workspace/dhardi.dev/public/scripts/main.js` — copy ALL code from `index.astro` `<script>` (lines 191-586), wrap key functions with `window.xxx = function...` exposures.
2. In `Layout.astro`, add `<script src="/scripts/main.js"></script>` (NOT type=module) before `</body>`.
3. In `index.astro`, remove the `<script>` block entirely (or replace with empty shell — the init will run from main.js).

**Functions to expose on window:**
- window.switchTheme
- window.switchLanguage
- window.toggleLangDropdown
- window.closeLangDropdown
- window.openCVModal
- window.closeModal
- window.openCertModal
- window.closeCertModal
- window.toggleMobileNav
- window.closeMobileNav
- window.nextSlide
- window.prevSlide

The initialization code at the bottom (init IIFE calling switchLanguage + switchTheme) must remain and run when the script loads.

---

## Phase 2 — dhardi.dev Changes

### 2a. Nav bar changes (Header.astro)
- Remove `<a href="#about">` link (desktop nav, lines 15 + 52 in mobile nav)
- Add `<a href="#certifications" data-i18n="nav.certifications">Certificaciones</a>` in both desktop and mobile nav

### 2b. i18n updates (main.js — the new public/scripts/main.js)
Add `nav.certifications` key in all 3 langs, remove `nav.about`:
- ES: `certifications: 'Certificaciones'`
- EN: `certifications: 'Certifications'`
- DE: `certifications: 'Zertifikate'`
(Also update in index.astro if needed for initial render — but Header.astro uses data-i18n so it'll be set by JS)

### 2c. SectionCertification.astro — Redesign
Current: flat list of all certs individually.
New design:
- One main expandable card: "CIC Associate Developer" (44% progress) — on hover shows collapsed programs
- Sub-items on expand: Desarrollo de Software v4 ✓, Inteligencia Artificial v1 ✓, Fundamentos Pensamiento Crítico v4 ✓, Mi primer empleo en Tech ✓, Curso de IA para Todos ✓
- Separate standalone cards: JSCAMP (20%), Mimo (15%), Exercism+TryHackMe (10%)
- Remove "Educación" section (duplicates CIC)
- Use CSS details/summary or hover/group approach for expansion

### 2d. Project badges colors (Proyect.astro — need to read first)
Check how Proyect.astro renders tech badges. Add color per technology using inline styles matching tagColors from terminal portfolio.

### 2e. README npm → pnpm
In `/home/diego/workspace/dhardi.dev/README.md`:
- `npm install` → `pnpm install`
- `npm run dev` → `pnpm dev`
- `npm run build` → `pnpm build`

### 2f. Material UI icon + skill
- Create `src/components/icons/IconMaterialUI.astro` with provided SVG path
- Add to `src/components/icons/index.ts`
- Add to `src/lib/skills.ts`

### 2g. VoltBuilder in SectionTechStack.astro
Add VoltBuilder div after Canvas div in the tech grid.

### 2h. i18n tech descriptions for new techs
In main.js (the new public file), add to the `tech` object in all 3 langs:
Svelte, Astro, Canvas, Railway, VoltBuilder, HTML, CSS, Bootstrap, Figma, Material UI

### 2i. Dotfiles project (projects.ts) — add liveAlt
Add field `liveAlt?: string` to interface and entry id=3:
`liveAlt: 'https://github.com/dizzi1222/dotfiles-wsl-dizzi'`
Also update descriptionLarge to mention termux branch.

### 2j. Nvim project (projects.ts)
Update descriptionLarge to mention termux branch at https://github.com/dizzi1222/nvim/tree/termux

### 2k. AboutMe.astro — i18n attributes
Current: hardcoded Spanish. Add data-i18n attributes matching existing i18n keys.
The about section exists in i18n but AboutMe.astro has no data-i18n attributes.

---

## Phase 3 — portfolio-terminal-dhardi Changes

### 3a. Remove Canvas from TechStack.svelte
Delete the `{ name: 'Canvas', ... }` entry from the `techs` array.

### 3b. Add Material UI to TechStack.svelte
Add after VoltBuilder entry: `{ name: 'Material UI', svg: 'M7.525 1.5L.6 5.4v10.8l6.9 3.9 6.9-3.9V5.4l-6.9-3.9zm0 2.4l4.5 2.55v2.88l-4.05-2.28V6.56l-3.15 1.8V8.4l3.95 2.25-.82.46-3.13-1.77v2.06l3.95 2.2 4.2-2.37V12.6l-4.2 2.37-4.2-2.37v2.06l4.2 2.37 4.2-2.37v-3l-1.05-.6v1.77l-3.15 1.8-3.16-1.8V9.83l3.16 1.8.34-.2h.02l.69-.39V7.42l-4.5-2.52z' }`

Add i18n descriptions in `src/lib/i18n/index.ts` for 'Material UI' in all 3 langs.

### 3c. Fix Footer.svelte commercial link
Change `https://dizzi1222.github.io/dhardi.dev` → `https://dhardidev.vercel.app`

### 3d. Projects.svelte "View Code" button style
Looking at the code: the "View Code" button (`a href={p.code}`) uses class `btn` style `flex:1;text-align:center`. The "Live Preview" button has class `btn detail-action-btn btn--live` with background accent color.
Make "View Code" button more consistent — add hover glow similar to live preview but with a different accent (e.g. cyan border). The btn already has base styles, just needs to stand out more via a modifier class `btn--code`.

### 3e. Dotfiles project (projects.ts) — WSL link in descriptionLarge
Update detailDesc for id=2 (Dotfiles Config) to mention WSL version at https://github.com/dizzi1222/dotfiles-wsl-dizzi.

### 3f. Nvim project (projects.ts) — termux link in descriptionLarge
Update detailDesc for id=4 (Nvim · WSL + Linux) to mention termux branch at https://github.com/dizzi1222/nvim/tree/termux.

---

## Phase 4 — Commit & Push Both Repos

1. `cd /home/diego/workspace/dhardi.dev && git add ... && git commit ...`
2. `cd /home/diego/workspace/portfolio-terminal-dhardi && git add ... && git commit ...`

---

## Files to read before editing (not yet read)
- `/home/diego/workspace/dhardi.dev/src/components/Proyect.astro` — for badge rendering

## Files to create/edit
### dhardi.dev:
- `public/scripts/main.js` (CREATE)
- `src/layouts/Layout.astro` (EDIT — add script tag)
- `src/pages/index.astro` (EDIT — remove script block)
- `src/components/Header.astro` (EDIT — nav links)
- `src/components/SectionCertification.astro` (EDIT — redesign)
- `src/components/SectionTechStack.astro` (EDIT — add VoltBuilder)
- `src/components/icons/IconMaterialUI.astro` (CREATE)
- `src/components/icons/index.ts` (EDIT — add Material UI)
- `src/lib/skills.ts` (EDIT — add Material UI)
- `src/lib/projects.ts` (EDIT — add liveAlt + descriptions)
- `src/components/AboutMe.astro` (EDIT — add data-i18n)
- `README.md` (EDIT — npm → pnpm)

### portfolio-terminal-dhardi:
- `src/lib/components/TechStack.svelte` (EDIT — remove Canvas, add Material UI)
- `src/lib/components/Footer.svelte` (EDIT — fix link)
- `src/lib/components/Projects.svelte` (EDIT — View Code button style)
- `src/lib/i18n/index.ts` (EDIT — add Material UI descriptions)
- `src/lib/data/projects.ts` (EDIT — Dotfiles + Nvim descriptions)
