"""Versioned API router."""

from __future__ import annotations

from fastapi import APIRouter

from ...schemas.common import PingResponse, SumResponse
from .auth import router as auth_router
from .boards import router as boards_router
from .evaluation import router as evaluation_router
from .practice import router as practice_router
from .wordbook import router as wordbook_router

router = APIRouter(tags=["v1"])


@router.get("/system/ping", response_model=PingResponse)
async def ping() -> PingResponse:
    """Return a simple ping response for smoke checks."""
    return PingResponse(message="pong")


@router.get("/system/sum", response_model=SumResponse)
async def sum_values(a: int, b: int) -> SumResponse:
    """Return the sum of query parameters."""
    return SumResponse(total=a + b)


router.include_router(auth_router)
router.include_router(boards_router)
router.include_router(practice_router)
router.include_router(evaluation_router)
router.include_router(wordbook_router)
