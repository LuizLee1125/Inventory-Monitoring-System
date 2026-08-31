"""The live channel: one in-process bus, fanned out over Server-Sent Events.

Every screen in this application used to learn about a change by asking again —
`notify.js` polled a count every sixty seconds, and everything else only ever
knew what was true at the moment it was drawn. That is the wrong shape for an
office where two clerks invoice the same item at the same counter: the number on
the second screen was correct when it was fetched and wrong by the time it was
used.

So the server tells them. This module is the telling.

Two rules decide everything else here, and both exist because the server is a PC
in the corner of the office rather than a datacentre:

**Nothing polls.** An event is published by the code that already performed the
write, inside the request that made it. There is no watcher thread, no
`WHERE updated_at > ?` loop, nothing tailing the database. An idle system runs no
timer and costs nothing.

**A publish is a fan-out to queues, not a query.** `publish()` appends to a ring
and to whichever subscriber queues want it. It does not touch SQLite, so it is
safe to call while holding the write lock — though the callers deliberately do
not, see `Batch` below.

The reference implementation is `NTC-TMS-Tauri`'s `RealtimeGateway`, a NestJS
Socket.IO gateway. What is copied is its *shape* — server pushes, the client
never sends, events are named `entity:action`, delivery is filtered per
recipient, and a reconnect inside a window replays what was missed. What is not
copied is Socket.IO itself: this application ships no JavaScript dependencies at
all, and `EventSource` is already in the browser. SSE also reconnects and
resumes by itself, which is the same guarantee `connectionStateRecovery` buys
there, obtained for free.
"""

from __future__ import annotations

import asyncio
import json
import threading
from collections import deque
from collections.abc import Iterable
from contextlib import suppress
from dataclasses import dataclass, field
from typing import Any

# How many events are held for replay, and for how long. A client that
# reconnects inside this window is brought up to date from the ring and never
# knows it was away; one that was gone longer is told to refetch instead.
#
# Two minutes matches `RECOVERY_WINDOW_MS` in NTC-TMS-Tauri's gateway. The count
# is the real cap: 256 events is several minutes of a busy afternoon in an
# office this size, and the memory is a few tens of kilobytes.
RING_SIZE = 256
RING_SECONDS = 120

# Per-subscriber queue depth. Past this the client is not keeping up — a laptop
# that suspended mid-afternoon, a tab the scheduler has stopped running. Its
# queue is emptied and it is sent one `sync:required` instead, because a hundred
# stale events are worth less than one instruction to start again, and an
# unbounded queue behind a stuck reader is how a long-running server dies.
QUEUE_DEPTH = 200

# A ceiling on open streams. An office has a dozen counter machines; anything
# past this is a client reconnecting in a loop, and refusing it is kinder than
# letting it accumulate.
MAX_SUBSCRIBERS = 200

# How long a stream waits for an event before writing a comment frame. An idle
# HTTP response is dropped by WebView2 and by anything sitting between the
# counter and the server, and the drop is silent — the client believes it is
# still connected and simply stops being told anything.
#
# This is the only recurring timer in the feature: one `asyncio.sleep` per open
# connection, which is not measurable.
KEEPALIVE_SECONDS = 25


@dataclass(frozen=True)
class Event:
    """One thing that happened, and who is allowed to hear about it.

    `permission` is the filter, and it is a permission rather than a role for
    exactly the reason `notifications.py` gives: there is then no second list of
    roles to keep in step with `security.ROLES`, and the answer follows the same
    matrix every endpoint already uses.

    `user_id` narrows it further, to one person. Only the events that are
    genuinely about somebody — `notification:read`, so their other tab agrees —
    set it. This is the equivalent of the gateway's per-user rooms; the
    difference is that here it is the exception rather than the rule, because
    most of what happens in an inventory system is everybody's business.
    """

    id: int
    name: str
    data: Any
    permission: str = ""
    user_id: int | None = None
    at: float = 0.0

    def wanted_by(self, subscriber: Subscriber) -> bool:
        if self.user_id is not None and self.user_id != subscriber.user_id:
            return False
        return not self.permission or self.permission in subscriber.permissions

    def frame(self) -> str:
        """One SSE frame. `id:` is what comes back as `Last-Event-ID`."""
        payload = json.dumps(self.data, separators=(",", ":"), default=str)
        return f"id: {self.id}\nevent: {self.name}\ndata: {payload}\n\n"


# `eq=False` keeps the default identity `__eq__`/`__hash__`, which is what a
# subscriber wants: it is one open connection, and two clients signed in as the
# same user with the same permissions are two subscribers, not one. A generated
# `__eq__` would also have set `__hash__ = None` and made this unusable in the
# hub's set.
@dataclass(eq=False)
class Subscriber:
    user_id: int
    permissions: frozenset[str]
    queue: asyncio.Queue = field(default_factory=lambda: asyncio.Queue(QUEUE_DEPTH))
    #: Set when the queue overflowed. The stream sends `sync:required` and the
    #: client refetches whatever it is showing.
    desynced: bool = False


