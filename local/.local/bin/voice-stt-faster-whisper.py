"""Small JSON bridge for the local faster-whisper STT backend."""
import json
import sys
from importlib import import_module
from importlib.metadata import version


def check_runtime():
    """Report whether faster-whisper and a supported CTranslate2 are importable."""
    try:
        faster_whisper_version = version("faster-whisper")
        ctranslate2_version = version("ctranslate2")
        major_version = int(ctranslate2_version.split(".", 1)[0])
        if major_version != 4:
            raise RuntimeError(
                f"CTranslate2 {ctranslate2_version} is unsupported; expected >=4,<5"
            )
        import_module("faster_whisper")
        return {
            "ready": True,
            "python": sys.executable,
            "faster_whisper": faster_whisper_version,
            "ctranslate2": ctranslate2_version,
        }
    except Exception as error:
        return {
            "ready": False,
            "python": sys.executable,
            "faster_whisper": None,
            "ctranslate2": None,
            "error": f"faster-whisper/CTranslate2 incompatible: {error}",
        }


def load_model(model_name, prefer_cuda=True):
    """Load faster-whisper in CUDA mode or explicitly on CPU."""
    WhisperModel = import_module("faster_whisper").WhisperModel

    if prefer_cuda:
        try:
            return WhisperModel(model_name, device="cuda", compute_type="float16")
        except Exception:
            pass
    return WhisperModel(model_name, device="cpu", compute_type="int8")


def transcribe_file(model, model_name, wav_path, language):
    def transcribe_with(model):
        segments, _info = model.transcribe(
            wav_path,
            language=language,
            beam_size=5,
            vad_filter=True,
            condition_on_previous_text=False,
            temperature=0.0,
        )
        return list(segments)

    try:
        segments = transcribe_with(model)
        active_model = model
    except Exception:
        # CUDA puede estar instalado pero no tener cuBLAS compatible. Reintenta
        # en CPU en el mismo proceso para que Live no pierda la transcripción.
        active_model = load_model(model_name, prefer_cuda=False)
        segments = transcribe_with(active_model)
    text = " ".join(segment.text.strip() for segment in segments if segment.text.strip()).strip()
    return text, active_model


def main() -> None:
    if len(sys.argv) == 2 and sys.argv[1] == "--check":
        status = check_runtime()
        print(json.dumps(status, ensure_ascii=False), flush=True)
        raise SystemExit(0 if status["ready"] else 2)

    if len(sys.argv) >= 2 and sys.argv[1] == "--server":
        if len(sys.argv) < 4:
            raise SystemExit("uso: voice-stt-faster-whisper.py --server MODEL LANGUAGE")
        status = check_runtime()
        if not status["ready"]:
            print(json.dumps({"error": status["error"]}, ensure_ascii=False), flush=True)
            raise SystemExit(2)
        model_name, language = sys.argv[2:4]
        model = load_model(model_name)
        print(json.dumps({"ready": True}), flush=True)
        for line in sys.stdin:
            wav_path = line.strip()
            if not wav_path:
                continue
            try:
                text, model = transcribe_file(model, model_name, wav_path, language)
                print(json.dumps({"text": text}, ensure_ascii=False), flush=True)
            except Exception as error:
                print(json.dumps({"error": str(error)}, ensure_ascii=False), flush=True)
        return

    if len(sys.argv) < 4:
        raise SystemExit("uso: voice-stt-faster-whisper.py WAV MODEL LANGUAGE")

    status = check_runtime()
    if not status["ready"]:
        raise SystemExit(status["error"])
    wav_path, model_name, language = sys.argv[1:4]
    model = load_model(model_name)
    text, _model = transcribe_file(model, model_name, wav_path, language)
    print(json.dumps({"text": text}, ensure_ascii=False))


if __name__ == "__main__":
    main()

