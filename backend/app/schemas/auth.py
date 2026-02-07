"""Schemas for auth endpoints."""

from __future__ import annotations

from pydantic import BaseModel, Field


class LoginRequest(BaseModel):
    """Login request payload."""

    username: str = Field(min_length=1)
    password: str = Field(min_length=1)


class LoginResponse(BaseModel):
    """Login response payload."""

    access_token: str
    token_type: str = "bearer"


class UserMeResponse(BaseModel):
    """Current user payload."""

    user_id: str
    username: str
    role: str
