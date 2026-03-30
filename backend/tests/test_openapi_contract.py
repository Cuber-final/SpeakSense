"""OpenAPI generation and contract presence tests."""

from __future__ import annotations

from backend.app.main import app


def test_openapi_contains_core_routes() -> None:
    """Generated OpenAPI should expose core MVP routes."""
    schema = app.openapi()
    paths = schema.get("paths", {})

    assert "/healthz" in paths
    assert "/v1/auth/login" in paths
    assert "/v1/auth/me" in paths
    assert "/v1/boards" in paths
    assert "/v1/attempts/{attempt_id}/evaluation" in paths
    assert "/v1/answers/voice" in paths


def test_openapi_version_is_available() -> None:
    """OpenAPI payload should include version metadata."""
    schema = app.openapi()
    assert isinstance(schema.get("openapi"), str)
