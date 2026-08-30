"""Shared FastAPI dependencies and small helpers used by every router."""

from __future__ import annotations

import sqlite3
from collections.abc import Callable
from typing import Any

from fastapi import Depends, HTTPException, Request, status

from . import config, security


class Conflict(HTTPException):
    """Raised when another user changed the record first (optimistic locking).

    The frontend turns this into the same message the DOS system used to show:
    the record has been changed by another user.
    """

    def __init__(self, entity: str, detail: str | None = None):
        super().__init__(
            status_code=status.HTTP_409_CONFLICT,
            detail=detail or (
                f"This {entity} was changed by another user while you were editing it. "
                f"Reload to see the current version, then apply your change again."
            ),
        )


def current_user(request: Request) -> dict:
    token = request.cookies.get(config.SESSION_COOKIE, "")
    user = security.resolve_session(token)
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED,
                            detail="Not signed in")
    return user


def require(permission: str) -> Callable[[dict], dict]:
    """Dependency factory: `Depends(require("invoice:write"))`."""

    def dependency(user: dict = Depends(current_user)) -> dict:
        if permission not in user["permissions"]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Your role ({user['role']}) cannot perform this action.",
            )
        return user

    return dependency


def check_version(row: dict | sqlite3.Row, expected: int | None, entity: str) -> None:
    """Optimistic locking gate. `expected` of None means the caller did not
    supply a version, which is only allowed for inserts."""
    if expected is None:
        raise HTTPException(status_code=400,
                            detail=f"Missing version for {entity}; reload the record.")
    if int(row["version"]) != int(expected):
        raise Conflict(entity)


def paging(page: int = 1, page_size: int = config.DEFAULT_PAGE_SIZE) -> tuple[int, int]:
    page = max(1, int(page))
    page_size = max(1, min(int(page_size), config.MAX_PAGE_SIZE))
    return page, page_size


def paged_response(rows: list[dict], total: int, page: int, page_size: int) -> dict:
    return {
        "items": rows,
        "total": total,
        "page": page,
        "page_size": page_size,
        "pages": max(1, -(-total // page_size)),
    }


def clean(value: Any, upper: bool = False) -> str:
    text = ("" if value is None else str(value)).strip()
    return text.upper() if upper else text


def money(value: Any) -> float:
    try:
        return round(float(value or 0), 2)
    except (TypeError, ValueError):
        return 0.0


def require_fields(payload: dict, *names: str) -> None:
    missing = [n for n in names if not clean(payload.get(n))]
    if missing:
        raise HTTPException(status_code=400,
                            detail=f"Required: {', '.join(missing)}")
