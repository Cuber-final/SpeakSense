"""Tests for OpenAI-compatible LLM adapter."""

from __future__ import annotations

import json
from typing import Any

import httpx
import pytest

from backend.app.services.llm.exceptions import LLMServiceError
from backend.app.services.llm.openai_compatible import OpenAICompatibleAdapter
from backend.app.services.llm.types import (
    ChatMessage,
    ContentImageBase64,
    ContentText,
    GenerateRequest,
)


def _build_request() -> GenerateRequest:
    """Build a minimal generation request fixture."""
    return GenerateRequest(
        request_id="req-1",
        model="mock-model",
        messages=[ChatMessage(role="user", content=[ContentText(text="hello")])],
    )


@pytest.mark.asyncio()
async def test_generate_success() -> None:
    """Adapter should parse text and usage from a success payload."""

    async def handler(request: httpx.Request) -> httpx.Response:
        assert request.method == "POST"
        assert request.url.path.endswith("/chat/completions")
        body = {
            "model": "mock-model",
            "choices": [
                {
                    "finish_reason": "stop",
                    "message": {"content": [{"type": "text", "text": "Hi"}]},
                }
            ],
            "usage": {"prompt_tokens": 2, "completion_tokens": 3, "total_tokens": 5},
        }
        return httpx.Response(200, json=body)

    transport = httpx.MockTransport(handler)
    client = httpx.AsyncClient(transport=transport, base_url="https://mock.local")

    adapter = OpenAICompatibleAdapter(
        provider_name="openai_compatible",
        base_url="https://mock.local/v1",
        api_key="",
        timeout_ms=1000,
        max_retries=0,
        client=client,
    )

    response = await adapter.generate(_build_request())

    await client.aclose()

    assert response.output_text == "Hi"
    assert response.usage.total_tokens == 5


@pytest.mark.asyncio()
async def test_generate_retry_on_rate_limit() -> None:
    """Adapter should retry once on 429 and then return success."""
    state = {"count": 0}

    async def handler(request: httpx.Request) -> httpx.Response:
        _ = request
        state["count"] += 1
        if state["count"] == 1:
            return httpx.Response(429, json={"error": "rate limit"})
        body = {
            "model": "mock-model",
            "choices": [{"finish_reason": "stop", "message": {"content": "done"}}],
            "usage": {"prompt_tokens": 1, "completion_tokens": 1, "total_tokens": 2},
        }
        return httpx.Response(200, json=body)

    transport = httpx.MockTransport(handler)
    client = httpx.AsyncClient(transport=transport, base_url="https://mock.local")

    adapter = OpenAICompatibleAdapter(
        provider_name="openai_compatible",
        base_url="https://mock.local/v1",
        api_key="",
        timeout_ms=1000,
        max_retries=1,
        client=client,
    )

    response = await adapter.generate(_build_request())

    await client.aclose()

    assert state["count"] == 2
    assert response.output_text == "done"


@pytest.mark.asyncio()
async def test_generate_raises_auth_error() -> None:
    """Adapter should map 401 to normalized auth error."""

    async def handler(request: httpx.Request) -> httpx.Response:
        _ = request
        return httpx.Response(401, json={"error": "unauthorized"})

    transport = httpx.MockTransport(handler)
    client = httpx.AsyncClient(transport=transport, base_url="https://mock.local")

    adapter = OpenAICompatibleAdapter(
        provider_name="openai_compatible",
        base_url="https://mock.local/v1",
        api_key="invalid",
        timeout_ms=1000,
        max_retries=0,
        client=client,
    )

    with pytest.raises(LLMServiceError) as exc_info:
        await adapter.generate(_build_request())

    await client.aclose()

    assert exc_info.value.code == "LLM_AUTH_ERROR"


@pytest.mark.asyncio()
async def test_generate_multimodal_base64_to_data_url() -> None:
    """Adapter should serialize base64 image content as data URL."""

    captured_payload: dict[str, Any] = {}

    async def handler(request: httpx.Request) -> httpx.Response:
        nonlocal captured_payload
        captured_payload = json.loads(request.content.decode("utf-8"))
        body = {
            "model": "mock-model",
            "choices": [{"finish_reason": "stop", "message": {"content": "ok"}}],
            "usage": {"prompt_tokens": 1, "completion_tokens": 1, "total_tokens": 2},
        }
        return httpx.Response(200, json=body)

    transport = httpx.MockTransport(handler)
    client = httpx.AsyncClient(transport=transport, base_url="https://mock.local")

    request = GenerateRequest(
        request_id="req-2",
        model="mock-model",
        messages=[
            ChatMessage(
                role="user",
                content=[
                    ContentText(text="describe image"),
                    ContentImageBase64(mime_type="image/png", data="AAA"),
                ],
            )
        ],
    )

    adapter = OpenAICompatibleAdapter(
        provider_name="openai_compatible",
        base_url="https://mock.local/v1",
        api_key="",
        timeout_ms=1000,
        max_retries=0,
        client=client,
    )

    _ = await adapter.generate(request)

    await client.aclose()

    content = captured_payload["messages"][0]["content"]
    image_part = content[1]
    assert image_part["image_url"]["url"].startswith("data:image/png;base64,AAA")
