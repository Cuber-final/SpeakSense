"""In-process websocket event hub for lightweight realtime notifications."""

from __future__ import annotations

import asyncio
import json
from dataclasses import dataclass
from uuid import uuid4


@dataclass(slots=True)
class Subscription:
    """Represents one websocket subscriber."""

    client_id: str
    queue: asyncio.Queue[str]


class EventHub:
    """Broadcast JSON events to active websocket subscribers."""

    def __init__(self) -> None:
        self._loop: asyncio.AbstractEventLoop | None = None
        self._subscriptions: dict[str, asyncio.Queue[str]] = {}

    def subscribe(self) -> Subscription:
        """Register one websocket subscriber."""
        self._ensure_loop()
        client_id = str(uuid4())
        queue: asyncio.Queue[str] = asyncio.Queue(maxsize=32)
        self._subscriptions[client_id] = queue
        return Subscription(client_id=client_id, queue=queue)

    def unsubscribe(self, client_id: str) -> None:
        """Unregister one websocket subscriber."""
        self._subscriptions.pop(client_id, None)

    def publish_sync(self, event: dict[str, object]) -> None:
        """Publish one event from sync or async contexts."""
        message = json.dumps(event, separators=(",", ":"))

        try:
            running_loop = asyncio.get_running_loop()
        except RuntimeError:
            if self._loop is None or self._loop.is_closed():
                self._loop = None
                return

            try:
                self._loop.call_soon_threadsafe(self._broadcast_message, message)
            except RuntimeError:
                # Bound loop can be closed between checks (e.g., test teardown).
                self._loop = None
            return

        if self._loop is None or self._loop.is_closed() or self._loop != running_loop:
            self._loop = running_loop

        self._broadcast_message(message)

    def _ensure_loop(self) -> None:
        """Bind hub to the currently running event loop if needed."""
        if self._loop is None or self._loop.is_closed():
            self._loop = asyncio.get_running_loop()

    def _broadcast_message(self, message: str) -> None:
        """Push one serialized event to all subscriber queues."""
        if not self._subscriptions:
            return

        stale_client_ids: list[str] = []
        for client_id, queue in self._subscriptions.items():
            if queue.full():
                # Drop oldest queued event so newest status can still arrive.
                queue.get_nowait()
            try:
                queue.put_nowait(message)
            except asyncio.QueueFull:
                stale_client_ids.append(client_id)

        for client_id in stale_client_ids:
            self._subscriptions.pop(client_id, None)


event_hub = EventHub()
