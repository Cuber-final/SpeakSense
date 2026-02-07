"""Problem JSON error handling utilities and exception mapping."""

from __future__ import annotations

import logging
from typing import Any

from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException
from starlette.requests import Request

from ..schemas.common import ProblemDetail, ProblemEnvelope
from ..services.auth.exceptions import AuthServiceError
from ..services.llm.exceptions import LLMServiceError

logger = logging.getLogger(__name__)


def _problem_response(
    *,
    status_code: int,
    error_type: str,
    code: str,
    message: str,
    details: dict[str, Any] | None = None,
) -> JSONResponse:
    """Build a Problem JSON response envelope."""
    payload = ProblemEnvelope(
        error=ProblemDetail(
            type=error_type,
            code=code,
            message=message,
            details=details,
        )
    )
    return JSONResponse(
        status_code=status_code,
        content=payload.model_dump(exclude_none=True),
    )


async def handle_http_exception(
    request: Request,
    exc: StarletteHTTPException,
) -> JSONResponse:
    """Map HTTP exceptions into Problem JSON format."""
    details: dict[str, Any] | None = None
    message = "Request failed"

    if isinstance(exc.detail, str):
        message = exc.detail
    elif isinstance(exc.detail, dict):
        details = exc.detail
        detail_message = exc.detail.get("message")
        if isinstance(detail_message, str):
            message = detail_message

    if exc.status_code == 404:
        code = "NOT_FOUND"
        message = "Resource not found"
    else:
        code = f"HTTP_{exc.status_code}"

    request_id = getattr(request.state, "request_id", None)
    if request_id:
        if details is None:
            details = {"request_id": request_id}
        else:
            details.setdefault("request_id", request_id)

    return _problem_response(
        status_code=exc.status_code,
        error_type="http_error",
        code=code,
        message=message,
        details=details,
    )


async def handle_validation_exception(
    request: Request,
    exc: RequestValidationError,
) -> JSONResponse:
    """Map validation failures into Problem JSON format."""
    request_id = getattr(request.state, "request_id", None)
    details: dict[str, Any] = {"errors": exc.errors()}

    if request_id:
        details["request_id"] = request_id

    return _problem_response(
        status_code=422,
        error_type="validation_error",
        code="VALIDATION_ERROR",
        message="Invalid request parameters",
        details=details,
    )


async def handle_unhandled_exception(
    request: Request,
    exc: Exception,
) -> JSONResponse:
    """Map unhandled exceptions into Problem JSON format."""
    request_id = getattr(request.state, "request_id", None)

    logger.exception(
        "Unhandled exception",
        extra={
            "request_id": request_id,
            "path": request.url.path,
            "method": request.method,
        },
    )

    details: dict[str, Any] | None = None
    if request_id:
        details = {"request_id": request_id}

    return _problem_response(
        status_code=500,
        error_type="internal_error",
        code="INTERNAL_SERVER_ERROR",
        message="Internal server error",
        details=details,
    )


async def handle_llm_service_error(
    request: Request,
    exc: LLMServiceError,
) -> JSONResponse:
    """Map LLM service errors into Problem JSON format."""
    details = exc.details.copy() if exc.details is not None else {}

    request_id = getattr(request.state, "request_id", None)
    if request_id is not None:
        details.setdefault("request_id", request_id)

    return _problem_response(
        status_code=exc.status_code,
        error_type=exc.error_type,
        code=exc.code,
        message=exc.message,
        details=details or None,
    )


async def handle_auth_service_error(
    request: Request,
    exc: AuthServiceError,
) -> JSONResponse:
    """Map auth service errors into Problem JSON format."""
    details = exc.details.copy() if exc.details is not None else {}

    request_id = getattr(request.state, "request_id", None)
    if request_id is not None:
        details.setdefault("request_id", request_id)

    return _problem_response(
        status_code=exc.status_code,
        error_type=exc.error_type,
        code=exc.code,
        message=exc.message,
        details=details or None,
    )
