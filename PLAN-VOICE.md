# Plan — Reparar voz en OpenCode y AGY (Termux/Android)

Estado: diagnóstico cerrado, listo para ejecutar.
Últimos commits revisados: `6625fdcb`, `027eee83`, `7e7ab8ff`, `ee41e1e5`.

---

## 1. Evidencia recogida (reproducible)

| # | Comprobación | Resultado |
|---|---|---|
| 1 | `pm list packages \| rg termux` | `com.termux`, `com.termux.boot`, `com.termux.widget` — **falta `com.termux.api`** |
| 2 | `timeout 12 termux-microphone-record -f t.aac -l 3` | `exit=124` (se cuelga) → no hay quien grabe |
| 3 | `~/.config/opencode/cli.json` | `"plugins": []` → el plugin `voice` **no se carga** |
| 4 | `dotfiles/opencode/.config/opencode/cli.json` | `"plugins": ["/var/home/diego/dotfiles-dizzi/..."]` → ruta de la **laptop Linux**, no existe en Termux |
| 5 | `opencode/.config/opencode/plugins/voice/` | no hay `package.json` → un plugin local por ruta no resuelve `./tui` |
| 6 | `plugins/voice/tui.tsx` | `execFileSync` **sin importar**; ffmpeg async usado como sync; ruta `/var/home/diego/.local/bin/opencode-voice`; `pw-record --version` con `try/catch` (execFile no lanza); **no escribe la transcripción en el prompt** |
| 7 | `strings agy.va39` | `audio.hostCapture.read`, `audio.(*Recorder).Stream/pump/containsAudio`, `"No microphone recorder found … arecord … pw-record"`, `"No audio player found … pw-cat/paplay/aplay"` → AGY espera **PCM continuo por stdout** |
| 8 | `local/.local/bin/arecord` | graba a `.m4a`, espera `SIGINT` y **solo entonces** transcodea y vuelca → AGY no recibe audio mientras hablas |
| 9 | `local/.local/bin/aplay` | `sys.stdin.buffer.read()` → espera **EOF** antes de reproducir → respuestas del modelo mudas |

## 2. Causas raíz

1. **Bloqueo externo:** la app `Termux:API` no está instalada en el dispositivo. Sin ella
   `termux-api` no responde y ningún bridge puede capturar micrófono.
   (El contexto dice que se instaló; la evidencia actual dice que no está o se desinstaló.)
2. **AGY (síntoma "sale /voice pero no responde"):** los bridges no son streaming.
   AGY abre `arecord`, lee PCM y detecta voz (`containsAudio`); nuestro wrapper no emite
   nada hasta detener la grabación → el motor de voz recibe silencio/ ráfaga final y no
   contesta. La reproducción (`aplay`) tampoco es streaming → la conversación no suena.
3. **OpenCode (`/voice` no responde):** el plugin no se carga (plugins vacío + ruta Linux
   + falta `package.json`) y, aunque cargara, falla en runtime (`execFileSync` indefinido,
   WAV inexistente, ruta hardcodeada) y nunca envía el texto al prompt/sesión.

## 3. Plan de ejecución

### Fase 0 — Desbloqueo (usuario, ~5 min)
1. Instalar **Termux:API** desde el **mismo origen** que Termux:
   - Termux de F-Droid → Termux:API de F-Droid.
   - Termux de GitHub → APK de GitHub Releases (misma firma).
2. Ajustes Android → Apps → Termux:API → Permisos → **Micrófono: Permitir**.
3. Verificación: `pm list packages | grep com.termux.api` y `termux-microphone-record -i`
   debe responder al instante (no colgarse).

> Alternativa si no se puede instalar: `agy mic-serve` en otra máquina + `voice-engine-addr`
> apuntando a esa IP (solo AGY; OpenCode seguiría sin micrófono local).

### Fase 1 — OpenCode: plugin `/voice` funcional y conversacional
Archivos:
- `opencode/.config/opencode/plugins/voice/package.json` (nuevo)
  ```json
  { "name": "opencode-voice", "type": "module", "exports": { ".": "./tui.tsx", "./tui": "./tui.tsx" },
    "dependencies": { "@opencode/plugin": "latest" } }
  ```
- `opencode/.config/opencode/cli.json` (dotfiles) y `~/.config/opencode/cli.json` (Termux):
  registrar el plugin con **ruta portable** (`$HOME/...` no se expande en JSON → usar
  ruta real de Termux `~/.config/opencode/plugins/voice`) y mantener `plugins` no vacío.
