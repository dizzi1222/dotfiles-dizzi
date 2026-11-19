# Voice routes

`/voice-config` → **Transcripción STT** selects the STT engine and model, then the OpenCode response provider, model and variant for F4 Live. New profiles default to OpenAI GPT-5.6 Luna `low`. Existing profiles keep their selections. **Ruta de respuestas** also offers AGY ACP and Codex app-server, each with a persistent conversation during Live. F5 sends the transcript using the current chat model.

Live transcribes full speech segments and plays the model response when the turn ends. A lower response variant reduces model effort, while transcription and playback have their own latency.

The response selector lists every provider and chat model reported by OpenCode. Disabled models are visible and must be enabled in OpenCode before use.

Linux defaults to local faster-whisper (`small`, Spanish). Install the pinned Python 3.12 runtime with `bash home/install-opencode-voice-runtime.sh`; it writes `OPENCODE_VOICE_PYTHON` to `~/.config/environment.d/80-opencode-voice.conf`. The helper must stay next to `~/.local/bin/opencode-voice`. The command also detects this runtime directly if the current session has not reloaded the environment file.

Termux preserves ALSA capture, `termux-tts-speak`, its Bun shebang and Gemini STT default. Configure the Gemini API key or choose OpenAI STT with its API key. The Termux branch adds optional local STT through its Ubuntu `proot` runtime: run `bash home/termux-basic-setup.sh --voice-only` from that branch. It pins faster-whisper 1.2.1 with PyAV 13.1.0 and checks the runtime. `voice-python-termux` is selected automatically; `OPENCODE_VOICE_PYTHON` can override it. Android microphone and TTS still need a device test.

The saved STT preference wins over shell variables, including `VOICE_PROVIDER=gemini`. If you already have a copy in `~/.local/bin`, update it together with the helper. From the root of the checked-out dotfiles branch:

```sh
install -d "$HOME/.local/bin"
install -m 755 local/.local/bin/opencode-voice "$HOME/.local/bin/opencode-voice"
install -m 644 local/.local/bin/voice-stt-faster-whisper.py "$HOME/.local/bin/voice-stt-faster-whisper.py"
"$HOME/.local/bin/opencode-voice" check-stt
```

Use the check for local Whisper. A failure reports that the installed transcriber, helper or compatible Python runtime needs attention. In Termux, run this from the host Android shell to check its actual paths and dependencies.

Use `opencode-voice doctor` on the target machine, then test two F4 turns and F5 dictation. A successful build does not validate the Android microphone or TTS service.
