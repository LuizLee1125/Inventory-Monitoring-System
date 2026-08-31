"""FastAPI application entry point."""

from __future__ import annotations

import asyncio
import socket
from contextlib import asynccontextmanager, suppress

from fastapi import FastAPI, Request
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles

from . import __version__, config, db, security
from .routers import (
    admin,
    archive,
    auth,
    collections,
    customers,
    invoices,
    maintenance,
    purchases,
    reports,
    returns,
    stock,
    suppliers,
)


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


# How often the backup schedule wakes up to see whether one is due. Shorter than
# the interval itself, so a server started mid-afternoon does not wait a full day
# to notice that yesterday's backup never happened.
BACKUP_TICK_SECONDS = 900


async def backup_schedule() -> None:
    """Take a backup whenever the newest one is older than the interval.

    A timer rather than a fixed hour: the office PC is not on overnight, so
    "every night at 2am" would mean never. This asks the same question every
    fifteen minutes and acts the first time the answer is yes, which on a
    machine switched on at nine gives a backup shortly after nine.
    """
    while True:
        await asyncio.sleep(BACKUP_TICK_SECONDS)
        # On a worker thread: copying 1.2 GB takes seconds, and doing it on the
        # event loop would stop the office working for exactly that long.
        with suppress(Exception):
            await asyncio.to_thread(maintenance.run_scheduled_backup)


@asynccontextmanager
async def lifespan(app: FastAPI):
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

    schedule = None
    if config.BACKUP_EVERY_HOURS:
        print(f"  Backups  : every {config.BACKUP_EVERY_HOURS}h, "
              f"kept {config.BACKUP_KEEP_DAYS} days, in {config.BACKUP_DIR}")
        # The first one is taken here rather than after a tick, so a machine
        # that is switched on for an hour a day still gets its backup.
        await asyncio.to_thread(maintenance.run_scheduled_backup)
        schedule = asyncio.create_task(backup_schedule())
    else:
        print("  Backups  : automatic backups are off (IMS_BACKUP_HOURS=0)")

    print(flush=True)
    try:
        yield
    finally:
        if schedule:
            schedule.cancel()
            with suppress(asyncio.CancelledError):
                await schedule


def create_app() -> FastAPI:
    app = FastAPI(
        title=f"{config.COMPANY_NAME} - {config.APP_NAME}",
        version=__version__,
        docs_url="/api/docs",
        openapi_url="/api/openapi.json",
        lifespan=lifespan,
    )

    for router in (auth, stock, customers, suppliers, invoices, purchases,
                   returns, collections, reports, admin, maintenance, archive):
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
