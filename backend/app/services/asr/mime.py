"""Audio MIME helpers for robust upload filename handling."""

from __future__ import annotations

from pathlib import Path

_MIME_TO_EXTENSION: dict[str, str] = {
    "audio/wav": ".wav",
    "audio/x-wav": ".wav",
    "audio/wave": ".wav",
    "audio/mpeg": ".mp3",
    "audio/mp3": ".mp3",
    "audio/mp4": ".m4a",
    "audio/m4a": ".m4a",
    "audio/webm": ".webm",
    "audio/ogg": ".ogg",
    "audio/opus": ".opus",
    "audio/flac": ".flac",
}


def resolve_audio_suffix(*, filename: str, content_type: str | None) -> str:
    """Resolve best suffix from filename first, then MIME type."""
    suffix = Path(filename).suffix.strip().lower()
    if suffix:
        return suffix if suffix.startswith(".") else f".{suffix}"

    if content_type is None:
        return ".bin"

    normalized = content_type.split(";")[0].strip().lower()
    return _MIME_TO_EXTENSION.get(normalized, ".bin")
