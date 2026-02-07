"""Practice routes for attempts and answers."""

from __future__ import annotations

from uuid import uuid4

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from sqlalchemy.orm import Session

from ...db.session import get_db
from ...models.attempt import Attempt
from ...models.board import Board
from ...schemas.practice import (
    AttemptCreateRequest,
    AttemptResponse,
    TextAnswerRequest,
    TextAnswerResponse,
    VoiceAnswerResponse,
)

router = APIRouter(tags=["practice"])
audio_file = File(...)
language_form = Form("en")
db_session = Depends(get_db)


def _word_count(text: str) -> int:
    """Count words in text by whitespace splitting."""
    words = [chunk for chunk in text.strip().split() if chunk]
    return len(words)


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
    """Submit a text answer and enforce 40-word hard limit."""
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

    return TextAnswerResponse(
        attempt_id=attempt_id,
        word_count=word_count,
        status="queued",
    )


@router.post("/answers/voice", response_model=VoiceAnswerResponse)
async def submit_voice_answer(
    audio: UploadFile = audio_file,
    language: str = language_form,
) -> VoiceAnswerResponse:
    """Accept voice file and return transcript preview placeholder."""
    if not audio.filename:
        raise HTTPException(status_code=400, detail="Audio filename is required")

    _ = await audio.read()
    await audio.close()

    return VoiceAnswerResponse(
        transcript_preview="This is a mock ASR transcript preview.",
        language=language,
    )
