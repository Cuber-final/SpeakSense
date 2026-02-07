"""Health and readiness routes."""

from __future__ import annotations

from datetime import UTC, datetime

from fastapi import APIRouter

from ..schemas.common import HealthResponse

router = APIRouter(tags=["health"])


@router.get("/healthz", response_model=HealthResponse)
async def healthz() -> HealthResponse:
    """Return liveness state for orchestrators."""
    return HealthResponse(status="ok", timestamp=datetime.now(UTC))


@router.get("/readyz", response_model=HealthResponse)
async def readyz() -> HealthResponse:
    """Return readiness state for dependencies."""
    return HealthResponse(status="ok", timestamp=datetime.now(UTC))
