"""Problem JSON contract tests."""

from __future__ import annotations

from fastapi.testclient import TestClient


def test_not_found_uses_problem_json(client: TestClient) -> None:
    """Unknown route should return Problem JSON envelope."""
    response = client.get("/v1/not-exists")

    assert response.status_code == 404
    body = response.json()
    assert "error" in body
    assert body["error"]["code"] == "NOT_FOUND"


def test_validation_error_uses_problem_json(client: TestClient) -> None:
    """Validation failure should return Problem JSON envelope."""
    response = client.get("/v1/system/sum?a=1&b=bad")

    assert response.status_code == 422
    body = response.json()
    assert body["error"]["code"] == "VALIDATION_ERROR"
    assert isinstance(body["error"]["details"]["errors"], list)
