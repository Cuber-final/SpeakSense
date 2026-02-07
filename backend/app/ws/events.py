"""Typed event emitters for websocket consumers."""

from __future__ import annotations

from datetime import UTC, datetime

from .hub import event_hub


def publish_evaluation_completed(attempt_id: str) -> None:
    """Emit evaluation completion event for one attempt."""
    event_hub.publish_sync(
        {
            "type": "evaluation.completed",
            "attempt_id": attempt_id,
            "occurred_at": datetime.now(UTC).isoformat(),
            "payload": {
                "attempt_id": attempt_id,
                "status": "completed",
            },
        }
    )
