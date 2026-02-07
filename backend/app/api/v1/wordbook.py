"""Wordbook routes for vocabulary management."""

from __future__ import annotations

from uuid import uuid4

from fastapi import APIRouter, Depends, status
from sqlalchemy import Select, select
from sqlalchemy.orm import Session

from ...db.session import get_db
from ...models.wordbook import WordbookEntry
from ...schemas.wordbook import WordCreateRequest, WordResponse

router = APIRouter(prefix="/wordbook", tags=["wordbook"])
db_session = Depends(get_db)


def _to_word_response(record: WordbookEntry) -> WordResponse:
    """Convert wordbook ORM entity to response schema."""
    return WordResponse(
        id=record.id,
        word=record.word,
        definition=record.definition,
        level=record.level,
        source=record.source,
        created_at=record.created_at,
    )


@router.post("", response_model=WordResponse, status_code=status.HTTP_201_CREATED)
async def add_word(
    payload: WordCreateRequest,
    db: Session = db_session,
) -> WordResponse:
    """Add one vocabulary item to wordbook."""
    record = WordbookEntry(
        id=str(uuid4()),
        word=payload.word,
        definition=payload.definition,
        level=payload.level,
        source=payload.source,
    )
    db.add(record)
    db.commit()
    db.refresh(record)
    return _to_word_response(record)


@router.get("", response_model=list[WordResponse])
async def list_words(db: Session = db_session) -> list[WordResponse]:
    """List vocabulary items."""
    query: Select[tuple[WordbookEntry]] = select(WordbookEntry).order_by(
        WordbookEntry.created_at.desc()
    )
    words = db.execute(query).scalars().all()
    return [_to_word_response(record) for record in words]
