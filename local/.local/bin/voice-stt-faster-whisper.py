"""Small JSON bridge for the local faster-whisper STT backend."""
import json
import sys

from faster_whisper import WhisperModel


def load_model(model_name):
    try:
        return WhisperModel(model_name, device="cuda", compute_type="float16")
    except Exception:
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
        active_model = WhisperModel(model_name, device="cpu", compute_type="int8")
        segments = transcribe_with(active_model)
    text = " ".join(segment.text.strip() for segment in segments if segment.text.strip()).strip()
    return text, active_model


def main() -> None:
    if len(sys.argv) >= 2 and sys.argv[1] == "--server":
        if len(sys.argv) < 4:
            raise SystemExit("uso: voice-stt-faster-whisper.py --server MODEL LANGUAGE")
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
                print(json.dumps({"error": str(error)}), flush=True)
        return

    if len(sys.argv) < 4:
        raise SystemExit("uso: voice-stt-faster-whisper.py WAV MODEL LANGUAGE")

    wav_path, model_name, language = sys.argv[1:4]
    model = load_model(model_name)
    text, _model = transcribe_file(model, model_name, wav_path, language)
    print(json.dumps({"text": text}, ensure_ascii=False))


if __name__ == "__main__":
    main()
