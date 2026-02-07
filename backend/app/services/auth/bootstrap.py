"""Bootstrap helpers for auth-related startup initialization."""

from __future__ import annotations

import logging
from uuid import uuid4

from sqlalchemy import select
from sqlalchemy.exc import SQLAlchemyError

from ...core.settings import get_settings
from ...db.session import SessionLocal
from ...models.user import User
from .security import hash_password

logger = logging.getLogger(__name__)


def seed_dev_admin() -> None:
    """Create development admin user when running in dev mode."""
    settings = get_settings()
    if settings.app_env != "dev":
        return

    session = SessionLocal()
    try:
        existing = session.execute(
            select(User).where(User.username == settings.dev_admin_username)
        ).scalar_one_or_none()
        if existing is not None:
            return

        admin = User(
            id=str(uuid4()),
            username=settings.dev_admin_username,
            password_hash=hash_password(settings.dev_admin_password),
            role=settings.dev_admin_role,
            is_active=True,
        )
        session.add(admin)
        session.commit()
        logger.info("Seeded development admin user")
    except SQLAlchemyError:
        logger.warning("Skipped development admin seed due to database state")
        session.rollback()
    finally:
        session.close()
