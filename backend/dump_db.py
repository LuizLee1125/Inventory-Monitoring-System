#!/usr/bin/env python3
"""
Write the SQLite databases out as plain text, one file per table.

    python backend/dump_db.py                      # the live database
    python backend/dump_db.py --backups latest     # ... and the newest backup
    python backend/dump_db.py --backups all        # ... and every backup
    python backend/dump_db.py --limit 0            # every row, however many
    python backend/dump_db.py --tables stock,customers
    python backend/dump_db.py --source some.sqlite # any other database file

Nothing in `database/` can be opened in an editor. `ims.sqlite` is binary, the
backups in `backups/` are the same format, and `-wal` / `-shm` are internal
SQLite structures that are not text either. The data is all there; it just has
no readable form. This gives it one:

    database/plaintext/
      live/                       the working database
        000_schema.sql            every CREATE statement, as stored
        _journal.txt              what -wal and -shm currently hold
        _manifest.txt             table, rows written, rows held, files, size
        divisions.sql             small tables: one file
        invoices/                 big ones: a folder of numbered chunks
          0001-0200.sql
          0201-0400.sql
      backups/
        ims-20260830-230617/      one folder per backup, same layout
          ...

Files are written to be *read*: 200 rows each, the column list stated once per
statement instead of once per row, a numbered column legend at the top of every
file, and every row wrapped so no line runs off the side of the editor.

The files are valid SQL and could be replayed into an empty database, but that
is not the point of them - `POST /api/maintenance/backup` takes real backups,
and it copies the database rather than re-typing it. These exist to be *read*.

Two safety rules, because the output is a plain file that invites being opened,
copied and pasted:

  * `sessions` is skipped. Its rows are live credentials.
  * `users.password_hash` is written as '<redacted>'. Pass --include-secrets to
    get either of them, and then treat the dump like the database itself.

Databases are opened read-only, so this is safe to run while the server is up.
"""

from __future__ import annotations

import argparse
import shutil
import sqlite3
import struct
import sys
import tempfile
import zipfile
from datetime import datetime
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from app import config

# Rows per table unless --limit says otherwise. Enough to see the shape of the
# data and the awkward records at the edges; small enough that the file opens
# instantly. stock_moves alone has millions.
DEFAULT_LIMIT = 2000

# Rows per file. A table with more than this gets a folder of numbered chunks
# instead of one long file: 2,000 invoices in one document is a 1.1 MB file
# nobody scrolls through, and the editor is slow with it besides.
ROWS_PER_FILE = 200

# Rows per INSERT statement. The column list is written once per statement
# rather than once per row - repeating 30 column names on every line is most of
# what made the first version unreadable. SQLite's own limit is 500.
ROWS_PER_STATEMENT = 50

# No line is allowed past this if wrapping can avoid it. A row is wrapped across
# as many lines as it needs, so nothing runs off the side of the editor.
LINE_WIDTH = 88
INDENT = "       "                      # 7 spaces, aligns under "INSERT "

SECRET_TABLES = {"sessions"}
SECRET_COLUMNS = {("users", "password_hash")}
REDACTED = "<redacted>"

# WAL header, big-endian: magic, format, page size, checkpoint sequence,
# salt-1, salt-2, checksum-1, checksum-2.  https://sqlite.org/fileformat2.html
WAL_HEADER = struct.Struct(">IIIIIIII")
WAL_FRAME_HEADER = struct.Struct(">IIIIII")
WAL_MAGIC = {0x377F0682: "little-endian checksums",
             0x377F0683: "big-endian checksums"}


# --------------------------------------------------------------------------- #
# reading
# --------------------------------------------------------------------------- #

def literal(value: object) -> str:
    """Render one value as a SQL literal."""
    if value is None:
        return "NULL"
    if isinstance(value, bytes):
        return "X'" + value.hex() + "'"
    if isinstance(value, (int, float)):
        return repr(value)
    return "'" + str(value).replace("'", "''") + "'"


def journal_files(source: Path) -> tuple[Path, Path]:
    return Path(f"{source}-wal"), Path(f"{source}-shm")


