"""Schemas for wordbook endpoints."""

from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, Field


class WordProvenance(BaseModel):
    """Word source metadata for traceability."""

    attempt_id: str | None = None
    evaluation_id: str | None = None
    board_id: str | None = None
    question_id: str | None = None
    note: str | None = None


class WordCreateRequest(BaseModel):
    """Wordbook creation payload."""

    word: str = Field(min_length=1)
    definition: str = Field(min_length=1)
    level: str = Field(default="B1")
    source: str = Field(default="evaluation")
    provenance: WordProvenance | None = None


class WordResponse(BaseModel):
    """Wordbook response payload."""

    id: str
    word: str
    definition: str
    level: str
    source: str
    provenance: WordProvenance | None = None
    created_at: datetime
