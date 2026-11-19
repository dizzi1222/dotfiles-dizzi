import { Plugin } from "@opencode/plugin/tui"
import { randomUUID } from "node:crypto"
import { accessSync, constants, existsSync, mkdirSync, mkdtempSync, rmSync, statSync } from "node:fs"
import { execFile, spawn, spawnSync, type ChildProcess } from "node:child_process"
import { delimiter, join } from "node:path"
import { homedir, platform, tmpdir } from "node:os"
import { promisify } from "node:util"
import { createSignal, Show } from "solid-js"

type TVoiceBackend = "oauth" | "agy" | "codex"
type TVoiceSttProvider = "faster-whisper" | "windows" | "openai" | "gemini"

interface IVoiceRouteProfile {
  provider: string
  model: string
  variant?: string
}

interface IVoicePreferences {
  backend: TVoiceBackend
  routes: Record<TVoiceBackend, IVoiceRouteProfile>
  stt: {
    provider: TVoiceSttProvider
    model: string
    language: string
  }
}

const DEFAULT_VOICE_PREFERENCES: IVoicePreferences = {
  backend: "oauth",
  routes: {
    oauth: { provider: "openai", model: "gpt-5.6-luna", variant: "low" },
    agy: { provider: "antigravity", model: "gemini-3.8-flash-medium" },
    codex: { provider: "codex-app-server", model: "gpt-5.6-luna", variant: "max" },
  },
  stt: { provider: process.env.PREFIX?.includes("com.termux") ? "gemini" : "faster-whisper", model: process.env.PREFIX?.includes("com.termux") ? "gemini-2.5-flash" : "small", language: "es" },
}

//Config
const run = promisify(execFile)
const PREFIX = process.env.PREFIX
const IS_TERMUX = PREFIX?.includes("com.termux") === true
const IS_WSL = Boolean(process.env.WSL_DISTRO_NAME || process.env.WSL_INTEROP)
const IS_WINDOWS = platform() === "win32"
const PREFER_PULSE_AUDIO = Boolean(
  IS_WSL || process.env.PULSE_SERVER,
)
const AUDIO_ENV: NodeJS.ProcessEnv = { ...process.env }
const TMP_DIR = join(tmpdir(), "opencode-voice")

if (IS_TERMUX) delete AUDIO_ENV.LD_LIBRARY_PATH

interface IRecorderCommand {
  executable: string
  backend: "pipewire" | "alsa" | "pulse" | "windows"
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
  acpClient: IAcpClient | null
  startedAt: number
  clockTimer: ReturnType<typeof setInterval> | null
}

interface IAcpClient {
  agent: "agy" | "codex"
  child: ChildProcess
  buffer: string
  stderr: string
  requestID: number
  pending: Map<number, { resolve: (value: any) => void; reject: (error: Error) => void; timer: ReturnType<typeof setTimeout> }>
  responseText: string
  turnCompletion: Promise<void> | null
  finishTurn: (() => void) | null
  failTurn: ((error: Error) => void) | null
  sessionID: string | null
  threadID: string | null
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
    acpClient: null,
    startedAt: 0,
    clockTimer: null,
  },
}

let voicePreferences: IVoicePreferences = structuredClone(DEFAULT_VOICE_PREFERENCES)
let persistVoicePreferences: (preferences: IVoicePreferences) => Promise<void> = async () => {}
let updateLiveStatusView: (view: ILiveStatusView) => void = () => {}

/** Devuelve la etiqueta visible para la ruta principal de voz. */
function voiceBackendLabel(backend: TVoiceBackend): string {
  if (backend === "agy") return "AGY ACP"
  if (backend === "codex") return "Codex app-server"
  return "OpenCode"
}

function cloneVoicePreferences(): IVoicePreferences {
  return JSON.parse(JSON.stringify(voicePreferences)) as IVoicePreferences
}

/** Configura la ruta con la jerarquía Motor -> Provider -> Modelo -> Variante. */
async function configureVoiceRoute(context: any): Promise<void> {
  const backend = await context.ui.dialog.select({
    title: "Motor de respuestas de voz",
    current: state.voiceBackend,
    options: [
      { title: "OpenCode", value: "oauth", description: "Providers y modelos configurados en OpenCode." },
      { title: "AGY ACP", value: "agy", description: "Sesión persistente de Antigravity ACP." },
      { title: "Codex app-server", value: "codex", description: "Codex oficial por JSON-RPC; no usa codex-acp." },
    ],
  }) as TVoiceBackend | undefined
  if (!backend) return

  if (backend === "oauth") {
    const response = await selectOpenCodeVoiceProfile(context)
    if (!response) return
    const next = cloneVoicePreferences()
    next.backend = "oauth"
    next.routes.oauth = response
    await saveVoiceConfiguration(context, next)
    return
  }

  const provider = backend === "agy" ? "antigravity" : "codex-app-server"
  const modelOptions = {
    agy: [
      { title: "Gemini 3.8 Flash Medium", value: "gemini-3.8-flash-medium" },
      { title: "Gemini 3.8 Flash High", value: "gemini-3.8-flash-high" },
      { title: "Claude Sonnet 4.6", value: "claude-sonnet-4-6" },
      { title: "Claude Opus 4.6 Thinking", value: "claude-opus-4-6-thinking" },
      { title: "GPT-OSS 120B Medium", value: "gpt-oss-120b-medium" },
    ],
    codex: [
      { title: "GPT-5.6 Luna", value: "gpt-5.6-luna" },
      { title: "GPT-6 Luna", value: "gpt-6-luna" },
    ],
  }
  const model = await context.ui.dialog.select({
    title: `${voiceBackendLabel(backend)} · Modelo`,
    current: voicePreferences.routes[backend].model,
    options: modelOptions[backend],
  }) as string | undefined
  if (!model) return

  let variant: string | undefined
  if (backend !== "agy") {
    variant = await context.ui.dialog.select({
      title: `${voiceBackendLabel(backend)} · Variante`,
      current: voicePreferences.routes[backend].variant ?? "max",
      options: ["max", "xhigh", "high", "medium", "low", "none"].map((value) => ({ title: value, value })),
    }) as string | undefined
    if (!variant) return
  }

  const next = cloneVoicePreferences()
  next.backend = backend
  next.routes[backend] = { provider, model, ...(variant ? { variant } : {}) }
  voicePreferences = next
  state.voiceBackend = backend
  await persistVoicePreferences(next)
  const active = state.live.active ? " Se aplicará al iniciar Live de nuevo." : ""
  toast(
    context,
    `${voiceBackendLabel(backend)} · ${provider} · ${model}${variant ? ` · ${variant}` : ""}.${active}`,
    "success",
    "Voz",
    6000,
  )
}

