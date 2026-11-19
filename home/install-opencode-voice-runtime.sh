#!/usr/bin/env bash
set -euo pipefail

VOICE_REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
VOICE_HOME="$HOME/.local/share/opencode-voice"
VOICE_VENV="$VOICE_HOME/.venv"
VOICE_PYTHON="$VOICE_VENV/bin/python"
MIN_FREE_KB=$((2 * 1024 * 1024))
AVAILABLE_KB="$(df -Pk "$HOME" | awk 'NR == 2 { print $4 }')"

if [[ -z "$AVAILABLE_KB" || "$AVAILABLE_KB" -lt "$MIN_FREE_KB" ]]; then
  AVAILABLE_GIB=$(( ${AVAILABLE_KB:-0} / 1024 / 1024 ))
  echo "Faster-Whisper requiere 2 GiB libres; ahora hay ${AVAILABLE_GIB} GiB." >&2
  echo "Libera espacio y vuelve a ejecutar este instalador." >&2
  exit 2
fi

UV_INSTALLER=""
UV_CACHE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/opencode-voice-uv.XXXXXX")"
cleanup() {
  [[ -z "$UV_INSTALLER" ]] || rm -f -- "$UV_INSTALLER"
  rm -rf -- "$UV_CACHE_DIR"
}
trap cleanup EXIT

if ! command -v uv >/dev/null 2>&1; then
  UV_INSTALLER="$(mktemp)"
  curl -fsSL --retry 3 --retry-all-errors \
    -o "$UV_INSTALLER" https://astral.sh/uv/install.sh
  bash -n "$UV_INSTALLER"
  sh "$UV_INSTALLER"
  export PATH="$HOME/.local/bin:$PATH"
fi

if ! command -v uv >/dev/null 2>&1; then
  echo "uv no quedó disponible en PATH; instala uv y vuelve a intentarlo." >&2
  exit 1
fi

export UV_CACHE_DIR

mkdir -p "$VOICE_HOME"
uv python install 3.12
uv venv --python 3.12 "$VOICE_VENV"
uv pip install --python "$VOICE_PYTHON" \
  "faster-whisper==1.2.1" \
  "ctranslate2>=4,<5" \
  "av==13.1.0"

mkdir -p "$HOME/.config/environment.d"
printf 'OPENCODE_VOICE_PYTHON="%s"\n' "$VOICE_PYTHON" \
  >"$HOME/.config/environment.d/80-opencode-voice.conf"
export OPENCODE_VOICE_PYTHON="$VOICE_PYTHON"

VOICE_COMMAND="$HOME/.local/bin/opencode-voice"
if [[ ! -x "$VOICE_COMMAND" ]]; then
  VOICE_COMMAND="$VOICE_REPO/local/.local/bin/opencode-voice"
fi
"$VOICE_COMMAND" check-stt
echo "Runtime STT listo: $OPENCODE_VOICE_PYTHON"
echo "Cierra e inicia sesión para que las aplicaciones gráficas reciban la variable nueva."
