"""Integration test for real Redis/RQ async pipeline."""

from __future__ import annotations

from uuid import uuid4

import pytest
from fastapi.testclient import TestClient
from redis import Redis
from redis.exceptions import RedisError
from rq import Queue, SimpleWorker

from backend.app.core.settings import get_settings


def _can_connect_redis(redis_url: str) -> bool:
    """Return whether Redis is reachable for integration tests."""
    try:
        client = Redis.from_url(redis_url)
        return bool(client.ping())
    except RedisError:
        return False


@pytest.mark.integration()
def test_async_queue_pipeline_with_real_worker(client: TestClient) -> None:
    """Queue jobs should be processed by RQ worker and update DB statuses."""
    settings = get_settings()
    if not _can_connect_redis(settings.redis_url):
        pytest.skip("Redis is not reachable; skipping async integration test.")

    original_enable = settings.enable_async_jobs
    original_inline_fallback = settings.job_inline_fallback
    original_queue = settings.job_queue_name
    settings.enable_async_jobs = True
    settings.job_inline_fallback = False
    settings.job_queue_name = f"test-async-{uuid4().hex[:8]}"

    redis_conn = Redis.from_url(settings.redis_url)
    queue = Queue(name=settings.job_queue_name, connection=redis_conn)

    try:
        board_response = client.post(
            "/v1/boards",
            json={"title": "Ordering Food", "topic": "Restaurant", "level": "B1"},
        )
        assert board_response.status_code == 201
        board_id = board_response.json()["id"]
        assert board_response.json()["status"] == "generating"

        worker = SimpleWorker([queue], connection=redis_conn)
        worker.work(burst=True)

        list_response = client.get("/v1/boards")
        assert list_response.status_code == 200
        board_item = next(
            item for item in list_response.json() if item["id"] == board_id
        )
        assert board_item["status"] == "ready"

        attempt_response = client.post("/v1/attempts", json={"board_id": board_id})
        assert attempt_response.status_code == 201
        attempt_id = attempt_response.json()["id"]

        submit_response = client.post(
            f"/v1/attempts/{attempt_id}/answers/text",
            json={"text": "Could I have a bowl of noodles and hot tea please"},
        )
        assert submit_response.status_code == 200
        assert submit_response.json()["status"] == "queued"

        worker.work(burst=True)

        status_response = client.get(f"/v1/attempts/{attempt_id}/status")
        assert status_response.status_code == 200
        assert status_response.json()["status"] == "completed"

        evaluation_response = client.get(f"/v1/attempts/{attempt_id}/evaluation")
        assert evaluation_response.status_code == 200
        assert "data" in evaluation_response.json()
    finally:
        settings.enable_async_jobs = original_enable
        settings.job_inline_fallback = original_inline_fallback
        settings.job_queue_name = original_queue
