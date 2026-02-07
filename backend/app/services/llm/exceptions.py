"""Domain exceptions for LLM service layer."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any


@dataclass(slots=True)
class LLMServiceError(Exception):
    """Structured LLM error used across provider adapters."""

    error_type: str
    code: str
    message: str
    details: dict[str, Any] | None = None
    status_code: int = 500

    def __str__(self) -> str:
        """Return human-readable exception string."""
        return f"{self.code}: {self.message}"
