import { Plugin } from "@opencode/plugin/tui"
import { randomUUID } from "node:crypto"
import { accessSync, constants, existsSync, mkdirSync, mkdtempSync, rmSync, statSync } from "node:fs"
import { execFile, spawn, type ChildProcess } from "node:child_process"
import { delimiter, join } from "node:path"
import { homedir, tmpdir } from "node:os"
import { promisify } from "node:util"
import { createSignal, Show } from "solid-js"

type TVoiceBackend = "oauth" | "agy" | "codex"

//Config
const run = promisify(execFile)
const PREFIX = process.env.PREFIX
const IS_TERMUX = PREFIX?.includes("com.termux") === true
const IS_WSL = Boolean(process.env.WSL_DISTRO_NAME || process.env.WSL_INTEROP)
const PREFER_PULSE_AUDIO = Boolean(
  IS_WSL || process.env.PULSE_SERVER,
)
const AUDIO_ENV: NodeJS.ProcessEnv = { ...process.env }
const TMP_DIR = join(tmpdir(), "opencode-voice")

if (IS_TERMUX) delete AUDIO_ENV.LD_LIBRARY_PATH

interface IRecorderCommand {
  executable: string
  backend: "pipewire" | "alsa" | "pulse"
}

interface IVoiceRecording {
  child: ChildProcess
  directory: string
  rawPath: string
  wavPath: string
}

interface ILiveTextPart {
  messageID: string
  ordinal: number
  text: string
}

interface ILiveVoiceState {
  active: boolean
  starting: boolean
  voiceBackend: TVoiceBackend
  modelSelection: Promise<void> | null
  muted: boolean
  phase: "listening" | "processing" | "speaking" | "muted"
  sessionID: string | null
  listener: ChildProcess | null
  listenerBuffer: string
  speaker: ChildProcess | null
  speakerPlayer: ChildProcess | null
  awaitingResponse: boolean
  hasObservedBusy: boolean
  responseParts: ILiveTextPart[]
  pendingTranscript: string
  context: any
  fallbackAgent: "agy" | "codex" | null
  fallbackHistory: Array<{ role: "user" | "assistant"; text: string }>
  acpChild: ChildProcess | null
  startedAt: number
  clockTimer: ReturnType<typeof setInterval> | null
}

interface ILiveStatusView {
  active: boolean
  muted: boolean
  phase: ILiveVoiceState["phase"]
  route: string
  startedAt: number
  updatedAt: number
}

interface IVoiceState {
  recording: IVoiceRecording | null
  lastText: string
  voiceBackend: TVoiceBackend
  live: ILiveVoiceState
}

const state: IVoiceState = {
  recording: null,
  lastText: "",
  voiceBackend: "oauth",
  live: {
    active: false,
    starting: false,
    voiceBackend: "oauth",
    modelSelection: null,
    muted: false,
    phase: "listening",
    sessionID: null,
    listener: null,
    listenerBuffer: "",
    speaker: null,
    speakerPlayer: null,
    awaitingResponse: false,
    hasObservedBusy: false,
    responseParts: [],
    pendingTranscript: "",
    context: null,
    fallbackAgent: null,
    fallbackHistory: [],
    acpChild: null,
    startedAt: 0,
    clockTimer: null,
  },
}

let persistVoiceBackend: (backend: TVoiceBackend) => Promise<void> = async () => {}
let updateLiveStatusView: (view: ILiveStatusView) => void = () => {}

/** Devuelve la etiqueta visible para la ruta principal de voz. */
function voiceBackendLabel(backend: TVoiceBackend): string {
  if (backend === "agy") return "AGY ACP"
  if (backend === "codex") return "Codex ACP"
  return "ChatGPT OAuth"
}

/** Permite cambiar la ruta primaria de Live y la persiste entre sesiones. */
async function configureVoiceBackend(context: any): Promise<void> {
  const backend = await context.ui.dialog.select({
    title: "Ruta de respuestas de voz",
    current: state.voiceBackend,
    options: [
      {
        title: "ChatGPT OAuth",
        value: "oauth",
        description: "Usa tu cuenta de ChatGPT; AGY ACP y Codex ACP quedan como fallbacks.",
      },
      {
        title: "AGY ACP",
        value: "agy",
        description: "Usa la sesión de Antigravity; Codex ACP queda como fallback.",
      },
      {
        title: "Codex ACP",
        value: "codex",
        description: "Usa el login de Codex; AGY ACP queda como fallback.",
      },
    ],
  }) as TVoiceBackend | undefined

  if (!backend || backend === state.voiceBackend) return

  state.voiceBackend = backend
  await persistVoiceBackend(backend)
  const active = state.live.active ? " Se aplicará al iniciar Live de nuevo." : ""
  toast(context, `Ruta de voz: ${voiceBackendLabel(backend)}.${active}`, "success", "Voz", 5000)
}

//AudioTools
/** Busca un ejecutable por ruta absoluta o en los directorios de PATH. */
function resolveExecutable(command: string): string | null {
  const candidates = command.includes("/")
    ? [command]
    : (process.env.PATH ?? "").split(delimiter).map((directory) => join(directory, command))

  for (const candidate of candidates) {
    try {
      accessSync(candidate, constants.X_OK)
      return candidate
    } catch {}
  }

  return null
}

/** Encuentra el grabador disponible, priorizando PulseAudio en WSLg. */
function findRecorder(): IRecorderCommand | null {
  const candidates = PREFER_PULSE_AUDIO
    ? [
        { command: "parecord", backend: "pulse" as const },
        { command: "pw-record", backend: "pipewire" as const },
        { command: "arecord", backend: "alsa" as const },
      ]
    : [
        { command: "pw-record", backend: "pipewire" as const },
        { command: "arecord", backend: "alsa" as const },
        { command: "parecord", backend: "pulse" as const },
      ]

  for (const candidate of candidates) {
    const command = IS_TERMUX && PREFIX ? join(PREFIX, "bin", candidate.command) : candidate.command
    const executable = resolveExecutable(command)
    if (executable) return { executable, backend: candidate.backend }
  }

  return null
}

