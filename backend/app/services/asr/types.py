"""Types for ASR provider gateway and adapters."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path


@dataclass(slots=True)
class ASRRequest:
    """ASR request DTO consumed by adapter implementations."""

    file_path: Path
    language: str
    filename: str
    content_type: str | None = None


@dataclass(slots=True)
class ASRResponse:
    """ASR response DTO returned by adapter implementations."""

    transcript: str
    provider: str
    model: str | None = None