def open_readonly(path: Path) -> sqlite3.Connection:
    """Read-only connection, so a dump can never damage what it is reading.

    `mode=ro` is not enough on its own. Reading a WAL database still needs the
    `-shm` index, and SQLite creates one if it is missing - which is how the
    first version of this script left a `-wal` and a `-shm` beside a backup
    that had neither. When there is no outstanding log, `immutable=1` says the
    file cannot change under us, and SQLite then skips the WAL machinery
    altogether and touches nothing.

    A database that *does* have an un-checkpointed log has to be opened the
    normal way: recovering the log is itself a write, so a read-only connection
    cannot be the first to reach it. Anything we create there is cleaned up by
    the caller.
    """
    wal, _shm = journal_files(path)
    outstanding = wal.exists() and wal.stat().st_size > 0

    for uri in ([f"{path.as_uri()}?mode=ro"] if outstanding
                else [f"{path.as_uri()}?mode=ro&immutable=1"]):
        try:
            conn = sqlite3.connect(uri, uri=True)
            conn.execute("SELECT COUNT(*) FROM sqlite_master")
        except sqlite3.OperationalError:
            continue
        conn.row_factory = sqlite3.Row
        return conn

    conn = sqlite3.connect(path)
    conn.row_factory = sqlite3.Row
    return conn


def table_names(conn: sqlite3.Connection) -> list[str]:
    rows = conn.execute(
        "SELECT name FROM sqlite_master WHERE type = 'table' "
        "AND name NOT LIKE 'sqlite_%' ORDER BY name"
    ).fetchall()
    return [r["name"] for r in rows]


# --------------------------------------------------------------------------- #
# writing
# --------------------------------------------------------------------------- #

def write_schema(conn: sqlite3.Connection, source: Path, out_dir: Path) -> Path:
    """The CREATE statements as SQLite actually stored them.

    Not a copy of backend/app/schema/ - that is the input, this is the result.
    When the two disagree, the database in front of you is older than the code.
    """
    rows = conn.execute(
        "SELECT type, name, sql FROM sqlite_master WHERE sql IS NOT NULL "
        "AND name NOT LIKE 'sqlite_%' ORDER BY type DESC, name"
    ).fetchall()

    lines = [
        "-- The schema as stored in the database file.",
        "-- Generated by backend/dump_db.py; edits here change nothing.",
        f"-- Source: {source}",
        "",
    ]
    for row in rows:
        lines.append(f"{row['sql'].rstrip().rstrip(';')};")
        if row["type"] == "table":
            lines.append("")

    target = out_dir / "000_schema.sql"
    target.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return target


def wrap_tuple(items: list[str], indent: str, tail: str) -> list[str]:
    """Render `(a, b, c)` across as many lines as it takes to stay narrow.

    A single item longer than the width - a long remarks field - goes on a line
    of its own and overflows. Splitting it would corrupt the value.
    """
    opening = indent + "("
    lines: list[str] = []
    current = opening

    for index, item in enumerate(items):
        piece = item + ("," if index < len(items) - 1 else "")
        if current != opening and len(current) + 1 + len(piece) > LINE_WIDTH:
            lines.append(current)
            current = indent + " "
        separator = "" if current.endswith("(") or current == indent + " " else " "
        current += separator + piece

    lines.append(current + ")" + tail)
    return lines