/** Construye los argumentos de captura para PipeWire, PulseAudio, ALSA o Termux. */
function recorderArguments(recorder: IRecorderCommand, rawPath: string): string[] {
  if (recorder.backend === "pulse") {
    const device = process.env.VOICE_DEVICE
    return [
      "--raw",
      "--format=s16le",
      "--rate=16000",
      "--channels=1",
      ...(device && device !== "@DEFAULT_SOURCE@" ? [`--device=${device}`] : []),
      rawPath,
    ]
  }

  if (recorder.backend === "alsa") {
    return ["-q", "-f", "S16_LE", "-r", "16000", "-c", "1", "-t", "raw", rawPath]
  }

  if (IS_TERMUX) {
    return ["--format=s16le", "--rate=16000", "--channels=1", rawPath]
  }

  return ["--raw", "--format=s16", "--rate=16000", "--channels=1", rawPath]
}

/** Encuentra ffmpeg en Termux o en el PATH del sistema. */
function findFfmpeg(): string | null {
  if (IS_TERMUX && PREFIX) {
    const termuxBinary = resolveExecutable(join(PREFIX, "bin", "ffmpeg"))
    if (termuxBinary) return termuxBinary
  }

  return resolveExecutable("ffmpeg")
}

/** Localiza el transcriptor opencode-voice instalado por Home Manager o Termux. */
function findVoiceBinary(): string | null {
  const candidates = [
    process.env.OPENCODE_VOICE_BIN,
    join(homedir(), ".local", "bin", "opencode-voice"),
    IS_TERMUX && PREFIX ? join(PREFIX, "bin", "opencode-voice") : undefined,
  ]

  for (const candidate of candidates) {
    if (!candidate) continue
    const executable = resolveExecutable(candidate)
    if (executable) return executable
  }

  return resolveExecutable("opencode-voice")
}

/** Encuentra el sintetizador disponible en Linux o en Termux. */
function findSpeaker(): string | null {
  const configured = process.env.OPENCODE_TTS_BIN
  if (configured) return resolveExecutable(configured)
  if (IS_TERMUX && PREFIX) return resolveExecutable(join(PREFIX, "bin", "termux-tts-speak"))
  return resolveExecutable("espeak-ng")
}

/** Encuentra el reproductor PulseAudio que WSLg usa para emitir el TTS. */
function findPulsePlayer(): string | null {
  return resolveExecutable("paplay")
}

/** Espera el cierre de un proceso de audio y conserva su error de diagnóstico. */
function waitForAudioProcess(child: ChildProcess, label: string): Promise<void> {
  return new Promise((resolve, reject) => {
    let stderr = ""
    child.stderr?.on("data", (chunk: Buffer) => {
      stderr = `${stderr}${chunk.toString()}`.slice(-2000)
    })
    child.once("error", reject)
    child.once("close", (code, signal) => {
      if (code === 0) resolve()
      else reject(new Error(stderr.trim() || `${label} terminó con code=${code} signal=${signal}`))
    })
  })
}

/** Borra el audio temporal de una grabación. */
function removeRecordingFiles(recording: IVoiceRecording): void {
  try {
    rmSync(recording.directory, { recursive: true, force: true })
  } catch {}
}

/** Muestra un aviso sin interrumpir la TUI si falla la API de notificaciones. */
function toast(
  context: any,
  message: string,
  variant: "info" | "success" | "warning" | "error" = "info",
  title = "Voz",
  duration = 3000,
): void {
  try {
    context?.ui?.toast?.show?.({ title, message, variant, duration })
  } catch {}
}

//Session
/** Devuelve el ID de sesión cuando OpenCode está mostrando una conversación. */
function getSessionID(context: any): string | null {
  const route = context?.ui?.router?.current?.()
  return route?.type === "session" && typeof route.sessionID === "string" ? route.sessionID : null
}

/** Envía una transcripción a la conversación activa de OpenCode. */
async function submitTranscript(context: any, text: string, targetSessionID: string | null = getSessionID(context)): Promise<void> {
  const client = context?.client

  if (!client?.session?.prompt || !targetSessionID) {
    throw new Error("Abre una sesión de OpenCode antes de enviar la transcripción")
  }

  await client.session.prompt({ sessionID: targetSessionID, text })
}

/** Selecciona el modelo OAuth de OpenAI disponible con menor latencia para Live. */
async function selectLiveOpenAIModel(context: any, sessionID: string): Promise<void> {
  const client = context?.client
  if (!client?.session?.get || !client?.session?.switchModel || !client?.model?.list || !client?.integration?.list) {
    throw new Error("Esta versión de OpenCode no permite cambiar el modelo de la sesión desde el plugin")
  }

  const [sessionResult, modelResult, integrationResult] = await Promise.all([
    client.session.get({ sessionID }),
    client.model.list(),
    client.integration.list(),
  ])
  const session = sessionResult?.data ?? sessionResult
  const availableModels = modelResult?.data ?? modelResult
  const integrations = integrationResult?.data ?? integrationResult
  const openAIIntegration = Array.isArray(integrations)
    ? integrations.find((integration: any) => integration?.id === "openai")
    : null
  const hasOAuth = openAIIntegration?.connections?.some(
    (connection: any) => connection?.type === "credential" && connection?.method === "oauth",
  )
  if (!hasOAuth) throw new Error("No hay una sesión OAuth de ChatGPT guardada en OpenCode")
  const currentModel = session?.model
  const candidates = Array.isArray(availableModels)
    ? availableModels.filter((model: any) => model?.providerID === "openai" && model?.type === "chat")
    : []
  const preferred = process.env.OPENCODE_VOICE_MODEL
  const model = candidates.find((candidate: any) => candidate.id === preferred)
    ?? candidates.find((candidate: any) => candidate.id === "gpt-6.1-sol-fast")
    ?? candidates.find((candidate: any) => candidate.id.endsWith("-fast"))
    ?? candidates.find((candidate: any) => candidate.id === "gpt-6.1-sol")
    ?? candidates[0]

  if (!model) throw new Error("No hay modelos ChatGPT disponibles en el catálogo OAuth de OpenAI")

  liveModelRefs.set(sessionID, {
    id: currentModel?.id,
    providerID: currentModel?.providerID,
    variant: currentModel?.variant,
    selected: { id: model.id, providerID: model.providerID },
  })
  await client.session.switchModel({
    sessionID,
    model: { id: model.id, providerID: model.providerID },
  })
}

