"""Attempt ORM model."""

from __future__ import annotations

from sqlalchemy import ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from ..db.base import Base, TimestampMixin, UUIDPrimaryKeyMixin


class Attempt(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """User attempt entity bound to a board."""

    __tablename__ = "attempts"

    board_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("boards.id", ondelete="CASCADE"),
        nullable=False,
    )
    answer_text: Mapped[str | None] = mapped_column(Text, nullable=True)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="draft")
