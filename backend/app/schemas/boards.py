"""Schemas for board endpoints."""

from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, Field


class BoardCreateRequest(BaseModel):
    """Board creation payload."""

    title: str = Field(min_length=1)
    topic: str = Field(min_length=1)
    level: str = Field(default="B1")


class BoardResponse(BaseModel):
    """Board response model."""

    id: str
    title: str
    topic: str
    level: str
    status: str
    created_at: datetime


class BoardQuestion(BaseModel):
    """Question attached to a board."""

    id: str
    prompt: str
    variant: str


class BoardQuestionsResponse(BaseModel):
    """Board questions list response."""

    board_id: str
    questions: list[BoardQuestion]
