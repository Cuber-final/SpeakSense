"""Websocket routes for realtime frontend updates."""

from __future__ import annotations

from fastapi import APIRouter, WebSocket, WebSocketDisconnect

from .hub import event_hub

router = APIRouter(tags=["ws"])


@router.websocket("/ws/events")
async def ws_events(websocket: WebSocket) -> None:
    """Stream realtime events to one connected frontend client."""
    await websocket.accept()
    subscription = event_hub.subscribe()
    try:
        while True:
            message = await subscription.queue.get()
            await websocket.send_text(message)
    except WebSocketDisconnect:
        return
    finally:
        event_hub.unsubscribe(subscription.client_id)
