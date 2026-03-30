"""Rate limiting middleware for per-IP and per-user request controls."""

from __future__ import annotations

import threading
import time
from collections.abc import Awaitable, Callable
from typing import Any

from redis import Redis
from redis.exceptions import RedisError
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

from ..schemas.common import ProblemDetail, ProblemEnvelope
from ..services.auth.security import decode_access_token
from .settings import get_settings


def _build_problem_response(
    *,
    status_code: int,
    code: str,
    message: str,
    details: dict[str, Any] | None = None,
) -> Response:
    """Build Problem JSON response for middleware-level rejections."""
    payload = ProblemEnvelope(
        error=ProblemDetail(
            type="rate_limit_error",
            code=code,
            message=message,
            details=details,
        )
    )
    return Response(
        content=payload.model_dump_json(exclude_none=True),
        status_code=status_code,
        media_type="application/json",
    )


class _InMemoryRateStore:
    """Simple fallback rate limiter store."""

    def __init__(self) -> None:
        self._lock = threading.Lock()
        self._data: dict[str, tuple[int, float]] = {}

    def increment(self, *, key: str, ttl_seconds: int) -> int:
        """Increment key count and return latest value."""
        now = time.time()
        with self._lock:
            count, expires_at = self._data.get(key, (0, now + ttl_seconds))
            if expires_at <= now:
                count = 0
                expires_at = now + ttl_seconds
            count += 1
            self._data[key] = (count, expires_at)
            return count


_memory_store = _InMemoryRateStore()


class _RateLimitStoreUnavailable(Exception):
    """Raised when rate-limit backing store is unavailable in strict mode."""


class RateLimitMiddleware(BaseHTTPMiddleware):
    """Apply per-window request limits using Redis with memory fallback."""

    def __init__(self, app: Any) -> None:
        """Initialize middleware with cached settings."""
        super().__init__(app)
        self._settings = get_settings()

    async def dispatch(
        self,
        request: Request,
        call_next: Callable[[Request], Awaitable[Response]],
    ) -> Response:
        """Reject requests that exceed configured per-window limits."""
        if request.url.path in {"/healthz", "/readyz"}:
            return await call_next(request)

        user_key = self._resolve_user_key(request)
        ip_key = self._resolve_ip(request)
        window = self._settings.rate_limit_window_seconds
        bucket = int(time.time() // window)
        key = f"rate:{ip_key}:{user_key}:{bucket}"

        try:
            count = self._increment_count(key=key, ttl_seconds=window + 2)
        except _RateLimitStoreUnavailable:
            request_id = getattr(request.state, "request_id", None)
            unavailable_details: dict[str, Any] = {"store": "redis"}
            if request_id is not None:
                unavailable_details["request_id"] = request_id
            return _build_problem_response(
                status_code=503,
                code="RATE_LIMIT_STORE_UNAVAILABLE",
                message="Rate limit store unavailable",
                details=unavailable_details,
            )

        if count > self._settings.rate_limit_requests:
            request_id = getattr(request.state, "request_id", None)
            details: dict[str, Any] = {
                "limit": self._settings.rate_limit_requests,
                "window_seconds": window,
            }
            if request_id is not None:
                details["request_id"] = request_id

            return _build_problem_response(
                status_code=429,
                code="RATE_LIMIT_EXCEEDED",
                message="Rate limit exceeded",
                details=details,
            )

        return await call_next(request)

    def _increment_count(self, *, key: str, ttl_seconds: int) -> int:
        """Increment rate-limit key using Redis when available."""
        try:
            redis_client = Redis.from_url(
                self._settings.redis_url,
                decode_responses=True,
            )
            with redis_client.pipeline() as pipeline:
                pipeline.incr(key)
                pipeline.expire(key, ttl_seconds)
                result = pipeline.execute()
            return int(result[0])
        except RedisError:
            if self._settings.allow_in_memory_controls_fallback():
                return _memory_store.increment(key=key, ttl_seconds=ttl_seconds)
            raise _RateLimitStoreUnavailable from None

    def _resolve_ip(self, request: Request) -> str:
        """Resolve best-effort client IP from proxy and socket info."""
        xff = request.headers.get("X-Forwarded-For")
        if xff:
            first = xff.split(",")[0].strip()
            if first:
                return first

        if request.client is not None and request.client.host:
            return request.client.host

        return "unknown"

    def _resolve_user_key(self, request: Request) -> str:
        """Resolve user identifier from bearer token; fallback to anon."""
        auth_header = request.headers.get("Authorization")
        if not auth_header:
            return "anon"

        parts = auth_header.strip().split(" ", 1)
        if len(parts) != 2 or parts[0].lower() != "bearer" or not parts[1]:
            return "anon"

        try:
            claims = decode_access_token(parts[1])
        except Exception:
            return "anon"

        subject = claims.get("sub")
        if isinstance(subject, str) and subject:
            return subject

        return "anon"