const liveModelRefs = new Map<string, {
  id?: string
  providerID?: string
  variant?: string
  selected: { id: string; providerID: string; variant?: string }
}>()

/** Restaura el modelo que estaba seleccionado antes de iniciar Live. */
async function restoreLiveModel(sessionID: string): Promise<void> {
  const live = state.live
  const saved = liveModelRefs.get(sessionID)
  liveModelRefs.delete(sessionID)
  if (!saved?.id || !saved.providerID) return

  try {
    const currentResult = await live.context?.client?.session?.get?.({ sessionID })
    const current = currentResult?.data ?? currentResult
    if (current?.model?.id !== saved.selected.id || current?.model?.providerID !== saved.selected.providerID) return
    await live.context.client.session.switchModel({
      sessionID,
      model: { id: saved.id, providerID: saved.providerID, variant: saved.variant },
    })
  } catch {}
}

//Capture
/** Espera el cierre del grabador y lo fuerza a terminar si se queda bloqueado. */
function stopRecorder(child: ChildProcess, signal: NodeJS.Signals = "SIGINT"): Promise<void> {
  return new Promise((resolve) => {
    let stopped = false

    /** Completa la espera una sola vez y cancela el límite de seguridad. */
    const finish = () => {
      if (stopped) return
      stopped = true
      clearTimeout(timeout)
      resolve()
    }

    const timeout = setTimeout(() => {
      child.kill("SIGKILL")
      finish()
    }, 5000)

    child.once("close", finish)
    if (child.exitCode !== null || child.signalCode !== null) {
      finish()
      return
    }

    child.kill(signal)
  })
}

/** Inicia la captura de audio en formato PCM mono de 16 kHz. */
function startRecording(context: any): void {
  if (state.recording) return
  if (!context?.client?.session?.prompt || !getSessionID(context)) {
    toast(context, "Abre una sesión antes de empezar a dictar", "error")
    return
  }

  const recorder = findRecorder()
  if (!recorder) {
    toast(context, "No encontré pw-record, parecord ni arecord", "error", "Voz", 6000)
    return
  }
  if (!findFfmpeg() || !findVoiceBinary()) {
    toast(context, "Falta ffmpeg o ~/.local/bin/opencode-voice", "error", "Voz", 6000)
    return
  }

  let directory: string
  try {
    mkdirSync(TMP_DIR, { recursive: true, mode: 0o700 })
    directory = mkdtempSync(join(TMP_DIR, "recording-"))
  } catch (error) {
    toast(context, `No pude preparar la grabación: ${(error as Error).message}`, "error", "Voz", 6000)
    return
  }

  const rawPath = join(directory, `audio-${randomUUID()}.raw`)
  const wavPath = join(directory, `audio-${randomUUID()}.wav`)
  const recording: IVoiceRecording = {
    child: execFile(recorder.executable, recorderArguments(recorder, rawPath), { env: AUDIO_ENV }),
    directory,
    rawPath,
    wavPath,
  }
  state.recording = recording

  recording.child.once("error", (error) => {
    if (state.recording?.child !== recording.child) return
    state.recording = null
    removeRecordingFiles(recording)
    toast(context, `No pude grabar: ${error.message}`, "error", "Voz", 6000)
  })
  recording.child.once("close", (code) => {
    if (state.recording?.child !== recording.child) return
    state.recording = null
    removeRecordingFiles(recording)
    toast(context, `El grabador terminó inesperadamente (code=${code})`, "error", "Voz", 6000)
  })

  toast(context, "🎙️ Grabando… pulsa F5 o /voice-ask para enviar la transcripción", "info", "Voz", 3000)
}

//Transcription
/** Detiene la captura, transcribe el audio y envía el resultado a la sesión. */
async function stopAndTranscribe(context: any): Promise<void> {
  const recording = state.recording
  if (!recording) return

  state.recording = null
  toast(context, "🧠 Transcribiendo y enviando…", "info", "Voz", 4000)

  try {
    await stopRecorder(recording.child)
    if (!existsSync(recording.rawPath) || statSync(recording.rawPath).size === 0) {
      toast(context, "No se capturó audio; revisa el micrófono", "warning", "Voz", 6000)
      return
    }

    const ffmpeg = findFfmpeg()
    const voiceBinary = findVoiceBinary()
    if (!ffmpeg || !voiceBinary) throw new Error("Falta ffmpeg o ~/.local/bin/opencode-voice")

    await run(
      ffmpeg,
      ["-y", "-f", "s16le", "-ar", "16000", "-ac", "1", "-i", recording.rawPath, recording.wavPath],
      { timeout: 20000, env: AUDIO_ENV },
    )

    if (statSync(recording.wavPath).size <= 44) {
      toast(context, "No se detectó voz", "warning", "Voz", 4000)
      return
    }

    const { stdout } = await run(voiceBinary, ["transcribe", recording.wavPath], {
      timeout: 90000,
      env: AUDIO_ENV,
    })
    const text = String(stdout).trim()
    if (!text) {
      toast(context, "No se detectó voz", "warning", "Voz", 4000)
      return
    }

    state.lastText = text
    await submitTranscript(context, text)
    toast(context, text.slice(0, 120), "success", "Voz enviada ✓", 4000)
  } catch (error) {
    toast(context, `Error: ${(error as Error).message}`, "error", "Voz", 8000)
  } finally {
    removeRecordingFiles(recording)
  }
}

