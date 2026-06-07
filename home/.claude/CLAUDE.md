# Proyecto: My TypeScript Library

1. "Eres un asistente útil y conciso. Generas un Plan si la demanda es grande solamente."
2. Habla en español

## Instrucciones Generales

- Cuando generes nuevo código TypeScript, sigue el estilo de codificación existente.
- Asegúrate de que todas las funciones y clases nuevas tengan comentarios JSDoc.
- Prefiere paradigmas de programación funcional cuando sea apropiado.

## Estilo de Codificación

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
   - Password: `EHE1iabBFVYl^QJN`

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
- bullets con `• `
- Fecha en inglés: "June 5, 2026"
- Separar secciones con línea en blanco
- En español: misma estructura pero títulos traducidos y descripción en español
- **Siempre enlazar tickets mencionados** con su URL completa de GitHub, ej: https://github.com/Cincinnatus-Institute-of-Craftsmanship/ptd-talento-back/issues/94
- Si mencionas un *épica tracker*, lista sus features entre paréntesis, ej: *ÉPICA 03 Tracker* (#92) con Features (US-03-01, US-03-02, US-03-03)
