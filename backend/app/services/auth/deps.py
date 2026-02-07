"""FastAPI auth dependencies for current-user retrieval."""

from __future__ import annotations

from fastapi import Depends, Request
from sqlalchemy.orm import Session

from ...db.session import get_db
from ...models.user import User
from .exceptions import AuthServiceError
from .security import decode_access_token

_db_session = Depends(get_db)


def _extract_bearer_token(request: Request) -> str:
    """Extract bearer token from Authorization header."""
    auth_header = request.headers.get("Authorization")
    if auth_header is None:
        raise AuthServiceError(
            error_type="auth_error",
            code="AUTH_TOKEN_MISSING",
            message="Authorization header is required",
            status_code=401,
        )

    parts = auth_header.strip().split(" ", 1)
    if len(parts) != 2 or parts[0].lower() != "bearer" or not parts[1]:
        raise AuthServiceError(
            error_type="auth_error",
            code="AUTH_TOKEN_INVALID",
            message="Authorization header must be Bearer token",
            status_code=401,
        )

    return parts[1]


def get_current_user(
    request: Request,
    db: Session = _db_session,
) -> User:
    """Resolve current active user from JWT access token."""
    token = _extract_bearer_token(request)
    payload = decode_access_token(token)

    user_id = payload.get("sub")
    if not isinstance(user_id, str) or not user_id:
        raise AuthServiceError(
            error_type="auth_error",
            code="AUTH_TOKEN_INVALID",
            message="Access token subject is invalid",
            status_code=401,
        )

    user = db.get(User, user_id)
    if user is None:
        raise AuthServiceError(
            error_type="auth_error",
            code="AUTH_USER_NOT_FOUND",
            message="User not found for token subject",
            status_code=401,
        )

    if not user.is_active:
        raise AuthServiceError(
            error_type="auth_error",
            code="AUTH_USER_DISABLED",
            message="User account is disabled",
            status_code=403,
        )

    return user
