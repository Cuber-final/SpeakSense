"""Idempotency middleware for deduplicating POST requests."""

from __future__ import annotations

import base64
import hashlib
import json
import threading
import time
from collections.abc import Awaitable, Callable
from dataclasses import dataclass
from typing import Any
from uuid import uuid4

from redis import Redis
from redis.exceptions import RedisError
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

from ..schemas.common import ProblemDetail, ProblemEnvelope
from ..services.auth.security import decode_access_token
from .settings import get_settings


@dataclass(slots=True)
class CachedResponse:
    """Cached idempotent response payload."""

    request_hash: str
    status_code: int
    content_type: str
    body_bytes: bytes
    expires_at: float


class _InMemoryIdempotencyStore:
    """Fallback in-memory idempotency store."""

    def __init__(self) -> None:
        self._lock = threading.Lock()
        self._data: dict[str, CachedResponse] = {}

    def get(self, key: str) -> CachedResponse | None:
        """Get valid cached response by key."""
        now = time.time()
        with self._lock:
            item = self._data.get(key)
            if item is None:
                return None
            if item.expires_at <= now:
                self._data.pop(key, None)
                return None
            return item

    def set(self, *, key: str, value: CachedResponse) -> None:
        """Set idempotent response cache entry."""
        with self._lock:
            self._data[key] = value


_memory_store = _InMemoryIdempotencyStore()


class _InMemoryLockStore:
    """Fallback lock store to prevent concurrent duplicate processing."""

    def __init__(self) -> None:
        self._lock = threading.Lock()
        self._data: dict[str, tuple[str, float]] = {}

    def try_acquire(self, *, key: str, owner: str, ttl_seconds: int) -> bool:
        """Acquire lock key when expired or absent."""
        now = time.time()
        with self._lock:
            current = self._data.get(key)
            if current is not None:
                _, expires_at = current
                if expires_at > now:
                    return False
            self._data[key] = (owner, now + ttl_seconds)
            return True

    def release(self, *, key: str, owner: str) -> None:
        """Release lock only when current owner matches."""
        with self._lock:
            current = self._data.get(key)
            if current is None:
                return
            lock_owner, _ = current
            if lock_owner == owner:
                self._data.pop(key, None)


_memory_lock_store = _InMemoryLockStore()


class _IdempotencyStoreUnavailable(Exception):
    """Raised when idempotency store is unavailable in strict mode."""


