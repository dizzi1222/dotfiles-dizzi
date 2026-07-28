# Proyecto: My TypeScript Library

1. "Eres un asistente útil y conciso. Generas un Plan si la demanda es grande solamente."
2. Habla en español

## Instrucciones Generales

- Cuando generes nuevo código TypeScript, sigue el estilo de codificación existente.
- Asegúrate de que todas las funciones y clases nuevas tengan comentarios JSDoc.
- Prefiere paradigmas de programación funcional cuando sea apropiado.

## Estilo de Codificaciónkkk

- Usa 2 espacios para la indentación.
- Prefija los nombres de interfaz con `I` (por ejemplo, `IUserService`).
- Siempre usa igualdad estricta (`===` y `!==`).

## Comentarios Seccionales (Section Headers)

Usar comentarios tipo `//SectionTitle` para dividir archivos largos en bloques lógicos.

### Reglas

| Regla          | Descripción                                                     |
| -------------- | --------------------------------------------------------------- |
| **Formato**    | `//SectionTitle` — sin punto final, mayúscula inicial           |
| **Frecuencia** | Máximo 1 comentario cada ~50 líneas                             |
| **Necesidad**  | Solo donde aporte claridad, nunca en obviedades                 |
| **Referencia** | Estilo `app.ts`: `//Settings`, `//session Settings`, `//routes` |

### Archivos que NO necesitan

Scripts, migraciones, archivos < 40 líneas autoexplicativos, configs.

## Conexión a Base de Datos Local (pgAdmin4)

### Prerrequisitos

1. GCloud CLI instalado y autenticado: `gcloud auth application-default login`
2. Cloud SQL Proxy descargado en `~/cloud-sql-proxy`

### Pasos para conectar

1. **Iniciar el proxy** (mantener corriendo en una terminal):

   ```sh
   ~/cloud-sql-proxy --port 5433 cic-ptd-dev:us-east1:cic-ptd-dev
   ```

   Esperar a que muestre: `The proxy has started successfully and is ready for new connections!`

2. **Configurar pgAdmin4** con estos valores exactos:
   - Host: `127.0.0.1` (NUNCA el nombre de la BD)
   - Port: `5433` (el del proxy, no el del .env)
   - Database: `talento-dev`
   - Username: `talento-dev`
   - Password: **Ver en 1Password / Vault del equipo**

3. **Errores comunes:**
   - "failed to resolve host 'talento-dev'" → se puso `talento-dev` como Host en vez de `127.0.0.1`
   - "Connection refused on port 5432" → se usó el puerto 5432 del .env en vez del 5433 del proxy
   - "Connection refused" en general → el proxy no está corriendo

## Daily Format (ChatSpace)

Siempre dar ambas versiones: español (para que Diego lea) e inglés (para enviar a ChatSpace).

> Para referencia detallada ver: `/home/diego/dotfiles-dizzi/.github/google-chatspace-format.md`

Estructura fija:

```
*Team:* PTD-Talento
*Member:* Diego Samuel Hardi Santana, Software Development
*Date:* [fecha]

*What I have done since the last DR:*

• [bullet points con *negritas* en palabras clave]

*What I will do until the next DR:*

• [bullet points]

*Impediments:*

• [None / descripción]
```

Reglas:

