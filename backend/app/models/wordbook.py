"""Wordbook ORM model."""

from __future__ import annotations

from sqlalchemy import String, Text
from sqlalchemy.orm import Mapped, mapped_column

from ..db.base import Base, TimestampMixin, UUIDPrimaryKeyMixin


class WordbookEntry(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """Vocabulary entry collected from evaluations."""

    __tablename__ = "wordbook_entries"

    word: Mapped[str] = mapped_column(String(255), nullable=False)
    definition: Mapped[str] = mapped_column(Text, nullable=False)
    level: Mapped[str] = mapped_column(String(32), nullable=False)
    source: Mapped[str] = mapped_column(String(64), nullable=False)
