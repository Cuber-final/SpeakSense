"""Structured JSON logging configuration."""

from __future__ import annotations

import json
import logging
from datetime import UTC, datetime

from .request_context import get_request_id


class JsonFormatter(logging.Formatter):
    """Serialize log records as JSON lines."""

    def format(self, record: logging.LogRecord) -> str:
        """Format a log record into a JSON string."""
        payload: dict[str, object] = {
            "timestamp": datetime.now(UTC).isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
        }

        request_id = get_request_id()
        if request_id:
            payload["request_id"] = request_id

        if record.exc_info:
            payload["exception"] = self.formatException(record.exc_info)

        return json.dumps(payload, ensure_ascii=True)


def configure_logging() -> None:
    """Configure root logger to output JSON logs."""
    root_logger = logging.getLogger()
    root_logger.setLevel(logging.INFO)

    handler = logging.StreamHandler()
    handler.setFormatter(JsonFormatter())

    root_logger.handlers.clear()
    root_logger.addHandler(handler)