type VoiceChatModel = {
  id: string
  providerID: string
  name?: string
  type: string
  enabled?: boolean
  variants?: Array<{ id: string }>
}

async function voiceChatModels(context: any): Promise<VoiceChatModel[]> {
  const result = await context.client.model.list()
  const models = result?.data ?? result
  if (!Array.isArray(models)) throw new Error("No pude cargar los modelos de OpenCode")
  return models.filter(model => model.type === "chat" && model.enabled !== false)
}

async function selectOpenCodeVoiceProfile(context: any): Promise<IVoiceRouteProfile | undefined> {
  try {
    const models = await voiceChatModels(context)
    if (!models.length) throw new Error("No hay modelos de chat habilitados en OpenCode")
    const saved = voicePreferences.routes.oauth
    const providers = [...new Set(models.map(model => model.providerID))].sort()
    const provider = await context.ui.dialog.select({
      title: "Respuesta OpenCode · Provider",
      current: saved.provider,
      options: providers.map(value => ({ title: value, value })),
    })
    if (!providers.includes(provider)) return
    const id = await context.ui.dialog.select({
      title: "Respuesta OpenCode · Modelo",
      current: provider === saved.provider ? saved.model : undefined,
      options: models.filter(model => model.providerID === provider)
        .map(model => ({ title: model.name ?? model.id, value: model.id })),
    })
    const model = models.find(entry => entry.id === id && entry.providerID === provider)
    if (!model) return
    const variants = (model.variants ?? []).map(entry => entry.id)
    if (!variants.length) return { provider, model: model.id }
    const variant = await context.ui.dialog.select({
      title: "Respuesta OpenCode · Variant",
      current: saved.model === id && saved.provider === provider && variants.includes(saved.variant ?? "")
        ? saved.variant : "__default__",
      options: [
        { title: "Predeterminada del modelo", value: "__default__" },
        ...variants.map(value => ({ title: value, value })),
      ],
    })
    if (variant === "__default__") return { provider, model: model.id }
    if (variants.includes(variant)) return { provider, model: model.id, variant }
  } catch (error) {
    toast(context, "Configuración de respuesta: " + (error as Error).message, "error", "Voz", 6000)
  }
}

async function saveVoiceConfiguration(context: any, next: IVoicePreferences): Promise<void> {
  await persistVoicePreferences(next)
  voicePreferences = next
  state.voiceBackend = next.backend
  const response = next.routes[next.backend]
  const summary = [response.provider, response.model, response.variant].filter(Boolean).join("/")
  const restart = state.live.active ? " Reinicia Live para aplicar." : ""
  toast(context, "STT " + next.stt.provider + "/" + next.stt.model + " · Respuesta " + summary + "." + restart, "success", "Voz", 6000)
}

/** Configura provider, modelo e idioma del reconocimiento de voz. */
async function configureVoiceStt(context: any): Promise<void> {
  const provider = await context.ui.dialog.select({
    title: "Transcripción · Provider",
    current: voicePreferences.stt.provider,
    options: [
      { title: "faster-whisper local", value: "faster-whisper", description: "Whisper local; sin API key." },
      { title: "Windows SAPI", value: "windows", description: "Reconocedor incluido en Windows." },
      { title: "OpenAI API", value: "openai", description: "Requiere OPENAI_API_KEY." },
      { title: "Gemini API", value: "gemini", description: "Requiere GOOGLE_API_KEY o GEMINI_API_KEY." },
    ].filter(option => IS_WINDOWS || option.value !== "windows"),
  }) as TVoiceSttProvider | undefined
  if (!provider) return

  const modelOptions: Record<TVoiceSttProvider, Array<{ title: string; value: string }>> = {
    "faster-whisper": [
      { title: "Whisper small", value: "small" },
      { title: "Whisper medium", value: "medium" },
      { title: "Whisper large-v3", value: "large-v3" },
    ],
    windows: [{ title: "System.Speech local", value: "local" }],
    openai: [
      { title: "gpt-4o-mini-transcribe", value: "gpt-4o-mini-transcribe" },
      { title: "gpt-4o-transcribe", value: "gpt-4o-transcribe" },
    ],
    gemini: [{ title: "Gemini 2.5 Flash", value: "gemini-2.5-flash" }],
  }
  const model = await context.ui.dialog.select({
    title: `${provider} · Modelo STT`,
    current: voicePreferences.stt.model,
    options: modelOptions[provider],
  }) as string | undefined
  if (!model) return

  const response = await selectOpenCodeVoiceProfile(context)
  if (!response) return
  const next = cloneVoicePreferences()
  next.stt = { provider, model, language: next.stt.language || "es" }
  next.backend = "oauth"
  next.routes.oauth = response
  await saveVoiceConfiguration(context, next)
}

