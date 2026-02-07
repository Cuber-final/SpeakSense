"""Evaluation pending-state behavior tests."""

from __future__ import annotations

from typing import TYPE_CHECKING

from fastapi.testclient import TestClient

if TYPE_CHECKING:
    import pytest


def _noop_dispatch(_: str) -> None:
    """Do nothing, used to simulate async queue delay."""


def test_evaluation_pending_returns_conflict(
    client: TestClient,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """Evaluation detail should return 409 when job has not produced result yet."""
    monkeypatch.setattr(
        "backend.app.api.v1.practice.dispatch_evaluate_attempt",
        _noop_dispatch,
    )

    board_response = client.post(
        "/v1/boards",
        json={"title": "Phone Call", "topic": "Support", "level": "B1"},
    )
    assert board_response.status_code == 201
    board_id = board_response.json()["id"]

    attempt_response = client.post("/v1/attempts", json={"board_id": board_id})
    assert attempt_response.status_code == 201
    attempt_id = attempt_response.json()["id"]

    submit_response = client.post(
        f"/v1/attempts/{attempt_id}/answers/text",
        json={"text": "I need help with my account settings."},
    )
    assert submit_response.status_code == 200
    assert submit_response.json()["status"] == "queued"

    status_response = client.get(f"/v1/attempts/{attempt_id}/status")
    assert status_response.status_code == 200
    assert status_response.json()["status"] == "queued"

    detail_response = client.get(f"/v1/attempts/{attempt_id}/evaluation")
    assert detail_response.status_code == 409
    body = detail_response.json()
    assert body["error"]["code"] == "HTTP_409"
