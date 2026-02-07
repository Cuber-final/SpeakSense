"""init core tables

Revision ID: 20260207_0001
Revises: None
Create Date: 2026-02-07 14:30:00
"""

from __future__ import annotations

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision = "20260207_0001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    """Create initial MVP tables."""
    op.create_table(
        "boards",
        sa.Column("id", sa.String(length=36), primary_key=True),
        sa.Column("title", sa.String(length=255), nullable=False),
        sa.Column("topic", sa.String(length=255), nullable=False),
        sa.Column("level", sa.String(length=32), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )

    op.create_table(
        "attempts",
        sa.Column("id", sa.String(length=36), primary_key=True),
        sa.Column("board_id", sa.String(length=36), nullable=False),
        sa.Column("answer_text", sa.Text(), nullable=True),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["board_id"], ["boards.id"], ondelete="CASCADE"),
    )
    op.create_index("ix_attempts_board_id", "attempts", ["board_id"])

    op.create_table(
        "wordbook_entries",
        sa.Column("id", sa.String(length=36), primary_key=True),
        sa.Column("word", sa.String(length=255), nullable=False),
        sa.Column("definition", sa.Text(), nullable=False),
        sa.Column("level", sa.String(length=32), nullable=False),
        sa.Column("source", sa.String(length=64), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )


def downgrade() -> None:
    """Drop initial MVP tables."""
    op.drop_table("wordbook_entries")
    op.drop_index("ix_attempts_board_id", table_name="attempts")
    op.drop_table("attempts")
    op.drop_table("boards")
