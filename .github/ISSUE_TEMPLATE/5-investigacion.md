---
name: Investigación (INV)
about: Ticket utilizado para analizar comportamientos extraños, inconsistencias o situaciones no esperadas dentro del sistema que requieren validación técnica para determinar su causa y confirmar si representan un bug, fallo funcional o comportamiento esperado.
title: '[INV] Nombre de lo que se investiga'
labels: investigation
assignees: ''
---

## Módulo o Feature relacionada

Indica el sistema, módulo, User Story o funcionalidad donde se detectó el comportamiento extraño.

[Epic] + [User Story ID] + [Feature o módulo]

## Descripción de la Investigación

Explica qué comportamiento inusual, inconsistencia o situación necesita analizarse.

Este ticket se utiliza cuando:
- Algo no cuadra técnicamente
- Existe un comportamiento inesperado
- Se necesita validar lógica interna
- Se requiere entender por qué ocurre un problema

## Comportamiento Observado

Describe exactamente qué ocurre actualmente.

Ejemplo:
- Redirecciones incorrectas
- Datos incorrectos
- Respuestas inesperadas
- Fallos intermitentes
- Diferencias entre frontend y backend

## Hipótesis Iniciales

Posibles causas identificadas preliminarmente antes de completar la investigación.

Ejemplos:
- Problemas de middleware
- Validaciones incompletas
- Fallo de conexión API
- Errores de sesión

## Pasos para Reproducir

Documenta cómo volver a generar el comportamiento observado.

## Evidencias

Incluye:
- Screenshots
- Logs
- Respuestas API
- Videos
- Errores de consola
- Referencias técnicas

## Resultado de la Investigación

Documenta los hallazgos obtenidos después del análisis.

Debe responder:
- ¿Qué causa el problema?
- ¿Realmente existe el bug?
- ¿O el comportamiento es esperado?

## Validación QA / Desarrollo

Espacio para confirmar:
- Si QA valida el issue
- Si desarrollo confirma el problema
- O si se descarta como comportamiento esperado

## Impacto

Explica cómo afecta el comportamiento al sistema, usuario o flujo funcional.

## Notas

Información adicional, referencias técnicas o decisiones tomadas durante la investigación.
