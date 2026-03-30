"""Mock ASR provider implementation for local development."""

from __future__ import annotations

from .adapter import ASRAdapter
from .types import ASRRequest, ASRResponse


class MockASRAdapter(ASRAdapter):
    """Return configured static transcript for quick smoke tests."""

    provider_name = "mock"

    def __init__(self, *, transcript: str) -> None:
        """Initialize mock provider with static transcript text."""
        self._transcript = transcript

    async def transcribe(self, request: ASRRequest) -> ASRResponse:
        """Return static transcript regardless of input payload."""
        _ = request
        return ASRResponse(
            transcript=self._transcript,
            provider=self.provider_name,
            model="mock",
        )
