#!/data/data/com.termux/files/usr/bin/bash
# Instala STT local reproducible sin ejecutar el resto del setup de Termux.
set -euo pipefail
VOICE_REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ ! -d /data/data/com.termux ]]; then
  echo 'Ejecuta este instalador desde Termux.' >&2
  exit 1
fi
if ! command -v proot-distro >/dev/null; then
  pkg install -y proot-distro
fi
if ! proot-distro list 2>&1 | grep -E '^[[:space:]]*\*[[:space:]]+ubuntu[[:space:]]*$' >/dev/null; then
  proot-distro install ubuntu
fi
env -u LD_LIBRARY_PATH PROOT_NO_SECCOMP=1 proot-distro login ubuntu -- \
  /usr/bin/env PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin HOME=/root \
  /bin/bash -euc '
    if [[ ! -x /opt/opencode-voice-bootstrap/bin/pip ]]; then
      if ! /usr/bin/python3 -m venv /opt/opencode-voice-bootstrap; then
        apt-get update
        DEBIAN_FRONTEND=noninteractive apt-get install -y python3 python3-venv ca-certificates
        /usr/bin/python3 -m venv /opt/opencode-voice-bootstrap
      fi
    fi
    /opt/opencode-voice-bootstrap/bin/pip install uv==0.13.9
    if [[ ! -x /opt/opencode-voice/bin/python ]]; then
      /opt/opencode-voice-bootstrap/bin/uv venv --python 3.12 /opt/opencode-voice
    fi
    # PyAV 19 elimina metadata_errors, todavía usado por faster-whisper 1.2.1.
    /opt/opencode-voice-bootstrap/bin/uv pip install --python /opt/opencode-voice/bin/python faster-whisper==1.2.1 av==13.1.0
    /opt/opencode-voice/bin/python -c "
import io, wave, ctranslate2, av
from faster_whisper.audio import decode_audio
audio = io.BytesIO()
writer = wave.open(audio, \"wb\")
writer.setparams((1, 2, 16000, 0, \"NONE\", \"not compressed\"))
writer.writeframes(bytes(3200))
writer.close()
audio.seek(0)
assert decode_audio(audio).size == 1600
print(\"Runtime STT y decodificacion WAV compatibles\")
"
  '
install -d "$HOME/.local/bin"
for tool in opencode-voice voice-python-termux; do
  install -m 700 "$VOICE_REPO/local/.local/bin/$tool" "$HOME/.local/bin/$tool"
done
install -m 644 "$VOICE_REPO/local/.local/bin/voice-stt-faster-whisper.py" "$HOME/.local/bin/voice-stt-faster-whisper.py"
"$HOME/.local/bin/opencode-voice" check-stt
echo 'Faster Whisper instalado. Selecciónalo en /voice-config; el modelo se descarga en el primer uso.'
