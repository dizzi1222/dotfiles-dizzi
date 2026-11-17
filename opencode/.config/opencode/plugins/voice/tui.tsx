import { Plugin } from "@opencode/plugin/tui"
import { basename, join } from "node:path"
import { pathToFileURL } from "node:url"
import { randomUUID } from "node:crypto"
import { existsSync, mkdirSync, readFileSync, renameSync, statSync, unlinkSync } from "node:fs"
import { execFile } from "node:child_process"
import { promisify } from "node:util"
import { homedir } from "node:os"

const run = promisify(execFile)

const PREFIX = process.env.PREFIX ?? "/data/data/com.termux/files/usr"
const AUDIO_ENV = { ...process.env }
delete AUDIO_ENV.LD_LIBRARY_PATH
const TMP_DIR = join(process.env.TMPDIR || join(PREFIX, "tmp"), "opencode-voice")
const RAW_PATH = join(TMP_DIR, "record.raw")
const WAV_PATH = join(TMP_DIR, "record.wav")
const IMAGE_PICKER_TIMEOUT_MS = 90000
const MAX_IMAGE_BYTES = 20 * 1024 * 1024

type Runtime = {
  proc: import("node:child_process").ChildProcess | null
  recording: boolean
  startedAt: number
  lastText: string
}

const state: Runtime = { proc: null, recording: false, startedAt: 0, lastText: "" }

function findVoiceBinary(): string | null {
  const candidates = [
    process.env.OPENCODE_VOICE_BIN,
    join(homedir(), ".local/bin/opencode-voice"),
    "/data/data/com.termux/files/usr/bin/opencode-voice",
  ].filter(Boolean) as string[]
  for (const candidate of candidates) {
    if (existsSync(candidate)) return candidate
  }
  return null
}

function findRecorder(): string {
  // En Termux el bridge arecord traduce ALSA -> Termux:API; pw-record es un symlink.
  for (const name of ["pw-record", "arecord"]) {
    const prefix = process.env.PREFIX ?? "/data/data/com.termux/files/usr"
    if (existsSync(join(prefix, "bin", name))) return join(prefix, "bin", name)
    if (existsSync(join("/usr/bin", name))) return join("/usr/bin", name)
  }
  return "pw-record"
}

function findFfmpeg(): string {
  const prefix = process.env.PREFIX ?? "/data/data/com.termux/files/usr"
  if (existsSync(join(prefix, "bin", "ffmpeg"))) return join(prefix, "bin", "ffmpeg")
  return "ffmpeg"
}

/** Detecta los formatos de imagen que OpenCode adjunta como contenido visual. */
function detectImageType(bytes: Buffer): { mime: string; extension: string } | null {
  if (bytes.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]))) {
    return { mime: "image/png", extension: "png" }
  }
  if (bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff) {
    return { mime: "image/jpeg", extension: "jpg" }
  }
  const gif = bytes.toString("ascii", 0, 6)
  if (gif === "GIF87a" || gif === "GIF89a") {
    return { mime: "image/gif", extension: "gif" }
  }
  if (bytes.toString("ascii", 0, 4) === "RIFF" && bytes.toString("ascii", 8, 12) === "WEBP") {
    return { mime: "image/webp", extension: "webp" }
  }
  return null
}

/** Espera a que el selector SAF termine de copiar el archivo a Termux. */
async function waitForPickedFile(path: string): Promise<boolean> {
  const deadline = Date.now() + IMAGE_PICKER_TIMEOUT_MS
  let lastSize = 0
  let stableChecks = 0
  while (Date.now() < deadline) {
    if (existsSync(path)) {
      try {
        const size = statSync(path).size
        if (size > 0 && size === lastSize) stableChecks += 1
        else stableChecks = 0
        if (stableChecks >= 2) return true
        lastSize = size
      } catch {}
    }
    await new Promise((resolve) => setTimeout(resolve, 300))
  }
  return false
}