def _problem_response(
    *,
    status_code: int,
    code: str,
    message: str,
    details: dict[str, Any] | None = None,
) -> Response:
    """Build Problem JSON response envelope."""
    payload = ProblemEnvelope(
        error=ProblemDetail(
            type="idempotency_error",
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


class IdempotencyMiddleware(BaseHTTPMiddleware):
    """Deduplicate POST requests by Idempotency-Key for configured TTL."""

    def __init__(self, app: Any) -> None:
        """Initialize middleware with runtime settings."""
        super().__init__(app)
        self._settings = get_settings()

    async def dispatch(
        self,
        request: Request,
        call_next: Callable[[Request], Awaitable[Response]],
    ) -> Response:
        """Replay cached response or execute request and cache it."""
        if request.method.upper() != "POST":
            return await call_next(request)

        idem_key = request.headers.get("Idempotency-Key")
        if idem_key is None or not idem_key.strip():
            return await call_next(request)

        request_body = await request.body()
        user_key = self._resolve_user_key(request)
        request_hash = self._hash_payload(
            method=request.method,
            path=request.url.path,
            user_key=user_key,
            body=request_body,
        )
        cache_key = self._cache_key(
            method=request.method,
            path=request.url.path,
            user_key=user_key,
            idempotency_key=idem_key.strip(),
        )

        try:
            cached = self._get(cache_key)
        except _IdempotencyStoreUnavailable:
            return _problem_response(
                status_code=503,
                code="IDEMPOTENCY_STORE_UNAVAILABLE",
                message="Idempotency store unavailable",
            )

        if cached is not None:
            if cached.request_hash != request_hash:
                return _problem_response(
                    status_code=409,
                    code="IDEMPOTENCY_KEY_REUSED",
                    message="Idempotency-Key was already used with different payload",
                )
            return Response(
                content=cached.body_bytes,
                status_code=cached.status_code,
                media_type=cached.content_type,
            )

        lock_key = f"{cache_key}:lock"
        lock_owner = uuid4().hex
        lock_ttl = max(5, self._settings.idempotency_ttl_seconds // 10)
        try:
            acquired = self._acquire_lock(
                key=lock_key,
                owner=lock_owner,
                ttl_seconds=lock_ttl,
            )
        except _IdempotencyStoreUnavailable:
            return _problem_response(
                status_code=503,
                code="IDEMPOTENCY_STORE_UNAVAILABLE",
                message="Idempotency store unavailable",
            )

        if not acquired:
            try:
                cached = self._get(cache_key)
            except _IdempotencyStoreUnavailable:
                return _problem_response(
                    status_code=503,
                    code="IDEMPOTENCY_STORE_UNAVAILABLE",
                    message="Idempotency store unavailable",
                )

            if cached is not None:
                if cached.request_hash != request_hash:
                    return _problem_response(
                        status_code=409,
                        code="IDEMPOTENCY_KEY_REUSED",
                        message=(
                            "Idempotency-Key was already used with different payload"
                        ),
                    )
                return Response(
                    content=cached.body_bytes,
                    status_code=cached.status_code,
                    media_type=cached.content_type,
                )
            return _problem_response(
                status_code=409,
                code="IDEMPOTENCY_REQUEST_IN_PROGRESS",
                message="Request with this Idempotency-Key is in progress",
            )

        try:
            response = await call_next(request)
            body_bytes = await self._extract_response_body(response)
            cached_response = Response(
                content=body_bytes,
                status_code=response.status_code,
                headers=dict(response.headers),
                media_type=response.media_type,
            )

            if response.status_code < 500:
                self._set(
                    key=cache_key,
                    value=CachedResponse(
                        request_hash=request_hash,
                        status_code=response.status_code,
                        content_type=response.media_type or "application/json",
                        body_bytes=body_bytes,
                        expires_at=time.time() + self._settings.idempotency_ttl_seconds,
                    ),
                )

            return cached_response
        finally:
            self._release_lock(key=lock_key, owner=lock_owner)

    async def _extract_response_body(self, response: Response) -> bytes:
        """Extract body bytes from response for replay."""
        body_attr = getattr(response, "body", None)
        if isinstance(body_attr, bytes):
            return body_attr

        body = b""
        iterator = getattr(response, "body_iterator", None)
        if iterator is None:
            return body

        async for chunk in iterator:
            body += chunk
        return body

    def _cache_key(
        self,
        *,
        method: str,
        path: str,
        user_key: str,
        idempotency_key: str,
    ) -> str:
        """Build stable cache key."""
        digest = hashlib.sha256(
            f"{method.upper()}:{path}:{user_key}:{idempotency_key}".encode()
        ).hexdigest()
        return f"idem:{digest}"

    def _hash_payload(
        self,
        *,
        method: str,
        path: str,
        user_key: str,
        body: bytes,
    ) -> str:
        """Build hash from request identity and payload body."""
        digest = hashlib.sha256()
        digest.update(method.upper().encode("utf-8"))
        digest.update(b"|")
        digest.update(path.encode("utf-8"))
        digest.update(b"|")
        digest.update(user_key.encode("utf-8"))
        digest.update(b"|")
        digest.update(body)
        return digest.hexdigest()

    def _resolve_user_key(self, request: Request) -> str:
        """Resolve user identity from bearer token; fallback anon."""
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

    def _get(self, key: str) -> CachedResponse | None:
        """Get idempotency cached response from Redis or memory."""
        try:
            redis_client = Redis.from_url(
                self._settings.redis_url,
                decode_responses=True,
            )
            raw = redis_client.get(key)
            if raw is None:
                return None
            if not isinstance(raw, str):
                return None

            payload = json.loads(raw)
            return CachedResponse(
                request_hash=str(payload["request_hash"]),
                status_code=int(payload["status_code"]),
                content_type=str(payload["content_type"]),
                body_bytes=base64.b64decode(payload["body_base64"]),
                expires_at=float(payload["expires_at"]),
            )
        except (RedisError, KeyError, ValueError, json.JSONDecodeError):
            if self._settings.allow_in_memory_controls_fallback():
                return _memory_store.get(key)
            raise _IdempotencyStoreUnavailable from None

    def _set(self, *, key: str, value: CachedResponse) -> None:
        """Store idempotency response in Redis or memory fallback."""
        payload = {
            "request_hash": value.request_hash,
            "status_code": value.status_code,
            "content_type": value.content_type,
            "body_base64": base64.b64encode(value.body_bytes).decode("utf-8"),
            "expires_at": value.expires_at,
        }

        try:
            redis_client = Redis.from_url(
                self._settings.redis_url,
                decode_responses=True,
            )
            redis_client.setex(
                key,
                self._settings.idempotency_ttl_seconds,
                json.dumps(payload, separators=(",", ":")),
            )
            return
        except RedisError:
            if self._settings.allow_in_memory_controls_fallback():
                _memory_store.set(key=key, value=value)

    def _acquire_lock(self, *, key: str, owner: str, ttl_seconds: int) -> bool:
        """Acquire distributed lock by key to avoid duplicate in-flight POST."""
        try:
            redis_client = Redis.from_url(
                self._settings.redis_url,
                decode_responses=True,
            )
            acquired = redis_client.set(key, owner, ex=ttl_seconds, nx=True)
            return bool(acquired)
        except RedisError:
            if self._settings.allow_in_memory_controls_fallback():
                return _memory_lock_store.try_acquire(
                    key=key,
                    owner=owner,
                    ttl_seconds=ttl_seconds,
                )
            raise _IdempotencyStoreUnavailable from None

    def _release_lock(self, *, key: str, owner: str) -> None:
        """Release lock key only if lock owner matches."""
        try:
            redis_client = Redis.from_url(
                self._settings.redis_url,
                decode_responses=True,
            )
            script = (
                "if redis.call('get', KEYS[1]) == ARGV[1] then "
                "return redis.call('del', KEYS[1]) else return 0 end"
            )
            redis_client.eval(script, 1, key, owner)
            return
        except RedisError:
            if self._settings.allow_in_memory_controls_fallback():
                _memory_lock_store.release(key=key, owner=owner)