def column_legend(columns: list[dict]) -> list[str]:
    """A numbered index of the columns, so a value can be placed by counting.

    Three to a line, because the point is to fit on one screen above the data.
    """
    name_width = max(len(c["name"]) for c in columns)
    type_width = max(len(c["type"] or "") for c in columns)
    entries = [
        f"{i:>3} {c['name']:<{name_width}}  {(c['type'] or ''):<{type_width}}"
        for i, c in enumerate(columns, start=1)
    ]
    per_line = max(1, (LINE_WIDTH - 3) // (len(entries[0]) + 3))
    return [
        "--  " + "   ".join(entries[i:i + per_line]).rstrip()
        for i in range(0, len(entries), per_line)
    ]


def file_header(name: str, columns: list[dict], redact: set[str],
                first: int, last: int, held: int) -> str:
    lines = [
        f"-- {name}  -  rows {first:,} to {last:,} of {held:,} in the database",
        "-- Generated by backend/dump_db.py.",
        "--",
        f"-- {len(columns)} column(s), in the order the values appear below:",
        *column_legend(columns),
    ]
    if redact:
        lines += ["--",
                  f"-- Redacted: {', '.join(sorted(redact))} "
                  f"(--include-secrets to write them)"]
    return "\n".join(lines) + "\n\n"


def write_rows(fh, name: str, columns: list[dict], rows: list[sqlite3.Row],
               redact: set[str], first_row_no: int) -> None:
    """Write rows as multi-row INSERTs: column list once, one tuple per row."""
    names = [c["name"] for c in columns]
    column_lines = wrap_tuple(names, INDENT, "")

    for start in range(0, len(rows), ROWS_PER_STATEMENT):
        batch = rows[start:start + ROWS_PER_STATEMENT]
        fh.write(f"INSERT INTO {name}\n")
        fh.write("\n".join(column_lines) + "\n")
        fh.write("VALUES\n")

        for offset, row in enumerate(batch):
            values = [
                literal(REDACTED if n in redact else row[n]) for n in names
            ]
            last = offset == len(batch) - 1
            fh.write(f"{INDENT}-- {first_row_no + start + offset:,}\n")
            fh.write("\n".join(wrap_tuple(values, INDENT, ";" if last else ",")))
            fh.write("\n")
        fh.write("\n")


def dump_table(conn: sqlite3.Connection, name: str, out_dir: Path,
               limit: int, rows_per_file: int, include_secrets: bool) -> dict:
    """Write one table. Returns a manifest entry.

    A table that fits in `rows_per_file` becomes `<table>.sql`. A bigger one
    becomes a folder of numbered chunks, `<table>/0001-0200.sql` and so on, so
    that opening a table never means opening a megabyte.
    """
    held = conn.execute(f"SELECT COUNT(*) FROM {name}").fetchone()[0]

    if name in SECRET_TABLES and not include_secrets:
        return {"table": name, "written": 0, "held": held, "bytes": 0,
                "files": 0, "note": "skipped, holds live credentials"}

    columns = [dict(r) for r in conn.execute(f"PRAGMA table_info({name})")]
    redact = set() if include_secrets else {
        c["name"] for c in columns if (name, c["name"]) in SECRET_COLUMNS}

    sql = f"SELECT * FROM {name}"
    if limit:
        sql += f" LIMIT {limit}"
    cursor = conn.execute(sql)

    to_write = min(held, limit) if limit else held
    chunked = to_write > rows_per_file
    number_width = len(f"{to_write:,}".replace(",", ""))
    folder = out_dir / name
    if chunked:
        folder.mkdir(parents=True, exist_ok=True)

    written = 0
    total_bytes = 0
    files = 0
    while True:
        rows = cursor.fetchmany(rows_per_file)
        if not rows:
            break
        first, last = written + 1, written + len(rows)
        target = (folder / f"{first:0{number_width}d}-{last:0{number_width}d}.sql"
                  if chunked else out_dir / f"{name}.sql")
        with target.open("w", encoding="utf-8", newline="\n") as fh:
            fh.write(file_header(name, columns, redact, first, last, held))
            write_rows(fh, name, columns, rows, redact, first)
        written = last
        total_bytes += target.stat().st_size
        files += 1

    if not written:
        target = out_dir / f"{name}.sql"
        target.write_text(
            f"-- {name}  -  empty, 0 rows in the database\n"
            "-- Generated by backend/dump_db.py.\n", encoding="utf-8")
        total_bytes, files = target.stat().st_size, 1

    return {"table": name, "written": written, "held": held,
            "bytes": total_bytes, "files": files, "note": ""}


def write_manifest(source: Path, entries: list[dict], out_dir: Path) -> Path:
    width = max([len(e["table"]) for e in entries] + [5])
    lines = [
        f"Database : {source}",
        f"Dumped to: {out_dir}",
        f"At       : {datetime.now().astimezone().isoformat(timespec='seconds')}",
        "",
        f"{'table'.ljust(width)}  {'written':>12}  {'in database':>12}  "
        f"{'files':>5}  {'size':>10}  where",
    ]
    for e in entries:
        size = f"{e['bytes'] / 1024:,.0f} KB" if e["bytes"] else "-"
        where = e["note"] or (f"{e['table']}/" if e["files"] > 1
                              else f"{e['table']}.sql")
        lines.append(
            f"{e['table'].ljust(width)}  {e['written']:>12,}  {e['held']:>12,}  "
            f"{e['files']:>5,}  {size:>10}  {where}".rstrip()
        )
    total = sum(e["bytes"] for e in entries)
    lines += ["", f"{len(entries)} table(s), {total / 1_048_576:,.1f} MB written"]

    target = out_dir / "_manifest.txt"
    target.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return target


# --------------------------------------------------------------------------- #
# the -wal and -shm
# --------------------------------------------------------------------------- #

def describe_wal(path: Path) -> list[str]:
    """Read the write-ahead log's header and count its frames.

    There is no text form of a `-wal`: it holds raw 4 KB database pages, not
    rows. What is worth knowing about it is how much committed work is sitting
    in the log that has not yet been folded back into the database file, and
    that much the header and frame count do tell us.
    """
    size = path.stat().st_size
    out = [f"{path.name}  ({size:,} bytes)"]

    if size < WAL_HEADER.size:
        out.append("  Empty. Everything is checkpointed into the database file.")
        return out

    with path.open("rb") as fh:
        (magic, fmt, page_size, checkpoint,
         salt1, salt2, _sum1, _sum2) = WAL_HEADER.unpack(fh.read(WAL_HEADER.size))

        if magic not in WAL_MAGIC:
            out.append(f"  Unrecognised magic 0x{magic:08X} - not a WAL file.")
            return out

        frame_size = WAL_FRAME_HEADER.size + page_size
        frames = (size - WAL_HEADER.size) // frame_size
        commits = 0
        last_db_pages = 0
        for _ in range(frames):
            header = fh.read(WAL_FRAME_HEADER.size)
            if len(header) < WAL_FRAME_HEADER.size:
                break
            _page_no, db_pages, f_salt1, _f_salt2, _c1, _c2 = \
                WAL_FRAME_HEADER.unpack(header)
            # A frame whose salt no longer matches the header belongs to an
            # earlier, already-checkpointed generation of the log.
            if f_salt1 != salt1:
                break
            if db_pages:
                commits += 1
                last_db_pages = db_pages
            fh.seek(page_size, 1)

    out += [
        f"  format             {fmt}  ({WAL_MAGIC[magic]})",
        f"  page size          {page_size:,} bytes",
        f"  checkpoint seq     {checkpoint}",
        f"  salt               {salt1}, {salt2}",
        f"  live frames        {frames:,}  ({frames * page_size / 1_048_576:,.1f} MB of pages)",
        f"  commit records     {commits:,}",
    ]
    if last_db_pages:
        out.append(f"  database size after last commit  {last_db_pages:,} pages")
    out += [
        "",
        "  These pages are already committed - a reader sees them as part of the",
        "  database. They move into ims.sqlite at the next checkpoint, which the",
        "  server does on its own. Deleting a -wal that has not been checkpointed",
        "  discards whatever it holds.",
    ]
    return out


def describe_shm(path: Path) -> list[str]:
    size = path.stat().st_size
    return [
        f"{path.name}  ({size:,} bytes)",
        "  A shared-memory index into the -wal above: which log frame holds the",
        "  newest copy of each page, so readers do not have to scan the log.",
        "  It holds no data of its own and its layout is platform-specific, so",
        "  there is nothing here to render as text. SQLite rebuilds it from the",
        "  -wal whenever the first connection opens the database.",
    ]


def write_journal_report(source: Path, out_dir: Path) -> Path | None:
    """Describe the -wal and -shm sitting beside a database, in words.

    Call this *before* opening the database. Reading a WAL database can create
    an `-shm`, and a report on files the reader just made describes nothing.
    """
    wal, shm = journal_files(source)
    if not wal.exists() and not shm.exists():
        return None

    lines = [
        f"Journal files beside {source.name}",
        f"At {datetime.now().astimezone().isoformat(timespec='seconds')}",
        "",
        "Neither of these is a text file and neither can be made into one: they",
        "hold raw database pages and a shared-memory index, not rows. This is a",
        "description of what they contain right now. The rows themselves are in",
        "the .sql files in this folder - a read of the database sees the WAL's",
        "contents already merged in.",
        "",
    ]
    for path, describe in ((wal, describe_wal), (shm, describe_shm)):
        lines += describe(path) if path.exists() else [
            f"{path.name}  (absent)",
            "  Nothing outstanding; the database file is complete on its own.",
        ]
        lines.append("")

    target = out_dir / "_journal.txt"
    target.write_text("\n".join(lines), encoding="utf-8")
    return target


# --------------------------------------------------------------------------- #

def dump_database(source: Path, out_dir: Path, args, label: str = "") -> None:
    """Write one database - live or backup - into its own folder.

    A dump leaves the database exactly as it found it, journal files included:
    a backup that arrived without a `-wal` still has none afterwards.

    `label` names the file the reader knows about, which for a backup is the zip
    rather than the temporary copy expanded out of it.
    """
    out_dir.mkdir(parents=True, exist_ok=True)
    print(f"\n{label or source.name}  ->  {out_dir}")

    # Both of these happen before the database is opened: see write_journal_report.
    pre_existing = {p for p in journal_files(source) if p.exists()}
    journal = write_journal_report(source, out_dir)
    if journal:
        print(f"  {journal.name}")

    conn = open_readonly(source)
    try:
        print(f"  {write_schema(conn, source, out_dir).name}")
        if args.schema_only:
            return
        _dump_tables(conn, source, out_dir, args)
    finally:
        conn.close()
        _remove_created_journals(source, pre_existing)


def _remove_created_journals(source: Path, pre_existing: set[Path]) -> None:
    """Delete any -wal/-shm this run brought into existence, and only those."""
    for path in journal_files(source):
        if path in pre_existing or not path.exists():
            continue
        try:
            path.unlink()
        except OSError as exc:
            # Something else opened the database while we were reading it and
            # is using them, which means they are not ours to remove after all.
            print(f"  left {path.name} in place: {exc}")


def _dump_tables(conn: sqlite3.Connection, source: Path, out_dir: Path,
                 args) -> None:
    """One .sql file per table, plus the manifest tying them together."""
    available = table_names(conn)
    if args.tables:
        wanted = [t.strip() for t in args.tables.split(",") if t.strip()]
        unknown = [t for t in wanted if t not in available]
        if unknown:
            sys.exit(f"{source.name} has no table(s): {', '.join(unknown)}")
    else:
        wanted = available

    entries = [
        dump_table(conn, name, out_dir, args.limit, args.rows_per_file,
                   args.include_secrets)
        for name in wanted
    ]

    for e in entries:
        note = f"  ({e['note']})" if e["note"] else (
            f"  -> {e['table']}/ ({e['files']} files)" if e["files"] > 1 else "")
        print(f"  {e['table']:<24}{e['written']:>10,} of {e['held']:>10,}{note}")
    print(f"  {write_manifest(source, entries, out_dir).name}")

    capped = [e["table"] for e in entries
              if e["held"] > e["written"] and not e["note"]]
    if capped and args.limit:
        print(f"  capped at {args.limit:,} rows: {', '.join(capped)}")


def backups_to_dump(which: str) -> list[Path]:
    if which == "skip":
        return []
    found = sorted(config.BACKUP_DIR.glob("ims-*.zip"), reverse=True)
    if not found:
        print(f"No backups in {config.BACKUP_DIR}.")
        return []
    return found[:1] if which == "latest" else found


def dump_zipped_backup(archive_path: Path, out_dir: Path, args) -> None:
    """Dump a backup, which is a zip with the database inside it.

    Expanded to a temporary file rather than read in place: SQLite needs a real
    file on disk, and a 1.2 GB database is not something to hold in memory.
    """
    work = Path(tempfile.mkdtemp(prefix="ims-dump-"))
    try:
        with zipfile.ZipFile(archive_path) as archive:
            names = [n for n in archive.namelist() if n.endswith(".sqlite")]
            if not names:
                print(f"  {archive_path.name}: no database inside, skipped")
                return
            archive.extract(names[0], work)
        dump_database(work / names[0], out_dir, args, label=archive_path.name)
    except zipfile.BadZipFile as exc:
        print(f"  {archive_path.name}: not a readable zip ({exc}), skipped")
    finally:
        shutil.rmtree(work, ignore_errors=True)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Write the SQLite databases out as plain text files.")
    parser.add_argument("--limit", type=int, default=DEFAULT_LIMIT,
                        help=f"rows per table, 0 for all (default {DEFAULT_LIMIT})")
    parser.add_argument("--rows-per-file", type=int, default=ROWS_PER_FILE,
                        help=f"rows per .sql file; a table with more than this "
                             f"gets a folder of numbered chunks "
                             f"(default {ROWS_PER_FILE})")
    parser.add_argument("--tables",
                        help="comma-separated list; default is every table")
    parser.add_argument("--schema-only", action="store_true",
                        help="write 000_schema.sql and _journal.txt, nothing else")
    parser.add_argument("--include-secrets", action="store_true",
                        help="write session tokens and password hashes too")
    parser.add_argument("--backups", choices=("skip", "latest", "all"),
                        default="skip",
                        help="also dump backups (default: skip)")
    parser.add_argument("--source", type=Path,
                        help="dump this database file instead of the live one")
    parser.add_argument("--out", type=Path, default=config.PLAINTEXT_DIR,
                        help=f"output folder (default {config.PLAINTEXT_DIR})")
    args = parser.parse_args()

    out_root: Path = args.out
    print(f"Writing to {out_root}")

    if args.source:
        if not args.source.exists():
            sys.exit(f"No database at {args.source}")
        dump_database(args.source, out_root / args.source.stem, args)
    else:
        if not config.DB_PATH.exists():
            sys.exit(f"No database at {config.DB_PATH}. Run backend/migrate.py first.")
        dump_database(config.DB_PATH, out_root / "live", args)
        for backup in backups_to_dump(args.backups):
            dump_zipped_backup(backup, out_root / "backups" / backup.stem, args)

    print(f"\nDone. Open {out_root} in the editor.")
    if args.limit:
        print(f"Row counts are capped at {args.limit:,} per table; "
              f"--limit 0 writes everything.")


if __name__ == "__main__":
    main()
