"""Adapter protocol for provider implementations."""

from __future__ import annotations

from collections.abc import AsyncIterator
from typing import Protocol

from .types import GenerateRequest, GenerateResponse, StreamChunk


class LLMAdapter(Protocol):
    """Provider adapter protocol."""

    provider_name: str
    supported_capabilities: set[str]

    async def generate(self, request: GenerateRequest) -> GenerateResponse:
        """Run a single non-stream generation call."""

    async def stream(self, request: GenerateRequest) -> AsyncIterator[StreamChunk]:
        """Run a stream generation call."""

    async def health(self) -> bool:
        """Return provider health status."""
