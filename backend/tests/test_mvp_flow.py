"""MVP API flow tests for boards, practice, and evaluation."""

from __future__ import annotations

from fastapi.testclient import TestClient
from sqlalchemy import update

from backend.app.db.session import SessionLocal
from backend.app.models.wordbook import WordbookEntry


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


def test_board_questions_ready_and_persisted(client: TestClient) -> None:
    """Generated board questions should be persisted and returned from API."""
    create_board = client.post(
        "/v1/boards",
        json={"title": "Hotel Check-in", "topic": "Travel", "level": "B1"},
    )
    assert create_board.status_code == 201
    board_id = create_board.json()["id"]
    assert create_board.json()["status"] == "ready"

    questions_response = client.get(f"/v1/boards/{board_id}/questions")
    assert questions_response.status_code == 200
    questions = questions_response.json()["questions"]
    variants = [item["variant"] for item in questions]
    assert variants == ["core", "follow_up", "role_play", "reflection"]
    assert all(item["prompt"] for item in questions)


def test_wordbook_provenance_round_trip(client: TestClient) -> None:
    """Wordbook API should accept and return provenance metadata."""
    payload = {
        "word": "negotiate",
        "definition": "to discuss and reach an agreement",
        "level": "B2",
        "source": "evaluation",
        "provenance": {
            "attempt_id": "attempt-123",
            "evaluation_id": "evaluation-123",
            "board_id": "board-123",
            "question_id": "question-123",
            "note": "Extracted from feedback",
        },
    }

    create_word = client.post("/v1/wordbook", json=payload)
    assert create_word.status_code == 201
    body = create_word.json()
    assert body["word"] == "negotiate"
    assert body["provenance"]["attempt_id"] == "attempt-123"

    list_words = client.get("/v1/wordbook")
    assert list_words.status_code == 200
    assert list_words.json()[0]["provenance"]["question_id"] == "question-123"


def test_wordbook_list_tolerates_invalid_provenance_json(client: TestClient) -> None:
    """Wordbook list should not fail when provenance payload in DB is invalid."""
    create_word = client.post(
        "/v1/wordbook",
        json={
            "word": "clarify",
            "definition": "to make something easier to understand",
            "level": "B1",
            "source": "evaluation",
        },
    )
    assert create_word.status_code == 201
    word_id = create_word.json()["id"]

    with SessionLocal() as session:
        session.execute(
            update(WordbookEntry)
            .where(WordbookEntry.id == word_id)
            .values(provenance_json="{invalid_json")
        )
        session.commit()

    list_words = client.get("/v1/wordbook")
    assert list_words.status_code == 200
    item = next(entry for entry in list_words.json() if entry["id"] == word_id)
    assert item["provenance"] is None


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
