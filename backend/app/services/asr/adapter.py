"""Adapter protocol for ASR provider implementations."""

from __future__ import annotations

from typing import Protocol

from .types import ASRRequest, ASRResponse


class ASRAdapter(Protocol):
    """Provider adapter protocol for speech-to-text calls."""

    provider_name: str

    async def transcribe(self, request: ASRRequest) -> ASRResponse:
        """Transcribe audio payload into plain text."""
