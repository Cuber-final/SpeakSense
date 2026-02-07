"""Job dispatch helpers with RQ enqueue and inline fallback."""

from __future__ import annotations

import logging
from collections.abc import Callable

from redis import Redis
from redis.exceptions import RedisError
from rq import Queue

from ..core.settings import get_settings
from .tasks import evaluate_attempt, generate_board

logger = logging.getLogger(__name__)


def dispatch_generate_board(board_id: str) -> None:
    """Dispatch board generation task."""
    _dispatch_task(generate_board, board_id)


def dispatch_evaluate_attempt(attempt_id: str) -> None:
    """Dispatch attempt evaluation task."""
    _dispatch_task(evaluate_attempt, attempt_id)


def _dispatch_task(task: Callable[[str], None], entity_id: str) -> None:
    """Dispatch one task via RQ or inline fallback based on settings."""
    settings = get_settings()

    if not settings.enable_async_jobs:
        task(entity_id)
        return

    try:
        redis_conn = Redis.from_url(settings.redis_url)
        queue = Queue(
            name=settings.job_queue_name,
            connection=redis_conn,
            default_timeout=settings.job_timeout_seconds,
        )
        queue.enqueue(task, entity_id)
    except RedisError:
        logger.warning(
            "Job enqueue failed",
            extra={
                "job": task.__name__,
                "entity_id": entity_id,
                "fallback": settings.job_inline_fallback,
            },
        )

        if settings.job_inline_fallback:
            task(entity_id)
            return

        raise
