"""Domain exceptions for ASR service layer."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any


@dataclass(slots=True)
class ASRServiceError(Exception):
    """Structured ASR error used across provider adapters."""

    code: str
    message: str
    details: dict[str, Any] | None = None
    status_code: int = 502

    def __str__(self) -> str:
        """Return human-readable exception string."""
        return self.message
