"""Model router for capability-aware provider selection."""

from __future__ import annotations

from .adapter import LLMAdapter
from .registry import ProviderRegistry


class ModelRouter:
    """Choose provider by explicit hint or required capability."""

    def __init__(self, registry: ProviderRegistry) -> None:
        """Initialize router with provider registry."""
        self._registry = registry

    def select(
        self,
        *,
        provider_hint: str | None,
        required_capability: str,
    ) -> LLMAdapter:
        """Select provider adapter for a request."""
        if provider_hint is not None:
            adapter = self._registry.get(provider_hint)
            if required_capability not in adapter.supported_capabilities:
                raise ValueError(
                    "Provider "
                    f"'{provider_hint}' does not support "
                    f"'{required_capability}'"
                )
            return adapter

        for provider_name in self._registry.list_providers():
            adapter = self._registry.get(provider_name)
            if required_capability in adapter.supported_capabilities:
                return adapter

        raise ValueError(
            f"No provider registered for required capability '{required_capability}'"
        )
