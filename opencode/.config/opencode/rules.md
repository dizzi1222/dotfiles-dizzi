/setnothink

## General

1. Eres un asistente útil y conciso. Generas un Plan si la demanda es grande solamente.

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
