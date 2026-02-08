"""FastAPI application entrypoint."""

from __future__ import annotations

from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from typing import Any, cast

from fastapi import FastAPI
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from starlette.exceptions import HTTPException as StarletteHTTPException

from .api.health import router as health_router
from .api.v1.router import router as v1_router
from .core.errors import (
    handle_auth_service_error,
    handle_http_exception,
    handle_llm_service_error,
    handle_unhandled_exception,
    handle_validation_exception,
)
from .core.idempotency import IdempotencyMiddleware
from .core.logging import configure_logging
from .core.rate_limit import RateLimitMiddleware
from .core.request_id import RequestIDMiddleware
from .core.settings import get_settings
from .services.auth import AuthServiceError, seed_dev_admin
from .services.llm.exceptions import LLMServiceError
from .ws.router import router as ws_router


@asynccontextmanager
async def lifespan(_: FastAPI) -> AsyncIterator[None]:
    """Configure process-wide resources during app lifespan."""
    configure_logging()
    seed_dev_admin()
    yield


def create_app() -> FastAPI:
    """Create and configure the FastAPI application."""
    settings = get_settings()

    app = FastAPI(
        title="SpeakSense API",
        version="0.1.0",
        lifespan=lifespan,
    )

    app.add_middleware(RequestIDMiddleware)
    app.add_middleware(RateLimitMiddleware)
    app.add_middleware(IdempotencyMiddleware)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_allow_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
        expose_headers=["X-Request-Id"],
    )

    app.add_exception_handler(
        StarletteHTTPException,
        cast(Any, handle_http_exception),
    )
    app.add_exception_handler(
        RequestValidationError,
        cast(Any, handle_validation_exception),
    )
    app.add_exception_handler(
        AuthServiceError,
        cast(Any, handle_auth_service_error),
    )
    app.add_exception_handler(
        LLMServiceError,
        cast(Any, handle_llm_service_error),
    )
    app.add_exception_handler(Exception, handle_unhandled_exception)

    app.include_router(health_router)
    app.include_router(ws_router)
    app.include_router(v1_router, prefix="/v1")

    return app


app = create_app()
