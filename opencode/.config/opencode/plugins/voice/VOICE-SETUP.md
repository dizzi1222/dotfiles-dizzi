# Voice routes

`/voice-config` selects response route → provider → model → variant, or STT provider → model.
OAuth defaults to GPT-5.6 Luna with `max`. AGY uses a persistent ACP session; Codex uses a persistent official app-server thread. Fallback requires `OPENCODE_VOICE_ALLOW_FALLBACK=1`.

Linux defaults to local faster-whisper (`small`, Spanish). Install with `python3 -m pip install 'faster-whisper>=1.1.1' 'av<14'` in your Python environment. Keep `voice-stt-faster-whisper.py` next to `~/.local/bin/opencode-voice`. Set `OPENCODE_VOICE_PYTHON` if using a virtual environment.

Termux preserves ALSA capture, `termux-tts-speak`, its Bun shebang and Gemini STT default. Configure the Gemini API key or choose OpenAI STT with its API key. Local faster-whisper is optional and requires a compatible CTranslate2/Python installation; it is not assumed available on Android.

Use `opencode-voice doctor` on the target machine, then test two F4 turns and F5 dictation. A successful build does not validate the Android microphone or TTS service.
