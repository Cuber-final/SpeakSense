"""Tests for OpenAI-compatible ASR adapter and MIME helpers."""

from __future__ import annotations

from pathlib import Path
from typing import Any

import httpx
import pytest

from backend.app.services.asr.mime import resolve_audio_suffix
from backend.app.services.asr.openai_compatible import OpenAICompatibleASRAdapter
from backend.app.services.asr.types import ASRRequest


@pytest.mark.asyncio()
async def test_openai_compatible_asr_success(tmp_path: Path) -> None:
    """Adapter should parse transcript from a success payload."""
    captured_content: bytes = b""

    async def handler(request: httpx.Request) -> httpx.Response:
        nonlocal captured_content
        assert request.method == "POST"
        assert request.url.path.endswith("/audio/transcriptions")
        captured_content = request.content
        body = {"text": "hello world"}
        return httpx.Response(200, json=body)

    audio_file = tmp_path / "sample.webm"
    audio_file.write_bytes(b"test-audio")

    transport = httpx.MockTransport(handler)
    client = httpx.AsyncClient(transport=transport, base_url="https://mock.local")
    adapter = OpenAICompatibleASRAdapter(
        provider_name="openai_compatible",
        base_url="https://mock.local/v1",
        api_key="",
        model="whisper-1",
        timeout_ms=1000,
        max_retries=0,
        client=client,
    )

    response = await adapter.transcribe(
        request=ASRRequest(
            file_path=audio_file,
            language="en",
            filename="sample.webm",
            content_type="audio/webm",
        )
    )
    await client.aclose()

    assert response.transcript == "hello world"
    assert b'name="model"' in captured_content
    assert b'filename="sample.webm"' in captured_content


@pytest.mark.asyncio()
async def test_openai_compatible_asr_retries_on_rate_limit(tmp_path: Path) -> None:
    """Adapter should retry once on 429 and then return success."""
    state: dict[str, Any] = {"count": 0}

    async def handler(request: httpx.Request) -> httpx.Response:
        _ = request
        state["count"] += 1
        if state["count"] == 1:
            return httpx.Response(429, json={"error": "rate limit"})
        return httpx.Response(200, json={"text": "ok"})

    audio_file = tmp_path / "sample.wav"
    audio_file.write_bytes(b"test-audio")

    transport = httpx.MockTransport(handler)
    client = httpx.AsyncClient(transport=transport, base_url="https://mock.local")
    adapter = OpenAICompatibleASRAdapter(
        provider_name="openai_compatible",
        base_url="https://mock.local/v1",
        api_key="",
        model="whisper-1",
        timeout_ms=1000,
        max_retries=1,
        client=client,
    )

    response = await adapter.transcribe(
        request=ASRRequest(
            file_path=audio_file,
            language="en",
            filename="sample.wav",
            content_type="audio/wav",
        )
    )
    await client.aclose()

    assert response.transcript == "ok"
    assert state["count"] == 2


def test_resolve_audio_suffix_from_mime_when_filename_missing() -> None:
    """MIME mapping should provide known extension when filename has no suffix."""
    suffix = resolve_audio_suffix(filename="audio", content_type="audio/webm")
    assert suffix == ".webm"


def test_resolve_audio_suffix_prefers_filename_suffix() -> None:
    """Filename suffix should take precedence over MIME fallback."""
    suffix = resolve_audio_suffix(filename="clip.wav", content_type="audio/webm")
    assert suffix == ".wav"