- `opencode/.config/opencode/plugins/voice/tui.tsx` (reescritura):
  - `execFile` promisificado para `pw-record`/bridge y `ffmpeg` (sin `execFileSync`).
  - Resolver binario: `$HOME/.local/bin/opencode-voice` → fallback `opencode-voice` en `$PATH`.
  - Grabar PCM crudo 16 kHz mono; al parar: convertir a WAV y transcribir con
    `opencode-voice transcribe`.
  - **Enviar la transcripción al prompt y enviarlo** para que el agente responda:
    `context.client.tui.appendPrompt({ body: { text } })` + `submitPrompt()`
    (si el server V2 sólo expone eventos: `tui.prompt.append` / `tui.command.execute`).
  - Toasts con la API real (`context.ui.toast.show`), sin `console.error` silencioso.
  - Keybinds F6 (grabar/parar), F7 (mute), F8 (push-to-talk), comando `/voice`.

Verificación:
- `bun build opencode/.config/opencode/plugins/voice/tui.tsx --target bun` sin errores.
- `~/voice` aparece en la paleta/slash de OpenCode y el toast "Grabando" sale al ejecutarlo.
- Con un WAV sintético: `opencode-voice transcribe muestra.wav` devuelve texto.
- Prueba real: decir "hola" → el texto aparece en el prompt y el agente responde.

### Fase 2 — AGY: bridges streaming (entrada y salida)
Archivo: `local/.local/bin/arecord` (+ symlink `pw-record`)
- Reemplazar "grabar todo y volcar al final" por streaming real:
  - Bucle de segmentos cortos (1 s) con `termux-microphone-record` (AAC/AMR),
    decodificar cada segmento cerrado con ffmpeg y escribir `s16le 16k mono` a stdout
    de inmediato; repetir hasta SIGINT/SIGTERM.
  - Mantener el parseo tolerante de flags de ALSA (`-r -c -f -t -D -q`) y el log de
    diagnóstico (`$TMPDIR/arecord_calls.log`).
  - Si `termux-api` no responde: salir con error claro en stderr (no colgarse).
- `local/.local/bin/aplay` (+ `paplay`, `pw-cat`): reproducir en streaming
  (chunks ~0,5 s → WAV → `termux-media-player play`), sin esperar EOF; cortar al recibir
  SIGINT o al cerrar stdin.

Verificación:
- `arecord | while read…` con cronómetro: deben llegar bytes **antes** de 1,5 s (hoy: 0).
- `aplay < wav` reproduce sin esperar a que termine la entrada.
- En AGY: `/voice` → hablar → el prompt recibe texto; `/voice live` (F6) → el modelo
  responde por el altavoz y la conversación continúa.

### Fase 3 — Instalador + memoria + commit
- Actualizar `home/termux-basic-setup.sh` (PASO 22d):
  - copiar bridges nuevos,
  - comprobar `com.termux.api` **antes** de dar el paso por bueno,
  - mensaje de error explícito si falta la app,
  - `voice-engine-addr: "default"` + `voice.start_dictation: ["f5"]` (ya existe).
- `bash -n home/termux-basic-setup.sh`.
- Commit en `termux` + push, y guardar en Engram.

## 4. Criterios de aceptación
1. `pm list packages` incluye `com.termux.api` y `termux-microphone-record -i` responde <2 s.
2. `arecord` emite PCM en menos de 1,5 s desde el arranque (medido con `wc -c` en bucle).
3. `aplay` suena sin cerrar stdin.
4. En AGY, `/voice` produce texto en el prompt y `/voice live` mantiene la conversación.
5. En OpenCode, `/voice` muestra toast, transcribe y **envía** el mensaje (el agente responde).
6. `bun build` del plugin y `bash -n` del instalador sin errores.
7. Commit pusheado a `origin/termux`.

## 5. Riesgos
- **Latencia de micrófono:** los segmentos de 1 s añaden ~0,3–1 s; si AGY corta por VAD,
  bajar a 0,5 s o usar AMR crudo incremental.
- **API de plugin OpenCode:** la versión instalada (`@opencode-ai/plugin@1.19.3`) expone
  `TuiPlugin` como función y `keymap.registerLayer`; el commit usó la API V2
  (`Plugin.define`). Se implementará contra la API del runtime y se validará con
  `bun build` + carga real del plugin.
- **Firma del APK:** instalar Termux:API de un origen distinto a Termux falla; usar el mismo.
