"""Authentication endpoint tests."""

from __future__ import annotations

from fastapi.testclient import TestClient


def test_login_success_and_me(client: TestClient) -> None:
    """Login should return JWT and /me should resolve user profile."""
    login_response = client.post(
        "/v1/auth/login",
        json={"username": "dev_admin", "password": "dev_admin_123456"},
    )

    assert login_response.status_code == 200
    login_payload = login_response.json()
    assert login_payload["token_type"] == "bearer"
    assert isinstance(login_payload["access_token"], str)
    assert login_payload["expires_in"] > 0

    access_token = login_payload["access_token"]
    me_response = client.get(
        "/v1/auth/me",
        headers={"Authorization": f"Bearer {access_token}"},
    )

    assert me_response.status_code == 200
    me_payload = me_response.json()
    assert me_payload["username"] == "dev_admin"
    assert me_payload["role"] == "admin"


def test_login_invalid_credentials(client: TestClient) -> None:
    """Login should reject invalid credentials with Problem JSON."""
    response = client.post(
        "/v1/auth/login",
        json={"username": "dev_admin", "password": "wrong-password"},
    )

    assert response.status_code == 401
    body = response.json()
    assert body["error"]["code"] == "AUTH_INVALID_CREDENTIALS"


def test_me_requires_bearer_token(client: TestClient) -> None:
    """Requesting /me without Authorization header should fail."""
    response = client.get("/v1/auth/me")

    assert response.status_code == 401
    body = response.json()
    assert body["error"]["code"] == "AUTH_TOKEN_MISSING"
