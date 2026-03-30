"""Deterministic mock LLM provider for local development and tests."""

from __future__ import annotations

from collections.abc import AsyncIterator

from .types import GenerateRequest, GenerateResponse, StreamChunk, Usage


class MockLLMAdapter:
    """Mock adapter returning fixed responses."""

    provider_name = "mock"
    supported_capabilities = {"chat", "vision_input", "tool_call", "json_output"}

    def __init__(self, *, model: str, response_text: str) -> None:
        """Initialize mock adapter settings."""
        self._model = model
        self._response_text = response_text

    async def generate(self, request: GenerateRequest) -> GenerateResponse:
        """Return deterministic mock output."""
        return GenerateResponse(
            provider=self.provider_name,
            model=request.model or self._model,
            output_text=self._response_text,
            finish_reason="stop",
            usage=Usage(input_tokens=1, output_tokens=1, total_tokens=2),
            raw_response={"mock": True},
        )

    async def stream(self, request: GenerateRequest) -> AsyncIterator[StreamChunk]:
        """Return one-shot mock stream."""
        _ = request

        async def _iterator() -> AsyncIterator[StreamChunk]:
            yield StreamChunk(delta_text=self._response_text, done=True)

        return _iterator()

    async def health(self) -> bool:
        """Always healthy for mock adapter."""
        return True
