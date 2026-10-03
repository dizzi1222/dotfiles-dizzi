#Diego Samuel Hardi Santana — instrucciones globales para agy (Antigravity CLI)

> Fuente única y completa: `~/.claude/CLAUDE.md` (la carga opencode). Este archivo es
> el espejo **esencial** para agy. Si algo no está acá, está allá.

## Estilo de Codificación

- **2 espacios** de indentación.
- Prefija las interfaces con `I` (ej. `IUserService`).
- Igualdad estricta: `===` y `!==`.
- JSDoc en todas las funciones y clases nuevas.
- Comentarios seccionales `//SectionTitle` (sin punto, máx. 1 cada ~50 líneas) en
  archivos largos. No en scripts, migraciones, configs ni archivos < 40 líneas.
- Prefiere paradigmas funcionales cuando sea apropiado.

## Seguimiento Visual — `oc-open` (OBLIGATORIO tras cada edición)

**Regla:** después de cada tanda de `edit`/`write`, llama a `oc-open` con `ruta:línea`
de **cada archivo modificado**, para que Diego vea el cambio en su Neovim mientras lo
implementas.

```bash
oc-open src/app.ts:42            # salta a la línea 42 (reutiliza el buffer)
oc-open src/app.ts:42:8          # ...y a la columna 8
oc-open a.ts:10 b.ts:200         # varios archivos, en orden
git diff --name-only | oc-open - # todos los archivos del diff
oc-open -b                       # vuelve a la ventana previa
```

- **Default**: si el archivo ya está abierto, mueve el cursor en la ventana existente
  (opencode/agy siguen visibles). Si no, abre una tab nueva.
- Funciona porque agy corre dentro de un terminal buffer de Neovim ⇒ `$NVIM` viene
  exportado ⇒ se conecta a la MISMA instancia.
- Fallback: `$OC_NVIM_SOCKET` > `$NVIM` > socket más reciente que responda.

### ⛔ Reglas de seguridad (aprendidas a la mala)

- **NUNCA** pruebes comandos de ventana sobre el Neovim vivo de Diego. Para cualquier
  experimento usá uno headless:
  ```bash
  nvim --headless -u NONE --listen /tmp/t.sock &
  OC_NVIM_SOCKET=/tmp/t.sock oc-open archivo.sh:10
  ```
  Sin `OC_NVIM_SOCKET`, `oc-open` se conecta al nvim real y rompés su layout.
- **NUNCA** uses `close`, `only`, `sbuffer` ni `:q` sobre ventanas ajenas: `win_gotoid`
  con un id obsoleto no falla en silencio, el comando siguiente cierra la ventana actual
  (a veces la de opencode). Para limpiar, preferí `bdelete` del buffer.
- Cliente `nvim --server` sin TTY: siempre `timeout -s KILL 3 ... </dev/null`, o se
  cuelga el shell del agente.
- `pkill -f "nvim --server"` matchea tu propio shell y lo mata. Usá el truco de corchetas:
  `pkill -f "nvim --serve[r]"`.

## Reglas de Git

- Commits descriptivos con bullets; formato `fix:` | `feat:` | `chore:`.
- Máximo 325 commits en el repo.
- **Dual remote** (`ptd-talento-back` / `ptd-talento-front`):
  - `origin` = repo oficial CIC (`dhardi007 <dhardi@cincinnatus.edu.do>`) — NUNCA cambiar author.
  - `dizzi1222` = fork personal (Vercel/Railway).
  - Las ramas locales (`dev`, `qa`, `main`) SIEMPRE trackean `origin/<rama>`.
  - Para pushear a `dizzi1222` con author correcto: env-vars inline, nunca
  `git config user.*`. Usar el método "snapshot squash" (ver CLAUDE.md).
  - Prohibido `git filter-branch` / `--amend --author` sobre ramas que trackean `origin`.

## Nomenclatura de ramas (PTD-Talento)

`tipo-rama/sigla-modulo-[codigo-us]-funcionalidad` — ej. `feat/m3-cat-us0305-ver-detalle`.
Siglas: `m1-aut`, `m2-per`, `m3-cat`, `m4-lis`, `m5-sol`, `m6-not`, `m7-adm`, `m8-aud`.

## Sistema (NixOS, `nixconf`)

- **Workflow**: home-manager con symlinks; NO es GNU Stow. Editá siempre la fuente en
  `~/dotfiles-dizzi/` y aplicá con `~/.local/bin/nixconf-rebuild`.
- Claude config: `~/.claude/CLAUDE.md` → fuente única `dotfiles-dizzi/home/.claude/CLAUDE.md`.
- `nvim/` es una **submodule**: los commits los hace Diego, nunca el agente.

## Memoria persistente

- **Engram** (`engram` CLI) para memoria entre sesiones. Proyecto por defecto: `dotfiles-dizzi`.
- Comando correcto: `engram save <titulo> <mensaje> --project dotfiles-dizzi --type <feat|fix|chore>`
  NO usar `engram add` (no existe en v1.17.0).
- Recuperar: `engram search <query> --project dotfiles-dizzi`

### Hábito obligatorio al final de cada sesión

Al terminar cualquier tanda de ediciones, guardar una memoria con:
  - Archivos modificados (ruta absoluta)
  - Líneas clave tocadas
  - Qué se hizo y por qué

Ejemplo:
```
engram save "sesion-YYYY-MM-DD" "Edité src/foo.ts:42 — agregué validación X. Creé /tmp/bar.sh:15 función log()." --project dotfiles-dizzi --type feat
```

### Trigger: "muéstrame los cambios" / "qué editaste"

Cuando Diego diga alguna de estas frases (o similares), el flujo es:
1. `engram search "sesion" --project dotfiles-dizzi` → recuperar memoria de sesión actual o la más reciente.
2. Leer los archivos y líneas listadas en la memoria.
3. Ejecutar `oc-open ruta:línea` para **cada archivo editado**, en orden, para que Diego vea exactamente dónde se hizo el cambio.
4. Describir brevemente qué hay en esa línea.

Frases que activan este flujo: "muéstrame los cambios", "qué editaste", "show changes", "dónde escribiste", "abre lo que cambiaste".

- Plantillas de issues/PR: `~/dotfiles-dizzi/.github/` (+ `templates/` de opencode).

## GitHub Issues y PRs

- Usar las plantillas de `~/.config/opencode/templates/` (epic, feature, bug) y las de
  `dotfiles-dizzi/.github/`.
- PRs de PTD-Talento usan el **QA Format** completo (objetivo, flujo, casos a validar,
  ambiente, credenciales) — ver CLAUDE.md. Sin esa info, QA no puede probar.

## Estilo de respuesta

- Español, conciso. Plan solo si la demanda es grande.
- Si modificás muchos archivos, agrupá los `oc-open` en un solo comando al final.