/** Cancela la captura activa y elimina sus archivos temporales. */
async function cancelRecording(context: any): Promise<void> {
  const recording = state.recording
  if (!recording) return

  state.recording = null
  await stopRecorder(recording.child, "SIGTERM")
  removeRecordingFiles(recording)
  toast(context, "Grabación cancelada", "info", "Voz", 1500)
}

//LiveConversation
/** Publica al TUI el estado efímero que muestra la franja Live. */
function publishLiveStatus(): void {
  updateLiveStatusView({
    active: state.live.active,
    muted: state.live.muted,
    phase: state.live.phase,
    route: state.live.fallbackAgent ? `${state.live.fallbackAgent.toUpperCase()} ACP` : voiceBackendLabel(state.live.voiceBackend),
    startedAt: state.live.startedAt,
    updatedAt: Date.now(),
  })
}

/** Formatea el tiempo transcurrido de la llamada como mm:ss. */
function formatLiveDuration(startedAt: number, now: number): string {
  const elapsed = Math.max(0, Math.floor((now - startedAt) / 1000))
  const minutes = Math.floor(elapsed / 60)
  const seconds = elapsed % 60
  return `${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`
}

/** Construye el texto breve de estado y controles de la franja Live. */
function formatLiveStatus(view: ILiveStatusView): string {
  const phase = view.muted
    ? "muted"
    : view.phase === "listening"
      ? "listening"
      : view.phase === "processing"
        ? "processing"
        : "speaking"
  const muteAction = view.muted ? "f6 unmute" : "f6 mute"

  return `● Live ${formatLiveDuration(view.startedAt, view.updatedAt)} · ${view.route} · ${phase} · ${muteAction} · f7 hang`
}

