"""Common shared API schemas."""

from __future__ import annotations

from datetime import datetime
from typing import Any

from pydantic import BaseModel


class HealthResponse(BaseModel):
    """Health endpoint response model."""

    status: str
    timestamp: datetime


class PingResponse(BaseModel):
    """Simple ping response model."""

    message: str


class SumResponse(BaseModel):
    """Sum response model."""

    total: int


class ProblemDetail(BaseModel):
    """Problem JSON error payload."""

    type: str
    code: str
    message: str
    details: dict[str, Any] | None = None


class ProblemEnvelope(BaseModel):
    """Problem JSON envelope wrapper."""

    error: ProblemDetail