class Hub:
    """The bus. One instance, module-level, for the life of the process."""

    def __init__(self) -> None:
        self._loop: asyncio.AbstractEventLoop | None = None
        self._subscribers: set[Subscriber] = set()
        self._ring: deque[Event] = deque(maxlen=RING_SIZE)
        self._next_id = 1
        # Publishers arrive on FastAPI's threadpool — the routers are `def`, not
        # `async def`, so every one of them runs on a worker thread. The ring and
        # the counter are therefore guarded, and delivery is handed to the loop.
        self._lock = threading.Lock()

    # -- lifecycle ---------------------------------------------------------- #

    def bind(self, loop: asyncio.AbstractEventLoop) -> None:
        """Called once from `lifespan`. Until this happens, publishing is a
        no-op rather than an error: `migrate.py` and `dump_db.py` import the
        routers without ever starting a server, and neither should fail because
        nobody is listening."""
        self._loop = loop

    def close(self) -> None:
        """Wake every stream so it can finish, at shutdown."""
        for subscriber in list(self._subscribers):
            self._offer(subscriber, None)
        self._subscribers.clear()

    @property
    def subscriber_count(self) -> int:
        return len(self._subscribers)

    # -- publishing --------------------------------------------------------- #

    def publish(self, name: str, data: Any = None, *, permission: str = "",
                user_id: int | None = None) -> None:
        """Announce one event. Never raises, never blocks, never touches SQLite.

        Safe to call from any thread and from the loop itself.
        """
        loop = self._loop
        if loop is None or loop.is_closed():
            return

        with self._lock:
            event = Event(id=self._next_id, name=name, data=data,
                          permission=permission, user_id=user_id,
                          at=loop.time())
            self._next_id += 1
            self._ring.append(event)
            # Scheduled inside the lock so two threads publishing at once cannot
            # deliver 6 before 5. `call_soon_threadsafe` is FIFO, and it is
            # documented to work from the loop's own thread as well.
            # RuntimeError here is the loop shutting down under us, which is a
            # normal way for the process to end and not something to report.
            with suppress(RuntimeError):
                loop.call_soon_threadsafe(self._deliver, event)

    def _deliver(self, event: Event) -> None:
        for subscriber in list(self._subscribers):
            if event.wanted_by(subscriber):
                self._offer(subscriber, event)

    def _offer(self, subscriber: Subscriber, event: Event | None) -> None:
        try:
            subscriber.queue.put_nowait(event)
        except asyncio.QueueFull:
            # Drain and mark. One instruction to resync beats two hundred stale
            # rows, and it is the only outcome that bounds memory.
            while not subscriber.queue.empty():
                subscriber.queue.get_nowait()
            subscriber.desynced = True
            subscriber.queue.put_nowait(None)

    # -- subscribing -------------------------------------------------------- #

    def subscribe(self, user_id: int, permissions: Iterable[str]) -> Subscriber:
        subscriber = Subscriber(user_id=user_id,
                                permissions=frozenset(permissions))
        self._subscribers.add(subscriber)
        return subscriber

    def unsubscribe(self, subscriber: Subscriber) -> None:
        self._subscribers.discard(subscriber)

    def replay(self, subscriber: Subscriber, after: int | None) -> tuple[list[Event], bool]:
        """What a reconnecting client missed, and whether it could be answered.

        Returns `(events, recovered)`. `recovered` is False when the client asked
        from further back than the ring reaches — it has to refetch — and also on
        a first connection, which has missed nothing and needs no replay.
        """
        if after is None or not self._ring:
            return [], False

        loop = self._loop
        cutoff = (loop.time() - RING_SECONDS) if loop else 0.0
        with self._lock:
            held = [e for e in self._ring if e.at >= cutoff]
            oldest = self._ring[0].id

        # The ring has already dropped what they are asking for. Say so rather
        # than sending a partial history that looks complete.
        if after < oldest - 1:
            return [], False
        return [e for e in held if e.id > after and e.wanted_by(subscriber)], True


hub = Hub()


# --------------------------------------------------------------------------- #
# coalescing
# --------------------------------------------------------------------------- #

class Batch:
    """Everything one request wants to announce, published once at the end.

    Two things this is for, and the second one is the important one.

    **Forty lines are one event.** An invoice touching forty stock codes must
    send one `stock:changed` carrying forty codes, not forty events carrying one
    each — otherwise every open stock screen in the office does forty debounced
    refetches for a single save.

    **Nothing is announced before it is true.** `flush()` is called *after* the
    `with db.transaction()` block has committed. Publishing inside it would race
    the commit: a client told about an invoice can ask for it, and would be
    answered by a reader that cannot see it yet, or — worse — be told about a
    document that then rolled back.
    """

    def __init__(self) -> None:
        self._events: list[tuple[str, Any, str, int | None]] = []
        self._stock: set[str] = set()

    def add(self, name: str, data: Any = None, *, permission: str = "",
            user_id: int | None = None) -> None:
        self._events.append((name, data, permission, user_id))

    def stock_changed(self, *codes: str) -> None:
        """Note that these codes moved. Merged into one event on flush."""
        self._stock.update(c for c in codes if c)

    def flush(self) -> None:
        for name, data, permission, user_id in self._events:
            hub.publish(name, data, permission=permission, user_id=user_id)
        if self._stock:
            hub.publish("stock:changed", {"codes": sorted(self._stock)},
                        permission="stock:read")
        self._events.clear()
        self._stock.clear()


def batch() -> Batch:
    return Batch()


def publish(name: str, data: Any = None, *, permission: str = "",
            user_id: int | None = None) -> None:
    """Announce a single event with no batching. For the callers that have
    exactly one thing to say."""
    hub.publish(name, data, permission=permission, user_id=user_id)
