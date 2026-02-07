"""MVP API flow tests for boards, practice, and evaluation."""

from __future__ import annotations

from fastapi.testclient import TestClient


def test_board_attempt_evaluation_flow(client: TestClient) -> None:
    """Create board and attempt, then fetch evaluation detail."""
    create_board = client.post(
        "/v1/boards",
        json={"title": "Coffee", "topic": "Cafe", "level": "B1"},
    )
    assert create_board.status_code == 201
    board_id = create_board.json()["id"]

    create_attempt = client.post("/v1/attempts", json={"board_id": board_id})
    assert create_attempt.status_code == 201
    attempt_id = create_attempt.json()["id"]

    submit_text = client.post(
        f"/v1/attempts/{attempt_id}/answers/text",
        json={"text": "Could I get a hot latte with oat milk please"},
    )
    assert submit_text.status_code == 200
    assert submit_text.json()["status"] == "queued"

    status_response = client.get(f"/v1/attempts/{attempt_id}/status")
    assert status_response.status_code == 200
    assert status_response.json()["status"] == "completed"

    detail_response = client.get(f"/v1/attempts/{attempt_id}/evaluation")
    assert detail_response.status_code == 200
    data = detail_response.json()["data"]
    assert data["id"] == attempt_id
    assert isinstance(data["dimensions"], list)


def test_text_word_limit_validation(client: TestClient) -> None:
    """Submitting more than 40 words should fail with Problem JSON."""
    create_board = client.post(
        "/v1/boards",
        json={"title": "Travel", "topic": "Airport", "level": "B2"},
    )
    assert create_board.status_code == 201
    board_id = create_board.json()["id"]

    create_attempt = client.post("/v1/attempts", json={"board_id": board_id})
    assert create_attempt.status_code == 201
    attempt_id = create_attempt.json()["id"]

    over_limit_text = " ".join(["word"] * 41)
    response = client.post(
        f"/v1/attempts/{attempt_id}/answers/text",
        json={"text": over_limit_text},
    )

    assert response.status_code == 422
    body = response.json()
    assert body["error"]["code"] == "HTTP_422"
