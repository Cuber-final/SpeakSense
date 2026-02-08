"""Practice routes for attempts and answers."""

from __future__ import annotations

import os
from contextlib import suppress
from email.parser import BytesParser
from email.policy import default
from inspect import isawaitable
from pathlib import Path
from tempfile import NamedTemporaryFile
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.orm import Session

from ...core.settings import get_settings
from ...db.session import get_db
from ...jobs import dispatch_evaluate_attempt
from ...models.attempt import Attempt
from ...models.board import Board
from ...schemas.practice import (
    AttemptCreateRequest,
    AttemptResponse,
    TextAnswerRequest,
    TextAnswerResponse,
    VoiceAnswerResponse,
)
from ...services.asr import (
    ASRServiceError,
    detect_wav_duration_seconds,
    transcribe_audio,
)

router = APIRouter(tags=["practice"])
db_session = Depends(get_db)


def _word_count(text: str) -> int:
    """Count words in text by whitespace splitting."""
    words = [chunk for chunk in text.strip().split() if chunk]
    return len(words)


def _extract_voice_payload(content_type: str, body: bytes) -> tuple[bytes, str, str]:
    """Parse multipart body and return audio bytes, filename, and language."""
    if "multipart/form-data" not in content_type:
        raise HTTPException(
            status_code=415,
            detail="Content-Type must be multipart/form-data",
        )

    envelope = (
        f"Content-Type: {content_type}\r\nMIME-Version: 1.0\r\n\r\n".encode()
        + body
    )
    message = BytesParser(policy=default).parsebytes(envelope)

    audio_bytes: bytes | None = None
    filename = ""
    language = "en"

    for part in message.iter_parts():
        content_disposition = part.get("Content-Disposition", "")
        if "form-data" not in content_disposition:
            continue

        part_name = part.get_param("name", header="Content-Disposition")
        if part_name == "language":
            part_text = part.get_content()
            if isinstance(part_text, str) and part_text.strip():
                language = part_text.strip()
            continue

        if part_name == "audio":
            filename = part.get_filename() or ""
            part_payload = part.get_payload(decode=True)
            if isinstance(part_payload, bytes) and part_payload:
                audio_bytes = part_payload
            continue

    if audio_bytes is None:
        raise HTTPException(status_code=400, detail="Audio file is required")
    if not filename:
        raise HTTPException(status_code=400, detail="Audio filename is required")

    return audio_bytes, filename, language


async def _extract_voice_payload_from_form(
    request: Request,
) -> tuple[bytes, str, str] | None:
    """Parse multipart via Starlette form parser when available."""
    try:
        form = await request.form()
    except Exception:
        return None

    audio_part = form.get("audio")
    if audio_part is None:
        raise HTTPException(status_code=400, detail="Audio file is required")

    filename = getattr(audio_part, "filename", "") or ""
    if not filename:
        raise HTTPException(status_code=400, detail="Audio filename is required")

    read_method = getattr(audio_part, "read", None)
    if not callable(read_method):
        raise HTTPException(status_code=400, detail="Audio payload is invalid")
    payload = read_method()
    if isawaitable(payload):
        payload = await payload
    if not isinstance(payload, bytes):
        raise HTTPException(status_code=400, detail="Audio payload is invalid")

    close_method = getattr(audio_part, "close", None)
    if callable(close_method):
        close_result = close_method()
        if isawaitable(close_result):
            await close_result

    language_raw = form.get("language", "en")
    language = language_raw.strip() if isinstance(language_raw, str) else "en"
    if not language:
        language = "en"

    return payload, filename, language


@router.post(
    "/attempts",
    response_model=AttemptResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_attempt(
    payload: AttemptCreateRequest,
    db: Session = db_session,
) -> AttemptResponse:
    """Create a practice attempt for one board."""
    board = db.get(Board, payload.board_id)
    if board is None:
        raise HTTPException(status_code=404, detail="Board not found")

    attempt = Attempt(id=str(uuid4()), board_id=payload.board_id, status="draft")
    db.add(attempt)
    db.commit()
    db.refresh(attempt)

    return AttemptResponse(
        id=attempt.id,
        board_id=attempt.board_id,
        status=attempt.status,
        created_at=attempt.created_at,
    )


@router.post(
    "/attempts/{attempt_id}/answers/text",
    response_model=TextAnswerResponse,
)
async def submit_text_answer(
    attempt_id: str,
    payload: TextAnswerRequest,
    db: Session = db_session,
) -> TextAnswerResponse:
    """Submit a text answer and dispatch evaluation job."""
    word_count = _word_count(payload.text)
    if word_count > 40:
        raise HTTPException(
            status_code=422,
            detail={
                "message": "Text answer exceeds 40 words",
                "word_count": word_count,
            },
        )

    attempt = db.get(Attempt, attempt_id)
    if attempt is None:
        raise HTTPException(status_code=404, detail="Attempt not found")

    attempt.answer_text = payload.text
    attempt.status = "queued"
    db.add(attempt)
    db.commit()

    dispatch_evaluate_attempt(attempt_id)

    return TextAnswerResponse(
        attempt_id=attempt_id,
        word_count=word_count,
        status="queued",
    )


@router.post("/answers/voice", response_model=VoiceAnswerResponse)
async def submit_voice_answer(
    request: Request,
) -> VoiceAnswerResponse:
    """Accept voice file and return transcript preview."""
    parsed = await _extract_voice_payload_from_form(request)
    if parsed is None:
        content_type = request.headers.get("content-type", "")
        body = await request.body()
        parsed = _extract_voice_payload(content_type, body)
    audio_bytes, filename, language = parsed

    settings = get_settings()
    if not settings.asr_delete_audio_after:
        raise HTTPException(
            status_code=500,
            detail={"message": "ASR_DELETE_AUDIO_AFTER must be true"},
        )

    suffix = Path(filename).suffix or ".bin"
    with NamedTemporaryFile(
        prefix="speaksense_asr_",
        suffix=suffix,
        delete=False,
    ) as temp_file:
        temp_path = Path(temp_file.name)
        temp_file.write(audio_bytes)

    try:
        duration_seconds = detect_wav_duration_seconds(temp_path)
        if (
            duration_seconds is not None
            and duration_seconds > settings.asr_max_duration_seconds
        ):
            raise HTTPException(
                status_code=422,
                detail={
                    "message": "Voice duration exceeds allowed limit",
                    "max_seconds": settings.asr_max_duration_seconds,
                    "duration_seconds": round(duration_seconds, 3),
                },
            )

        try:
            transcript_preview = transcribe_audio(
                file_path=temp_path,
                language=language,
            )
        except ASRServiceError as exc:
            raise HTTPException(
                status_code=502,
                detail={"message": str(exc)},
            ) from exc
    finally:
        with suppress(FileNotFoundError):
            os.unlink(temp_path)

    return VoiceAnswerResponse(
        transcript_preview=transcript_preview,
        language=language,
    )
