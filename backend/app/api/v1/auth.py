"""Authentication routes for MVP backend."""

from __future__ import annotations

from fastapi import APIRouter

from ...schemas.auth import LoginRequest, LoginResponse, UserMeResponse

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/login", response_model=LoginResponse)
async def login(payload: LoginRequest) -> LoginResponse:
    """Return a mock JWT-style token for development flow."""
    token = f"dev-token-{payload.username}"
    return LoginResponse(access_token=token)


@router.get("/me", response_model=UserMeResponse)
async def me() -> UserMeResponse:
    """Return current user profile from development stub."""
    return UserMeResponse(user_id="user-dev-001", username="dev_admin", role="admin")
