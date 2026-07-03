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
| Sigla | Módulo |
|---|---|
| `m1-aut` | Autenticación y Control de Acceso |
| `m2-per` | Perfil de Talento (Estudiante) |
| `m3-cat` | Catálogo y Búsqueda de Talentos |
| `m4-lis` | Lista de Candidatos (Watch List) |
| `m5-sol` | Solicitudes |
| `m6-not` | Notificaciones |
| `m7-adm` | Administración y Gestión de Usuarios |
| `m8-aud` | Historial de Acciones (Auditoría) |

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

| Rama | Contenido | Base | Merge a |
|---|---|---|---|
| `feat/m3-cat-hub` (frontend) | Marketplace: cards, filtros, catálogo, búsqueda | `dev` | `dev` |
| `feat/m3-cat-ui-global` (frontend) | Componentes globales: NavBar, SideBar, Layout, modals, theme.ts, animations, UIX | `feat/m3-cat-hub` | `feat/m3-cat-hub` → `dev` |

> **UI** = componentes visuales (botón, navbar, card, modal).  
> **UIX** = interacción + experiencia (micro-animaciones, skeletons, loading/error/empty states, transiciones).

Flujo: `feat/m3-cat-ui-global` → merge a → `feat/m3-cat-hub` → PR a `dev` con formato QA.

## Referencias dotfiles-dizzi

### Plantillas GitHub (dotfiles-dizzi)

- **PULL_REQUEST_TEMPLATE.md**: `/home/diego/dotfiles-dizzi/.github/PULL_REQUEST_TEMPLATE.md` — Plantilla QA unificada para PRs (formato unificado front/back)
- **PR_CONCLUSION.md**: `/home/diego/dotfiles-dizzi/.github/PR_CONCLUSION.md` — Template para actualizaciones de PR (update brief, foco re-testing, notas)
- **ISSUE_TEMPLATE/**: `/home/diego/dotfiles-dizzi/.github/ISSUE_TEMPLATE/` — Plantillas de issues:
  - `1-epic.md` — Épicas
  - `2-feature.md` — Features
  - `3-bug.md` — Bugs
  - `4-dailly-report.md` — Daily Report (ESP/ENG integrado)

### Rutas absolutas de referencia

- Dotfiles principal: `/home/diego/dotfiles-dizzi/`
- GitHub templates: `/home/diego/dotfiles-dizzi/.github/`
- CLAUDE.md dotfiles: `/home/diego/dotfiles-dizzi/home/.claude/CLAUDE.md`
- Scripts install: `/home/diego/dotfiles-dizzi/home/fase2-HyprInstall-full.sh`, `/home/diego/dotfiles-dizzi/home/fase2-HyprInstall-CachyOS-Edition.sh`
- Engram bin: `/home/diego/dotfiles-dizzi/home/.local/bin/engram`
- jscamp-memory helper: `/home/diego/dotfiles-dizzi/home/.local/bin/jscamp-memory`
- Keymaps Neovim: `/home/diego/dotfiles-dizzi/nvim/.config/nvim/lua/config/keymaps.lua`

## Engram - Memoria Persistente para Agentes IA

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
