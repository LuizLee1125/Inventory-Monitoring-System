"""FastAPI application entry point."""

from __future__ import annotations

import socket
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles

from . import __version__, config, db, security
from .routers import (
    admin,
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


@asynccontextmanager
async def lifespan(app: FastAPI):
    db.init_db()
    removed = security.purge_expired_sessions()
    print(f"\n  {config.COMPANY_NAME} - {config.APP_NAME} {__version__}")
    print(f"  Database : {config.DB_PATH}")
    if removed:
        print(f"  Sessions : purged {removed} expired")
    print(f"  Local    : http://localhost:{config.PORT}")
    for address in lan_addresses():
        print(f"  Network  : http://{address}:{config.PORT}")
    print(flush=True)
    yield


def create_app() -> FastAPI:
    app = FastAPI(
        title=f"{config.COMPANY_NAME} - {config.APP_NAME}",
        version=__version__,
        docs_url="/api/docs",
        openapi_url="/api/openapi.json",
        lifespan=lifespan,
    )

    for router in (auth, stock, customers, suppliers, invoices, purchases,
                   returns, collections, reports, admin, maintenance):
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

    app.mount("/", StaticFiles(directory=config.STATIC_DIR, html=True), name="static")
    return app


app = create_app()