/** Abre el selector de ruta o el selector de STT. */
async function configureVoiceBackend(context: any): Promise<void> {
  const area = await context.ui.dialog.select({
    title: "Configuración de voz",
    options: [
      { title: "Ruta de respuestas", value: "route", description: "Motor -> Provider -> Modelo -> Variante." },
      { title: "Transcripción STT", value: "stt", description: "Motor y modelo STT, luego provider, modelo y variant de respuesta." },
    ],
  }) as "route" | "stt" | undefined
  if (area === "route") await configureVoiceRoute(context)
  if (area === "stt") await configureVoiceStt(context)
}

//AudioTools
/** Busca un ejecutable por ruta absoluta o en los directorios de PATH. */
function resolveExecutable(command: string): string | null {
  if (IS_WINDOWS) {
    const extensions = [".exe", ".cmd", ".bat", ".ps1", ""]
    const absolute = command.includes("/") || command.includes("\\")
    const candidates = absolute
      ? [command]
      : (process.env.PATH ?? "").split(delimiter).map((directory) => join(directory, command))

    for (const candidate of candidates) {
      try {
        accessSync(candidate, constants.F_OK)
        return candidate
      } catch {}

      const lowered = candidate.toLowerCase()
      const hasExtension = extensions.some((extension) => extension && lowered.endsWith(extension))
      if (hasExtension) {
        try {
          accessSync(candidate, constants.F_OK)
          return candidate
        } catch {}
        continue
      }
      for (const extension of extensions) {
        try {
          accessSync(`${candidate}${extension}`, constants.F_OK)
          return `${candidate}${extension}`
        } catch {}
      }
    }

    return null
  }

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

/** Nombre del dispositivo DirectShow elegido para la captura en Windows. */
let windowsAudioDevice: string | null = null

/** Puntúa un micrófono para preferir el físico sobre cámaras y dispositivos virtuales. */
function rankWindowsAudioDevice(name: string): number {
  const lowered = name.toLowerCase()
  let score = 0
  if (/microphone|micrófono|array|headset|mic\b/.test(lowered)) score += 2
  if (/irium|obs|virtual|webcam|cable|vb-audio|voicemeeter|virtual-audio-capturer|nvidia broadcast/.test(lowered)) score -= 5
  return score
}

/** Descubre el micrófono por defecto de Windows consultando a FFmpeg (DirectShow). */
function findWindowsAudioDevice(ffmpeg: string): string | null {
  if (windowsAudioDevice) return windowsAudioDevice
  const configured = process.env.VOICE_DEVICE
  if (configured) {
    windowsAudioDevice = configured
    return windowsAudioDevice
  }

  const result = spawnSync(
    ffmpeg,
    ["-hide_banner", "-list_devices", "true", "-f", "dshow", "-i", "dummy"],
    { encoding: "utf8", timeout: 10000, stdio: ["ignore", "pipe", "pipe"], windowsHide: true },
  )
  const output = [result.stderr, result.stdout, result.error?.message].filter(Boolean).join("\n")
  const devices = [...output.matchAll(/"([^"]+)"\s*\(audio\)/gi)].map((match) => match[1])
  const ranked = devices
    .map((name, index) => ({ name, index, score: rankWindowsAudioDevice(name) }))
    .sort((left, right) => right.score - left.score || left.index - right.index)
  windowsAudioDevice = ranked[0]?.name ?? null
  return windowsAudioDevice
}

/** Encuentra el grabador disponible, priorizando DirectShow en Windows y PulseAudio en WSLg. */
function findRecorder(): IRecorderCommand | null {
  if (IS_WINDOWS) {
    const ffmpeg = findFfmpeg()
    if (!ffmpeg) return null
    if (!findWindowsAudioDevice(ffmpeg)) return null
    return { executable: ffmpeg, backend: "windows" }
  }

  const candidates = IS_TERMUX
    ? [{ command: "arecord", backend: "alsa" as const }]
    : PREFER_PULSE_AUDIO
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

/** Construye los argumentos de captura para PipeWire, PulseAudio, ALSA, Termux o Windows. */
function recorderArguments(recorder: IRecorderCommand, rawPath: string): string[] {
  if (recorder.backend === "windows") {
    const device = windowsAudioDevice ?? process.env.VOICE_DEVICE ?? "Microphone"
    const input = device.startsWith("audio=") ? device : `audio=${device}`
    return [
      "-hide_banner",
      "-loglevel", "error",
      "-f", "dshow",
      "-i", input,
      "-ar", "16000",
      "-ac", "1",
      "-f", "s16le",
      "-acodec", "pcm_s16le",
      "-y",
      rawPath,
    ]
  }

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


  return ["--raw", "--format=s16", "--rate=16000", "--channels=1", rawPath]
}

/** Encuentra ffmpeg en Termux o en el PATH del sistema. */
function findFfmpeg(): string | null {
  const configured = process.env.FFMPEG_PATH
  if (configured) {
    const executable = resolveExecutable(configured)
    if (executable) return executable
  }

  if (IS_TERMUX && PREFIX) {
    const termuxBinary = resolveExecutable(join(PREFIX, "bin", "ffmpeg"))
    if (termuxBinary) return termuxBinary
  }

  const fromPath = resolveExecutable("ffmpeg")
  if (fromPath) return fromPath

  if (IS_WINDOWS) {
    return resolveExecutable(join(homedir(), "AppData", "Local", "Microsoft", "WinGet", "Links", "ffmpeg.exe"))
  }
  return null
}

/** Localiza el transcriptor opencode-voice instalado por Home Manager, Termux o Windows. */
function findVoiceBinary(): string | null {
  const candidates = [
    process.env.OPENCODE_VOICE_BIN,
    join(homedir(), ".local", "bin", "opencode-voice"),
    IS_TERMUX && PREFIX ? join(PREFIX, "bin", "opencode-voice") : undefined,
    IS_WINDOWS ? join(homedir(), ".local", "bin", "opencode-voice.exe") : undefined,
    IS_WINDOWS ? join(homedir(), ".local", "bin", "opencode-voice.mjs") : undefined,
  ]

  for (const candidate of candidates) {
    if (!candidate) continue
    const executable = resolveExecutable(candidate)
    if (executable) return executable
  }

  return resolveExecutable("opencode-voice")
}

interface IVoiceCommand {
  executable: string
  args: string[]
}

/** Encuentra Node.js real para ejecutar el transcriptor .mjs desde el TUI empaquetado. */
function findNodeExecutable(): string | null {
  const candidates = [
    process.env.OPENCODE_VOICE_NODE,
    process.env.NODE_BINARY,
    "node",
    IS_WINDOWS ? join(process.env.ProgramFiles ?? "C:\\Program Files", "nodejs", "node.exe") : undefined,
  ]

  for (const candidate of candidates) {
    if (!candidate) continue
    const executable = resolveExecutable(candidate)
    if (executable) return executable
  }

  return null
}

/** Resuelve cómo invocar el transcriptor: binario nativo o Node para el script .mjs de Windows. */
function resolveVoiceCommand(commandArgs: string[]): IVoiceCommand | null {
  const binary = findVoiceBinary()
  if (!binary) return null
  if (IS_WINDOWS && /\.mjs$/i.test(binary)) {
    const node = findNodeExecutable()
    if (!node) throw new Error("No encuentro node.exe para ejecutar opencode-voice.mjs")
    return { executable: node, args: [binary, ...commandArgs] }
  }
  return { executable: binary, args: commandArgs }
}

/** Inyecta la configuración STT persistida en cada proceso de captura. */
function voiceEnvironment(overrides?: NodeJS.ProcessEnv): NodeJS.ProcessEnv {
  const stt = voicePreferences.stt
  const environment: NodeJS.ProcessEnv = {
    ...AUDIO_ENV,
    ...overrides,
    VOICE_PROVIDER: stt.provider,
    VOICE_MODEL: stt.model,
    VOICE_LANGUAGE: stt.language,
  }
  if (IS_WINDOWS) {
    delete environment.VOICE_DEVICE
    const ffmpeg = findFfmpeg()
    const device = ffmpeg ? findWindowsAudioDevice(ffmpeg) : null
    if (device) environment.VOICE_DEVICE = device
  }
  return environment
}

/** Ejecuta el transcriptor como proceso hijo compatible con Windows. */
function spawnVoice(commandArgs: string[], options: Parameters<typeof spawn>[2]): ChildProcess {
  const voice = resolveVoiceCommand(commandArgs)
  if (!voice) throw new Error("Falta ~/.local/bin/opencode-voice")
  const merged = { ...options, env: voiceEnvironment(options?.env) }
  return spawn(voice.executable, voice.args, IS_WINDOWS ? { ...merged, windowsHide: true } : merged)
}

/** Ejecuta el transcriptor y recoge su salida estándar. */
function runVoice(commandArgs: string[], options: Parameters<typeof execFile>[2]): Promise<{ stdout: string; stderr: string }> {
  const voice = resolveVoiceCommand(commandArgs)
  if (!voice) return Promise.reject(new Error("Falta ~/.local/bin/opencode-voice"))
  return run(
    voice.executable,
    voice.args,
    IS_WINDOWS ? { ...options, env: voiceEnvironment(options?.env), windowsHide: true } : { ...options, env: voiceEnvironment(options?.env) },
  ) as Promise<{ stdout: string; stderr: string }>
}

async function checkVoiceStt(): Promise<void> {
  if (voicePreferences.stt.provider !== "faster-whisper") return
  try {
    await runVoice(["check-stt"], { timeout: 25000 })
  } catch (error) {
    const detail = String((error as { stderr?: string }).stderr ?? "").trim()
    const hasDiagnostic = detail.startsWith("STT faster-whisper:")
    throw new Error(hasDiagnostic ? detail : "Actualiza opencode-voice y su helper juntos. El transcriptor instalado no pudo comprobar faster-whisper.")
  }
}

function initialVoiceStt(): IVoicePreferences["stt"] {
  const defaults = DEFAULT_VOICE_PREFERENCES.stt
  const provider = process.env.VOICE_PROVIDER
  if (provider !== "faster-whisper" && provider !== "gemini" && provider !== "openai" &&
    !(provider === "windows" && IS_WINDOWS)) return defaults
  const models = {
    "faster-whisper": "small", gemini: "gemini-2.5-flash",
    openai: "gpt-4o-mini-transcribe", windows: "local",
  }
  return { provider, model: process.env.VOICE_MODEL || models[provider], language: process.env.VOICE_LANGUAGE || defaults.language }
}

/** Encuentra el sintetizador disponible en Linux, Termux o Windows. */
function findSpeaker(): string | null {
  const configured = process.env.OPENCODE_TTS_BIN
  if (configured) return resolveExecutable(configured)
  if (IS_TERMUX && PREFIX) return resolveExecutable(join(PREFIX, "bin", "termux-tts-speak"))
  if (IS_WINDOWS) return resolveExecutable("powershell")
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

/** Escribe trazas de voz en el log de OpenCode sin incluir audio crudo. */
function voiceLog(event: string, details: Record<string, unknown> = {}): void {
  try {
    console.info(`[voice] ${JSON.stringify({ event, at: new Date().toISOString(), ...details })}`)
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

/** Aplica el perfil de respuesta de OpenCode a la sesión Live. */
async function selectLiveOpenCodeModel(context: any, sessionID: string): Promise<void> {
  const client = context?.client
  if (!client?.session?.get || !client?.session?.switchModel || !client?.model?.list) {
    throw new Error("Esta versión de OpenCode no permite cambiar el modelo de la sesión desde el plugin")
  }
  const configured = voicePreferences.routes.oauth
  const [sessionResult, models] = await Promise.all([
    client.session.get({ sessionID }),
    voiceChatModels(context),
  ])
  const currentModel = (sessionResult?.data ?? sessionResult)?.model
  const model = models.find(candidate => candidate.id === configured.model && candidate.providerID === configured.provider)
  if (!model) throw new Error("Modelo no disponible: " + configured.provider + "/" + configured.model + ". Revisa /voice-config.")
  if (configured.variant && !model.variants?.some(entry => entry.id === configured.variant)) {
    throw new Error("Variant no disponible: " + configured.variant + ". Revisa /voice-config.")
  }
  const selected = { id: model.id, providerID: model.providerID, variant: configured.variant }
  await client.session.switchModel({ sessionID, model: selected })
  liveModelRefs.set(sessionID, {
    id: currentModel?.id,
    providerID: currentModel?.providerID,
    variant: currentModel?.variant,
    selected,
  })
  voiceLog("opencode_model_selected", { sessionID, ...selected })
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
function stopRecorder(
  child: ChildProcess,
  signal: NodeJS.Signals = "SIGINT",
  gracefulWindowsFFmpeg = false,
): Promise<void> {
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
      if (child.exitCode !== null || child.signalCode !== null) {
        finish()
        return
      }

      child.kill("SIGKILL")
    }, 30000)

    child.once("close", finish)
    if (child.exitCode !== null || child.signalCode !== null) {
      finish()
      return
    }

    if (gracefulWindowsFFmpeg && IS_WINDOWS && child.stdin) {
      try {
        child.stdin.write("q\n")
        child.stdin.end()
        return
      } catch {}
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
    const message = IS_WINDOWS
      ? "No encontré FFmpeg con DirectShow o un micrófono disponible"
      : "No encontré pw-record, parecord ni arecord"
    toast(context, message, "error", "Voz", 6000)
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
    child: execFile(recorder.executable, recorderArguments(recorder, rawPath), {
      env: AUDIO_ENV,
      windowsHide: IS_WINDOWS,
    }),
    directory,
    rawPath,
    wavPath,
  }
  state.recording = recording
  let recorderError = ""

  recording.child.stderr?.on("data", (chunk: Buffer) => {
    recorderError = `${recorderError}${chunk.toString()}`.slice(-2000)
  })

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
    const errorMessage = recorderError.trim() || `El grabador terminó inesperadamente (code=${code})`
    toast(context, errorMessage, "error", "Voz", 6000)
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
    await stopRecorder(recording.child, "SIGINT", IS_WINDOWS)
    if (!existsSync(recording.rawPath) || statSync(recording.rawPath).size === 0) {
      toast(context, "No se capturó audio; revisa el micrófono", "warning", "Voz", 6000)
      return
    }

    const ffmpeg = findFfmpeg()
    if (!ffmpeg || !findVoiceBinary()) throw new Error("Falta ffmpeg o ~/.local/bin/opencode-voice")

    await run(
      ffmpeg,
      ["-y", "-f", "s16le", "-ar", "16000", "-ac", "1", "-i", recording.rawPath, recording.wavPath],
      { timeout: 20000, env: AUDIO_ENV, windowsHide: IS_WINDOWS },
    )

    if (statSync(recording.wavPath).size <= 44) {
      toast(context, "No se detectó voz", "warning", "Voz", 4000)
      return
    }

    await checkVoiceStt()
    const { stdout } = await runVoice(["transcribe", recording.wavPath], {
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
  await stopRecorder(recording.child, "SIGTERM", IS_WINDOWS)
  removeRecordingFiles(recording)
  toast(context, "Grabación cancelada", "info", "Voz", 1500)
}

//LiveConversation
/** Publica al TUI el estado efímero que muestra la franja Live. */
function publishLiveStatus(): void {
  const profile = voicePreferences.routes[state.live.voiceBackend]
  updateLiveStatusView({
    active: state.live.active,
    muted: state.live.muted,
    phase: state.live.phase,
    route: state.live.fallbackAgent
      ? state.live.fallbackAgent === "agy" ? "AGY ACP" : "Codex app-server"
      : `${voiceBackendLabel(state.live.voiceBackend)} · ${profile.model}${profile.variant ? `/${profile.variant}` : ""}`,
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

  if (!findVoiceBinary()) {
    void stopLive()
    toast(context, "Falta ~/.local/bin/opencode-voice", "error", "Live", 6000)
    return
  }

  live.listenerBuffer = ""
  live.phase = "listening"
  publishLiveStatus()

  let child: ChildProcess
  try {
    child = spawnVoice(["listen"], {
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
  voiceLog("transcript", {
    route: live.voiceBackend,
    provider: voicePreferences.stt.provider,
    model: voicePreferences.stt.model,
    language: voicePreferences.stt.language,
    chars: text.length,
    ...(process.env.VOICE_DEBUG ? { text } : {}),
  })
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

/** Sintetiza la respuesta con eSpeak NG, PulseAudio, SAPI de Windows o el TTS nativo de Termux. */
async function speakAssistantResponse(text: string): Promise<void> {
  const speaker = findSpeaker()
  if (!speaker) throw new Error("Falta espeak-ng, termux-tts-speak o PowerShell")

  const spokenText = cleanSpeechText(text)
  if (!spokenText) return

  const language = process.env.VOICE_LANGUAGE ?? "es"
  const voice = process.env.OPENCODE_TTS_VOICE ?? "es-419"
  const speed = process.env.OPENCODE_TTS_SPEED ?? "165"

  if (IS_WINDOWS) {
    const rate = Math.max(-10, Math.min(10, Math.round((Number(speed) - 165) / 20)))
    const script = [
      "$ErrorActionPreference = 'Stop'",
      "Add-Type -AssemblyName System.Speech",
      "$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer",
      "$reader = [System.IO.StreamReader]::new([Console]::OpenStandardInput(), [System.Text.Encoding]::UTF8)",
      "try {",
      `$synth.Rate = ${Number.isFinite(rate) ? rate : 0}`,
      "$voice = $synth.GetInstalledVoices() | Where-Object { $_.Enabled -and $_.VoiceInfo.Culture.Name -like ($env:OPENCODE_TTS_LANGUAGE + '*') } | Select-Object -First 1",
      "if ($voice) { $synth.SelectVoice($voice.VoiceInfo.Name) }",
      "$synth.Speak($reader.ReadToEnd())",
      "} finally { $reader.Dispose(); $synth.Dispose() }",
    ].join("\n")

    const child = spawn(speaker, [
      "-NoProfile", "-NonInteractive", "-EncodedCommand", Buffer.from(script, "utf16le").toString("base64"),
    ], {
      env: { ...AUDIO_ENV, OPENCODE_TTS_LANGUAGE: language },
      stdio: ["pipe", "ignore", "pipe"],
      windowsHide: true,
    })
    state.live.speaker = child
    state.live.speakerPlayer = null
    try {
      const closed = waitForAudioProcess(child, "SAPI de Windows")
      child.stdin?.end(spokenText)
      await closed
    } finally {
      if (state.live.speaker === child) state.live.speaker = null
      state.live.speakerPlayer = null
    }
    return
  }

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
async function finishLiveTurn(context: any, sessionID: string, interrupted = false): Promise<void> {
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
  } else if (!interrupted) {
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

/** Conserva el texto recibido incluso si la ejecución se interrumpe a mitad de respuesta. */
function collectLiveResponse(event: any, complete: boolean): void {
  const live = state.live
  if (!live.active || !live.awaitingResponse || event?.data?.sessionID !== live.sessionID) return

  const { assistantMessageID, ordinal, text, delta } = event.data
  const incoming = complete ? text : delta
  if (typeof assistantMessageID !== "string" || typeof ordinal !== "number" || typeof incoming !== "string") return

  const part = live.responseParts.find((item) => item.messageID === assistantMessageID && item.ordinal === ordinal)
  if (part) part.text = complete ? incoming : part.text + incoming
  else live.responseParts.push({ messageID: assistantMessageID, ordinal, text: incoming })
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

/** Reproduce el texto recibido y vuelve al micrófono si la ejecución se interrumpe. */
function handleLiveInterrupted(context: any, event: any): void {
  const sessionID = event?.data?.sessionID
  if (typeof sessionID === "string" && event.data.reason !== "shutdown") {
    void finishLiveTurn(context, sessionID, true)
  }
}

/** Conserva solo los seis intercambios recientes para el contexto de ACP. */
function rememberLiveExchange(userText: string, assistantText: string): void {
  const history = state.live.fallbackHistory
  history.push({ role: "user", text: userText }, { role: "assistant", text: assistantText })
  if (history.length > 12) history.splice(0, history.length - 12)
}

function acpExecutable(agent: "agy" | "codex"): string | null {
  return resolveExecutable(agent === "agy" ? "agy" : "codex")
}

function acpArgs(agent: "agy" | "codex"): string[] {
  return agent === "agy" ? ["acp"] : ["app-server", "--listen", "stdio://"]
}

function sendAcpNotification(client: IAcpClient, method: string, params: Record<string, unknown>): void {
  client.child.stdin?.write(`${JSON.stringify({ jsonrpc: "2.0", method, params })}\n`)
}

function rejectAcpClient(client: IAcpClient, error: Error): void {
  for (const waiting of client.pending.values()) {
    clearTimeout(waiting.timer)
    waiting.reject(error)
  }
  client.pending.clear()
  client.failTurn?.(error)
  client.failTurn = null
  client.finishTurn = null
}

function handleAcpMessage(client: IAcpClient, message: any): void {
  if (client.agent === "agy" && message?.method === "session/update") {
    const update = message.params?.update
    if (update?.sessionUpdate === "agent_message_chunk" && update.content?.type === "text") {
      client.responseText += update.content.text ?? ""
    }
  }
  if (client.agent === "codex" && message?.method === "item/agentMessage/delta") {
    client.responseText += message.params?.delta ?? message.params?.text ?? ""
  }
  if (client.agent === "codex" && message?.method === "turn/completed") {
    const status = message.params?.turn?.status
    if (status === "completed") client.finishTurn?.()
    else client.failTurn?.(new Error(`Codex turn terminó con estado ${status ?? "desconocido"}`))
    client.finishTurn = null
    client.failTurn = null
  }

  const waiting = client.pending.get(message?.id)
  if (!waiting) return
  clearTimeout(waiting.timer)
  client.pending.delete(message.id)
  if (message.error) waiting.reject(new Error(message.error.message ?? `${client.agent} falló`))
  else waiting.resolve(message.result)
}

function acpRequest(client: IAcpClient, method: string, params: Record<string, unknown>, timeoutMs = 10000): Promise<any> {
  const id = ++client.requestID
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      client.pending.delete(id)
      reject(new Error(`${client.agent} agotó el tiempo en ${method}`))
    }, timeoutMs)
    client.pending.set(id, { resolve, reject, timer })
    client.child.stdin?.write(`${JSON.stringify({ jsonrpc: "2.0", id, method, params })}\n`)
  })
}

async function createAcpClient(agent: "agy" | "codex"): Promise<IAcpClient> {
  const executable = acpExecutable(agent)
  if (!executable) throw new Error(`No encuentro el ejecutable ${agent === "agy" ? "agy" : "codex app-server"}`)

  const acpEnv: NodeJS.ProcessEnv = { ...process.env }
  delete acpEnv.OPENAI_API_KEY
  delete acpEnv.GOOGLE_API_KEY
  delete acpEnv.GEMINI_API_KEY
  const child = spawn(executable, acpArgs(agent), {
    cwd: state.live.context?.directory ?? process.cwd(),
    env: acpEnv,
    stdio: ["pipe", "pipe", "pipe"],
    windowsHide: IS_WINDOWS,
  })
  const client: IAcpClient = {
    agent,
    child,
    buffer: "",
    stderr: "",
    requestID: 0,
    pending: new Map(),
    responseText: "",
    turnCompletion: null,
    finishTurn: null,
    failTurn: null,
    sessionID: null,
    threadID: null,
  }
  state.live.acpChild = child
  state.live.acpClient = client
  voiceLog("transport_start", {
    route: agent,
    transport: agent === "agy" ? "acp" : "app-server",
    model: voicePreferences.routes[agent].model,
    variant: voicePreferences.routes[agent].variant,
  })

  child.stdout?.on("data", (chunk: Buffer) => {
    client.buffer += chunk.toString()
    const lines = client.buffer.split("\n")
    client.buffer = lines.pop() ?? ""
    for (const line of lines) {
      if (!line.trim()) continue
      try {
        handleAcpMessage(client, JSON.parse(line))
      } catch {}
    }
  })
  child.stderr?.on("data", (chunk: Buffer) => {
    client.stderr = `${client.stderr}${chunk.toString()}`.slice(-3000)
  })
  child.on("error", (error) => rejectAcpClient(client, error))
  child.on("close", (code) => rejectAcpClient(client, new Error(client.stderr.trim() || `${agent} terminó con code=${code}`)))

  try {
    await acpRequest(client, "initialize", {
      protocolVersion: 1,
      clientCapabilities: {},
      clientInfo: { name: "opencode-voice", version: "0.4.0" },
    })
    sendAcpNotification(client, "initialized", {})
    if (agent === "agy") {
      const profile = voicePreferences.routes.agy
      const session = await acpRequest(client, "session/new", {
        cwd: state.live.context?.directory ?? process.cwd(),
        mcpServers: [],
      })
      client.sessionID = session.sessionId
      const geminiMatch = profile.model.match(/^gemini-3\.8-flash-(high|medium|low)$/)
      const modelValue = geminiMatch ? "gemini-3.8-flash" : profile.model
      await acpRequest(client, "session/set_config_option", {
        sessionId: client.sessionID,
        configId: "model",
        value: modelValue,
      })
      if (geminiMatch) {
        await acpRequest(client, "session/set_config_option", {
          sessionId: client.sessionID,
          configId: "thought_level",
          value: geminiMatch[1],
        })
      }
      voiceLog("agy_session_started", { sessionID: client.sessionID, model: voicePreferences.routes.agy.model })
    } else {
      const profile = voicePreferences.routes.codex
      const thread = await acpRequest(client, "thread/start", {
        cwd: state.live.context?.directory ?? process.cwd(),
        model: profile.model,
        approvalPolicy: "never",
        sandbox: "read-only",
      })
      client.threadID = thread?.thread?.id ?? thread?.threadId ?? null
      if (!client.threadID) throw new Error("Codex app-server no devolvió thread.id")
      voiceLog("codex_thread_started", { threadID: client.threadID, model: profile.model, variant: profile.variant })
    }
    return client
  } catch (error) {
    child.kill("SIGTERM")
    if (state.live.acpClient === client) state.live.acpClient = null
    if (state.live.acpChild === child) state.live.acpChild = null
    throw error
  }
}

async function closeAcpClient(): Promise<void> {
  const client = state.live.acpClient
  state.live.acpClient = null
  state.live.acpChild = null
  if (!client) return
  rejectAcpClient(client, new Error("Live detenido"))
  await stopRecorder(client.child, "SIGTERM")
}

/** Ejecuta múltiples turnos en una sola sesión ACP/app-server durante F4. */
async function runAcpVoiceTurn(agent: "agy" | "codex", text: string): Promise<string> {
  let client = state.live.acpClient
  if (!client || client.agent !== agent) {
    if (client) await closeAcpClient()
    client = await createAcpClient(agent)
  }
  client.responseText = ""
  if (agent === "agy") {
    await acpRequest(client, "session/prompt", {
      sessionId: client.sessionID,
      prompt: [{ type: "text", text: `Responde de forma conversacional, breve y en español. No uses herramientas.\n\n${text}` }],
    }, 90000)
  } else {
    client.turnCompletion = new Promise<void>((resolve, reject) => {
      client!.finishTurn = resolve
      client!.failTurn = reject
    })
    await acpRequest(client, "turn/start", {
      threadId: client.threadID,
      input: [{ type: "text", text }],
      effort: voicePreferences.routes.codex.variant ?? "max",
    }, 15000)
    await client.turnCompletion
    client.turnCompletion = null
  }
  const result = client.responseText.trim()
  voiceLog("response_completed", {
    route: agent,
    sessionID: client.sessionID,
    threadID: client.threadID,
    chars: result.length,
  })
  if (!result) throw new Error(`${agent} terminó sin devolver texto${client.stderr ? `: ${client.stderr.trim()}` : ""}`)
  return result
}

/** Ejecuta la ruta ACP/app-server seleccionada y mantiene fallback explícito. */
async function speakAcpFallback(context: any, text: string): Promise<void> {
  const live = state.live
  const preferredAgent = live.fallbackAgent
    ?? (live.voiceBackend === "codex" ? "codex" : "agy")
  const allowFallback = process.env.OPENCODE_VOICE_ALLOW_FALLBACK === "1"
  const agents: Array<"agy" | "codex"> = allowFallback
    ? preferredAgent === "codex" ? ["codex", "agy"] : ["agy", "codex"]
    : [preferredAgent]
  let lastError: Error | null = null

  for (const agent of agents) {
    let response: string
    try {
      response = await runAcpVoiceTurn(agent, text)
    } catch (error) {
      lastError = error as Error
      await closeAcpClient()
      if (!live.active) return
      continue
    }

    if (!live.active) return
    live.fallbackAgent = agent
    rememberLiveExchange(text, response)
    live.phase = "speaking"
    publishLiveStatus()
    toast(context, `Live responde con ${agent === "agy" ? "AGY ACP" : "Codex app-server"}`, "info", "Voz", 3500)
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
  const missingWindowsTTS = IS_WINDOWS && !findSpeaker()
  if (!findVoiceBinary() || !findRecorder() || !findSpeaker() || missingPulsePlayer || missingWindowsTTS) {
    let requirement = "un grabador y un sintetizador de voz"
    if (missingPulsePlayer) requirement = "paplay para el audio de WSLg"
    if (missingWindowsTTS) requirement = "PowerShell para la síntesis de voz de Windows"
    if (IS_WINDOWS && !findRecorder()) requirement = "FFmpeg con DirectShow y un micrófono disponible"
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
  const sttCheck = checkVoiceStt()
  live.modelSelection = sttCheck
  try {
    await sttCheck
  } catch (error) {
    if (live.starting && live.modelSelection === sttCheck) {
      await stopLive()
      toast(context, (error as Error).message, "error", "Live", 7000)
    }
    return
  }
  if (!live.starting || live.modelSelection !== sttCheck) return
  live.modelSelection = null
  const selectedProfile = voicePreferences.routes[live.voiceBackend]
  voiceLog("live_start", {
    route: live.voiceBackend,
    provider: selectedProfile.provider,
    model: selectedProfile.model,
    variant: selectedProfile.variant,
    sttProvider: voicePreferences.stt.provider,
    sttModel: voicePreferences.stt.model,
  })
  toast(
    context,
    `${voiceBackendLabel(live.voiceBackend)} · ${selectedProfile.provider} · ${selectedProfile.model}${selectedProfile.variant ? ` · ${selectedProfile.variant}` : ""}; STT ${voicePreferences.stt.provider}/${voicePreferences.stt.model}`,
    "info",
    "Live",
    5000,
  )
  if (live.voiceBackend === "oauth") {
    const modelSelection = selectLiveOpenCodeModel(context, sessionID)
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

      if (process.env.OPENCODE_VOICE_ALLOW_FALLBACK === "1") {
        startupFallbackAgent = resolveExecutable("agy")
          ? "agy"
          : resolveExecutable("codex")
            ? "codex"
            : null
      }
      if (!startupFallbackAgent) {
        live.starting = false
        live.sessionID = null
        live.modelSelection = null
        live.context = null
        toast(context, `La ruta OpenCode no pudo activarse y el fallback está deshabilitado: ${(error as Error).message}`, "error", "Live", 7000)
        return
      }
      toast(
        context,
        `La ruta OpenCode no pudo activarse (${(error as Error).message}); Live usará ${startupFallbackAgent === "agy" ? "AGY ACP" : "Codex app-server"}`,
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
  live.acpClient = null
  live.startedAt = Date.now()
  live.clockTimer = setInterval(publishLiveStatus, 1000)
  publishLiveStatus()
  startLiveListener(context, sessionID)
}

/** Detiene la captura y el audio de salida y oculta la franja Live. */
async function stopLive(): Promise<void> {
  const live = state.live
  const sessionID = live.sessionID
  voiceLog("live_stop", { route: live.voiceBackend, sessionID })
  const modelSelection = live.modelSelection
  const listener = live.listener
  const speaker = live.speaker
  const speakerPlayer = live.speakerPlayer
  const acpChild = live.acpChild
  const acpClient = live.acpClient

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
    acpClient ? closeAcpClient() : acpChild ? stopRecorder(acpChild, "SIGTERM") : Promise.resolve(),
    modelSelection ? modelSelection.catch(() => {}) : Promise.resolve(),
  ])
  if (sessionID) await restoreLiveModel(sessionID)
  live.context = null
  live.fallbackAgent = null
  live.fallbackHistory = []
  live.acpClient = null

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

    const [savedPreferences, updateVoicePreferences] = context.storage.store("voice-preferences", {
      initial: { ...structuredClone(DEFAULT_VOICE_PREFERENCES), stt: initialVoiceStt() },
    })
    const saved = savedPreferences as Partial<IVoicePreferences>
    voicePreferences = {
      ...structuredClone(DEFAULT_VOICE_PREFERENCES),
      ...saved,
      routes: { ...DEFAULT_VOICE_PREFERENCES.routes, ...(saved.routes ?? {}) },
      stt: { ...DEFAULT_VOICE_PREFERENCES.stt, ...(saved.stt ?? {}) },
    }
    state.voiceBackend = voicePreferences.backend
    persistVoicePreferences = async (preferences) => {
      await updateVoicePreferences((draft) => {
        Object.assign(draft, preferences)
      })
    }

    const [liveStatus, setLiveStatus] = createSignal<ILiveStatusView>({
      active: false,
      muted: false,
      phase: "listening",
      route: "OpenCode",
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
    const removeTextDeltaListener = context.data.on("session.text.delta", (event) => collectLiveResponse(event, false))
    const removeTextListener = context.data.on("session.text.ended", (event) => collectLiveResponse(event, true))
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
      removeTextDeltaListener()
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
        try {
          await stopRecorder(recording.child)
        } finally {
          removeRecordingFiles(recording)
        }
      }
    }
  },
})
