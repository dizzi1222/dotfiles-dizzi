# Hermes + Antigravity CLI (`agy`)

## 1. Delegar tareas a `agy` — opción habitual

La [skill oficial `antigravity-cli`](https://hermes-agent.nousresearch.com/docs/user-guide/skills/optional/autonomous-ai-agents/autonomous-ai-agents-antigravity-cli) permite que Hermes opere `agy` como agente externo sin cambiar su propio proveedor. No es un subagente nativo y no aparece en `/agents`.

```bash
hermes skills install official/autonomous-ai-agents/antigravity-cli
agy --sandbox --print 'Responde exactamente: HERMES_AGY_OK. No uses herramientas.'
```

Puedes pedirle a Hermes: «Usa la skill `antigravity-cli` para delegar esta revisión de solo lectura y devuélveme el resultado». Sin `--model`, se deja la selección al CLI; para fijar un modelo, consulta `agy models` y pásale `--model` con el identificador correspondiente. El login se gestiona en `agy`.

**Progreso:** una llamada normal desde Hermes devuelve la salida al terminar. Para seguirla durante la ejecución, ejecuta `agy` en segundo plano desde Hermes y consulta los logs del proceso; `--output-format stream-json` expone eventos si necesitas procesarlos. La skill no añade un panel de progreso.

El escáner marcó una receta de instalación `curl | bash` en la referencia de la skill. No hace falta ejecutarla: `agy` ya está instalado. Evita saltarte las aprobaciones.

## 2. Usar `agy` como proveedor de modelos — instalado, desactivado

[`antigravity-agy`](https://hermes-agent.nousresearch.com/marketplace/antigravity-agy) usa el CLI oficial para inferencia con la cuenta de Antigravity ya autenticada. Hermes selecciona el modelo y ejecuta las herramientas. Transmite texto en vivo, no el progreso de un subagente. No requiere la skill de arriba ni el puente ACP de terceros.

```bash
hermes plugins install antigravity-agy --no-enable --no-deps
hermes plugins disable antigravity-agy
hermes plugins list --plain --no-bundled | grep antigravity-agy
```

Comprueba que la fila diga `disabled`: en esta instalación, el mensaje del instalador decía «not enabled», pero la lista mostró `enabled` hasta desactivarlo explícitamente.

El [repositorio del plugin](https://github.com/Realtyxxx/hermes-plugin-antigravity-agy) está archivado. Mantenerlo desactivado evita usar una integración sin mantenimiento que puede truncar el contenido más reciente en conversaciones largas. Si algún día lo habilitas deliberadamente en un entorno de prueba, elige el proveedor y el modelo explícitamente en una consulta puntual (`hermes chat --provider antigravity-agy --model … -q '…'`) sin cambiar el proveedor por defecto. Revisa antes los términos de tu cuenta y los efectos del plugin sobre los procesos y registros locales de `agy`.

## Estado verificado en este equipo

- Hermes 0.23.2 y `agy` 1.5.12. El `initialize` de ACP v1 con `agy acp --sandbox` respondió correctamente; no fue una prueba de inferencia autenticada.
- Skill `antigravity-cli` instalada. Plugin `antigravity-agy` 0.1.0 (`f85003d3`) instalado y verificado como `disabled`, sin instalar dependencias ni cambiar el proveedor por defecto.
