"""Request ID middleware implementation."""

from __future__ import annotations

import uuid
from collections.abc import Awaitable, Callable

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

from .request_context import set_request_id


class RequestIDMiddleware(BaseHTTPMiddleware):
    """Attach and propagate X-Request-Id for every request."""

    async def dispatch(
        self,
        request: Request,
        call_next: Callable[[Request], Awaitable[Response]],
    ) -> Response:
        """Inject request id from header or generate one when missing."""
        request_id_header = request.headers.get("X-Request-Id")
        request_id = request_id_header if request_id_header else str(uuid.uuid4())

        set_request_id(request_id)
        request.state.request_id = request_id

        response = await call_next(request)
        response.headers["X-Request-Id"] = request_id

        return response
