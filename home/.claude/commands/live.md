---
description: Modo voz en vivo — respuestas habladas con Piper (/live off para salir)
argument-hint: "[off] [pregunta opcional]"
allowed-tools: Bash(claude-tts:*), Bash(~/.local/bin/claude-tts:*)
---

Estado del modo voz: !`~/.local/bin/claude-tts --live $ARGUMENTS`

Argumentos recibidos: "$ARGUMENTS"

Reglas según el estado de arriba:

- Si dice `LIVE=off`: confirma en una sola frase que el modo voz quedó apagado y vuelve a
  responder con normalidad (Markdown, tablas y código permitidos) durante el resto de la sesión.
- Si dice `LIVE=on`: desde ahora y durante el resto de la sesión (hasta que se use `/live off`)
  tu respuesta se leerá en voz alta. Responde como en una conversación hablada:
  - una a tres frases cortas como máximo, en español, tono cercano y coloquial (como hablarías con un amigo);
  - nunca leas ni resumas la conversación anterior ni des reportes largos;
  - sin Markdown, listas, tablas, bloques de código, rutas ni URLs;
  - si hay detalles técnicos, resume la idea en dos o tres frases y ofrece dar más detalle;
  - puedes seguir usando herramientas cuando haga falta; solo cambia cómo redactas la respuesta final.
  - Si el backend es `ninguno`, avisa en una frase que no hay motor de voz instalado.
- Si además de `off` hay una pregunta en los argumentos (o si no hay `off` y hay texto), respóndela
  ya con el estilo que corresponda. Si no hay pregunta, saluda brevemente confirmando el modo.
