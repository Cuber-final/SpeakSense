"""JWT and password utilities for authentication."""

from __future__ import annotations

import base64
import binascii
import hashlib
import hmac
import secrets
from datetime import UTC, datetime, timedelta
from typing import Any

import jwt
from jwt import ExpiredSignatureError, InvalidTokenError

from ...core.settings import get_settings
from .exceptions import AuthServiceError

_PASSWORD_SCHEME = "pbkdf2_sha256"
_PASSWORD_ITERATIONS = 390000


def hash_password(password: str) -> str:
    """Hash plaintext password with PBKDF2-HMAC-SHA256."""
    salt = secrets.token_bytes(16)
    digest = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode("utf-8"),
        salt,
        _PASSWORD_ITERATIONS,
    )
    return (
        f"{_PASSWORD_SCHEME}${_PASSWORD_ITERATIONS}$"
        f"{base64.urlsafe_b64encode(salt).decode('utf-8')}$"
        f"{base64.urlsafe_b64encode(digest).decode('utf-8')}"
    )


def verify_password(password: str, password_hash: str) -> bool:
    """Verify plaintext password against PBKDF2 hash string."""
    try:
        scheme, iterations_text, salt_text, digest_text = password_hash.split("$", 3)
    except ValueError:
        return False

    if scheme != _PASSWORD_SCHEME:
        return False

    try:
        iterations = int(iterations_text)
        salt = base64.urlsafe_b64decode(salt_text.encode("utf-8"))
        expected_digest = base64.urlsafe_b64decode(digest_text.encode("utf-8"))
    except (ValueError, binascii.Error):
        return False

    candidate_digest = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode("utf-8"),
        salt,
        iterations,
    )
    return hmac.compare_digest(candidate_digest, expected_digest)


def create_access_token(
    *,
    user_id: str,
    username: str,
    role: str,
) -> str:
    """Create signed JWT access token from user identity."""
    settings = get_settings()
    now = datetime.now(UTC)
    expires_at = now + timedelta(minutes=settings.jwt_expires_minutes)

    payload: dict[str, Any] = {
        "sub": user_id,
        "username": username,
        "role": role,
        "jti": secrets.token_hex(16),
        "iat": int(now.timestamp()),
        "exp": int(expires_at.timestamp()),
    }

    return jwt.encode(
        payload,
        settings.jwt_secret,
        algorithm=settings.jwt_algorithm,
    )


def decode_access_token(token: str) -> dict[str, Any]:
    """Decode and validate access token payload."""
    settings = get_settings()

    try:
        payload = jwt.decode(
            token,
            settings.jwt_secret,
            algorithms=[settings.jwt_algorithm],
        )
    except ExpiredSignatureError as exc:
        raise AuthServiceError(
            error_type="auth_error",
            code="AUTH_TOKEN_EXPIRED",
            message="Access token has expired",
            status_code=401,
        ) from exc
    except InvalidTokenError as exc:
        raise AuthServiceError(
            error_type="auth_error",
            code="AUTH_TOKEN_INVALID",
            message="Access token is invalid",
            status_code=401,
        ) from exc

    if not isinstance(payload, dict):
        raise AuthServiceError(
            error_type="auth_error",
            code="AUTH_TOKEN_INVALID",
            message="Access token payload is invalid",
            status_code=401,
        )

    return payload
