"""Health endpoint tests."""

from __future__ import annotations

from fastapi.testclient import TestClient


def test_healthz_returns_ok(client: TestClient) -> None:
    """Health endpoint should return status ok and request id header."""
    response = client.get("/healthz")

    assert response.status_code == 200
    assert response.json()["status"] == "ok"
    assert "X-Request-Id" in response.headers
