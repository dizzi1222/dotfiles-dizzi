import { Plugin } from "@opencode/plugin/tui"
import { join } from "node:path"
import { existsSync, mkdirSync } from "node:fs"
import { execFile } from "node:child_process"

const TMP_DIR = "/tmp/opencode-voice"
const RECORD_PATH = join(TMP_DIR, "record.raw")

let recording = false
let active = false
let recorderPid: number | null = null
let startTime = 0
let lastTranscript = ""
let muteState = false

function formatTime(ms: number): string {
  const total = Math.floor(ms / 1000)
  const m = String(Math.floor(total / 60)).padStart(2, "0")
  const s = String(total % 60).padStart(2, "0")
  return `${m}:${s}`
}

function transcribeFile(): string {
  const wavPath = join(TMP_DIR, "record.wav")
  execFile("ffmpeg", ["-y", "-f", "s16le", "-ar", "16000", "-ac", "1", "-i", RECORD_PATH, wavPath], {
    env: { ...process.env, USERMOTDSOURCED: "Y" }
  }, () => {})
  try {
    const result = execFileSync("/var/home/diego/.local/bin/opencode-voice", ["transcribe", wavPath], {
      env: { ...process.env, GOOGLE_API_KEY: process.env.GOOGLE_API_KEY, USERMOTDSOURCED: "Y" }
    })
    return result.stdout.trim()
  } catch {
    return ""
  }
}

function startRecording(context: any) {
  if (recording || active) return
  if (!existsSync(TMP_DIR)) { mkdirSync(TMP_DIR, { recursive: true }) }
  try { execFile("pw-record", ["--version"], { timeout: 2000 }) }
  catch { if (context?.ui?.toast?.show) context.ui.toast.show({ title: "Voice", message: "pw-record not found.", variant: "error" }) }
  const child = execFile("pw-record", ["--format=s16le", "--rate=16000", "--channels=1", RECORD_PATH], {
    env: { ...process.env, USERMOTDSOURCED: "Y" }
  })
  child.on("error", function(err) {
    if (context?.ui?.toast?.show) context.ui.toast.show({ title: "Voice", message: "Recorder error: " + err.message, variant: "error" })
    recording = false
    active = false
  })
  ;(globalThis as any).__voiceRecorder = child
  recorderPid = child.pid || null
  recording = true; active = true; startTime = Date.now(); muteState = false
  if (context?.ui?.toast?.show) context.ui.toast.show({ title: "Voice", message: "🎙️ Grabando... (F6=mute, F7=stop, F8=push-to-talk)", variant: "info" })
}

function stopRecording(context: any) {
  if (!active || !recording) return
  recording = false
  if (context?.ui?.toast?.show) context.ui.toast.show({ title: "Voice", message: "🧠 Transcribiendo con Gemini...", variant: "info" })
  const child = (globalThis as any).__voiceRecorder
  if (child) { child.kill("SIGINT"); setTimeout(() => child.kill("SIGKILL"), 500) }
  try {
    const text = transcribeFile()
    if (text && text.trim()) {
      lastTranscript = text.trim()
      if (context?.ui?.toast?.show) context.ui.toast.show({ title: "Voice ✓", message: lastTranscript.slice(0, 100), variant: "success", duration: 3000 })
    } else { if (context?.ui?.toast?.show) context.ui.toast.show({ title: "Voice", message: "Sin voz detectable", variant: "info" }) }
  } catch (e) { if (context?.ui?.toast?.show) context.ui.toast.show({ title: "Voice", message: "Error: " + (e as Error).message, variant: "error" }) }
  active = false; startTime = 0; recorderPid = null
}

function toggleMute(context: any) {
  if (!active || !recording) return
  muteState = !muteState
  const child = (globalThis as any).__voiceRecorder
  if (child && child.pid) { try { process.kill(child.pid, muteState ? "SIGSTOP" : "SIGCONT") } catch {} }
  if (context?.ui?.toast?.show) context.ui.toast.show({ title: "Voice", message: muteState ? "🔇 Silenciado" : "🎙️ Grabando", variant: "info", duration: 1000 })
}

function pushToTalk(context: any) {
  if (active && recording) { stopRecording(context) }
  else if (!active) { startRecording(context) }
}

// Minimal Plugin.define - setup runs synchronously, no await in body
export default Plugin.define({
  id: "voice",
  setup(context) {
    // Register keymap layer with F6/F7/F8 bindings
    try {
      if (context?.keymap?.layer) {
        context.keymap.layer(() => ({
          commands: [
            {
              id: "voice.toggle",
              title: "Toggle voice recording",
              description: "Start or stop voice recording",
              slash: { name: "voice" },
              run: () => { if (active) { stopRecording(context) } else { startRecording(context) } },
            },
            {
              id: "voice.mute",
              title: "Mute/unmute microphone",
              description: "Toggle microphone mute",
              run: () => toggleMute(context),
            },
            {
              id: "voice.stop",
              title: "Stop recording",
              description: "Stop recording and transcribe",
              run: () => stopRecording(context),
            },
            {
              id: "voice.ptt",
              title: "Push-to-talk",
              description: "Start/stop recording",
              run: () => pushToTalk(context),
            },
          ],
          bindings: ["f6", "f7", "f8"],
        }))
      }
    } catch (e) { console.error("voice plugin keymap error:", e) }
  },
})