- Usar `*texto*` para negritas (formato ChatSpace)
- bullets con `•`
- Fecha en inglés: "June 5, 2026"
- Separar secciones con línea en blanco
- En español: misma estructura pero títulos traducidos y descripción en español
- **Siempre enlazar tickets mencionados** con su URL completa de GitHub, ej: <https://github.com/Cincinnatus-Institute-of-Craftsmanship/ptd-talento-back/issues/94>
- Si mencionas un _épica tracker_, lista sus features entre paréntesis, ej: _ÉPICA 03 Tracker_ (#92) con Features (US-03-01, US-03-02, US-03-03)

### Plantilla Issue: Daily Report

Ubicaciones:

- **Backend:** `/home/diego/workspace/ptd-talento-back/.github/ISSUE_TEMPLATE/4-dailly-report.md`
- **Dotfiles:** `/home/diego/dotfiles-dizzi/.github/ISSUE_TEMPLATE/4-dailly-report.md`
- Formato ESP/ENG integrado
- Labels: `daily`, `diego`
- Usar para crear issue diario de avances

### Plantilla Issue: Investigación (INV)

Ubicaciones:

- **Dotfiles:** `/home/diego/dotfiles-dizzi/.github/ISSUE_TEMPLATE/5-investigacion.md`
- Labels: `investigation`
- Usar para analizar comportamientos extraños, inconsistencias o bugs no confirmados
- Incluir: módulo afectado, comportamiento observado, hipótesis, pasos para reproducir, evidencias

### Plantilla Issue: Investigación Técnica (SPIKE)

Ubicaciones:

- **Dotfiles:** `/home/diego/dotfiles-dizzi/.github/ISSUE_TEMPLATE/6-spike.md`
- Labels: `spike`
- Usar para aprendizaje técnico, exploración de enfoques y POCs antes de implementar
- Incluir: objetivo, preguntas a resolver, actividades, entregables, recomendación final

### Plantilla Issue: Comentarios Seccionales

Ubicaciones:

- **Dotfiles:** `/home/diego/dotfiles-dizzi/.github/ISSUE_TEMPLATE/7-comentarios-seccionales.md`
- Labels: `documentation`
- Usar para estandarizar `//SectionTitle` en archivos que necesiten orientación de lectura
- Incluir: archivos afectados, reglas de formato, checklist de validación

## PR Template (QA Format)

Usar esta plantilla en el body de todos los PRs:

```markdown
## QA Testing Information

### Código y Ramas afectadas

⚠️ Nota: Dependiendo del alcance del ticket, es posible que este Pull Request solo incluya una de las siguientes ramas (no es obligatorio que estén ambas).

- **Rama Backend:**
- **Rama Frontend:**

### Objetivo del cambio

¿Qué problema resuelve o añade este PR?

### Flujo funcional afectado

Describir brevemente qué flujo del sistema cambia.
Ejemplo:

- Registro de asistencia
- Login con Google
- Salida de laptops
- Gestión de campus

### Comportamiento esperado

¿Qué debe ocurrir después del cambio?

### Casos importantes a validar

- **Caso exitoso:**
- **Caso de error:**
- **Caso límite (si aplica):**

### Funcionalidades relacionadas

¿Qué otras áreas podrían verse impactadas por este cambio?

### Evidencia sugerida para validación

¿Cómo confirmar que el cambio funciona correctamente?
Ejemplo:

- Respuesta esperada de API
- Registro en base de datos
- Cambio visible en interfaz
- Log esperado
- Estado esperado en sistema externo

### Ambiente o configuración requerida

Indicar cualquier requisito necesario para ejecutar y validar el cambio. Es fundamental puntualizar detalladamente las siguientes secciones para que QA pueda levantar el entorno y ejecutar las pruebas sin fricciones:

- **URL Base / Puerto:** (Indicar en qué puerto corre localmente o la URL del ambiente de pruebas)
- **Pasos previos para preparar el escenario de prueba (si aplica):** (Comandos como npm install, correr migraciones, etc.)
- **Variables de entorno requeridas**
- **Tokens o credenciales necesarias**
- **Usuario(s) de prueba y sus permisos o roles**
- **Datos de prueba específicos**
- **Servicios externos necesarios**
- **Configuración especial del ambiente (si aplica)**

### Observaciones adicionales

Revisar los comentarios de Gemini Code Assist (o la herramienta de code review utilizada) durante la preparación del PR y antes de solicitar validación de QA. Los hallazgos del code review pueden ayudar a identificar validaciones faltantes, escenarios de error, riesgos potenciales, cambios de comportamiento o información adicional que debería incluirse en la descripción del PR para facilitar un proceso de pruebas más claro y reducir el intercambio de preguntas entre Desarrollo y QA.
```

## PR Conclusion Template (QA Update)

Usar esta plantilla cuando se actualiza un PR ya existente:

```markdown
🔄 **PR Update / Commit Information for QA** 🛠️

### ¿Qué cambió en esta actualización?

(Describe de forma breve y directa qué cambios o correcciones introduce este nuevo commit)

### ⚠ ¿Afecta al "QA Testing Information" principal?

(Marca con una X la opción que aplique)

- [ ] **NO.** El objetivo del cambio, los pre-requisitos, las variables y los casos de prueba siguen siendo exactamente los mismos que se describieron en el mensaje principal del PR.
- [ ] **SÍ.** Esta actualización modifica o añade elementos a la estrategia de pruebas original. (Especifica los cambios abajo):

**Nuevo flujo/caso afectado:**
**Nueva variable/configuración requerida:**
**Cambio en el comportamiento esperado:**

### 🎯 Foco de Re-testing (Sugerencia para QA)

(¿Qué debería priorizar QA al revisar este nuevo commit? Ej: "Enfocarse solo en validar el flujo de error 401 que antes fallaba" o "Volver a correr el flujo completo")

### 📝 Notas adicionales / Evidencia (Opcional)

(Cualquier dato extra, logs, capturas de pantalla o comentarios que el desarrollador considere útiles para QA)
```

## Estándar de Nomenclatura de Ramas (PTD-Talento)

Formato oficial: `tipo-rama/sigla-modulo-[codigo-us]-funcionalidad`

### Siglas de Módulos

| Sigla    | Módulo                               |
| -------- | ------------------------------------ |
| `m1-aut` | Autenticación y Control de Acceso    |
| `m2-per` | Perfil de Talento (Estudiante)       |
| `m3-cat` | Catálogo y Búsqueda de Talentos      |
| `m4-lis` | Lista de Candidatos (Watch List)     |
| `m5-sol` | Solicitudes                          |
| `m6-not` | Notificaciones                       |
| `m7-adm` | Administración y Gestión de Usuarios |
| `m8-aud` | Historial de Acciones (Auditoría)    |

### Ejemplos para Épica 03 (Catálogo)

- Rama integración: `feat/m3-cat-hub` (renombrada desde `e3-hub`)
- US-03-01: `feat/m3-cat-us0301-ver-talentos`
- US-03-02: `feat/m3-cat-us0302-buscar-nombre`
- US-03-03: `feat/m3-cat-us0303-filtrar-path`
- US-03-04: `feat/m3-cat-us0304-filtrar-campus`
- US-03-05: `feat/m3-cat-us0305-ver-detalle`
- Hotfix: `hotfix/m3-cat-fix-descripcion`

Regla: minúsculas estrictas, prefijo `feat/` o `hotfix/`, sigla módulo de 5 chars, código US con 4 dígitos si aplica.

## Modus Operandi — PTD-Talento

Separación de responsabilidades en ramas:

| Rama                               | Contenido                                                                        | Base              | Merge a                   |
| ---------------------------------- | -------------------------------------------------------------------------------- | ----------------- | ------------------------- |
| `feat/m3-cat-hub` (frontend)       | Marketplace: cards, filtros, catálogo, búsqueda                                  | `dev`             | `dev`                     |
| `feat/m3-cat-ui-global` (frontend) | Componentes globales: NavBar, SideBar, Layout, modals, theme.ts, animations, UIX | `feat/m3-cat-hub` | `feat/m3-cat-hub` → `dev` |

> **UI** = componentes visuales (botón, navbar, card, modal).  
> **UIX** = interacción + experiencia (micro-animaciones, skeletons, loading/error/empty states, transiciones).

Flujo: `feat/m3-cat-ui-global` → merge a → `feat/m3-cat-hub` → PR a `dev` con formato QA.

## Reglas de Commit

- Commits descriptivos con bullet points detallando cada cambio
- Usar formato: `fix:|feat:|chore:` según corresponda
- Incluir métricas cuando aplique (espacio liberado, tiempo, etc.)
- Máximo 325 commits en el repo

## NixOS Config (thinkpad-x1e2)

### Flake structure
```
dotfiles-dizzi/nixconf/
├── flake.nix              # Entry point: nixos + home-manager outputs
├── nixos/
│   ├── base-configuration.nix  # system-level: pkgs, services, users, boot, sddm
│   └── pkgs/                    # custom package derivations
│       └── sddm-astronaut-theme/default.nix
└── home-manager/
    ├── home.nix                 # home-manager: symlinks, activation scripts
    └── features/
        ├── shell.nix            # zsh, starship, eza, bat, git, bottom, etc.
        ├── work.nix             # dev tools: code-cursor, pgadmin4, gcloud, docker
        ├── desktop.nix          # theming: GTK, Qt, cursors, icons
        └── programs.nix         # misc programs
```

### Rebuild commands
```bash
# Full rebuild (nixos + home-manager)
sudo nixos-rebuild switch --flake ~/dotfiles-dizzi/nixconf#thinkpad-x1e2
sudo -u $USER home-manager switch --flake ~/dotfiles-dizzi/nixconf#$USER@thinkpad-x1e2 -b backup

# Or use the wrapper script
~/.local/bin/nixconf-rebuild
```

### Key packages installed
| Package | Location | Notes |
|---|---|---|
| `code-cursor` | work.nix | AI editor, reemplazó vscodium |
| `pgadmin4` | work.nix | PostgreSQL GUI |
| `google-cloud-sql-proxy` | work.nix | GCP SQL proxy — binario: `cloud-sql-proxy` |
| `docker-client` | work.nix | Docker CLI |
| `gnome-disk-utility` + `udisks2` | base-configuration | USB Disk Manager |
| `lazydocker` | shell.nix | Docker TUI |
| `sddm-astronaut` | base-configuration | SDDM theme |
| `xorg.xinput` | base-configuration | needed for ydotool virtual device |

### Git safe.directory (NixOS fix)
```nix
# shell.nix — formato correcto para git config multi-value
"safe" = { directory = "/home/diego/dotfiles-dizzi"; };
```

### ydotool (autoclicker/autopress)
- Service: `~/wrapper/autoclicker-menu` → `~/.local/bin/autoclicker menu`
- Service: `~/wrapper/autopress-menu` → `~/.local/bin/autopress`
- Keybinds: F7 (autoclicker), F9 (autopress) in hypr/bindings.conf
- Socket: `/tmp/.ydotool_socket` (needs `xorg.xinput` + `ydotool.service` running)
- Service: systemctl --user ydotool.service (auto-started by wrapper)

### system_control.sh (rofi menu)
Path: `~/scripts/system_control.sh` (symlinked from `home/scripts/`)
- `󰮮` → `~/.local/bin/clean-boot`
- `` → `~/.local/bin/nixconf-rebuild`
- `🦙` → ollama list
- `󰳾` → autoclicker (via wrapper)
- `󰌌 󱊮` → autopress (via wrapper)
- `` → ydotool service check
- `` → Docker Desktop flatpak / lazydocker

## Referencias dotfiles-dizzi

### Plantillas GitHub (dotfiles-dizzi)

- **PULL_REQUEST_TEMPLATE.md**: `/home/diego/dotfiles-dizzi/.github/PULL_REQUEST_TEMPLATE.md` — Plantilla QA unificada para PRs (formato unificado front/back)
- **PR_CONCLUSION.md**: `/home/diego/dotfiles-dizzi/.github/PR_CONCLUSION.md` — Template para actualizaciones de PR (update brief, foco re-testing, notas)
- **DMR-TEMPLATE.md**: `/home/diego/dotfiles-dizzi/.github/DMR-TEMPLATE.md` — Developer Merge Report: para developers externos que revisan y mergean PRs ajenos (análisis estructural, refactor, code review, post-merge checks)
- **GOOGLE-CHATSPACE-FORMAT.md**: `/home/diego/dotfiles-dizzi/.github/google-chatspace-format.md` — Formato concreto de Google ChatSpace: negritas, bullets, títulos, códigos, enlaces
- **ISSUE_TEMPLATE/**: `/home/diego/dotfiles-dizzi/.github/ISSUE_TEMPLATE/` — Plantillas de issues:
  - `1-epic.md` — Épicas
  - `2-feature.md` — Features
  - `3-bug.md` — Bugs
  - `4-dailly-report.md` — Daily Report (ESP/ENG integrado)
  - `5-investigacion.md` — Investigación (INV): comportamiento inusual, inconsistencias, bugs no confirmados
  - `6-spike.md` — Investigación Técnica (SPIKE): aprendizaje, exploración de enfoques, POCs
  - `7-comentarios-seccionales.md` — Comentarios Seccionales: estandarizar //SectionTitle en archivos
  - `8-refactor-metodologia.md` — Refactorización: tomar código de otros devs, corregirlo y mergearlo a dev cuando sea requerido para modulos especificos.
  - `Estándar de Nombramiento de Ramas en GitHub (PTD-Talento).docx` — Documento con nomenclatura oficial de ramas (tipo-rama/sigla-modulo-[codigo-us]-funcionalidad)

### Sistema de Diseño PTD-Talento

- **GLOSARIO.md**: `/home/diego/dotfiles-dizzi/.github/GLOSARIO.md` — Brandkit Cincinnatus: colores 60-30-10, tipografía, componentes base, reglas visuales
- **design.md**: `/home/diego/Escritorio/PTD-Talento Material Diego/design.md` — Guía completa de diseño (2,912 líneas): paleta, contraste, tipografía, espaciado, grid, componentes, tokens, estados, navegación, accesibilidad
- **Brandkit.md**: `/home/diego/Escritorio/PTD-Talento Material Diego/Brandkit.md` — Brand Guidelines Cincinnatus (logo, colores, uso)
- **PLAN-UI-UX-MARKETPLACE.md**: `/home/diego/Escritorio/PTD-Talento Material Diego/PLAN-UI-UX-MARKETPLACE.md` — Plan de componentes globales UI/UIX + Marketplace
- **theme.ts (Yordi)**: `/home/diego/Escritorio/PTD-Talento Material Diego/theme.ts/theme.ts` — Theme MUI oficial con paleta extendida, tipografía, breakpoints
- **Fuentes**: `/home/diego/Escritorio/PTD-Talento Material Diego/theme.ts/fonts/` — Getboreg + Volksans (7 archivos .woff2)
- **Figma**: https://www.figma.com/design/xJf08uRY7A8G3lXt90dn5u/PTD-Talento-Marketplace

### Rutas absolutas de referencia

- Dotfiles principal: `/home/diego/dotfiles-dizzi/`
- GitHub templates: `/home/diego/dotfiles-dizzi/.github/`
- CLAUDE.md dotfiles: `/home/diego/dotfiles-dizzi/home/.claude/CLAUDE.md`
- Scripts install: `/home/diego/dotfiles-dizzi/home/fase2-HyprInstall-full.sh`, `/home/diego/dotfiles-dizzi/home/fase2-HyprInstall-CachyOS-Edition.sh`
- Engram bin: `/home/diego/dotfiles-dizzi/home/.local/bin/engram`
- jscamp-memory helper: `/home/diego/dotfiles-dizzi/home/.local/bin/jscamp-memory`
- Keymaps Neovim: `/home/diego/dotfiles-dizzi/nvim/.config/nvim/lua/config/keymaps.lua`

## Workflow Dual Remote (CIC + dizzi1222)

Cada repo (`ptd-talento-front`, `ptd-talento-back`) tiene dos remotes:

| Remote | URL | Uso |
|---|---|---|
| `origin` | `Cincinnatus-Institute-of-Craftsmanship/ptd-talento-*` | Repo oficial CIC (dhardi007) — **NUNCA cambiar author** |
| `dizzi1222` | `dizzi1222/ptd-talento-*` | Fork personal (dizzi1222) — Vercel, Railway, workflows propios |

### Mapeo de deploys (verificado 2026-08-24)

| Destino | Rama que dispara | Author requerido |
|---|---|---|
| **CIC** (`origin`) | `dev`; QA via merge dev→qa (dispara Cloud Build) | `dhardi007 <dhardi@cincinnatus.edu.do>` |
| **Vercel** | `dizzi1222/main` | `dizzi1222 <diegosamuel042@gmail.com>` |

⚠️ `dizzi1222/main` y `origin/dev` **NO comparten merge-base** (historia espejo con SHAs reescritos): un `git merge` entre ellos es imposible/inútil. NO intentar sincronizarlos por merge/rebase.

### Reglas estrictas

1. **NUNCA** usar `git filter-branch`, `git rebase --exec`, ni `git commit --amend --author` sobre ramas que trackeen `origin`. Esto reescribe historia del repo CIC.
2. Para pushear a `dizzi1222` con author correcto (Vercel/Railway), usar el **snapshot squash** (método preferido, abajo). `filter-branch` queda como LEGACY.
3. Las ramas locales de trabajo (`dev`, `qa`, `main`) SIEMPRE trackean `origin/<rama>`. Si alguna quedó apuntando a `dizzi1222`: `git reset --hard origin/<rama> && git branch --set-upstream-to="origin/<rama>" <rama>`.
4. `git config user.name` y `git config user.email` locales se quedan como `dhardi007` / `dhardi@cincinnatus.edu.do` — no cambiar. **NUNCA ejecutar `git config user.name/email`** como parte del author rewrite: usar env-vars inline (`GIT_COMMITTER_NAME=... git commit --author=...`).
5. Para verificar acceso a `origin`, usar la sesión `dhardi007` (`gh auth switch -u dhardi007`). Para `dizzi1222`, usar `gh auth switch -u dizzi1222`.

### ✅ Método preferido: snapshot squash a dizzi1222/main

Crea UN commit nuevo encima del tip actual del fork con el árbol exacto de `origin/dev`. No reescribe historia existente, no toca ramas locales ni su tracking. Usado con éxito 2026-08-24 (`e5af37b`).

```bash
# 0. Dev al día + rama temporal desde el main del fork
git checkout dev && git pull --ff-only
git fetch dizzi1222
git checkout -b sync-vercel dizzi1222/main

# 1. Volcar el árbol COMPLETO de origin/dev sobre el temporal
git rm -rq .
git restore --source=origin/dev --staged --worktree :/

# 2. PRESERVAR overrides propios del fork (ej. .env.production apunta a backend PROD)
git checkout HEAD -- .env.production

# 3. Registrar TODO (incluye deletes de archivos que ya no existen en dev) y VERIFICAR
git add -A
git diff --stat origin/dev --cached
#    DEBE mostrar ÚNICAMENTE los archivos override preservados (ej. solo .env.production).
#    Si aparece cualquier otro archivo, DETENER y revisar antes de commitear.

# 4. Commit squasheado con author dizzi1222 (env-vars inline, sin tocar git config)
GIT_COMMITTER_NAME="dizzi1222" GIT_COMMITTER_EMAIL="diegosamuel042@gmail.com" \
  git commit --author="dizzi1222 <diegosamuel042@gmail.com>" \
  -m "sync: dev -> main para Vercel"

# 5. Push (suele ser fast-forward; --force-with-lease cubre el caso de fork avanzado)
git push dizzi1222 sync-vercel:main --force-with-lease=main:dizzi1222/main

# 6. Limpieza y verificación final
git checkout dev
git branch -D sync-vercel
git branch -vv | grep -E '^\*?\s+(dev|main)\b'
#    Ambas deben seguir mostrando [origin/dev] y [origin/main]
```

Ventajas vs filter-branch: 1 commit nuevo en vez de reescribir ~600 SHAs; push fast-forward posible; cero riesgo de corromper tracking local.

### ⚠️ Error común (NO repetir)

Aplica sobre todo al flujo LEGACY de abajo. **Problema:** Después de operaciones de author rewrite, la rama local queda trackeando `dizzi1222/rama` en vez de `origin/rama`. Esto causa:
- `git pull` trae commits de `dizzi1222` (con author dizzi1222) en vez de `origin` (con author dhardi007)
- Ramas "divergent" con 300+ commits diferentes
- `git config user.name` cambiado accidentalmente a `dizzi1222`

**Solución:** Después de cada operación de author rewrite, SIEMPRE ejecutar:
```bash
git reset --hard "origin/<rama>"
git branch --set-upstream-to="origin/<rama>" <rama>
```

### LEGACY: filter-branch completo (evitar — solo si se necesita espejo de historia completa)

> Preferir el snapshot squash de arriba. Este proceso reescribe TODOS los SHAs en cada ejecución y es el origen del error común documentado arriba.

```bash
# 1. Checkout a la rama
git checkout <rama>

# 2. Rewriter SOLO local (no tocar origin)
git filter-branch --env-filter '
if [ "$GIT_AUTHOR_EMAIL" = "dhardi@cincinnatus.edu.do" ]; then
    export GIT_AUTHOR_NAME="dizzi1222"
    export GIT_AUTHOR_EMAIL="diegosamuel042@gmail.com"
    export GIT_COMMITTER_NAME="dizzi1222"
    export GIT_COMMITTER_EMAIL="diegosamuel042@gmail.com"
fi
' -- <rama>  # SOLO la rama actual, NUNCA --all

# 3. Push a dizzi1222
git push dizzi1222 <rama> --force

# 4. Restaurar local desde origin Y re-configurar upstream
git reset --hard "origin/<rama>"
git branch --set-upstream-to="origin/<rama>" <rama>

# 5. Verificar que trackea origin, no dizzi1222
git branch -vv | grep "<rama>"
# Debe mostrar: [origin/<rama>] NO [dizzi1222/<rama>]
```

## Engram - Memoria Persistente para Agentes IA

> **Regla fija:** Siempre guardar memorias en proyecto `dotfiles-dizzi` por defecto. Usar `project: "dotfiles-dizzi"` con `project_choice_reason: "user_selected_after_ambiguous_project"` y el recovery token correspondiente cuando haya ambigüedad.

### Instalación (CachyOS)

```bash
# Binario precompilado
curl -L https://github.com/Gentleman-Programming/engram/releases/latest/download/engram_1.17.0_linux_amd64.tar.gz | tar xz -C /tmp
mv /tmp/engram ~/.local/bin/engram
chmod +x ~/.local/bin/engram
```

### Configuración para OpenCode

```bash
engram setup opencode
# Reinicia OpenCode
```

### Uso en OpenCode (herramientas MCP)

- `mem_save` — Guardar memoria (title, msg, type, project)
- `mem_search` — Buscar memorias
- `mem_context` — Contexto reciente de sesión
- `mem_timeline` — Contexto cronológico
- `mem_session_start/end/summary` — Ciclo de sesión

### Proyecto JSCamp

```bash
# Guardar lección
engram save "Lección: Filtrado resultados" "Usar event.target.classList.contains y .is-hidden" --type lesson --project jscamp

# Guardar patrón
engram save "Patrón: Delegación eventos" "click en .jobs-listings → event.target.button-apply-job" --type pattern --project jscamp

# Contexto antes de continuar
engram context --project jscamp
```

### Keymaps Neovim (Engram)

- `<leader>ems` — Guardar memoria
- `<leader>eml` — Guardar lección
- `<leader>emp` — Guardar patrón
- `<leader>emsess` — Guardar resumen sesión
- `<leader>emc` — Mostrar contexto
- `<leader>emf` — Buscar memoria

### Helper jscamp-memory

```bash
jscamp-memory save "Título" "Mensaje" [--type TYPE]
jscamp-memory lesson "Título" "Contenido"
jscamp-memory pattern "Título" "Descripción"
jscamp-memory session "Resumen de la sesión"
jscamp-memory search "query"
jscamp-memory context
```

### JSCamp - Bootcamp midudev

**Repo:** `dizzi1222/jscamp` (fork de `midudev/jscamp`)
**Submódulo:** `workspace/jscamp` → `dizzi1222/jscamp`
**Rama actual:** `ejercicio-filtrando` (commit `9646b6b` - punto exacto del ejercicio)

**Estructura:**

- `01-javascript/empleos.html` — Página con filtros (tecnología, ubicación, experiencia)
- `01-javascript/script.js` — Ejercicio implementado (filtrado por tecnología)
- `01-javascript/styles.css` — Design system completo (dark theme, vars CSS)

**Workflow ramas:**

```bash
cd workspace/jscamp
git checkout -b leccion-fetch-json ejercicio-filtrando
# programas...
git commit -am "feat: implement fetch from data.json"
git push origin leccion-fetch-json
```

**Arrancar:**

```bash
cd workspace/jscamp/01-javascript
python3 -m http.server 8083
# → http://localhost:8083/empleos.html
```

## Cuentas de Google (login 3ra opción)

1. `sanakyds@gmail.com` → `authuser=0` (default)
2. `diegosamuel042@gmail.com` → `authuser=1`
3. `dhardi@cincinnatus.edu.do` (institucional CIC) → `authuser=2`

> Para App Password u otros servicios Google que requieran la cuenta 3 (dhardi), agregar `?authuser=2` a la URL. Ej: `https://myaccount.google.com/apppasswords?authuser=2`

---

# Convenciones del Profesor (sesión `vim-learn`)

> Documento fusionado desde `~/.claude/CLAUDE.md` (config global) al repo para unificar la fuente única.

## Rol: Profesor

- Soy el **Profesor** de Diego: doy instrucciones y el razonamiento ideal para que ÉL resuelva los problemas.
- Busco documentación oficial y uso métodos de aprendizaje efectivos.
- **PROHIBIDO escribir código en archivos** (regla general). Muestro snippets en el chat de referencia; el trabajo lo hace Diego.
- **EXCEPCIÓN (autorizada): la submodule `nvim/.config/nvim`** — Diego me dio permiso para leer y **editar** su configuración Lua/plugins, y sus docs `.md` (limpieza markdownlint). En el resto de repos de código la regla Profesor sigue vigente.
- En `nvim/`, **los commits los hace Diego**, nunca yo.

## Nota: `hypr/.config/hypr/scripts/text_animation/scripttext`

- **Este archivo se autogenera siempre** (script de text animation).
- **Siempre hay que ignorarlo del stage** — nunca hacer `git add`, ni incluirlo en un commit/amend.
- NO es necesario que esté en `.gitignore`; simplemente se ignora al commitear.
- No es un valor literal fijo: su contenido cambia con cada ejecución de la animación.
- Si aparece como `M` en `git status`, descartar con `git checkout --` y seguir.

## Trabajo con nvim (`dotfiles-dizzi/nvim/.config/nvim`)

Esta submodule **sí puedo editarla** (config Lua, plugins y docs `.md`).

### Linters markdown y config
- Hay **dos** linters:
  - `markdownlint` (CLI, `~/.npm-global`) → lee **`.markdownlintrc`** (JSON anidado).
  - `markdownlint-cli2` (vía Mason; es el **LSP** que ve Diego en Neovim) → lee **`.markdownlint-cli2.jsonc`** con estructura `{"config": { ... }}`.
- **IMPORTANTE:** para que no aparezcan errores en Neovim hay que crear **ambos** archivos en cada directorio, con la misma regla: `MD013` line_length 120 + `tables: false`, y `MD060: false`.
  - Config en `nvim/.config/nvim/docs/.markdownlintrc` y `.markdownlint-cli2.jsonc`.
  - Config en `workspace/AGENT-records/.markdownlintrc` y `.markdownlint-cli2.jsonc`.
- **El LSP de Neovim (markdownlint-cli2) NO auto-detecta `.markdownlint-cli2.jsonc` por defecto** → muestra `Expected: 80` (defaults). La solución definitiva es forzar las reglas vía `settings.config` del server en `nvim/.config/nvim/lua/plugins/overrides.lua` (server `markdownlint`): `MD013 { line_length = 120, tables = false }`, `MD060 = false`. Tras cambiarlo: `:LspRestart` o reabrir el archivo.
- **⚠️ CAUSA REAL del "Expected: 80":** el diagnostico `markdownlint` con MD013 a 80 NO viene del LSP (que no existe como server lspconfig) sino de **`nvim-lint`** (extra de LazyVim `extras/lang/markdown.lua` → `linters_by_ft.markdown = { "markdownlint-cli2" }`). Al correr con stdin `-` y sin config desde el cwd (`~/`), usa defaults. **Solución:** override en `overrides.lua` del linter `["markdownlint-cli2"]` con `args = { "--config", vim.fn.stdpath("config") .. "/.markdownlint-cli2.jsonc", "-" }`, apuntando al config canónico `~/.config/nvim/.markdownlint-cli2.jsonc`. (El server `markdownlint` en `servers` NO sirve porque lspconfig ya no trae ese server.)
- Verificar con la CLI del LSP: `cd <dir> && markdownlint-cli2 "*.md"` → 0 issues.

### Warnings de Lua del LSP (falsos positivos comunes)
El LSP de nvim diagnostica sobre la submodule `nvim/lua/plugins/*.lua`. La mayoría son **falsos positivos** por las *globals* de LazyVim que se definen en otros archivos:
- `Undefined global 'LazyVim'` → global de LazyVim; ignorar.
- `Undefined global 'get_args'` → función usada en keybindings de nvim-dap; se define en otra parte; ignorar.
- `Undefined global 'Mini...'`/`snacks`/otros → globals de frameworks; ignorar.
- `Duplicate field 'json_decode'` en nvim-dap.lua → es un *override* intencional para el `dap.ext.vscode`; ignorar.
- `Deprecated` (cualquiera) → revisar, puede implicar limpieza.
- `undefined-global` reales con nombres no-LazyVim → revisar si son un bug.

### Verificar sintaxis Lua sin romper el setup
- `timeout 30 nvim --headless -u NONE -c "luafile lua/plugins/nvim-dap.lua" -c "q"` → exit 0 = sintaxis válida.
- `luac -p` normalmente no está instalado; usar el chequeo con nvim headless.

### DAP (nvim-dap)
- Para JS/TS/React: adapter `pwa-node`/`pwa-chrome` vía plugin `mxsdev/nvim-dap-vscode-js` + `microsoft/vscode-js-debug`.
- El `build` de `vscode-js-debug` usa **`--ignore-scripts`** (salta el postinstall de Playwright que necesita `apt-get`, no disponible) + `gulp vsDebugServerBundle && mv dist out`.
- `nvim-dap-vscode-js` necesita `debugger_path = vim.fn.stdpath("data") .. "/lazy/vscode-js-debug"` (no la ruta de packer por defecto).
- `dap.configurations` definidos para `typescriptreact`, `typescript`, `javascript`, `javascriptreact`: Launch file (Node), Attach (Node), Launch Chrome (Vite :5173, runtimeExecutable `/home/diego/.nix-profile/bin/chromium`), Attach a Chrome (puerto 9222).
- `dap.ext.vscode.load_launchjs()` está **deprecado** (leyó launch.json automáticamente); no usarlo.
- El `vscode.json_decode` override sí se conserva (parsea JSON con comentarios).

### Chromium/Playwright vía Nix
- Diego tiene Playwright/Chromium **nativos vía Nix** (`nixconf/home-manager/features/work.nix`: `playwright-driver.browsers`, `chromium`, `chromedriver`, `geckodriver`, `cypress`).
- Chromium del sistema: `/home/diego/.nix-profile/bin/chromium` (no hay google-chrome/edge).
- El postinstall de Playwright del repo `vscode-js-debug` es solo para sus tests; el adapter `pwa-chrome` lanza el Chromium del sistema vía `runtimeExecutable`.

### Plugin `cord.nvim`
- Tiene un **patch local de Diego** (`[dizzi patch]`) en `lua/cord/internal/activity/workspace.lua` que sube directorios padres para detectar `.git`.
- **NO revertirlo** — es intencional y se auto-reaplica con el build del plugin. Lazy mostrará "local changes" al actualizar cord.nvim; ignorar ese aviso.
