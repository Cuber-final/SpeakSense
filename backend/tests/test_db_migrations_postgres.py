"""PostgreSQL migration smoke tests."""

from __future__ import annotations

import os
from pathlib import Path

import pytest
from alembic.config import Config
from sqlalchemy import create_engine, text

from alembic import command
from backend.app.core.settings import get_settings


@pytest.mark.integration()
def test_alembic_upgrade_head_on_postgres() -> None:
    """Alembic head migration should create required core tables on PostgreSQL."""
    database_url = os.getenv("TEST_POSTGRES_URL", os.getenv("TEST_DATABASE_URL", ""))
    if not database_url.startswith("postgresql+psycopg://"):
        pytest.skip(
            "Set TEST_POSTGRES_URL (or TEST_DATABASE_URL) to run PG migration test."
        )

    original_database_url = os.getenv("DATABASE_URL")
    try:
        os.environ["DATABASE_URL"] = database_url
        get_settings.cache_clear()

        alembic_ini = Path(__file__).resolve().parents[1] / "alembic.ini"
        alembic_config = Config(str(alembic_ini))
        command.upgrade(alembic_config, "head")

        engine = create_engine(database_url)
        with engine.connect() as connection:
            users_table = connection.execute(
                text("select to_regclass('public.users')")
            ).scalar_one()
            boards_table = connection.execute(
                text("select to_regclass('public.boards')")
            ).scalar_one()
            evaluations_table = connection.execute(
                text("select to_regclass('public.evaluations')")
            ).scalar_one()
    finally:
        if original_database_url is None:
            os.environ.pop("DATABASE_URL", None)
        else:
            os.environ["DATABASE_URL"] = original_database_url
        get_settings.cache_clear()

    assert users_table == "users"
    assert boards_table == "boards"
    assert evaluations_table == "evaluations"
