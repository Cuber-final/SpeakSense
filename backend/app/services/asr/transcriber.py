"""ASR transcription service wrapper with mock and faster-whisper backends."""

from __future__ import annotations

import wave
from dataclasses import dataclass
from pathlib import Path

from ...core.settings import get_settings


@dataclass(slots=True)
class ASRServiceError(Exception):
    """ASR service exception."""

    message: str

    def __str__(self) -> str:
        """Return error message string."""
        return self.message


def detect_wav_duration_seconds(file_path: Path) -> float | None:
    """Detect WAV duration in seconds; return None for unsupported files."""
    try:
        with wave.open(str(file_path), "rb") as wav_file:
            frame_rate = wav_file.getframerate()
            if frame_rate <= 0:
                return None
            return wav_file.getnframes() / float(frame_rate)
    except (wave.Error, OSError):
        return None


def transcribe_audio(*, file_path: Path, language: str) -> str:
    """Transcribe one audio file via configured ASR provider."""
    settings = get_settings()
    provider = settings.asr_provider.strip().lower()

    if provider == "mock":
        return settings.asr_mock_transcript

    if provider != "faster_whisper":
        raise ASRServiceError(f"Unsupported ASR provider: {settings.asr_provider}")

    try:
        from faster_whisper import WhisperModel  # type: ignore[import-not-found]
    except ImportError as exc:
        raise ASRServiceError(
            "faster_whisper is not installed but ASR_PROVIDER=faster_whisper",
        ) from exc

    try:
        model = WhisperModel(
            settings.asr_whisper_model_size,
            compute_type=settings.asr_whisper_compute_type,
        )
        segments, _ = model.transcribe(str(file_path), language=language)
    except Exception as exc:  # pragma: no cover - provider/runtime variability
        raise ASRServiceError(f"ASR provider failed: {exc}") from exc

    text_parts = [segment.text.strip() for segment in segments if segment.text.strip()]
    transcript = " ".join(text_parts).strip()
    if not transcript:
        raise ASRServiceError("ASR transcript is empty")
    return transcript
