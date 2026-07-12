---
name: Comentarios Seccionales (Section Headers)
about: Estandarizar el uso de comentarios con títulos breves para orientar la lectura del código, siguiendo el estilo //SectionTitle utilizado en app.ts.
title: 'docs: agregar/seccionar comentarios en [módulo/archivo]'
labels: documentation
assignees: ''
---

## Descripción

Aplicar comentarios de tipo **section header** (`//SectionTitle`) en los archivos indicados para facilitar la lectura del código, especialmente para revisiones de QA y nuevos desarrolladores.

## Metodología

| Regla | Descripción |
|---|---|
| **Formato** | `//SectionTitle` — sin punto final, con mayúscula inicial |
| **Frecuencia** | Máximo 1 comentario cada ~50 líneas |
| **Necesidad** | Solo donde aporte claridad (no en obviedades) |
| **Ubicación** | Inmediatamente antes del bloque lógico que introduce |
| **Referencia** | Estilo usado en `app.ts`: `//Settings`, `//session Settings`, `//routes` |

## Criterios para agregar un comentario

Preguntar antes de cada comentario:
- ¿Este bloque hace algo no obvio?
- ¿Un desarrollador nuevo entendería el flujo sin este comentario?
- ¿Hay más de 30 líneas desde el último comentario?

Si la respuesta es "sí" a cualquiera de las dos primeras o "sí" a la tercera, agregar el comentario.

## Ejemplos

### Bien (sigue el estándar)

```typescript
// Google OAuth
export const googleAuth = passport.authenticate('google', { ... })

// Login por credenciales
export async function loginCredentials(req, res) { ... }

// Bloqueo por intentos fallidos
if (attempts >= 5) { ... }

// Cierre de sesión
export async function logout(req, res) { ... }

// Obtener usuario autenticado
export function getMe(req, res) { ... }
```

### Mal (no sigue el estándar)

```typescript
// Esto es el login de Google xd
export const googleAuth = ...

// -----------------------------------------------------------------
// BLOQUE: AUTENTICACIÓN
// -----------------------------------------------------------------
export async function loginCredentials(...) { ... }

const x = 1 // asignar 1 a x   ← comentario obvio, no aporta
```

## Archivos que NO necesitan comentarios seccionales

- Scripts utilitarios (`src/scripts/`)
- Migraciones de BD (`src/migrations/`)
- Archivos de rutas/endpoints con pocas líneas
- Componentes de menos de 40 líneas y autoexplicativos
- `package.json`, configs
- Archivos que ya siguen el estándar

## Checklist

- [ ] Los comentarios usan formato `//SectionTitle`
- [ ] No hay más de 1 comentario por cada ~50 líneas
- [ ] Cada comentario está justificado (aporta claridad)
- [ ] No se comentaron obviedades
- [ ] Ningún archivo de la lista de excluidos fue modificado
