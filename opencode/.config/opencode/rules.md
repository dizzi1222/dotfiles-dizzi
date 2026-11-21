/setnothink

## Fuente Única de Verdad (CLAUDE.md)

> **Instrucciones completas y detalladas:** `~/.claude/CLAUDE.md` (fuente en `~/dotfiles-dizzi/home/.claude/CLAUDE.md`).
> Si una instrucción, regla de arquitectura, git, estilo de código o workflow no está detallada aquí, la referencia canónica es `CLAUDE.md`.

## Engram Index & Memoria Persistente

> **Índice central:** `~/dotfiles-dizzi/ENGRAM_INDEX.md`  
> **Memoria consolidada Diego:** Project `dotfiles-dizzi`, topic_key `profile/diego-consolidated`, observación **#164** (archive: `~/dotfiles-dizzi/home/memoria_diego.zip`).

- **CLI:** `engram search "profile/diego-consolidated" --project dotfiles-dizzi`
- **OpenCode MCP:** `await mem_search({ query: "profile diego", project: "dotfiles-dizzi" })` y `await mem_get_observation({ id: 164 })`
- **Contexto de sesión:** `await mem_context({ project: "dotfiles-dizzi" })`

## General

1. Eres un asistente útil y conciso. Generas un Plan si la demanda es grande solamente.

## Seguimiento Visual (obligatorio)

Después de cada tanda de `edit`/`write`, ejecuta `oc-open <archivo>:<línea>` por cada
archivo modificado, para que Diego vea el cambio en su Neovim mientras lo implemento.

- `/open <archivo>:<línea>` — comando de opencode que hace lo mismo
- Doc completa (mecanismo lazygit + `$NVIM`): `~/.claude/CLAUDE.md` → "Seguimiento Visual"

## GitHub Issues — Formato de Tickets

Al crear o editar issues en GitHub, usa las plantillas en `~/.config/opencode/templates/` según el tipo:

| Tipo | Archivo | Referencia |
|------|---------|------------|
| **Épica** | `templates/epic.md` | #92 |
| **Feature** | `templates/feature.md` | #95, #96, #97 |
| **Bug** | `templates/bug.md` | #87 |

Reglas del formato:
- Los Issues Relacionados van con `- #N` (GitHub auto-linkea)
- Features usan prefijo `[Feature] ~ [ÉPICA N] - US-N-M: desc`
- Bugs usan prefijo `[Bug] - Módulo - desc`
- Estados en tablas: ✅ / ❌ / ⚠️
- Metadata siempre al inicio: `**Parent:**`, `**Branch:**`, `**Depende de:**`
