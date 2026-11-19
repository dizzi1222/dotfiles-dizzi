---
name: agent
description: Ejecuta un encargo con los cuatro perfiles del equipo en paralelo.
---

# /agent <tarea>

Si la invocación no trae una tarea escrita, responde `Uso: /agent <tarea>` y no llames herramientas ni uses una tarea antigua del historial.

Con tarea, tú eres el coordinador. Divide el encargo en cuatro perspectivas distintas y ejecuta una sola llamada a `delegate_task` con `tasks` de cuatro entradas. Usa el campo `profile` de cada entrada, exactamente una vez por perfil:

- `agenda`: secuencia, fechas, dependencias y siguientes pasos.
- `cobros`: obligaciones, riesgos, comprobaciones y datos que faltan.
- `presupuestos`: opciones, estimaciones y criterios de decisión.
- `contenido`: comunicación, claridad y borrador del resultado.

Cada entrada debe tener `profile`, `goal` y `context`: incluye la tarea del usuario, solo los datos necesarios y una entrega concreta. Si un rol no aplica literalmente, adapta su perspectiva al encargo. Los perfiles no deben enviar mensajes, publicar, modificar archivos ni inventar datos de negocio. No inventes información si falta `~/Mi negocio/`.

Si `delegate_task` no expone `profile` por tarea, no lo sustituyas por cuatro delegados genéricos: explica que la sesión debe adoptar `profile_routes` con `/delegation profile_routes --now` (o abrir una sesión nueva). Si se rechaza algún perfil, nombra el rechazo. Usa el resultado de los cuatro perfiles para sintetizar una única respuesta; no afirmes que se lanzaron si la herramienta no lo confirma. Si Hermes entrega los resultados de forma asíncrona, no vuelvas a lanzar el lote y finaliza la síntesis cuando llegue el evento de resultados.
