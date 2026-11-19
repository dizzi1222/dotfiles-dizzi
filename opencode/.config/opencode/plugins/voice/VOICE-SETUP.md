# Voice routes

`/voice-config` → **Transcripción STT** selects the STT engine and model, then the OpenCode response provider, model and variant for F4 Live. New profiles default to OpenAI GPT-5.6 Luna `low`. Existing profiles keep their selections. **Ruta de respuestas** also offers AGY ACP and Codex app-server, each with a persistent conversation during Live. F5 sends the transcript using the current chat model.

Live transcribes full speech segments and plays the model response when the turn ends. A lower response variant reduces model effort, while transcription and playback have their own latency.

The response selector lists every provider and chat model reported by OpenCode. Disabled models are visible and must be enabled in OpenCode before use.

Linux defaults to local faster-whisper (`small`, Spanish). Install with `python3 -m pip install 'faster-whisper>=1.1.1' 'av<14'` in your Python environment. Keep `voice-stt-faster-whisper.py` next to `~/.local/bin/opencode-voice`. Set `OPENCODE_VOICE_PYTHON` if using a virtual environment.

Termux preserves ALSA capture, `termux-tts-speak`, its Bun shebang and Gemini STT default. Install local STT from the host shell with `bash home/termux-basic-setup.sh --voice-only` (also included in the full setup). This creates an isolated Python 3.12 environment in Ubuntu/proot at `/opt/opencode-voice`, installs faster-whisper 1.2.1 with PyAV 13.1.0, deploys the transcriber and helper, and checks imports. PyAV is pinned because version 19 removes an argument used by this faster-whisper release. `voice-python-termux` selects this glibc runtime automatically; `OPENCODE_VOICE_PYTHON` remains an explicit override. Select Faster Whisper in `/voice-config`. The first transcription downloads the selected model; microphone capture and Android TTS stay in Termux. Gemini/OpenAI remain available with their API keys.

The saved STT preference wins over shell variables, including `VOICE_PROVIDER=gemini`. If you already have a copy in `~/.local/bin`, update it together with the helper. From the root of the checked-out dotfiles branch:

```sh
install -d "$HOME/.local/bin"
install -m 755 local/.local/bin/opencode-voice "$HOME/.local/bin/opencode-voice"
install -m 644 local/.local/bin/voice-stt-faster-whisper.py "$HOME/.local/bin/voice-stt-faster-whisper.py"
"$HOME/.local/bin/opencode-voice" check-stt
```

Use the check for local Whisper. A failure reports that the installed transcriber, helper or compatible Python runtime needs attention. In Termux, run this from the host Android shell to check its actual paths and dependencies.

Use `opencode-voice doctor` on the target machine, then test two F4 turns and F5 dictation. A successful build does not validate the Android microphone or TTS service.
