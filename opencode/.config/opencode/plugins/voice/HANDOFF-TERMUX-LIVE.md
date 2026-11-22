# Handoff → Termux: /live que "habla" + diagnóstico real de faster-whisper

> Para el agente que trabaje en la rama `termux`. Origen: commit en `main`
> (Bazzite), ya cherry-pickeado a `cachyos` y `nixos`. **Termux NO recibe
> cherry-pick**: su `tui.tsx` y `opencode-voice` divergen (arecord, shebang
> `/data/data/...`, proot, `AUDIO_ENV`). Recicla la **idea**, no el diff.

## Por qué no cherry-pick

Un cherry-pick anterior entre ramas metió rutas de otra plataforma
(`/var/home` de Bazzite, `/data/data` de Termux) y JSON roto. Regla:

- Termux usa `$PREFIX` / `$HOME` de Termux; **nunca** `/var/home` ni `/home/diego`.
- No toques la lógica Termux existente: grabación con `arecord`, `AUDIO_ENV`
  sin `LD_LIBRARY_PATH`, `stdin.end()` del servidor whisper bajo proot,
  `TMPDIR` del doctor, toasts con stderr del grabador.

## Cambio 1 — /live responde en "modo voz" (opción A)

**Problema:** /live leía el Markdown literal con eSpeak ("bloque de código
omitido", listas, rutas…). Suena a lectura, no a conversación.

**Idea:** antes de enviar el texto dictado en /live, anteponer una instrucción
para que el modelo conteste ya en estilo hablado. F4 "Transcribir" no cambia.

En `plugins/voice/tui.tsx`, justo encima de `submitTranscript`:

```ts
/** Instrucción que convierte la respuesta de Live en habla natural (OPENCODE_LIVE_STYLE=0 la desactiva). */
const LIVE_SPOKEN_STYLE = "[modo voz: tu respuesta se leerá en voz alta. Responde como en una conversación hablada: " +
  "frases cortas y naturales, sin Markdown, listas, tablas, código, rutas ni URLs. Si hay detalles técnicos, " +
  "resume la idea en dos o tres frases y ofrece dar más detalle. Igual puedes usar herramientas si hace falta.]"

/** Antepone el estilo hablado al texto dictado en Live. */
function withLiveSpokenStyle(text: string): string {
  return process.env.OPENCODE_LIVE_STYLE === "0" ? text : `${LIVE_SPOKEN_STYLE}\n\n${text}`
}
```

Y **solo** en la llamada de Live (la que pasa `sessionID` explícito, dentro del
listener Live — no la de F4):

```ts
await submitTranscript(context, withLiveSpokenStyle(text), sessionID)
```

Notas:

- `live.pendingTranscript` sigue guardando el texto **sin** prefijo (memoria
  de la conversación limpia).
- El fallback ACP (`agy`) ya tenía su propia instrucción conversacional; no
  hace falta tocarlo.
- Limitación conocida: el prefijo se ve en el chat. El SDK TUI
  (`client.session.prompt({ sessionID, text })`) no acepta `system`; ocultarlo
  requeriría un plugin de servidor.
- En Termux el TTS es `termux-tts-speak`, así que el beneficio es igual o mayor
  (la voz de Android lee peor los símbolos).

## Cambio 2 — el error de faster-whisper deja de ser genérico

**Problema:** el plugin mostraba siempre
"Actualiza opencode-voice y su helper juntos…" porque esperaba stderr con
prefijo `STT faster-whisper:` y `opencode-voice` imprimía
`STT faster-whisper no disponible.` (sin `:`). Además se descartaba el JSON
de `voice-stt-faster-whisper.py --check` y el timeout era corto (20 s).

En `local/.local/bin/opencode-voice`:

1. `let fasterWhisperFailure = ""` junto a `let fasterWhisperInstalled`.
2. En `fasterWhisperReady()`: `timeout: 60000` y, si falla, guardar el motivo:

   ```ts
   if (!fasterWhisperInstalled) {
     let reason = result.error?.message || (result.signal ? `terminado por ${result.signal} (¿timeout?)` : "")
     try { reason = JSON.parse(result.stdout.trim().split(/\r?\n/).pop() ?? "").error || reason } catch {}
     fasterWhisperFailure = reason || String(result.stderr ?? "").trim().split(/\r?\n/).pop() || `exit ${result.status}`
   }
   ```

3. En `case "check-stt"`:

   ```ts
   console.error(`STT faster-whisper: no disponible (${existsSync(helper) ? fasterWhisperFailure : "falta el helper"}). Python: ${python.executable}`)
   ```

En `tui.tsx`, `checkVoiceStt()`:

```ts
await runVoice(["check-stt"], { timeout: 70000 })
} catch (error) {
  const failure = error as { stderr?: string; message?: string; killed?: boolean }
  const detail = String(failure.stderr ?? "").trim()
  if (detail.startsWith("STT faster-whisper")) throw new Error(detail)
  const reason = failure.killed ? "timeout del check-stt" : detail || failure.message || "sin detalle"
  throw new Error(`No pude comprobar faster-whisper: ${reason}`)
```

Termux: el timeout de 60/70 s importa más (proot + CPU del móvil arranca lento).

## Verificación en Termux

```sh
cd ~/dotfiles-dizzi
git diff -- opencode/.config/opencode/plugins/voice/tui.tsx local/.local/bin/opencode-voice \
  | grep -nE '^\+.*(/var/home|/home/diego)'        # debe salir vacío
bun build opencode/.config/opencode/plugins/voice/tui.tsx --target=bun --external '*' --outfile=/dev/null
opencode-voice check-stt; echo "exit=$?"            # 0 = OK
OPENCODE_VOICE_PYTHON=/nope opencode-voice check-stt # debe mostrar la causa real
```

Luego: reiniciar OpenCode → `/live` → preguntar algo técnico → debe responder
en 2-3 frases habladas, sin leer símbolos.

## Pendiente (no hacer aún)

- **Opción B**: respuesta normal + reescritura a texto hablado con un modelo
  rápido antes del TTS (más natural en respuestas largas; añade latencia).
- **F4 lento** (Bazzite): cuBLAS 12 falta → CUDA falla y recarga en CPU en cada
  pulsación. En Termux no aplica (no hay CUDA); allí convendría reusar el
  servidor whisper entre pulsaciones de F4.
