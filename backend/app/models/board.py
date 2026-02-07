"""Board ORM model."""

from __future__ import annotations

from sqlalchemy import String
from sqlalchemy.orm import Mapped, mapped_column

from ..db.base import Base, TimestampMixin, UUIDPrimaryKeyMixin


class Board(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """Board entity for generated practice scenarios."""

    __tablename__ = "boards"

    title: Mapped[str] = mapped_column(String(255), nullable=False)
    topic: Mapped[str] = mapped_column(String(255), nullable=False)
    level: Mapped[str] = mapped_column(String(32), nullable=False)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="ready")
