"""add evaluations table

Revision ID: 20260207_0003
Revises: 20260207_0002
Create Date: 2026-02-07 16:20:00
"""

from __future__ import annotations

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision = "20260207_0003"
down_revision = "20260207_0002"
branch_labels = None
depends_on = None


def upgrade() -> None:
    """Create evaluations table keyed by attempt id."""
    op.create_table(
        "evaluations",
        sa.Column("id", sa.String(length=36), primary_key=True),
        sa.Column("attempt_id", sa.String(length=36), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("payload_json", sa.Text(), nullable=True),
        sa.Column("error_message", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["attempt_id"], ["attempts.id"], ondelete="CASCADE"),
    )
    op.create_index(
        "ix_evaluations_attempt_id",
        "evaluations",
        ["attempt_id"],
        unique=True,
    )


def downgrade() -> None:
    """Drop evaluations table and index."""
    op.drop_index("ix_evaluations_attempt_id", table_name="evaluations")
    op.drop_table("evaluations")
