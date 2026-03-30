"""add board questions and wordbook provenance

Revision ID: 20260208_0004
Revises: 20260207_0003
Create Date: 2026-02-08 15:10:00
"""

from __future__ import annotations

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision = "20260208_0004"
down_revision = "20260207_0003"
branch_labels = None
depends_on = None


def upgrade() -> None:
    """Add question payload storage and provenance metadata columns."""
    op.add_column(
        "boards",
        sa.Column("questions_json", sa.Text(), nullable=False, server_default="[]"),
    )
    op.add_column(
        "wordbook_entries",
        sa.Column("provenance_json", sa.Text(), nullable=True),
    )


def downgrade() -> None:
    """Drop question payload and provenance metadata columns."""
    op.drop_column("wordbook_entries", "provenance_json")
    op.drop_column("boards", "questions_json")
