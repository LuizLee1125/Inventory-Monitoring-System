"""Handing out the desktop edition.

The desktop app is one more way into the same system, not a replacement for the
browser - so the browser is where you get it. A clerk who wants an icon on their
desktop signs in as they always do, opens Settings, and presses Download; the
installer comes off the server they are already talking to.

That is the only distribution channel this office needs. `NTC-TMS-Tauri` fetches
its releases from cloud storage because its users are spread across the country;
these users are all on one local network, with the server in the corner of the
room, and a release channel that needs the internet would be a release channel
that stops working on the days the line is down.

Nothing here is privileged: every role reaches Settings, and installing the
client application grants nothing that signing in does not. The permission
checks that matter are on the endpoints the app then calls.
"""

from __future__ import annotations

import re
from datetime import datetime, timezone
from pathlib import Path

from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import FileResponse

from .. import config
from ..deps import current_user

router = APIRouter(prefix="/desktop", tags=["desktop"])

# What an installer looks like on each platform. `.exe` first: this office is
# Windows, and an NSIS setup is what its staff expect a program to arrive as.
INSTALLER_SUFFIXES = (".exe", ".msi", ".dmg", ".AppImage", ".deb")

MEDIA_TYPES = {
    ".exe": "application/vnd.microsoft.portable-executable",
    ".msi": "application/x-msi",
    ".dmg": "application/x-apple-diskimage",
    ".deb": "application/vnd.debian.binary-package",
}

# Tauri names its bundles `Marina IMS_1.0.0_x64-setup.exe`. The version is the
# part between the underscores, and it is the only thing in the name worth
# showing somebody.
VERSION_IN_NAME = re.compile(r"[_-](\d+\.\d+\.\d+(?:\.\d+)?)[_-]")


def _installer() -> Path | None:
    """The installer this server hands out, or None if there is not one yet.

    Two orderings, and the order between them matters:

    * The published folder wins over the build output even when the build is
      newer. Publishing is the deliberate act; a half-tested build sitting in
      `target/` should not quietly become what the office installs.
    * Within a folder, **format beats date**. A Tauri build writes an NSIS
      `.exe` and an MSI within a second of each other, so picking the newest
      file would hand out whichever finished last - which is the MSI, and the
      wrong answer: `.exe` is what staff here expect a program to arrive as,
      and it installs without an administrator. Date only breaks ties between
      files of the same kind.
    """
    for folder in (config.DESKTOP_DIR, *config.DESKTOP_BUILD_DIRS):
        if not folder.is_dir():
            continue
        found = [
            path for path in folder.iterdir()
            if path.is_file() and path.suffix in INSTALLER_SUFFIXES
        ]
        if found:
            return min(found, key=lambda p: (INSTALLER_SUFFIXES.index(p.suffix),
                                             -p.stat().st_mtime))
    return None


def _describe(path: Path) -> dict:
    stat = path.stat()
    match = VERSION_IN_NAME.search(path.name)
    return {
        "available": True,
        "filename": path.name,
        "version": match.group(1) if match else None,
        "size": stat.st_size,
        "built": datetime.fromtimestamp(stat.st_mtime, timezone.utc).isoformat(),
        "kind": path.suffix.lstrip("."),
    }


@router.get("")
def desktop_release(_user: dict = Depends(current_user)) -> dict:
    """What there is to download, if anything.

    Answers rather than 404s when no installer has been published, because the
    settings screen has something useful to say either way: "here is the app" or
    "nobody has built one for this server yet". A 404 would leave it guessing
    between that and a server too old to have this endpoint at all.
    """
    path = _installer()
    if path is None:
        return {"available": False}
    return _describe(path)


# GET *and* HEAD, for the same reason the backup download registers both: the
# screen checks the headers before pointing the browser at the file, so a
# missing installer is reported in the page rather than failing silently in the
# downloads tray.
@router.api_route("/download", methods=["GET", "HEAD"])
def download_installer(_user: dict = Depends(current_user)) -> FileResponse:
    path = _installer()
    if path is None:
        raise HTTPException(404, "No desktop installer has been published on this server.")
    return FileResponse(
        path,
        media_type=MEDIA_TYPES.get(path.suffix, "application/octet-stream"),
        filename=path.name,
    )
