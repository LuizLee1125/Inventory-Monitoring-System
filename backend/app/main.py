"""FastAPI application entry point."""

from __future__ import annotations

import asyncio
import socket
from contextlib import asynccontextmanager, suppress

from fastapi import FastAPI, Request
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles

from . import __version__, config, db, events, security
from . import notifications as alerts
from .routers import (
    admin,
    archive,
    auth,
    collections,
    customers,
    desktop,
    invoices,
    maintenance,
    notifications,
    purchases,
    reports,
    returns,
    stock,
    suppliers,
)

# Aliased and on its own line because `app.events` — the bus — is already
# imported above under its own name, and the router that exposes it cannot share
# that name in this module.
from .routers import events as events_router


def lan_addresses() -> list[str]:
    """Best-effort list of addresses other PCs on the network can reach."""
    found: list[str] = []
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.connect(("8.8.8.8", 80))          # no traffic is sent
        found.append(sock.getsockname()[0])
        sock.close()
    except OSError:
        pass
    try:
        for info in socket.getaddrinfo(socket.gethostname(), None, socket.AF_INET):
            address = info[4][0]
            if address not in found and not address.startswith("127."):
                found.append(address)
    except OSError:
        pass
    return found


# How often the housekeeping tick wakes up. Shorter than the backup interval
# itself, so a server started mid-afternoon does not wait a full day to notice
# that yesterday's backup never happened.
BACKUP_TICK_SECONDS = 900


async def housekeeping() -> None:
    """The backup schedule and the notification sweep, on one timer.

    A timer rather than a fixed hour: the office PC is not on overnight, so
    "every night at 2am" would mean never. This asks the same question every
    fifteen minutes and acts the first time the answer is yes, which on a
    machine switched on at nine gives a backup shortly after nine.

    Both jobs go to a worker thread. Copying 1.2 GB takes seconds and sweeping
    the stock table takes rather less, but neither belongs on the event loop —
    doing them there would stop the office working for exactly as long as they
    run. Each is suppressed separately, so a sweep that throws cannot stop the
    backup that follows it, or the other way round.
    """
    while True:
        await asyncio.sleep(BACKUP_TICK_SECONDS)
        with suppress(Exception):
            await asyncio.to_thread(maintenance.run_scheduled_backup)
        with suppress(Exception):
            await asyncio.to_thread(alerts.sweep)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Before anything can publish. Every router runs on FastAPI's threadpool, so
    # the bus needs a handle on the loop to hand deliveries back to it; until
    # this happens `events.publish()` is a no-op, which is what lets `migrate.py`
    # and `dump_db.py` import the routers without a server.
    events.hub.bind(asyncio.get_running_loop())

    added = db.init_db()
    removed = security.purge_expired_sessions()
    print(f"\n  {config.COMPANY_NAME} - {config.APP_NAME} {__version__}")
    print(f"  Database : {config.DB_PATH}")
    if added:
        print(f"  Schema   : added {', '.join(added)}")
    if removed:
        print(f"  Sessions : purged {removed} expired")
    print(f"  Local    : http://localhost:{config.PORT}")
    for address in lan_addresses():
        print(f"  Network  : http://{address}:{config.PORT}")

    # Before anything else touches the folder: move in anything left in the old
    # location, and clear away backups the power cut off halfway through.
    tidied = maintenance.tidy_backup_dir()
    if tidied["moved"]:
        print(f"  Backups  : moved {len(tidied['moved'])} from "
              f"{config.LEGACY_BACKUP_DIR}")
    if tidied["swept"]:
        print(f"  Backups  : discarded {len(tidied['swept'])} unfinished "
              f"({', '.join(tidied['swept'])})")

    if config.BACKUP_EVERY_HOURS:
        print(f"  Backups  : every {config.BACKUP_EVERY_HOURS}h, "
              f"kept {config.BACKUP_KEEP_DAYS} days, in {config.BACKUP_DIR}")
        # The first one is taken here rather than after a tick, so a machine
        # that is switched on for an hour a day still gets its backup.
        await asyncio.to_thread(maintenance.run_scheduled_backup)
    else:
        print("  Backups  : automatic backups are off (IMS_BACKUP_HOURS=0)")

    # Swept at startup as well as on the tick, for the same reason the backup
    # is: a machine switched on for an hour a day would otherwise never reach
    # the first tick, and the bell would be empty on exactly the days somebody
    # most needs it.
    with suppress(Exception):
        counts = await asyncio.to_thread(alerts.sweep)
        if counts["opened"] or counts["closed"]:
            print(f"  Alerts   : opened {counts['opened']}, "
                  f"closed {counts['closed']}")

    # One task for both jobs. It runs whether or not automatic backups are on —
    # turning those off is a statement about backups, not about whether the
    # office wants to be told its stock has run out.
    schedule = asyncio.create_task(housekeeping())

    print(flush=True)
    try:
        yield
    finally:
        if schedule:
            schedule.cancel()
            with suppress(asyncio.CancelledError):
                await schedule
        # Wake every open stream so its generator can finish, rather than
        # leaving uvicorn waiting on connections that are never told to stop.
        events.hub.close()


def create_app() -> FastAPI:
    app = FastAPI(
        title=f"{config.COMPANY_NAME} - {config.APP_NAME}",
        version=__version__,
        docs_url="/api/docs",
        openapi_url="/api/openapi.json",
        lifespan=lifespan,
    )

    for router in (auth, stock, customers, suppliers, invoices, purchases,
                   returns, collections, reports, admin, maintenance, archive,
                   notifications, desktop, events_router):
        app.include_router(router.router, prefix="/api")

    @app.middleware("http")
    async def no_stale_assets(request: Request, call_next):
        """Force browsers to revalidate. Workstations leave this app open for
        days; without it, an update to the server would not reach them."""
        response = await call_next(request)
        if not request.url.path.startswith("/api/"):
            response.headers["Cache-Control"] = "no-cache, must-revalidate"
        return response

    @app.get("/api/meta")
    def meta() -> dict:
        return {
            "company": config.COMPANY_NAME,
            "app": config.APP_NAME,
            "version": __version__,
            "roles": {name: {"label": role["label"], "legacy": role["legacy"]}
                      for name, role in security.ROLES.items()},
        }

    @app.exception_handler(404)
    async def spa_fallback(request: Request, exc):
        """Unknown /api paths stay JSON; everything else serves the app shell so
        deep links like /#/invoices work on refresh."""
        if request.url.path.startswith("/api/"):
            return JSONResponse({"detail": "Not found"}, status_code=404)
        return FileResponse(config.STATIC_DIR / "index.html")

    # Anything under /api that no router claimed is an API error, not a file.
    # Without this the static mount below catches it and answers 405 for a POST,
    # because StaticFiles only serves GET and HEAD.
    @app.api_route("/api/{rest:path}", methods=["GET", "POST", "PUT", "DELETE", "PATCH"],
                   include_in_schema=False)
    def unknown_api(rest: str) -> JSONResponse:
        return JSONResponse({"detail": f"No such endpoint: /api/{rest}"}, status_code=404)

    app.mount("/", StaticFiles(directory=config.STATIC_DIR, html=True), name="static")
    return app


app = create_app()
