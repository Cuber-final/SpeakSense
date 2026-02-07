"""add users table

Revision ID: 20260207_0002
Revises: 20260207_0001
Create Date: 2026-02-07 15:45:00
"""

from __future__ import annotations

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision = "20260207_0002"
down_revision = "20260207_0001"
branch_labels = None
depends_on = None


def upgrade() -> None:
    """Create users table with unique username index."""
    op.create_table(
        "users",
        sa.Column("id", sa.String(length=36), primary_key=True),
        sa.Column("username", sa.String(length=128), nullable=False),
        sa.Column("password_hash", sa.String(length=512), nullable=False),
        sa.Column("role", sa.String(length=32), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_users_username", "users", ["username"], unique=True)


def downgrade() -> None:
    """Drop users table and index."""
    op.drop_index("ix_users_username", table_name="users")
    op.drop_table("users")
