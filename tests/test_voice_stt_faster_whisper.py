"""Regression tests for the local faster-whisper fallback."""
import importlib.util
from pathlib import Path
from types import SimpleNamespace
from unittest import TestCase, mock


HELPER_PATH = (
    Path(__file__).resolve().parents[1]
    / "local/.local/bin/voice-stt-faster-whisper.py"
)
SPEC = importlib.util.spec_from_file_location("voice_stt_faster_whisper", HELPER_PATH)
if SPEC is None or SPEC.loader is None:
    raise ImportError(f"Cannot load voice helper at {HELPER_PATH}")
voice_stt = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(voice_stt)


class VoiceSttFallbackTests(TestCase):
    def test_decode_cuda_failure_retries_with_cpu(self):
        requested_devices = []

        class FakeModel:
            def __init__(self, device):
                self.device = device

            def transcribe(self, *_args, **_kwargs):
                if self.device == "cuda":
                    def fail_during_decode():
                        raise RuntimeError("Library libcublas.so.12 is not found")
                        yield None

                    return fail_during_decode(), None
                return [SimpleNamespace(text=" prueba local ")], None

        def fake_whisper_model(_model_name, *, device, compute_type):
            requested_devices.append(device)
            return FakeModel(device)

        with mock.patch.object(
            voice_stt,
            "import_module",
            return_value=SimpleNamespace(WhisperModel=fake_whisper_model),
        ):
            initial_model = voice_stt.load_model("small")
            transcript, active_model = voice_stt.transcribe_file(
                initial_model,
                "small",
                "unused.wav",
                "es",
            )

        self.assertEqual(transcript, "prueba local")
        self.assertEqual(active_model.device, "cpu")
        self.assertEqual(requested_devices, ["cuda", "cpu"])
