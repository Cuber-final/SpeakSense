"""Versioned API router."""

from __future__ import annotations

from uuid import uuid4

from fastapi import APIRouter

from ...core.settings import get_settings
from ...schemas.common import (
    LLMSmokeRequest,
    LLMSmokeResponse,
    PingResponse,
    SumResponse,
)
from ...services.llm.factory import get_llm_gateway
from ...services.llm.types import ChatMessage, ContentText, GenerateRequest
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


@router.post("/system/llm/smoke", response_model=LLMSmokeResponse)
async def llm_smoke(payload: LLMSmokeRequest) -> LLMSmokeResponse:
    """Execute a minimal LLM request to validate provider wiring."""
    settings = get_settings()
    gateway = get_llm_gateway()
    response = await gateway.generate(
        GenerateRequest(
            request_id=str(uuid4()),
            model=settings.llm_default_model,
            provider_hint=settings.llm_provider,
            messages=[
                ChatMessage(
                    role="user",
                    content=[ContentText(text=payload.prompt)],
                )
            ],
        )
    )
    return LLMSmokeResponse(
        provider=response.provider,
        model=response.model,
        output_text=response.output_text,
    )


router.include_router(auth_router)
router.include_router(boards_router)
router.include_router(practice_router)
router.include_router(evaluation_router)
router.include_router(wordbook_router)