/** Abre el selector de Android y envía la imagen seleccionada como adjunto. */
async function attachImage(context: any, input = "") {
  const client = context?.client
  const route = context?.ui?.router?.current?.()
  const sessionID: string | undefined = route?.type === "session" ? route.sessionID : undefined
  if (!client?.session?.prompt || !sessionID) {
    toast(context, "Abre una sesión de OpenCode antes de usar /image", "error", "Imagen", 5000)
    return
  }

  const question = input.replace(/^\/image(?:\s+|$)/i, "").trim()
  const defaultPrompt = "Analiza la imagen adjunta y descríbeme su contenido."
  const pendingPath = join(TMP_DIR, `picked-image-${randomUUID()}.pending`)
  let imagePath: string | undefined

  try {
    mkdirSync(TMP_DIR, { recursive: true })
    toast(context, "Selecciona una imagen en el selector de Android…", "info", "Imagen", 3000)
    const picker = join(PREFIX, "bin", "termux-storage-get")
    await run(existsSync(picker) ? picker : "termux-storage-get", [pendingPath], {
      timeout: IMAGE_PICKER_TIMEOUT_MS,
      env: AUDIO_ENV,
    })

    if (!(await waitForPickedFile(pendingPath))) {
      toast(context, "No se seleccionó una imagen (selector cancelado o expirado)", "warning", "Imagen", 5000)
      return
    }

    const size = statSync(pendingPath).size
    if (size > MAX_IMAGE_BYTES) {
      toast(context, "La imagen supera el límite de 20 MiB de OpenCode", "error", "Imagen", 6000)
      return
    }

    const type = detectImageType(readFileSync(pendingPath))
    if (!type) {
      toast(context, "El archivo elegido no es PNG, JPEG, GIF ni WebP", "error", "Imagen", 6000)
      return
    }

    imagePath = join(TMP_DIR, `picked-image-${randomUUID()}.${type.extension}`)
    renameSync(pendingPath, imagePath)
    await client.session.prompt({
      sessionID,
      text: question || defaultPrompt,
      files: [{ uri: pathToFileURL(imagePath).href, name: basename(imagePath) }],
    })
    toast(context, "Imagen adjunta y enviada", "success", "Imagen", 3000)
  } catch (error) {
    toast(context, `No pude adjuntar la imagen: ${(error as Error).message}`, "error", "Imagen", 7000)
  } finally {
    for (const path of [pendingPath, imagePath]) {
      if (!path || !existsSync(path)) continue
      try {
        unlinkSync(path)
      } catch {}
    }
  }
}

function toast(context: any, message: string, variant: "info" | "success" | "warning" | "error" = "info", title = "Voice", duration = 3000) {
  try {
    context?.ui?.toast?.show?.({ title, message, variant, duration })
  } catch {
    // nunca romper el TUI por un toast
  }
}

function startRecording(context: any) {
  if (state.recording) return
  try {
    mkdirSync(TMP_DIR, { recursive: true })
  } catch {}

  const recorder = findRecorder()
  const child = execFile(
    recorder,
    ["--format=s16le", "--rate=16000", "--channels=1", RAW_PATH],
    { env: AUDIO_ENV },
  )
  child.on("error", (error) => {
    state.recording = false
    state.proc = null
    toast(context, `No pude grabar: ${error.message}`, "error", "Voice", 6000)
  })
  child.on("exit", (code) => {
    if (state.recording) {
      state.recording = false
      state.proc = null
      toast(context, `Grabador terminó inesperadamente (code=${code})`, "error", "Voice", 6000)
    }
  })
  state.proc = child
  state.recording = true
  state.startedAt = Date.now()
  toast(context, "🎙️ Grabando… pulsa /voice de nuevo para transcribir", "info", "Voice", 2000)
}

