# Engram Index — dotfiles-dizzi

> Índice de topic_keys principales en Engram (MCP) para el proyecto `dotfiles-dizzi`.
> Última actualización: 20 de noviembre de 2026.

---

## Topic Keys Activos

| Topic Key | Tipo | Última Obs | Descripción |
|-----------|------|------------|-------------|
| `profile/diego-consolidated` | decision | #164 | **Perfil maestro de Diego**: hardware, OS, agentes, IAs, Neovim IA, workspace, aprendizaje, reglas de interacción, OBSOLETO. Fuente sincronizada: `~/.hermes/memories/USER.md` + `MEMORY.md` + `~/dotfiles-dizzi/home/memoria_diego.zip`. |
| `architecture/auth-model` | architecture | — | Pendiente: decisión sobre modelo de autenticación (JWT vs sessions, refresh tokens, etc.). |
| `architecture/nvim-config` | architecture | — | Pendiente: arquitectura de config Neovim (LazyVim + Gentleman, plugin-switcher, avante/neocursor). |
| `hermes/termux-to-bazzite` | discovery | #153 | Mapeo del setup Hermes en Termux (commit `7a125fd`) a Bazzite: 4 perfiles + SOUL, symlink helper, workspace 4-agentes, bootstrap script. |
| `workflow/dual-remote-cic-dizzi` | decision | — | Workflow dual remote CIC/dizzi1222: snapshot squash preferido, no filter-branch, reglas de author y tracking. |
| `workflow/snapshot-squash-vercel` | pattern | — | Patrón snapshot squash a `dizzi1222/main` para Vercel: 1 commit, fast-forward, preserva overrides. |
| `config/engram-setup-opencode` | config | — | Setup Engram MCP en OpenCode: `engram setup opencode`, reinicio, herramientas `mem_*`. |
| `config/markdownlint-dual` | config | — | Dos linters markdown: `markdownlint` (`.markdownlintrc`) + `markdownlint-cli2` (`.markdownlint-cli2.jsonc`); MD013=120, tables=false, MD060=off; override en `overrides.lua`. |
| `learning/developer-pro` | learning | — | Ecosistema "Developer Pro" 3 niveles: JSCAMP (estrategia) → Exercism (técnica) → Mimo (hábito). Meta: MERN-Stack. |
| `tool/avante-visual-mode` | discovery | #164 | Avante en Neovim: modo visual → `<leader>ae` (Edit), verificado en `lua/plugins/avante-cursor.lua:65` `mode="x"`. También `<leader>aa` (ask) y `<leader>an` (new ask) en visual. |
| `tool/neocursor-backend` | discovery | #164 | `neocursor.nvim` usa backend Cursor + Antigravity (`sidecar_antigravity.py`); **solo completions**, no chat/agente. |
| `tool/cursor-antigravity-discarded` | decision | #164 | Cursor y Antigravity **descartados** como chat/agente; solo backend ghost text vía neocursor. |
| `tool/gemini-cli-warp-discarded` | decision | #164 | `gemini-cli` y Warp **descartados** (no uso). IAs chat: Deepseek/Gemini web + `tgpt` terminal. |

---

## Cómo Consultar

```bash
# Buscar por topic_key
engram search "profile/diego-consolidated" --project dotfiles-dizzi

# Buscar por palabras clave
engram search "avante visual" --project dotfiles-dizzi

# Ver observación completa por ID
engram get 164

# Contexto reciente del proyecto
engram context --project dotfiles-dizzi
```

---

## Sincronización con Fuentes Externas

| Engram Topic | Fuente Externa | Última Sync |
|--------------|----------------|-------------|
| `profile/diego-consolidated` | `~/.hermes/memories/USER.md` + `MEMORY.md` + `~/dotfiles-dizzi/home/memoria_diego.zip` | 2026-11-20 (obs #164) |
| `hermes/termux-to-bazzite` | Commit Termux `7a125fd35fa9` | 2026-11-18 (obs #153) |

---

## Convenciones de Nombrado

- **Formato:** `categoria/subcategoria-descriptiva` (kebab-case)
- **Categorías:** `profile`, `architecture`, `workflow`, `config`, `learning`, `tool`, `hermes`, `discovery`, `decision`, `pattern`, `bugfix`
- **Proyecto por defecto:** `dotfiles-dizzi`
- **Scope:** `personal` (por defecto para perfil usuario), `project` (para arquitectura/config), `global` (raramente)

---

## Referencias Rápidas

- **Engram bin:** `~/dotfiles-dizzi/home/.local/bin/engram`
- **Helper JSCamp:** `~/dotfiles-dizzi/home/.local/bin/jscamp-memory`
- **OpenCode MCP config:** `~/.config/opencode/opencode.json` → `"mcp": { "engram": { "command": "engram", "args": ["mcp"] } }`
- **Engram DB:** `~/.local/share/engram/` (SQLite + FTS5)
- **CLI setup:** `engram setup opencode` → reiniciar OpenCode