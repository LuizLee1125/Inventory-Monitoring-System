"""Notifications — the bell in the top bar and the screen behind it.

Everything here is behind `current_user` rather than `require(...)`. Every
signed-in account has notifications; *which* ones is decided by the permission
carried on each row and filtered in `notifications.list_for()`, not by a guard
on the route. Putting a single permission on the endpoint would have meant
choosing one that every role holds, which is the same as no filter at all.
"""

from __future__ import annotations

from fastapi import APIRouter, Depends, Query

from .. import events, notifications
from ..deps import current_user

router = APIRouter(prefix="/notifications", tags=["notifications"])


@router.get("")
def list_notifications(
    unread_only: bool = False,
    open_only: bool = True,
    limit: int = Query(50, le=200),
    offset: int = 0,
    user: dict = Depends(current_user),
) -> dict:
    """The panel asks for the first few open ones; the screen pages through.

    `unread` comes back on every call so the badge can be corrected from the
    same response that filled the list, rather than needing a second request.
    """
    return {
        "items": notifications.list_for(user, unread_only=unread_only,
                                        open_only=open_only,
                                        limit=limit, offset=offset),
        "total": notifications.count_for(user, unread_only=unread_only,
                                         open_only=open_only),
        "unread": notifications.unread_count(user),
    }


@router.get("/unread-count")
def unread_count(user: dict = Depends(current_user)) -> dict:
    """Polled on a timer, so it stays one COUNT and never builds the list."""
    return {"unread": notifications.unread_count(user)}


def _read_response(user: dict, marked: int) -> dict:
    """Reply, and tell this person's *other* screens.

    Read state is the one thing on the bell that belongs to a person rather than
    to the business, so the event is addressed by `user_id` and carries no
    permission — the counter PC and the office PC somebody is signed in on at
    once should not disagree about their own badge. This is the equivalent of
    the reference gateway's per-user rooms; here it is the exception, because
    almost everything else that happens in an inventory system is everybody's.
    """
    unread = notifications.unread_count(user)
    events.publish("notification:read", {"unread": unread}, user_id=user["id"])
    return {"marked": marked, "unread": unread}


@router.post("/read")
def mark_read(payload: dict, user: dict = Depends(current_user)) -> dict:
    return _read_response(user, notifications.mark_read(user, payload.get("ids") or []))


@router.post("/read-all")
def mark_all_read(user: dict = Depends(current_user)) -> dict:
    return _read_response(user, notifications.mark_all_read(user))