async function stopAndTranscribe(context: any) {
  if (!state.recording || !state.proc) return
  state.recording = false
  const child = state.proc
  state.proc = null
  try {
    child.kill("SIGINT")
  } catch {}

  toast(context, "🧠 Transcribiendo…", "info", "Voice", 4000)
  try {
    // Esperar a que el bridge cierre el fichero después de recibir SIGINT.
    await new Promise<void>((resolve) => {
      const timeout = setTimeout(resolve, 10000)
      child.once("close", () => {
        clearTimeout(timeout)
        resolve()
      })
    })
    await run(findFfmpeg(), ["-y", "-f", "s16le", "-ar", "16000", "-ac", "1", "-i", RAW_PATH, WAV_PATH], {
      timeout: 20000,
      env: AUDIO_ENV,
    })
    const size = statSync(WAV_PATH).size
    if (size <= 44) {
      toast(context, "Sin audio capturado (¿micrófono sin permiso?)", "warning", "Voice", 6000)
      return
    }
    const binary = findVoiceBinary()
    if (!binary) {
      toast(context, "Falta ~/.local/bin/opencode-voice (voice-doctor)", "error", "Voice", 8000)
      return
    }
    const { stdout } = await run(binary, ["transcribe", WAV_PATH], { timeout: 90000, env: AUDIO_ENV })
    const text = String(stdout).trim()
    if (!text) {
      toast(context, "No se detectó voz", "warning", "Voice", 4000)
      return
    }
    state.lastText = text
    await submit(context, text)
    toast(context, text.slice(0, 120), "success", "Voice ✓", 4000)
  } catch (error) {
    toast(context, `Error: ${(error as Error).message}`, "error", "Voice", 8000)
  }
}

/** Envía el texto a la sesión activa para que el agente responda (conversación continua). */
async function submit(context: any, text: string) {
  const client = context?.client
  const route = context?.ui?.router?.current?.()
  const sessionID: string | undefined = route?.type === "session" ? route.sessionID : undefined

  if (!client?.session?.prompt || !sessionID) {
    throw new Error("abre una sesión de OpenCode antes de usar /voice")
  }

  // OpenCode TUI V2 envía el prompt directamente a la sesión activa.
  await client.session.prompt({ sessionID, text })
}

export default Plugin.define({
  id: "voice",
  async setup(context) {
    // OpenCode también evalúa los plugins de cli.json en el proceso server.
    // La API keymap solo existe en la TUI; en server no hay nada que registrar.
    if (!context?.keymap?.layer) return

    context.keymap.layer(() => ({
      mode: "global",
      priority: 10,
      commands: [
        {
          id: "voice.toggle",
          title: "Voice: grabar / transcribir y enviar",
          group: "Voice",
          bind: "f6",
          palette: true,
          slash: { name: "voice", aliases: ["stt"], arguments: false },
          run: async () => {
            if (state.recording) await stopAndTranscribe(context)
            else startRecording(context)
          },
        },
        {
          id: "voice.stop",
          title: "Voice: cancelar grabación",
          group: "Voice",
          bind: "f7",
          palette: true,
          run: async () => {
            if (!state.recording) return
            state.recording = false
            try {
              state.proc?.kill("SIGKILL")
            } catch {}
            state.proc = null
            toast(context, "Grabación cancelada", "info", "Voice", 1500)
          },
        },
        {
          id: "voice.repeat",
          title: "Voice: reenviar última transcripción",
          group: "Voice",
          palette: true,
          run: async () => {
            if (!state.lastText) return toast(context, "No hay transcripción previa", "warning", "Voice", 2000)
            await submit(context, state.lastText)
          },
        },
        {
          id: "voice.image",
          title: "Imagen: adjuntar desde Android",
          description: "Abre el selector de archivos de Android y envía una imagen a la sesión",
          group: "Voice",
          palette: true,
          slash: { name: "image", aliases: ["attach-image"], arguments: true },
          run: async (input = "") => attachImage(context, input),
        },
      ],
      bindings: ["voice.toggle", "voice.stop"],
    }))

    return () => {
      try {
        if (state.recording) state.proc?.kill("SIGKILL")
      } catch {}
      state.recording = false
      state.proc = null
    }
  },
})
