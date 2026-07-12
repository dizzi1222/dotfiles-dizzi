---
name: Refactorización y Corrección de Código (REFACTOR)
about: Estandar para refactorizar, corregir y mejorar código de otros desarrolladores, integrándolo a dev de forma definitiva después de aplicar mejoras estructurales, correcciones de bugs y alineación con los estándares del proyecto.
title: '[REFACTOR] Módulo o rama origen — Descripción del refactor'
labels: refactor
assignees: ''
---

## Descripción

Refactorización de código proveniente de ramas de trabajo de otros desarrolladores. Se toma el código existente, se analiza, se corrigen bugs, se mejora la estructura y se integra a `dev` de forma definitiva.

## Metodología

| Paso | Descripción | Ejemplo |
|---|---|---|
| **1. Analizar** | Revisar la rama origen: identificar bugs, code smells, dependencias faltantes, estilos inconsistentes | Revisar `feat-pt` o `auth-roles` de Ryan |
| **2. Crear rama base** | Crear rama desde `dev` (o desde fix si hay múltiples cambios) | `fix/roles-segun-mvp` desde `dev` |
| **3. Refactorizar** | Aplicar correcciones: tipados, seguridad, patrones, estructura, dependencias | Arreglar `getRawOne()` con prefijos `User_`, agregar `IF NOT EXISTS` en migraciones |
| **4. Probar** | Verificar que lo original sigue funcionando + las mejoras no rompen nada | Login, Google OAuth, roles |
| **5. Mergear** | La rama refactorizada se mergea a `dev` como la versión definitiva | `fix/roles-segun-mvp` → `dev` |

## Criterios de Refactorización

### Seguridad
- [ ] SQL injection: usar parámetros, no concatenación
- [ ] Autenticación: validar sesión en cada endpoint protegido
- [ ] Contraseñas: hasheadas con bcrypt, no almacenadas en plano
- [ ] Roles: verificar autorización por rol, no solo existencia de sesión

### Estructura y Calidad
- [ ] Tipados correctos (TypeScript, interfaces, DTOs)
- [ ] Nomenclatura consistente con el proyecto (prefijos `User_`, PascalCase en enums)
- [ ] Código muerto eliminado (variables, imports, funciones sin usar)
- [ ] Consultas a BD optimizadas (select explícito, evitar N+1)

### Compatibilidad
- [ ] La rama refactorizada es compatible con `dev` sin conflictos mayores
- [ ] Migraciones existentes no se modifican (solo se agregan nuevas si es necesario)
- [ ] Frontend y backend siguen comunicándose (mismos endpoints, mismos formatos de respuesta)

## Ramas involucradas

- **Rama(s) origen:** (ej: `feat-pt`, `auth-roles`)
- **Rama de refactor:** (ej: `fix/roles-segun-mvp`)
- **Rama destino:** `dev`

## Archivos afectados

Listar los archivos modificados durante la refactorización:

| Archivo | Cambio |
|---|---|
| `src/controllers/auth.controller.ts` | Se agregó login por credenciales + bloqueo por intentos |
| `src/libs/passport.ts` | Se corrigió deserialización con prefijos User_ |
| ... | ... |

## Lecciones Aprendidas

Documentar hallazgos importantes durante el refactor para referencia futura.

Ejemplo:
- `getRawOne()` devuelve columnas con prefijo del alias (`User_rol`, `User_password`)
- `ALTER TABLE ADD COLUMN` sin `IF NOT EXISTS` rompe si la columna ya existe
- `ON CONFLICT DO NOTHING` no actualiza registros existentes; usar `DO UPDATE SET`
- Las migraciones de TypeORM se ejecutan en orden de timestamp
