"""Request id middleware tests."""

from __future__ import annotations

from fastapi.testclient import TestClient


def test_request_id_is_preserved_when_provided(client: TestClient) -> None:
    """Incoming request ID should be echoed in response headers."""
    request_id = "req-123"

    response = client.get("/v1/system/ping", headers={"X-Request-Id": request_id})

    assert response.status_code == 200
    assert response.headers.get("X-Request-Id") == request_id
