"""Context variables shared across request lifecycle."""

from __future__ import annotations

from contextvars import ContextVar

_request_id_ctx: ContextVar[str | None] = ContextVar("request_id", default=None)


def set_request_id(value: str) -> None:
    """Set request identifier for current context."""
    _request_id_ctx.set(value)


def get_request_id() -> str | None:
    """Get request identifier from current context."""
    return _request_id_ctx.get()