/** Convierte la respuesta Markdown del agente en texto cómodo para hablar. */
function cleanSpeechText(text: string): string {
  return text
    .replace(/```[\s\S]*?```/g, " bloque de código omitido ")
    .replace(/!\[([^\]]*)\]\([^)]*\)/g, "$1")
    .replace(/\[([^\]]+)\]\([^)]*\)/g, "$1")
    .replace(/https?:\/\/\S+/g, "")
    .replace(/^#{1,6}\s*/gm, "")
    .replace(/^\s*[-*+]\s+/gm, "")
    .replace(/[`*_~>#|]/g, " ")
    .replace(/\n+/g, ". ")
    .replace(/\s+/g, " ")
    .trim()
}

/** Arranca la captura VAD continua y consume las transcripciones por frase. */
function startLiveListener(context: any, sessionID: string): void {
  const live = state.live
  if (!live.active || live.muted || live.awaitingResponse || live.listener) return

  const voiceBinary = findVoiceBinary()
  if (!voiceBinary) {
    void stopLive()
    toast(context, "Falta ~/.local/bin/opencode-voice", "error", "Live", 6000)
    return
  }

  live.listenerBuffer = ""
  live.phase = "listening"
  publishLiveStatus()

  let child: ChildProcess
  try {
    child = spawn(voiceBinary, ["listen"], {
      env: AUDIO_ENV,
      stdio: ["ignore", "pipe", "pipe"],
    })
  } catch (error) {
    void stopLive()
    toast(context, `No pude iniciar Live: ${(error as Error).message}`, "error", "Live", 6000)
    return
  }

  live.listener = child
  child.stdout?.on("data", (chunk: Buffer) => handleLiveOutput(context, child, sessionID, chunk))
  child.stderr?.on("data", (chunk: Buffer) => {
    if (process.env.VOICE_DEBUG) {
      const message = chunk.toString().trim()
      if (message) toast(context, message.slice(0, 160), "info", "Live", 1500)
    }
  })
  child.once("error", (error) => {
    if (live.listener !== child) return
    live.listener = null
    void stopLive()
    toast(context, `Falló el capturador de Live: ${error.message}`, "error", "Live", 6000)
  })
  child.once("close", (code) => {
    if (live.listener !== child) return
    live.listener = null
    if (!live.active || live.awaitingResponse) return
    void stopLive()
    toast(context, `El capturador Live terminó (code=${code})`, "error", "Live", 6000)
  })
}

/** Lee los eventos NDJSON del transcriptor y reacciona solo a frases completas. */
function handleLiveOutput(context: any, child: ChildProcess, sessionID: string, chunk: Buffer): void {
  const live = state.live
  if (live.listener !== child) return

  const lines = `${live.listenerBuffer}${chunk.toString()}`.split(/\r?\n/)
  live.listenerBuffer = lines.pop() ?? ""

  for (const line of lines) {
    if (!line.trim()) continue

    try {
      const event = JSON.parse(line) as { type?: string; text?: string; message?: string }
      if (event.type === "transcribing") {
        live.phase = "processing"
        publishLiveStatus()
        continue
      }
      if (event.type === "no_speech") {
        live.phase = "listening"
        publishLiveStatus()
        continue
      }
      if (event.type === "transcript" && typeof event.text === "string" && event.text.trim()) {
        void handleLiveTranscript(context, child, sessionID, event.text.trim())
        return
      }
      if (event.type === "error" && event.message) {
        live.phase = "listening"
        publishLiveStatus()
        toast(context, event.message, "error", "Transcripción", 6000)
      }
    } catch {
      toast(context, "El transcriptor devolvió un evento inválido", "warning", "Live", 3000)
    }
  }
}

/** Detiene el micrófono, envía la frase a OpenCode y espera su respuesta. */
async function handleLiveTranscript(
  context: any,
  child: ChildProcess,
  sessionID: string,
  text: string,
): Promise<void> {
  const live = state.live
  if (!live.active || live.listener !== child || live.sessionID !== sessionID) return

  state.lastText = text
  live.listener = null
  live.listenerBuffer = ""

  if (live.voiceBackend === "oauth" && !live.fallbackAgent && context?.data?.session?.status?.(sessionID) === "running") {
    await stopRecorder(child)
    if (live.active && !live.muted) startLiveListener(context, sessionID)
    if (live.active) toast(context, "OpenCode todavía está respondiendo; repite la frase cuando termine", "warning", "Live", 4000)
    return
  }

  if (live.voiceBackend !== "oauth" || live.fallbackAgent) {
    await stopRecorder(child)
    live.phase = "processing"
    publishLiveStatus()
    try {
      await speakAcpFallback(context, text)
    } catch (error) {
      if (live.active) toast(context, `Falló el fallback ACP: ${(error as Error).message}`, "error", "Live", 7000)
    }
    if (live.active && !live.muted) startLiveListener(context, sessionID)
    return
  }

  live.awaitingResponse = true
  live.hasObservedBusy = false
  live.responseParts = []
  live.pendingTranscript = text
  live.phase = "processing"
  publishLiveStatus()
  await stopRecorder(child)
  if (!live.active || live.sessionID !== sessionID) return

  try {
    await submitTranscript(context, text, sessionID)
  } catch (error) {
    live.awaitingResponse = false
    live.hasObservedBusy = false
    live.responseParts = []
    if (!live.active) return
    live.fallbackAgent ??= "agy"
    live.phase = "processing"
    publishLiveStatus()
    toast(context, `OpenCode rechazó el turno; cambio a ACP: ${(error as Error).message}`, "warning", "Live", 5000)
    try {
      await speakAcpFallback(context, text)
    } catch (fallbackError) {
      if (live.active) toast(context, `Falló el fallback ACP: ${(fallbackError as Error).message}`, "error", "Live", 7000)
    }
    live.pendingTranscript = ""
    if (live.active && !live.muted) startLiveListener(context, sessionID)
  }
}

/** Sintetiza la respuesta con eSpeak NG, PulseAudio o el TTS nativo de Termux. */
async function speakAssistantResponse(text: string): Promise<void> {
  const speaker = findSpeaker()
  if (!speaker) throw new Error("Falta espeak-ng o termux-tts-speak")

  const spokenText = cleanSpeechText(text)
  if (!spokenText) return

  const language = process.env.VOICE_LANGUAGE ?? "es"
  const voice = process.env.OPENCODE_TTS_VOICE ?? "es-419"
  const speed = process.env.OPENCODE_TTS_SPEED ?? "165"

  if (!IS_TERMUX && PREFER_PULSE_AUDIO) {
    const player = findPulsePlayer()
    if (player) {
      const synthesizer = spawn(speaker, ["--stdout", "-v", voice, "-s", speed, "--stdin"], {
        env: AUDIO_ENV,
        stdio: ["pipe", "pipe", "pipe"],
      })
      const playback = spawn(player, [], { env: AUDIO_ENV, stdio: ["pipe", "ignore", "pipe"] })
      state.live.speaker = synthesizer
      state.live.speakerPlayer = playback

      const synthesizerClosed = waitForAudioProcess(synthesizer, "eSpeak NG")
      const playbackClosed = waitForAudioProcess(playback, "paplay")
      let streamError: Error | null = null
      playback.stdin?.on("error", (error: NodeJS.ErrnoException) => {
        if (error.code !== "EPIPE") streamError = error
      })
      synthesizer.stdout?.pipe(playback.stdin!)

      try {
        synthesizer.stdin?.end(spokenText)
        await Promise.all([synthesizerClosed, playbackClosed])
        if (streamError) throw streamError
      } catch (error) {
        await Promise.all([
          stopRecorder(synthesizer, "SIGTERM"),
          stopRecorder(playback, "SIGTERM"),
        ])
        throw error
      } finally {
        if (state.live.speaker === synthesizer) state.live.speaker = null
        if (state.live.speakerPlayer === playback) state.live.speakerPlayer = null
      }
      return
    }
  }

  const child = IS_TERMUX
    ? spawn(
        speaker,
        [
          "-l",
          language,
          "-r",
          process.env.OPENCODE_TTS_RATE ?? "0.85",
          "-s",
          process.env.OPENCODE_TTS_STREAM ?? "MUSIC",
          spokenText,
        ],
        {
          env: AUDIO_ENV,
          stdio: ["ignore", "ignore", "pipe"],
        },
      )
    : spawn(
        speaker,
        [
          "-v",
          voice,
          "-s",
          speed,
          "--stdin",
        ],
        { env: AUDIO_ENV, stdio: ["pipe", "ignore", "pipe"] },
      )

  state.live.speaker = child
  state.live.speakerPlayer = null
  try {
    const closed = waitForAudioProcess(child, "TTS")
    if (!IS_TERMUX) child.stdin?.end(spokenText)
    await closed
  } finally {
    if (state.live.speaker === child) state.live.speaker = null
    state.live.speakerPlayer = null
  }
}

/** Habla la última respuesta completa y vuelve al micrófono si Live sigue activo. */
async function finishLiveTurn(context: any, sessionID: string): Promise<void> {
  const live = state.live
  if (!live.active || !live.awaitingResponse || live.sessionID !== sessionID) return

  live.awaitingResponse = false
  live.hasObservedBusy = false
  const lastMessageID = live.responseParts.at(-1)?.messageID
  const response = lastMessageID
    ? live.responseParts
        .filter((part) => part.messageID === lastMessageID)
        .sort((left, right) => left.ordinal - right.ordinal)
        .map((part) => part.text)
        .join("\n")
    : ""
  live.responseParts = []

  if (response.trim()) {
    rememberLiveExchange(live.pendingTranscript, response)
    live.phase = "speaking"
    publishLiveStatus()
    try {
      await speakAssistantResponse(response)
    } catch (error) {
      if (live.active) toast(context, `No pude hablar la respuesta: ${(error as Error).message}`, "error", "Live", 7000)
    }
  } else {
    live.fallbackAgent ??= "agy"
    try {
      await speakAcpFallback(context, live.pendingTranscript)
    } catch (error) {
      if (live.active) toast(context, `No pude completar la respuesta de voz: ${(error as Error).message}`, "error", "Live", 7000)
    }
  }
  live.pendingTranscript = ""
  if (!live.active || live.sessionID !== sessionID) return
  if (live.muted) {
    live.phase = "muted"
    publishLiveStatus()
    return
  }

  startLiveListener(context, sessionID)
}

/** Guarda las partes de texto emitidas por la respuesta del asistente en Live. */
function collectLiveResponse(event: any): void {
  const live = state.live
  if (!live.active || !live.awaitingResponse || event?.data?.sessionID !== live.sessionID) return

  live.responseParts.push({
    messageID: event.data.assistantMessageID,
    ordinal: event.data.ordinal,
    text: event.data.text,
  })
}

/** Completa la ronda de voz cuando OpenCode marca la sesión como inactiva. */
function handleLiveIdle(context: any, event: any): void {
  const sessionID = event?.data?.sessionID
  if (typeof sessionID === "string") void finishLiveTurn(context, sessionID)
}

/** Completa el turno si OpenCode publica el cambio de estado antes del evento idle. */
function handleLiveStatus(context: any, event: any): void {
  const live = state.live
  const sessionID = event?.data?.sessionID
  const status = event?.data?.status?.type

  if (!live.active || !live.awaitingResponse || sessionID !== live.sessionID) return
  if (status === "busy") {
    live.hasObservedBusy = true
    return
  }
  if (status === "idle" && live.hasObservedBusy) void finishLiveTurn(context, sessionID)
}

/** Finaliza Live cuando OpenCode emite error o un resultado terminal de ejecución. */
function handleLiveError(context: any, event: any): void {
  const sessionID = event?.data?.sessionID
  if (typeof sessionID === "string") void finishLiveTurn(context, sessionID)
}

/** Descarta el turno cancelado y devuelve Live al micrófono sin responderlo. */
function handleLiveInterrupted(context: any, event: any): void {
  const live = state.live
  const sessionID = event?.data?.sessionID
  if (!live.active || !live.awaitingResponse || sessionID !== live.sessionID) return

  live.awaitingResponse = false
  live.hasObservedBusy = false
  live.responseParts = []
  live.pendingTranscript = ""
  live.phase = live.muted ? "muted" : "listening"
  publishLiveStatus()
  if (!live.muted) startLiveListener(context, sessionID)
}

/** Conserva solo los seis intercambios recientes para el contexto de ACP. */
function rememberLiveExchange(userText: string, assistantText: string): void {
  const history = state.live.fallbackHistory
  history.push({ role: "user", text: userText }, { role: "assistant", text: assistantText })
  if (history.length > 12) history.splice(0, history.length - 12)
}

/** Ejecuta una ronda de voz con AGY ACP o Codex ACP manteniendo el historial Live. */
async function runAcpVoiceTurn(
  agent: "agy" | "codex",
  text: string,
  history: Array<{ role: "user" | "assistant"; text: string }>,
): Promise<string> {
  const executable = resolveExecutable(agent === "agy" ? "agy" : "codex-acp")
  if (!executable) throw new Error(`No encuentro el ejecutable ${agent === "agy" ? "agy" : "codex-acp"}`)

  const acpEnv: NodeJS.ProcessEnv = { ...process.env }
  delete acpEnv.OPENAI_API_KEY
  delete acpEnv.GOOGLE_API_KEY
  delete acpEnv.GEMINI_API_KEY
  const child = spawn(executable, agent === "agy" ? ["acp"] : ["--message-streaming"], {
    cwd: state.live.context?.directory ?? process.cwd(),
    env: acpEnv,
    stdio: ["pipe", "pipe", "pipe"],
  })
  state.live.acpChild = child
  let buffer = ""
  let stderr = ""
  let responseText = ""
  let requestID = 0
  const pending = new Map<number, { resolve: (value: any) => void; reject: (error: Error) => void; timer: ReturnType<typeof setTimeout> }>()

  /** Envía una petición JSON-RPC y espera su respuesta correlacionada. */
  const request = (method: string, params: Record<string, unknown>, timeoutMs = 10000): Promise<any> => {
    const id = ++requestID
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        pending.delete(id)
        reject(new Error(`${agent} ACP agotó el tiempo en ${method}`))
      }, timeoutMs)
      pending.set(id, { resolve, reject, timer })
      child.stdin?.write(`${JSON.stringify({ jsonrpc: "2.0", id, method, params })}\n`)
    })
  }

  child.stdout?.on("data", (chunk: Buffer) => {
    buffer += chunk.toString()
    const lines = buffer.split("\n")
    buffer = lines.pop() ?? ""
    for (const line of lines) {
      try {
        const message = JSON.parse(line)
        if (message?.method === "session/update") {
          const update = message.params?.update
          if (update?.sessionUpdate === "agent_message_chunk" && update.content?.type === "text") {
            responseText += update.content.text ?? ""
          }
        }
        const waiting = pending.get(message?.id)
        if (!waiting) continue
        clearTimeout(waiting.timer)
        pending.delete(message.id)
        if (message.error) waiting.reject(new Error(message.error.message ?? `${agent} ACP falló`))
        else waiting.resolve(message.result)
      } catch {}
    }
  })
  child.stderr?.on("data", (chunk: Buffer) => {
    stderr = `${stderr}${chunk.toString()}`.slice(-2000)
  })
  child.on("error", (error) => {
    for (const waiting of pending.values()) {
      clearTimeout(waiting.timer)
      waiting.reject(error)
    }
    pending.clear()
  })
  child.on("close", (code) => {
    const error = new Error(stderr.trim() || `${agent} ACP terminó con code=${code}`)
    for (const waiting of pending.values()) {
      clearTimeout(waiting.timer)
      waiting.reject(error)
    }
    pending.clear()
  })

  try {
    await request("initialize", {
      protocolVersion: 1,
      clientCapabilities: {},
      clientInfo: { name: "opencode-voice", version: "0.2.0" },
    })
    const session = await request("session/new", { cwd: state.live.context?.directory ?? process.cwd(), mcpServers: [] })
    const conversation = [
      ...history.slice(-12).map((turn) => `${turn.role === "user" ? "Usuario" : agent === "agy" ? "AGY" : "Codex"}: ${turn.text}`),
      `Usuario: ${text}`,
    ].join("\n\n")
    await request("session/prompt", {
      sessionId: session.sessionId,
      prompt: [{ type: "text", text: `Responde de forma conversacional, breve y en español. No uses herramientas.\n\n${conversation}` }],
    }, 90000)
    const result = responseText.trim()
    if (!result) throw new Error(`${agent} ACP terminó sin devolver texto${stderr ? `: ${stderr.trim()}` : ""}`)
    return result
  } finally {
    for (const waiting of pending.values()) clearTimeout(waiting.timer)
    pending.clear()
    child.kill("SIGTERM")
    if (state.live.acpChild === child) state.live.acpChild = null
  }
}

/** Recurre a AGY ACP y después a Codex ACP cuando ChatGPT OAuth no responde. */
async function speakAcpFallback(context: any, text: string): Promise<void> {
  const live = state.live
  const preferredAgent = live.fallbackAgent
    ?? (live.voiceBackend === "codex" ? "codex" : "agy")
  const agents: Array<"agy" | "codex"> = preferredAgent === "codex"
    ? ["codex", "agy"]
    : ["agy", "codex"]
  let lastError: Error | null = null

  for (const agent of agents) {
    let response: string
    try {
      response = await runAcpVoiceTurn(agent, text, live.fallbackHistory)
    } catch (error) {
      lastError = error as Error
      if (!live.active) return
      continue
    }

    if (!live.active) return
    live.fallbackAgent = agent
    rememberLiveExchange(text, response)
    live.phase = "speaking"
    publishLiveStatus()
    toast(context, `Live responde con ${agent.toUpperCase()} ACP`, "info", "Voz", 3500)
    await speakAssistantResponse(response)
    return
  }

  throw lastError ?? new Error("AGY ACP y Codex ACP no están disponibles")
}

/** Inicia Live continuo en la ruta de voz seleccionada. */
async function startLive(context: any): Promise<void> {
  const live = state.live
  let startupFallbackAgent: "agy" | "codex" | null = null
  if (live.active || live.starting) return

  const sessionID = getSessionID(context)
  if (!sessionID) {
    toast(context, "Abre una sesión antes de iniciar Live", "error", "Live", 5000)
    return
  }
  if (!context?.data?.on) {
    toast(context, "Esta versión de OpenCode no expone eventos de sesión para Live", "error", "Live", 6000)
    return
  }
  if (state.recording) {
    toast(context, "Termina el dictado actual con F5 antes de iniciar Live", "warning", "Live", 4000)
    return
  }

  const missingPulsePlayer = IS_WSL && !findPulsePlayer()
  if (!findVoiceBinary() || !findRecorder() || !findSpeaker() || missingPulsePlayer) {
    const requirement = missingPulsePlayer ? "paplay para el audio de WSLg" : "un grabador y un sintetizador de voz"
    toast(
      context,
      `Live requiere opencode-voice, ${requirement}`,
      "error",
      "Live",
      7000,
    )
    return
  }

  live.starting = true
  live.sessionID = sessionID
  live.context = context
  live.voiceBackend = state.voiceBackend
  if (live.voiceBackend === "oauth") {
    const modelSelection = selectLiveOpenAIModel(context, sessionID)
    live.modelSelection = modelSelection
    try {
      await modelSelection
    } catch (error) {
      await restoreLiveModel(sessionID)
      const wasCancelled = !live.starting
      if (wasCancelled) {
        live.starting = false
        live.sessionID = null
        live.modelSelection = null
        live.context = null
        return
      }

      startupFallbackAgent = resolveExecutable("agy")
        ? "agy"
        : resolveExecutable("codex-acp")
          ? "codex"
          : null
      if (!startupFallbackAgent) {
        live.starting = false
        live.sessionID = null
        live.modelSelection = null
        live.context = null
        toast(context, `No pude activar ChatGPT OAuth ni encontrar AGY/Codex ACP: ${(error as Error).message}`, "error", "Live", 7000)
        return
      }
      toast(
        context,
        `ChatGPT OAuth no pudo activarse (${(error as Error).message}); Live usará ${startupFallbackAgent.toUpperCase()} ACP`,
        "warning",
        "Live",
        8000,
      )
    }
  }
  if (!live.starting) {
    await restoreLiveModel(sessionID)
    live.modelSelection = null
    return
  }
  live.starting = false
  live.modelSelection = null
  live.active = true
  live.muted = false
  live.phase = "listening"
  live.sessionID = sessionID
  live.listener = null
  live.listenerBuffer = ""
  live.speaker = null
  live.speakerPlayer = null
  live.awaitingResponse = false
  live.hasObservedBusy = false
  live.responseParts = []
  live.pendingTranscript = ""
  live.fallbackAgent = startupFallbackAgent
  live.fallbackHistory = []
  live.acpChild = null
  live.startedAt = Date.now()
  live.clockTimer = setInterval(publishLiveStatus, 1000)
  publishLiveStatus()
  startLiveListener(context, sessionID)
}

/** Detiene la captura y el audio de salida y oculta la franja Live. */
async function stopLive(): Promise<void> {
  const live = state.live
  const sessionID = live.sessionID
  const modelSelection = live.modelSelection
  const listener = live.listener
  const speaker = live.speaker
  const speakerPlayer = live.speakerPlayer
  const acpChild = live.acpChild

  live.active = false
  live.starting = false
  live.muted = false
  live.sessionID = null
  live.listener = null
  live.listenerBuffer = ""
  live.speaker = null
  live.speakerPlayer = null
  live.awaitingResponse = false
  live.hasObservedBusy = false
  live.responseParts = []
  live.pendingTranscript = ""
  live.acpChild = null
  if (live.clockTimer) clearInterval(live.clockTimer)
  live.clockTimer = null
  publishLiveStatus()

  await Promise.all([
    listener ? stopRecorder(listener) : Promise.resolve(),
    speaker ? stopRecorder(speaker, "SIGTERM") : Promise.resolve(),
    speakerPlayer ? stopRecorder(speakerPlayer, "SIGTERM") : Promise.resolve(),
    acpChild ? stopRecorder(acpChild, "SIGTERM") : Promise.resolve(),
    modelSelection ? modelSelection.catch(() => {}) : Promise.resolve(),
  ])
  if (sessionID) await restoreLiveModel(sessionID)
  live.context = null
  live.fallbackAgent = null
  live.fallbackHistory = []

}

/** Activa o pausa el micrófono sin terminar la conversación. */
async function toggleLiveMute(context: any): Promise<void> {
  const live = state.live
  if (!live.active) return

  live.muted = !live.muted
  if (live.muted) {
    const listener = live.listener
    live.listener = null
    live.listenerBuffer = ""
    live.phase = "muted"
    publishLiveStatus()
    if (listener) await stopRecorder(listener)
    return
  }

  if (live.awaitingResponse) live.phase = "processing"
  else if (live.speaker) live.phase = "speaking"
  else if (live.sessionID) startLiveListener(context, live.sessionID)
  publishLiveStatus()
}

//Commands
export default Plugin.define({
  id: "voice",
  /** Registra los comandos de dictado y limpia el grabador al cerrar la TUI. */
  async setup(context) {
    if (!context?.keymap?.layer) return

    const [voicePreferences, updateVoicePreferences] = context.storage.store("voice-preferences", {
      initial: { backend: "oauth" as TVoiceBackend },
    })
    const savedBackend = voicePreferences.backend
    state.voiceBackend = savedBackend === "agy" || savedBackend === "codex" ? savedBackend : "oauth"
    persistVoiceBackend = async (backend) => {
      await updateVoicePreferences((draft) => {
        draft.backend = backend
      })
    }

    const [liveStatus, setLiveStatus] = createSignal<ILiveStatusView>({
      active: false,
      muted: false,
      phase: "listening",
      route: "ChatGPT OAuth",
      startedAt: 0,
      updatedAt: 0,
    })
    updateLiveStatusView = setLiveStatus

    const removeLiveStatus = context.ui.slot({
      append: "prompt.footer.status",
      render: () => (
        <Show when={liveStatus().active}>
          <text fg={context.theme.text.base}>{() => formatLiveStatus(liveStatus())}</text>
        </Show>
      ),
    })
    const removeTextListener = context.data.on("session.text.ended", (event) => collectLiveResponse(event))
    const removeIdleListener = context.data.on("session.idle", (event) => handleLiveIdle(context, event))
    const removeStatusListener = context.data.on("session.status", (event) => handleLiveStatus(context, event))
    const removeErrorListener = context.data.on("session.error", (event) => handleLiveError(context, event))
    const removeFailedListener = context.data.on("session.execution.failed", (event) => handleLiveError(context, event))
    const removeSucceededListener = context.data.on("session.execution.succeeded", (event) => handleLiveError(context, event))
    const removeInterruptedListener = context.data.on("session.execution.interrupted", (event) => handleLiveInterrupted(context, event))

    context.keymap.layer(() => ({
      mode: "global",
      priority: 10,
      commands: [
        {
          id: "voice.live",
          title: "Voz: iniciar o terminar conversación Live",
          group: "Voz",
          bind: "f4",
          palette: true,
          slash: { name: "live", aliases: ["voice"] },
          run: async () => {
            if (state.live.active || state.live.starting) await stopLive()
            else startLive(context)
          },
        },
        {
          id: "voice.ask",
          title: "Voz: transcribir y enviar texto al chat",
          group: "Voz",
          bind: "f5",
          palette: true,
          slash: { name: "voice-ask", aliases: ["stt"] },
          run: async () => {
            if (state.live.active || state.live.starting) {
              await stopLive()
              startRecording(context)
            } else if (state.recording) {
              await stopAndTranscribe(context)
            } else {
              startRecording(context)
            }
          },
        },
        {
          id: "voice.mute",
          title: "Voz: mutear o reactivar el micrófono Live",
          group: "Voz",
          bind: "f6",
          palette: true,
          run: async () => {
            if (state.live.active) await toggleLiveMute(context)
            else toast(context, "F6 mutea el micrófono durante Live; usa F5 para dictar", "info", "Voz", 3500)
          },
        },
        {
          id: "voice.config",
          title: "Voz: configurar la ruta de respuestas",
          group: "Voz",
          bind: "f3",
          palette: true,
          slash: { name: "voice-config" },
          run: async () => configureVoiceBackend(context),
        },
        {
          id: "voice.stop",
          title: "Voz: colgar Live o cancelar grabación",
          group: "Voz",
          bind: "f7",
          palette: true,
          run: async () => {
            if (state.live.active || state.live.starting) await stopLive()
            else await cancelRecording(context)
          },
        },
        {
          id: "voice.repeat",
          title: "Voz: reenviar última transcripción",
          group: "Voz",
          palette: true,
          run: async () => {
            if (!state.lastText) {
              toast(context, "Todavía no hay una transcripción", "warning", "Voz", 2000)
              return
            }

            try {
              await submitTranscript(context, state.lastText)
            } catch (error) {
              toast(context, `No pude reenviar: ${(error as Error).message}`, "error", "Voz", 6000)
            }
          },
        },
      ],
      bindings: ["voice.live", "voice.ask", "voice.mute", "voice.stop"],
    }))

    return async () => {
      removeTextListener()
      removeIdleListener()
      removeStatusListener()
      removeErrorListener()
      removeFailedListener()
      removeSucceededListener()
      removeInterruptedListener()
      removeLiveStatus()
      updateLiveStatusView = () => {}
      await stopLive()

      const recording = state.recording
      state.recording = null
      if (recording) {
        await stopRecorder(recording.child, "SIGKILL")
        removeRecordingFiles(recording)
      }
    }
  },
})
