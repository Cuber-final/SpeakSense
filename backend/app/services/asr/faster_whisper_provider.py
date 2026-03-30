"""Local faster-whisper ASR provider implementation."""

from __future__ import annotations

import asyncio

from .adapter import ASRAdapter
from .exceptions import ASRServiceError
from .types import ASRRequest, ASRResponse


class FasterWhisperASRAdapter(ASRAdapter):
    """Use local faster-whisper model for transcription."""

    provider_name = "faster_whisper"

    def __init__(self, *, model_size: str, compute_type: str) -> None:
        """Initialize local model options."""
        self._model_size = model_size
        self._compute_type = compute_type

    async def transcribe(self, request: ASRRequest) -> ASRResponse:
        """Run local inference in a worker thread to avoid event-loop blocking."""
        return await asyncio.to_thread(self._transcribe_blocking, request)

    def _transcribe_blocking(self, request: ASRRequest) -> ASRResponse:
        """Execute faster-whisper call synchronously."""
        try:
            from faster_whisper import WhisperModel  # type: ignore[import-not-found]
        except ImportError as exc:
            raise ASRServiceError(
                code="ASR_PROVIDER_DEPENDENCY_MISSING",
                message="faster_whisper is not installed",
                details={"provider": self.provider_name},
                status_code=500,
            ) from exc

        try:
            model = WhisperModel(
                self._model_size,
                compute_type=self._compute_type,
            )
            segments, _ = model.transcribe(
                str(request.file_path),
                language=request.language,
            )
        except Exception as exc:  # pragma: no cover - runtime/provider variability
            raise ASRServiceError(
                code="ASR_PROVIDER_FAILED",
                message=f"ASR provider failed: {exc}",
                details={"provider": self.provider_name},
                status_code=502,
            ) from exc

        text_parts = [
            segment.text.strip() for segment in segments if segment.text.strip()
        ]
        transcript = " ".join(text_parts).strip()
        if not transcript:
            raise ASRServiceError(
                code="ASR_EMPTY_TRANSCRIPT",
                message="ASR transcript is empty",
                details={"provider": self.provider_name},
                status_code=502,
            )

        return ASRResponse(
            transcript=transcript,
            provider=self.provider_name,
            model=self._model_size,
        )
