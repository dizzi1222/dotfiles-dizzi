# Google ChatSpace Format — PTD-Talento Daily

Formato estandarizado para enviar daily reports al ChatSpace del equipo.

## Estructura

```
*Team:* PTD-Talento
*Member:* Diego Samuel Hardi Santana, Software Development
*Date:* July 21, 2026

*What I have done since the last DR:*

• [bullet point]

*What I will do until the next DR:*

• [bullet point]

*Impediments:*

• [None / descripción]
```

## Reglas de Formato

### Negritas (`*texto*`)

Usar `*asteriscos simples*` para negritas. Ejemplo:

```
• *Backend* PR #124 merged
• *Frontend* conflictos resueltos con *reverse merge*
```

### Código / Ramas / Commits (`` `texto` ``)

Usar backticks para ramas, commits, comandos y cualquier referencia técnica:

```
• Rama: `feat/auth-roles`
• Commit: `6ef288f`
• Comando: `git merge dev -X ours`
• *Branch* `feat/auth-roles` → `dev`
```

### Bullets (`•`)

Cada ítem debe empezar con `•` (bullet Unicode). No usar guiones ni asteriscos.

```
• Ítem correcto
- Ítem incorrecto
* Ítem incorrecto
```

### Títulos / Headers (`*Texto:*`)

Los títulos de sección se escriben con asteriscos al inicio Y dos puntos al final:

```
*What I have done since the last DR:*
```

No usar `##` ni `###` (ChatSpace no renderiza markdown de headers).

### Fecha

Formato en inglés: `[Month] [Day], [Year]` — ej. `July 21, 2026`.

### Separación entre secciones

**Siempre** dejar una línea en blanco entre secciones (título → blank → bullets → blank → next title).

```
*What I have done since the last DR:*

• Ítem 1
• Ítem 2

*What I will do until the next DR:*

• Ítem 1
```

### Enlaces a Tickets

Siempre usar la URL completa. No usar markdown `[texto](url)` — pegar la URL directamente.

✅ Correcto: `• PR #88: https://github.com/.../pull/88`
❌ Incorrecto: `• PR #88`

### Épicas y Features

Cuando menciones una épica tracker, listar sus features entre paréntesis:

```
• *ÉPICA 03 Tracker* (#92) con Features (US-03-01, US-03-02, US-03-03)
```

### Tabla resumen de sintaxis

| Elemento       | Sintaxis ChatSpace          | Ejemplo                          |
|----------------|-----------------------------|-----------------------------------|
| Negritas       | `*texto*`                   | `*Backend* merged`               |
| Bullet         | `• `                        | `• Item`                         |
| Título sección | `*Texto:*`                  | `*What I did:*`                  |
| Código         | `` `texto` ``               | `` `feat/auth-roles` ``           |
| Enlace         | URL directa                 | `https://github.com/...`         |
| Separación     | línea en blanco             | `[bullet]\n\n*Title:*`          |
| Fecha          | Month DD, YYYY              | `July 21, 2026`                 |
