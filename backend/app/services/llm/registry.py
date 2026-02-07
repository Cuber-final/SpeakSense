"""Provider registry for LLM adapters."""

from __future__ import annotations

from .adapter import LLMAdapter


class ProviderRegistry:
    """Store and resolve provider adapter instances."""

    def __init__(self) -> None:
        """Initialize empty registry."""
        self._providers: dict[str, LLMAdapter] = {}

    def register(self, adapter: LLMAdapter) -> None:
        """Register a provider adapter."""
        self._providers[adapter.provider_name] = adapter

    def get(self, provider_name: str) -> LLMAdapter:
        """Get provider adapter by name."""
        try:
            return self._providers[provider_name]
        except KeyError as exc:
            raise ValueError(f"Unknown provider: {provider_name}") from exc

    def list_providers(self) -> list[str]:
        """List registered provider names."""
        return sorted(self._providers.keys())
