"""Evaluation ORM model."""

from __future__ import annotations

from sqlalchemy import ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from ..db.base import Base, TimestampMixin, UUIDPrimaryKeyMixin


class Evaluation(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """Evaluation result entity for one attempt."""

    __tablename__ = "evaluations"

    attempt_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("attempts.id", ondelete="CASCADE"),
        nullable=False,
        unique=True,
    )
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="pending")
    payload_json: Mapped[str | None] = mapped_column(Text, nullable=True)
    error_message: Mapped[str | None] = mapped_column(Text, nullable=True)
