"""Gateway that routes generation calls across provider adapters."""

from __future__ import annotations

from .exceptions import LLMServiceError
from .router import ModelRouter
from .types import (
    ContentImageBase64,
    ContentImageUrl,
    GenerateRequest,
    GenerateResponse,
)


class LLMGateway:
    """Capability-aware gateway for LLM/VLM generation."""

    def __init__(self, router: ModelRouter) -> None:
        """Initialize gateway with routing strategy."""
        self._router = router

    async def generate(self, request: GenerateRequest) -> GenerateResponse:
        """Route request and execute generation on selected provider."""
        required_capability = self._resolve_capability(request)
        adapter = self._router.select(
            provider_hint=request.provider_hint,
            required_capability=required_capability,
        )

        if request.stream:
            raise LLMServiceError(
                error_type="provider_error",
                code="LLM_UNSUPPORTED_CAPABILITY",
                message="Streaming path is not implemented yet",
                details={"provider": adapter.provider_name},
                status_code=400,
            )

        return await adapter.generate(request)

    def _resolve_capability(self, request: GenerateRequest) -> str:
        """Resolve required capability from request shape."""
        for message in request.messages:
            for part in message.content:
                if isinstance(part, ContentImageUrl | ContentImageBase64):
                    return "vision_input"

        if request.tools:
            return "tool_call"

        return "chat"
