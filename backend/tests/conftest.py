"""Pytest fixtures for backend tests."""

from __future__ import annotations

import os
from collections.abc import Generator
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

TEST_DB_PATH = Path("/tmp/speaksense_backend_test.db")
DEFAULT_SQLITE_URL = f"sqlite+pysqlite:///{TEST_DB_PATH}"
TEST_DATABASE_URL = os.getenv("TEST_DATABASE_URL", DEFAULT_SQLITE_URL)
os.environ["DATABASE_URL"] = TEST_DATABASE_URL

from backend.app.db.base import Base  # noqa: E402
from backend.app.db.session import engine  # noqa: E402
from backend.app.main import app  # noqa: E402


@pytest.fixture(autouse=True)
def reset_database() -> Generator[None, None, None]:
    """Reset all tables before each test for deterministic behavior."""
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    yield


@pytest.fixture()
def client() -> Generator[TestClient, None, None]:
    """Provide test client for API tests."""
    with TestClient(app) as test_client:
        yield test_client
