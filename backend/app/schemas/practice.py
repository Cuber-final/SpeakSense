"""Schemas for practice endpoints."""

from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, Field


class AttemptCreateRequest(BaseModel):
    """Attempt creation payload."""

    board_id: str = Field(min_length=1)


class AttemptResponse(BaseModel):
    """Attempt response payload."""

    id: str
    board_id: str
    status: str
    created_at: datetime


class TextAnswerRequest(BaseModel):
    """Text answer payload."""

    text: str = Field(min_length=1)


class TextAnswerResponse(BaseModel):
    """Text answer save response."""

    attempt_id: str
    word_count: int
    status: str


class VoiceAnswerResponse(BaseModel):
    """Voice answer preview payload."""

    transcript_preview: str
    language: str
