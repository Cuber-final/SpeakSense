"""Tests for mock LLM provider and smoke route."""

from __future__ import annotations

from fastapi.testclient import TestClient

from backend.app.core.settings import get_settings
from backend.app.services.llm.factory import get_llm_gateway


def test_llm_smoke_uses_mock_provider(client: TestClient) -> None:
    """Smoke endpoint should return deterministic mock output when configured."""
    settings = get_settings()
    original_provider = settings.llm_provider
    original_model = settings.llm_default_model
    original_mock_text = settings.llm_mock_response_text
    try:
        settings.llm_provider = "mock"
        settings.llm_default_model = "mock-model"
        settings.llm_mock_response_text = "mock-fixed-response"
        get_llm_gateway.cache_clear()

        response = client.post(
            "/v1/system/llm/smoke",
            json={"prompt": "hello"},
        )
    finally:
        settings.llm_provider = original_provider
        settings.llm_default_model = original_model
        settings.llm_mock_response_text = original_mock_text
        get_llm_gateway.cache_clear()

    assert response.status_code == 200
    payload = response.json()
    assert payload["provider"] == "mock"
    assert payload["model"] == "mock-model"
    assert payload["output_text"] == "mock-fixed-response"
