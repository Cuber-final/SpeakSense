"""Schemas for wordbook endpoints."""

from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, Field


class WordCreateRequest(BaseModel):
    """Wordbook creation payload."""

    word: str = Field(min_length=1)
    definition: str = Field(min_length=1)
    level: str = Field(default="B1")
    source: str = Field(default="evaluation")


class WordResponse(BaseModel):
    """Wordbook response payload."""

    id: str
    word: str
    definition: str
    level: str
    source: str
    created_at: datetime
