"""Voice ASR endpoint behavior tests."""

from __future__ import annotations

import io
import os
import wave
from pathlib import Path
from tempfile import NamedTemporaryFile
from typing import TYPE_CHECKING

from fastapi.testclient import TestClient

from backend.app.core.settings import get_settings

if TYPE_CHECKING:
    import pytest


def _build_wav_bytes(duration_seconds: float, sample_rate: int = 16000) -> bytes:
    """Build in-memory silent WAV bytes for tests."""
    frame_count = int(duration_seconds * sample_rate)
    payload = io.BytesIO()
    with wave.open(payload, "wb") as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        wav_file.writeframes(b"\x00\x00" * frame_count)
    return payload.getvalue()


def test_voice_answer_returns_mock_transcript(client: TestClient) -> None:
    """Voice endpoint should return mock transcript with mock ASR provider."""
    settings = get_settings()
    original_provider = settings.asr_provider
    original_text = settings.asr_mock_transcript
    try:
        settings.asr_provider = "mock"
        settings.asr_mock_transcript = "mock-asr-transcript"
        wav = _build_wav_bytes(1.0)
        response = client.post(
            "/v1/answers/voice",
            files={"audio": ("sample.wav", wav, "audio/wav")},
            data={"language": "en"},
        )
    finally:
        settings.asr_provider = original_provider
        settings.asr_mock_transcript = original_text

    assert response.status_code == 200
    assert response.json()["transcript_preview"] == "mock-asr-transcript"


def test_voice_answer_rejects_when_delete_guard_disabled(client: TestClient) -> None:
    """Endpoint should refuse operation when ASR delete-audio guard is disabled."""
    settings = get_settings()
    original_flag = settings.asr_delete_audio_after
    try:
        settings.asr_delete_audio_after = False
        wav = _build_wav_bytes(1.0)
        response = client.post(
            "/v1/answers/voice",
            files={"audio": ("sample.wav", wav, "audio/wav")},
            data={"language": "en"},
        )
    finally:
        settings.asr_delete_audio_after = original_flag

    assert response.status_code == 500
    assert response.json()["error"]["code"] == "HTTP_500"


def test_voice_answer_rejects_when_duration_exceeds_limit(client: TestClient) -> None:
    """Endpoint should return 422 when WAV duration exceeds configured limit."""
    settings = get_settings()
    original_limit = settings.asr_max_duration_seconds
    try:
        settings.asr_max_duration_seconds = 1
        wav = _build_wav_bytes(2.0)
        response = client.post(
            "/v1/answers/voice",
            files={"audio": ("long.wav", wav, "audio/wav")},
            data={"language": "en"},
        )
    finally:
        settings.asr_max_duration_seconds = original_limit

    assert response.status_code == 422
    assert response.json()["error"]["code"] == "HTTP_422"


def test_voice_answer_temp_file_is_deleted(
    client: TestClient,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """Temporary audio file should be deleted after ASR processing."""
    settings = get_settings()
    original_provider = settings.asr_provider
    settings.asr_provider = "mock"

    with NamedTemporaryFile(
        prefix="asr_tmp_test_",
        suffix=".wav",
        delete=False,
    ) as temp:
        temp_path = Path(temp.name)

    class _TempWrapper:
        """Minimal temp-file wrapper compatible with route usage."""

        def __init__(self, path: Path) -> None:
            self.name = str(path)
            self._fd = os.open(path, os.O_WRONLY | os.O_TRUNC)

        def write(self, payload: bytes) -> int:
            return os.write(self._fd, payload)

        def flush(self) -> None:
            os.fsync(self._fd)

        def close(self) -> None:
            os.close(self._fd)

        def __enter__(self) -> _TempWrapper:
            return self

        def __exit__(self, *_: object) -> None:
            self.close()

    monkeypatch.setattr(
        "backend.app.api.v1.practice.NamedTemporaryFile",
        lambda **_: _TempWrapper(temp_path),
    )

    try:
        wav = _build_wav_bytes(1.0)
        response = client.post(
            "/v1/answers/voice",
            files={"audio": ("sample.wav", wav, "audio/wav")},
            data={"language": "en"},
        )
    finally:
        settings.asr_provider = original_provider

    assert response.status_code == 200
    assert not temp_path.exists()
