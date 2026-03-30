"""Rate limiting and idempotency middleware behavior tests."""

from __future__ import annotations

from typing import Any

from fastapi.testclient import TestClient
from redis.exceptions import RedisError

import backend.app.core.rate_limit as rate_limit_module
from backend.app.core.settings import get_settings


def test_rate_limit_rejects_excess_requests(client: TestClient) -> None:
    """Requests above configured limit should return 429 Problem JSON."""
    settings = get_settings()
    original_limit = settings.rate_limit_requests
    original_window = settings.rate_limit_window_seconds
    settings.rate_limit_requests = 1
    settings.rate_limit_window_seconds = 60
    try:
        headers = {"X-Forwarded-For": "203.0.113.10"}
        first = client.get("/v1/system/ping", headers=headers)
        second = client.get("/v1/system/ping", headers=headers)
    finally:
        settings.rate_limit_requests = original_limit
        settings.rate_limit_window_seconds = original_window

    assert first.status_code == 200
    assert second.status_code == 429
    assert second.json()["error"]["code"] == "RATE_LIMIT_EXCEEDED"


def test_post_idempotency_replays_cached_response(client: TestClient) -> None:
    """Repeated POST with same Idempotency-Key should replay original response."""
    headers = {"Idempotency-Key": "idem-create-board"}
    payload = {"title": "Coffee Chat", "topic": "Cafe", "level": "B1"}

    first = client.post("/v1/boards", json=payload, headers=headers)
    second = client.post("/v1/boards", json=payload, headers=headers)

    assert first.status_code == 201
    assert second.status_code == 201
    assert first.json()["id"] == second.json()["id"]


def test_post_idempotency_rejects_payload_mismatch(client: TestClient) -> None:
    """Same Idempotency-Key with different payload should return conflict."""
    headers = {"Idempotency-Key": "idem-payload-mismatch"}

    first = client.post(
        "/v1/boards",
        json={"title": "Scenario A", "topic": "Work", "level": "B1"},
        headers=headers,
    )
    second = client.post(
        "/v1/boards",
        json={"title": "Scenario B", "topic": "Work", "level": "B1"},
        headers=headers,
    )

    assert first.status_code == 201
    assert second.status_code == 409
    assert second.json()["error"]["code"] == "IDEMPOTENCY_KEY_REUSED"


def _raise_redis_error(*_: Any, **__: Any) -> Any:
    """Raise redis error for strict-mode fallback checks."""
    raise RedisError("redis unavailable")


def test_rate_limit_prod_requires_redis_store(
    client: TestClient,
    monkeypatch: Any,
) -> None:
    """Prod env should return 503 when rate-limit Redis is unavailable."""
    settings = get_settings()
    original_env = settings.app_env
    settings.app_env = "prod"
    monkeypatch.setattr(
        "backend.app.core.rate_limit.Redis.from_url",
        _raise_redis_error,
    )
    try:
        response = client.get(
            "/v1/system/ping",
            headers={"X-Forwarded-For": "203.0.113.20"},
        )
    finally:
        settings.app_env = original_env

    assert response.status_code == 503
    assert response.json()["error"]["code"] == "RATE_LIMIT_STORE_UNAVAILABLE"


def test_idempotency_prod_requires_redis_store(
    client: TestClient,
    monkeypatch: Any,
) -> None:
    """Prod env should return 503 when idempotency Redis is unavailable."""
    settings = get_settings()
    original_env = settings.app_env
    settings.app_env = "prod"
    monkeypatch.setattr(
        "backend.app.core.idempotency.Redis.from_url",
        _raise_redis_error,
    )
    monkeypatch.setattr(
        rate_limit_module.RateLimitMiddleware,
        "_increment_count",
        lambda self, key, ttl_seconds: 1,
    )
    try:
        response = client.post(
            "/v1/boards",
            json={"title": "Travel", "topic": "Airport", "level": "B1"},
            headers={"Idempotency-Key": "idem-prod-redis-required"},
        )
    finally:
        settings.app_env = original_env

    assert response.status_code == 503
    assert response.json()["error"]["code"] == "IDEMPOTENCY_STORE_UNAVAILABLE"
