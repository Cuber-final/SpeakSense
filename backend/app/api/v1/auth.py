"""Authentication routes for JWT login and current-user profile."""

from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from ...core.settings import get_settings
from ...db.session import get_db
from ...models.user import User
from ...schemas.auth import LoginRequest, LoginResponse, UserMeResponse
from ...services.auth import (
    AuthServiceError,
    create_access_token,
    get_current_user,
    verify_password,
)

router = APIRouter(prefix="/auth", tags=["auth"])
_db_session = Depends(get_db)
_current_user = Depends(get_current_user)


@router.post("/login", response_model=LoginResponse)
async def login(
    payload: LoginRequest,
    db: Session = _db_session,
) -> LoginResponse:
    """Authenticate user credentials and return access token."""
    user = db.execute(
        select(User).where(User.username == payload.username)
    ).scalar_one_or_none()

    if user is None or not verify_password(payload.password, user.password_hash):
        raise AuthServiceError(
            error_type="auth_error",
            code="AUTH_INVALID_CREDENTIALS",
            message="Username or password is invalid",
            status_code=401,
        )

    if not user.is_active:
        raise AuthServiceError(
            error_type="auth_error",
            code="AUTH_USER_DISABLED",
            message="User account is disabled",
            status_code=403,
        )

    token = create_access_token(user_id=user.id, username=user.username, role=user.role)

    return LoginResponse(
        access_token=token,
        token_type="bearer",
        expires_in=get_settings().jwt_expires_minutes * 60,
    )


@router.get("/me", response_model=UserMeResponse)
async def me(current_user: User = _current_user) -> UserMeResponse:
    """Return profile for current authenticated user."""
    return UserMeResponse(
        user_id=current_user.id,
        username=current_user.username,
        role=current_user.role,
    )
