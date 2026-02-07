"""Websocket realtime event behavior tests."""

from __future__ import annotations

from typing import TYPE_CHECKING

from fastapi.testclient import TestClient

from backend.app.ws.events import publish_evaluation_completed

if TYPE_CHECKING:
    import pytest


def test_ws_events_stream_published_event(client: TestClient) -> None:
    """Connected websocket should receive a published evaluation event."""
    with client.websocket_connect("/ws/events") as websocket:
        publish_evaluation_completed("attempt-123")
        payload = websocket.receive_json()

    assert payload["type"] == "evaluation.completed"
    assert payload["attempt_id"] == "attempt-123"
    assert payload["payload"]["status"] == "completed"


def test_submit_answer_triggers_event_publish(
    client: TestClient,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """Submitting text answer should invoke evaluation completion event publisher."""
    published_attempt_ids: list[str] = []

    def _capture_publish(attempt_id: str) -> None:
        published_attempt_ids.append(attempt_id)

    monkeypatch.setattr(
        "backend.app.jobs.tasks.publish_evaluation_completed",
        _capture_publish,
    )

    board_response = client.post(
        "/v1/boards",
        json={"title": "Meeting", "topic": "Work", "level": "B2"},
    )
    assert board_response.status_code == 201
    board_id = board_response.json()["id"]

    attempt_response = client.post("/v1/attempts", json={"board_id": board_id})
    assert attempt_response.status_code == 201
    attempt_id = attempt_response.json()["id"]

    submit_response = client.post(
        f"/v1/attempts/{attempt_id}/answers/text",
        json={"text": "I can present the project update in ten minutes."},
    )

    assert submit_response.status_code == 200
    assert published_attempt_ids == [attempt_id]
