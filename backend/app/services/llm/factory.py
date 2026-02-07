"""Factory helpers for LLM service dependency wiring."""

from __future__ import annotations

from functools import lru_cache

from ...core.settings import get_settings
from .gateway import LLMGateway
from .openai_compatible import OpenAICompatibleAdapter
from .registry import ProviderRegistry
from .router import ModelRouter


@lru_cache(maxsize=1)
def get_llm_gateway() -> LLMGateway:
    """Build and cache default LLM gateway."""
    settings = get_settings()

    registry = ProviderRegistry()
    registry.register(
        OpenAICompatibleAdapter(
            provider_name=settings.llm_provider,
            base_url=settings.llm_base_url,
            api_key=settings.llm_api_key,
            timeout_ms=settings.llm_timeout_ms,
            max_retries=settings.llm_max_retries,
        )
    )

    router = ModelRouter(registry)
    return LLMGateway(router)
