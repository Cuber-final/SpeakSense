"""Domain exceptions for authentication service layer."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any


@dataclass(slots=True)
class AuthServiceError(Exception):
    """Structured auth error used by auth routes and dependencies."""

    error_type: str
    code: str
    message: str
    details: dict[str, Any] | None = None
    status_code: int = 401

    def __str__(self) -> str:
        """Return human-readable exception string."""
        return f"{self.code}: {self.message}"
