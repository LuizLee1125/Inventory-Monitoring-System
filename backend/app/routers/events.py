"""The live stream: `GET /api/events`, one long-lived Server-Sent Events response.

Behind plain `current_user` rather than `require(...)`, for the same reason every
endpoint in `routers/notifications.py` is: every signed-in account has a stream,
and *what appears on it* is decided per event by the permission the event
carries, filtered in `events.Event.wanted_by`. A permission on the route would
have to be one that every role holds, which is the same as no filter at all.
"""

from __future__ import annotations

import asyncio
from collections.abc import AsyncIterator

from fastapi import APIRouter, Depends, Header, HTTPException, Request
from fastapi.responses import StreamingResponse

from .. import events
from ..deps import current_user

router = APIRouter(tags=["events"])

# Told to the browser, which honours it on every automatic reconnect. Three
# seconds is EventSource's own default; it is stated rather than left implicit
# because the client in `live.js` backs off past it on repeated failure and the
# two need to be talking about the same number.
RETRY_MS = 3000

HEADERS = {
    "Cache-Control": "no-store, no-transform",
    "Connection": "keep-alive",
    # Nginx and IIS buffer a response body by default, which for a stream means
    # holding every frame until the connection closes — the feature silently
    # does nothing. Neither is in front of this server today; the header costs a
    # line and saves a very confusing afternoon if one ever is.
    "X-Accel-Buffering": "no",
}


@router.get("/events")
async def stream(request: Request, since: str = "",
                 last_event_id: str = Header(default=""),
                 user: dict = Depends(current_user)) -> StreamingResponse:
    """Open a stream. It stays open until the client goes away.

    The position comes from either of two places, and both are needed.
    `Last-Event-ID` is the header the browser sets on its *own* automatic
    retries, which is the common case. `since` is the query parameter the client
    sets when it reopens the stream deliberately — returning to a tab that was
    hidden — because there is no way to set that header by hand, and without it
    every wake-up would be a full resync of every screen.
    """
    if events.hub.subscriber_count >= events.MAX_SUBSCRIBERS:
        # A dozen counter machines is normal; two hundred is a client
        # reconnecting in a loop, and refusing it is kinder than accumulating it.
        raise HTTPException(status_code=503, detail="Too many open streams.")

    try:
        marker = last_event_id or since
        after = int(marker) if marker else None
    except ValueError:
        after = None

    subscriber = events.hub.subscribe(user["id"], user["permissions"])
    missed, recovered = events.hub.replay(subscriber, after)

    async def frames() -> AsyncIterator[str]:
        try:
            yield f"retry: {RETRY_MS}\n\n"

            # Mirrors the gateway's `connection:ack`. `recovered` is the client's
            # cue: true means the gap was filled from the ring and whatever is on
            # screen is now current, false means it was away too long — or has
            # just arrived — and should fetch what it is showing.
            ack = {"recovered": recovered, "replayed": len(missed)}
            yield events.Event(id=0, name="connection:ack", data=ack).frame()

            for event in missed:
                yield event.frame()

            while True:
                try:
                    event = await asyncio.wait_for(
                        subscriber.queue.get(), timeout=events.KEEPALIVE_SECONDS)
                except asyncio.TimeoutError:
                    # A comment frame. It carries no event, so no handler runs on
                    # the client; it exists only to keep the connection warm
                    # through whatever sits between the counter and the server.
                    yield ": keep-alive\n\n"
                    continue

                if event is None:
                    if subscriber.desynced:
                        subscriber.desynced = False
                        yield events.Event(
                            id=0, name="sync:required",
                            data={"reason": "backlog"}).frame()
                        continue
                    return                    # shutdown
                yield event.frame()
        finally:
            # Reached on client disconnect too: Starlette cancels the generator
            # when the connection drops, and a subscriber left in the set would
            # be delivered to forever.
            events.hub.unsubscribe(subscriber)

    return StreamingResponse(frames(), media_type="text/event-stream",
                             headers=HEADERS)
