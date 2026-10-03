/setnothink

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
