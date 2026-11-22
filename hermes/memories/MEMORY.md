Proyecto: My TypeScript Library: "Eres un asistente útil y conciso. Generas un Plan si la demanda es grande solamente."
§
Proyecto: My TypeScript Library: Habla en español
§
Proyecto: My TypeScript Library > Instrucciones Generales: Cuando generes nuevo código TypeScript, sigue el estilo de codificación existente.
§
Proyecto: My TypeScript Library > Instrucciones Generales: Asegúrate de que todas las funciones y clases nuevas tengan comentarios JSDoc.
§
Proyecto: My TypeScript Library > Instrucciones Generales: Prefiere paradigmas de programación funcional cuando sea apropiado.
§
Proyecto: My TypeScript Library > Seguimiento Visual — `oc-open` (obligatorio tras cada edición): **Regla:** después de cada tanda de `edit`/`write`, llama a `oc-open` con `ruta:línea` de **cada archivo modificado**, para que Diego vea el cambio en su Neovim mientras lo implemento. Es el equivalente agente→humano del "open file" de lazygit.
§
Proyecto: My TypeScript Library > Seguimiento Visual — `oc-open` (obligatorio tras cada edición): Fuente: `~/dotfiles-dizzi/local/.local/bin/oc-open` → `~/.local/bin/oc-open`
§
Proyecto: My TypeScript Library > Seguimiento Visual — `oc-open` (obligatorio tras cada edición): Default: si el archivo ya está abierto, mueve el cursor en la ventana existente; si no, abre una tab nueva. Nunca spamea tabs. `-n` fuerza tab nueva (comportamiento lazygit).
§
Proyecto: My TypeScript Library > Seguimiento Visual — `oc-open` (obligatorio tras cada edición): Facts técnicos: OpenCode corre dentro de un terminal buffer de Neovim, así que `$NVIM` ya viene exportado → `oc-open` se conecta **a la misma instancia** desde la que Diego me lanzó. Fallback: `$OC_NVIM_SOCKET` > `$NVIM` > socket más reciente que responda.
§
Proyecto: My TypeScript Library > Seguimiento Visual — `oc-open` (obligatorio tras cada edición): Ejecuté `normal! V` para señalar la línea: si la siguiente tecla es accidental, puede reemplazar la línea. Alternativa pasiva: `matchadd`. Pendiente de decisión de Diego.
§
Proyecto: My TypeScript Library > Seguimiento Visual — `oc-open` (obligatorio tras cada edición) > ⚠ Efecto secundario conocido (anotado 2026-10-03, NO es bug): **Al saltar al archivo, OpenCode "desaparece" de la vista.** No se cerró: el TUI vive en un *terminal buffer* del mismo Neovim, y `win_gotoid`/`tabedit` mueven el foco de esa ventana al código. Decisión de Diego: es el comportamiento deseado (analiza el código y luego vuelve). No intentar "arreglarlo" con hacks de focus-preserving.
§
Proyecto: My TypeScript Library > Seguimiento Visual — `oc-open` (obligatorio tras cada edición) > ⚠ Efecto secundario conocido (anotado 2026-10-03, NO es bug): **Ojo con el "doble press"**: el toggle clásico (`term:toggle()`) necesita **2 pulsaciones** cuando la ventana de opencode quedó en otra tab — la 1ª oculta / no cambia nada visible, la 2ª muestra. Se resolvió con un toggle **inteligente** que razona sobre visibilidad real, así que **siempre es 1 pulsación**:
§
Proyecto: My TypeScript Library > Seguimiento Visual — `oc-open` (obligatorio tras cada edición) > ⚠ Efecto secundario conocido (anotado 2026-10-03, NO es bug): Ambas funciones ya **no dependen de `snacks.terminal`**: localizan el buffer por `buftype == "terminal"` + nombre con `opencode` + `channel > 0` (`find_opencode_buf()`), que es lo que fallaba cuando snacks pierde el registro. Definidas en `nvim/.config/nvim/lua/plugins/opencode-chat.lua`. Lógica verificada 9/9 en nvim headless (`/tmp/opencode/toggle_test.lua`).
§
Proyecto: My TypeScript Library > Seguimiento Visual — `oc-open` (obligatorio tras cada edición) > ⛔ NO existe modo split, ni dentro de nvim ni en otra ventana: Se probaron **dos** variantes para que opencode siguiera visible mientras se ve el código, y **ambas se descartaron**:
§
Proyecto: My TypeScript Library > Seguimiento Visual — `oc-open` (obligatorio tras cada edición) > ⛔ NO existe modo split, ni dentro de nvim ni en otra ventana: `-w/--split` (mismo nvim, panel de código estable junto al terminal). Rompió el layout: `opencode-chat.lua` tiene autocmds (`User OpencodeEvent:*`) que hacen `nvim_api_set_current_win` + `startinsert` sobre la ventana del opencode, así que cualquier secuencia `win_gotoid` + `normal!` aterriza en el terminal en vez de en el código. Resultado: ventana de opencode duplicada + 4 splits.
§
Proyecto: My TypeScript Library > Seguimiento Visual — `oc-open` (obligatorio tras cada edición) > ⛔ NO existe modo split, ni dentro de nvim ni en otra ventana: `-k/--os-window` (2do nvim en su propia ventana de terminal, socket `$XDG_RUNTIME_DIR/oc-open-code.sock`). Funcionaba técnicamente y dejaba el nvim de Diego intacto, pero **Diego lo rechazó**: abrir otra ventana de terminal es más intrusivo que perder de vista el TUI.
§
Proyecto: My TypeScript Library > Seguimiento Visual — `oc-open` (obligatorio tras cada edición) > ⛔ NO existe modo split, ni dentro de nvim ni en otra ventana: Decisión final: sólo el comportamiento default. OpenCode sale de la vista mientras se analiza el código y se vuelve con `oc-open -b`, `Ctrl-^` o `<leader>ao`. Si alguna vez se revisa, hay que aislar el bucle de eventos de opencode del salto de cursor.
§
Proyecto: My TypeScript Library > Seguimiento Visual — `oc-open` (obligatorio tras cada edición) > Origen: el workflow de lazygit: Lazygit ejecuta el editor vía `$SHELL -c`, y en esta máquina `$SHELL` es `~/.local/bin/lazygit-shell` (wrapper que descarta el `-c`, recompone el cmd y lo reejecuta con `zsh -ic` para cargar el `~/.zshrc` completo):
§
Proyecto: My TypeScript Library > Seguimiento Visual — `oc-open` (obligatorio tras cada edición) > Origen: el workflow de lazygit: `oc-open` conserva el mecanismo (`--server` + `execute()` de Vimscript vía `--remote-expr`) pero cambia la política para el uso agente→humano: **no cierra tu buffer ni crea tabs nuevas si el archivo ya está abierto**; sólo mueve el cursor, centra la línea y la selecciona en visual (`V`) para que veas exactamente dónde escribí.
§
Proyecto: My TypeScript Library > Estilo de Codificaciónkkk: Usa 2 espacios para la indentación.
§
Proyecto: My TypeScript Library > Estilo de Codificaciónkkk: Prefija los nombres de interfaz con `I` (por ejemplo, `IUserService`).
§
Proyecto: My TypeScript Library > Estilo de Codificaciónkkk: Siempre usa igualdad estricta (`===` y `!==`).
§
Proyecto: My TypeScript Library > Comentarios Seccionales (Section Headers): Usar comentarios tipo `//SectionTitle` para dividir archivos largos en bloques lógicos.
§
Proyecto: My TypeScript Library > Comentarios Seccionales (Section Headers) > Archivos que NO necesitan: Scripts, migraciones, archivos < 40 líneas autoexplicativos, configs.
§
Proyecto: My TypeScript Library > Conexión a Base de Datos Local (pgAdmin4) > Prerrequisitos: GCloud CLI instalado y autenticado: `gcloud auth application-default login`
§
Proyecto: My TypeScript Library > Conexión a Base de Datos Local (pgAdmin4) > Prerrequisitos: Cloud SQL Proxy descargado en `~/cloud-sql-proxy`
§
Proyecto: My TypeScript Library > Conexión a Base de Datos Local (pgAdmin4) > Pasos para conectar: **Iniciar el proxy** (mantener corriendo en una terminal): Esperar a que muestre: `The proxy has started successfully and is ready for new connections!`
§
Proyecto: My TypeScript Library > Conexión a Base de Datos Local (pgAdmin4) > Pasos para conectar: **Configurar pgAdmin4** con estos valores exactos: Host: `127.0.0.1` (NUNCA el nombre de la BD), Port: `5433` (el del proxy, no el del .env), Database: `talento-dev`, Username: `talento-dev`, Password: **Ver en 1Password / Vault del equipo**
§
Proyecto: My TypeScript Library > Conexión a Base de Datos Local (pgAdmin4) > Errores comunes: "failed to resolve host 'talento-dev'" → se puso `talento-dev` como Host en vez de `127.0.0.1`; "Connection refused on port 5432" → se usó el puerto 5432 del .env en vez del 5433 del proxy; "Connection refused" en general → el proxy no está corriendo
§
Proyecto: My TypeScript Library > Daily Format (ChatSpace): Siempre dar ambas versiones: español (para que Diego lea) e inglés (para enviar a ChatSpace).
§
Proyecto: My TypeScript Library > Daily Format (ChatSpace): > Para referencia detallada ver: `/home/diego/dotfiles-dizzi/.github/google-chatspace-format.md`
§
Proyecto: My TypeScript Library > Daily Format (ChatSpace): Estructura fija: Reglas: Usar `*texto*` para negritas (formato ChatSpace), bullets con `•`, Fecha en inglés: "June 5, 2026", Separar secciones con línea en blanco, En español: misma estructura pero títulos traducidos y descripción en español
§
Proyecto: My TypeScript Library > Daily Format (ChatSpace): **Siempre enlazar tickets mencionados** con su URL completa de GitHub, ej: <https://github.com/Cincinnatus-Institute-of-Craftsmanship/ptd-talento-back/issues/94>
§
Proyecto: My TypeScript Library > Daily Format (ChatSpace): Si mencionas un _épica tracker_, lista sus features entre paréntesis, ej: _ÉPICA 03 Tracker_ (#92) con Features (US-03-01, US-03-02, US-03-03)
§
Proyecto: My TypeScript Library > Daily Format (ChatSpace) > Plantilla Issue: Daily Report: Ubicaciones: **Backend:** `/home/diego/workspace/ptd-talento-back/.github/ISSUE_TEMPLATE/4-dailly-report.md`, **Dotfiles:** `/home/diego/dotfiles-dizzi/.github/ISSUE_TEMPLATE/4-dailly-report.md`, Formato ESP/ENG integrado, Labels: `daily`, `diego`, Usar para crear issue diario de avances
§
Proyecto: My TypeScript Library > Daily Format (ChatSpace) > Plantilla Issue: Investigación (INV): Ubicaciones: **Dotfiles:** `/home/diego/dotfiles-dizzi/.github/ISSUE_TEMPLATE/5-investigacion.md`, Labels: `investigation`, Usar para analizar comportamientos extraños, inconsistencias o bugs no confirmados, Incluir: módulo afectado, comportamiento observado, hipótesis, pasos para reproducir, evidencias
§
Proyecto: My TypeScript Library > Daily Format (ChatSpace) > Plantilla Issue: Investigación Técnica (SPIKE): Ubicaciones: **Dotfiles:** `/home/diego/dotfiles-dizzi/.github/ISSUE_TEMPLATE/6-spike.md`, Labels: `spike`, Usar para aprendizaje técnico, exploración de enfoques y POCs antes de implementar, Incluir: objetivo, preguntas a resolver, actividades, entregables, recomendación final
§
Proyecto: My TypeScript Library > Daily Format (ChatSpace) > Plantilla Issue: Comentarios Seccionales: Ubicaciones: **Dotfiles:** `/home/diego/dotfiles-dizzi/.github/ISSUE_TEMPLATE/7-comentarios-seccionales.md`, Labels: `documentation`, Usar para estandarizar `//SectionTitle` en archivos que necesiten orientación de lectura, Incluir: archivos afectados, reglas de formato, checklist de validación
§
Proyecto: My TypeScript Library > PR Template (QA Format): Usar esta plantilla en el body de todos los PRs
§
Proyecto: My TypeScript Library > PR Conclusion Template (QA Update): Usar esta plantilla cuando se actualiza un PR ya existente
§
Proyecto: My TypeScript Library > Estándar de Nomenclatura de Ramas (PTD-Talento): Formato oficial: `tipo-rama/sigla-modulo-[codigo-us]-funcionalidad`
§
Proyecto: My TypeScript Library > Estándar de Nomenclatura de Ramas (PTD-Talento) > Ejemplos para Épica 03 (Catálogo): Rama integración: `feat/m3-cat-hub` (renombrada desde `e3-hub`); US-03-01: `feat/m3-cat-us0301-ver-talentos`; US-03-02: `feat/m3-cat-us0302-buscar-nombre`; US-03-03: `feat/m3-cat-us0303-filtrar-path`; US-03-04: `feat/m3-cat-us0304-filtrar-campus`; US-03-05: `feat/m3-cat-us0305-ver-detalle`; Hotfix: `hotfix/m3-cat-fix-descripcion`; Regla: minúsculas estrictas, prefijo `feat/` o `hotfix/`, sigla módulo de 5 chars, código US con 4 dígitos si aplica.
§
Proyecto: My TypeScript Library > Modus Operandi — PTD-Talento: Separación de responsabilidades en ramas: **UI** = componentes visuales (botón, navbar, card, modal). **UIX** = interacción + experiencia (micro-animaciones, skeletons, loading/error/empty states, transiciones). Flujo: `feat/m3-cat-ui-global` → merge a → `feat/m3-cat-hub` → PR a `dev` con formato QA.
§
Proyecto: My TypeScript Library > Reglas de Commit: Commits descriptivos con bullet points detallando cada cambio; Usar formato: `fix:|feat:|chore:` según corresponda; Incluir métricas cuando aplique (espacio liberado, tiempo, etc.); Máximo 325 commits en el repo
§
Proyecto: My TypeScript Library > NixOS Config (thinkpad-x1e2): ⚠️ **WORKFLOW ACTUAL: NO es GNU Stow ni GNU Stow dotfiles.** Toda la config de apps (opencode, hypr, nvim, ghostty, starship, etc.) vive en `~/dotfiles-dizzi/<app>/` y se **home-manager** la enlaza vía symlinks (out-of-store) a las rutas XDG esperadas. El mapeo está en `~/dotfiles-dizzi/nixconf/home-manager/home.nix` (sección `home.file`). **NO revisar/verificar si la config está "stoweada"** — ya no hay Stow; las ediciones se hacen SIEMPRE sobre la fuente en `~/dotfiles-dizzi/` y se aplican con `home-manager switch` (o `~/.local/bin/nixconf-rebuild`).
§
Proyecto: My TypeScript Library > NixOS Config (thinkpad-x1e2) > ydotool (autoclicker/autopress): Service: `~/wrapper/autoclicker-menu` → `~/.local/bin/autoclicker menu`; Service: `~/wrapper/autopress-menu` → `~/.local/bin/autopress`; Keybinds: F7 (autoclicker), F9 (autopress) in hypr/bindings.conf; Socket: `/tmp/.ydotool_socket` (needs `xorg.xinput` + `ydotool.service` running); Service: systemctl --user ydotool.service (auto-started by wrapper)
§
Proyecto: My TypeScript Library > NixOS Config (thinkpad-x1e2) > system_control.sh (rofi menu): Path: `~/scripts/system_control.sh` (symlinked from `home/scripts/`); `󰮮` → `~/.local/bin/clean-boot`; `` → `~/.local/bin/nixconf-rebuild`; `🦙` → ollama list; `󰳾` → autoclicker (via wrapper); `󰌌 󱊮` → autopress (via wrapper); `` → ydotool service check; `` → Docker Desktop flatpak / lazydocker
§
Proyecto: My TypeScript Library > Referencias dotfiles-dizzi > Plantillas GitHub (dotfiles-dizzi): **PULL_REQUEST_TEMPLATE.md**: `/home/diego/dotfiles-dizzi/.github/PULL_REQUEST_TEMPLATE.md` — Plantilla QA unificada para PRs (formato unificado front/back); **ISSUE_TEMPLATE/**: `/home/diego/dotfiles-dizzi/.github/ISSUE_TEMPLATE/` — Plantillas de issues
§
Proyecto: Análisis Comparativas Hardware: Sesión agregada — comparación de costos y beneficios entre Hostinger VPS (KVM 2: 2 vCPU, 8 GB RAM, 100 GB NVMe, 8 TB transferencia/mes, US$8.79/mes intro, US$14.99/mes renovación) vs Obsidian Sync (Standard US$4/mes, 1 GB, 1 mes historial; Plus US$8/mes, 10-100 GB, 12 meses historial) para sincronizar Obsidian mediante Self-hosted LiveSync (CouchDB). Conclusión: VPS conviene si se usa para más cosas; solo para Obsidian, Sync es más barato y menos mantenimiento. Los 8 TB son ancho de banda, no almacenamiento.