"""ASR gateway wrapper with mock/local/API providers."""

from __future__ import annotations

import wave
from pathlib import Path

from ...core.settings import get_settings
from .adapter import ASRAdapter
from .faster_whisper_provider import FasterWhisperASRAdapter
from .mock_provider import MockASRAdapter
from .openai_compatible import OpenAICompatibleASRAdapter
from .types import ASRRequest


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


def _build_adapter() -> ASRAdapter:
    """Build ASR adapter from runtime settings."""
    settings = get_settings()
    provider = settings.asr_provider.strip().lower()

    if provider == "mock":
        return MockASRAdapter(transcript=settings.asr_mock_transcript)

    if provider == "faster_whisper":
        return FasterWhisperASRAdapter(
            model_size=settings.asr_whisper_model_size,
            compute_type=settings.asr_whisper_compute_type,
        )

    return OpenAICompatibleASRAdapter(
        provider_name=settings.asr_provider,
        base_url=settings.asr_base_url,
        api_key=settings.asr_api_key,
        model=settings.asr_model,
        timeout_ms=settings.asr_timeout_ms,
        max_retries=settings.asr_max_retries,
    )


async def transcribe_audio(
    *,
    file_path: Path,
    language: str,
    filename: str,
    content_type: str | None = None,
) -> str:
    """Transcribe one audio file via configured ASR provider."""
    adapter = _build_adapter()
    response = await adapter.transcribe(
        ASRRequest(
            file_path=file_path,
            language=language,
            filename=filename,
            content_type=content_type,
        )
    )
    return response.transcript
