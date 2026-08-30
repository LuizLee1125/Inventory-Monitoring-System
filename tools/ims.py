#!/usr/bin/env python3
"""
ims.py - read the Marina Trading IMS data files without FoxPro.

The system's tables are plain dBase/FoxPro .DBF files, so they can be read on
any modern machine. This tool lists them, dumps schemas, previews and filters
records, and exports to CSV or SQLite.

    python tools/ims.py tables
    python tools/ims.py schema STKFYL
    python tools/ims.py head CUSTFYL -n 5
    python tools/ims.py find STKFYL STK_M PARACETAMOL
    python tools/ims.py csv SPLYRFYL
    python tools/ims.py sqlite --skip-big

Requires: pip install dbfread
Records flagged deleted are skipped, matching the app's SET DELETED ON.
"""

from __future__ import annotations

import argparse
import csv
import sqlite3
import sys
from datetime import date, datetime
from decimal import Decimal
from pathlib import Path

try:
    from dbfread import DBF, FieldParser
except ImportError:
    sys.exit("dbfread is not installed.  Run:  python -m pip install dbfread")


class TolerantParser(FieldParser):
    """Return None instead of raising on malformed values.

    Twenty-five years of production data contain numeric fields holding a bare
    '.', blank dates, and similar debris that FoxPro tolerated. A strict parser
    aborts the whole export on the first one, so bad cells become NULL and the
    rest of the record is kept.
    """

    def parse(self, field, data):
        try:
            return super().parse(field, data)
        except Exception:
            return None

# DOS-era data: code page 437 is the safe assumption for these files.
ENCODING = "cp437"
DATA_DIR = Path(__file__).resolve().parent.parent
BIG_MB = 100  # tables above this are skipped by `sqlite --skip-big`


def open_dbf(path: Path) -> DBF:
    return DBF(
        str(path),
        encoding=ENCODING,
        char_decode_errors="replace",
        ignore_missing_memofile=True,
        parserclass=TolerantParser,
        load=False,
    )


def record_count(table: DBF) -> int:
    """Header record count - O(1). len(table) would scan the whole file."""
    return table.header.numrecords


def resolve(name: str) -> Path:
    """Accept STKFYL, stkfyl, or STKFYL.DBF."""
    stem = name.upper().removesuffix(".DBF")
    for candidate in (DATA_DIR / f"{stem}.DBF", DATA_DIR / f"{stem}.dbf"):
        if candidate.exists():
            return candidate
    matches = [p for p in DATA_DIR.glob("*.[Dd][Bb][Ff]") if p.stem.upper() == stem]
    if matches:
        return matches[0]
    sys.exit(f"No table named {stem!r} in {DATA_DIR}")


def fmt(value) -> str:
    if value is None:
        return ""
    if isinstance(value, (date, datetime)):
        return value.isoformat()[:10]
    if isinstance(value, bool):
        return "T" if value else "F"
    return str(value).strip()


# --------------------------------------------------------------------------- #
# commands
# --------------------------------------------------------------------------- #

def cmd_tables(args) -> None:
    rows = []
    for path in sorted(DATA_DIR.glob("*.[Dd][Bb][Ff]")):
        try:
            table = open_dbf(path)
            rows.append((path.stem.upper(), record_count(table), len(table.field_names),
                         path.stat().st_size / 1_048_576))
        except Exception as exc:  # unreadable / truncated file
            rows.append((path.stem.upper(), -1, -1, path.stat().st_size / 1_048_576))
            if args.verbose:
                print(f"  ! {path.name}: {exc}", file=sys.stderr)

    print(f"{'TABLE':<14}{'RECORDS':>12}{'FIELDS':>8}{'SIZE MB':>10}")
    print("-" * 44)
    for name, count, fields, mb in rows:
        recs = "unreadable" if count < 0 else f"{count:,}"
        flds = "" if fields < 0 else str(fields)
        print(f"{name:<14}{recs:>12}{flds:>8}{mb:>10.1f}")
    total = sum(mb for *_, mb in rows)
    print("-" * 44)
    print(f"{len(rows)} tables, {total:,.1f} MB")


def cmd_schema(args) -> None:
    path = resolve(args.table)
    table = open_dbf(path)
    print(f"{path.stem.upper()}   {record_count(table):,} records, {len(table.fields)} fields")
    print(f"{'FIELD':<14}{'TYPE':<6}{'LEN':>5}{'DEC':>5}")
    print("-" * 30)
    for f in table.fields:
        print(f"{f.name:<14}{f.type:<6}{f.length:>5}{f.decimal_count:>5}")


def cmd_head(args) -> None:
    path = resolve(args.table)
    table = open_dbf(path)
    fields = args.fields.split(",") if args.fields else table.field_names

    records = []
    for i, rec in enumerate(table):
        if i >= args.number:
            break
        records.append([fmt(rec.get(f)) for f in fields])

    widths = [max(len(f), *(len(r[i]) for r in records)) if records else len(f)
              for i, f in enumerate(fields)]
    widths = [min(w, 30) for w in widths]

    print(" ".join(f.ljust(w)[:w] for f, w in zip(fields, widths)))
    print(" ".join("-" * w for w in widths))
    for row in records:
        print(" ".join(v.ljust(w)[:w] for v, w in zip(row, widths)))


def cmd_find(args) -> None:
    path = resolve(args.table)
    table = open_dbf(path)
    if args.field.upper() not in {f.upper() for f in table.field_names}:
        sys.exit(f"{path.stem.upper()} has no field {args.field!r}. "
                 f"Fields: {', '.join(table.field_names)}")
    field = next(f for f in table.field_names if f.upper() == args.field.upper())
    needle = args.value.upper()

    shown = 0
    for rec in table:
        if needle in fmt(rec.get(field)).upper():
            shown += 1
            print(f"--- match {shown} " + "-" * 40)
            for k, v in rec.items():
                text = fmt(v)
                if text:
                    print(f"  {k:<14} {text}")
            if shown >= args.limit:
                print(f"\n(stopped at --limit {args.limit})")
                return
    print(f"\n{shown} match(es).")


def cmd_csv(args) -> None:
    path = resolve(args.table)
    table = open_dbf(path)
    out = Path(args.out) if args.out else DATA_DIR / "export" / f"{path.stem.upper()}.csv"
    out.parent.mkdir(parents=True, exist_ok=True)

    with out.open("w", newline="", encoding="utf-8-sig") as fh:
        writer = csv.writer(fh)
        writer.writerow(table.field_names)
        written = 0
        for rec in table:
            writer.writerow([fmt(rec.get(f)) for f in table.field_names])
            written += 1
            if written % 100_000 == 0:
                print(f"  {written:,} rows...", file=sys.stderr)
    print(f"Wrote {written:,} rows to {out}")


SQL_TYPE = {"N": "REAL", "F": "REAL", "I": "INTEGER", "B": "REAL",
            "Y": "REAL", "L": "INTEGER", "D": "TEXT", "T": "TEXT"}


def cmd_sqlite(args) -> None:
    out = Path(args.out) if args.out else DATA_DIR / "export" / "ims.sqlite"
    out.parent.mkdir(parents=True, exist_ok=True)
    if out.exists() and not args.append:
        out.unlink()

    conn = sqlite3.connect(out)
    conn.execute("PRAGMA journal_mode=OFF")
    conn.execute("PRAGMA synchronous=OFF")

    only = {t.upper() for t in args.only.split(",")} if args.only else None

    for path in sorted(DATA_DIR.glob("*.[Dd][Bb][Ff]")):
        name = path.stem.upper()
        if only and name not in only:
            continue
        size_mb = path.stat().st_size / 1_048_576
        if args.skip_big and size_mb > BIG_MB and not (only and name in only):
            print(f"  skip {name} ({size_mb:,.0f} MB > {BIG_MB} MB)")
            continue
        try:
            table = open_dbf(path)
        except Exception as exc:
            print(f"  !! {name}: {exc}")
            continue

        cols = ", ".join(f'"{f.name}" {SQL_TYPE.get(f.type, "TEXT")}' for f in table.fields)
        conn.execute(f'DROP TABLE IF EXISTS "{name}"')
        conn.execute(f'CREATE TABLE "{name}" ({cols})')
        placeholders = ", ".join("?" * len(table.field_names))
        insert = f'INSERT INTO "{name}" VALUES ({placeholders})'

        batch, written = [], 0
        for rec in table:
            batch.append([fmt(rec.get(f)) if isinstance(rec.get(f), (date, datetime))
                          else float(rec[f]) if isinstance(rec.get(f), Decimal)
                          else rec.get(f) for f in table.field_names])
            if len(batch) >= 10_000:
                conn.executemany(insert, batch)
                written += len(batch)
                batch.clear()
        if batch:
            conn.executemany(insert, batch)
            written += len(batch)
        conn.commit()
        print(f"  {name:<14} {written:>10,} rows")

    conn.close()
    print(f"\nDatabase written to {out}")
    print("Query it with any SQLite client, e.g.:")
    print('  sqlite3 export/ims.sqlite "SELECT CUST_M, CUST_BAL FROM CUSTFYL '
          'ORDER BY CUST_BAL DESC LIMIT 10;"')


# --------------------------------------------------------------------------- #

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Read Marina Trading IMS .DBF files without FoxPro.")
    parser.add_argument("--data-dir", help="folder holding the .DBF files "
                                           "(default: the repository root)")
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("tables", help="list every table with record counts")
    p.add_argument("-v", "--verbose", action="store_true")
    p.set_defaults(func=cmd_tables)

    p = sub.add_parser("schema", help="show a table's field definitions")
    p.add_argument("table")
    p.set_defaults(func=cmd_schema)

    p = sub.add_parser("head", help="preview the first records of a table")
    p.add_argument("table")
    p.add_argument("-n", "--number", type=int, default=10)
    p.add_argument("-f", "--fields", help="comma-separated subset of fields")
    p.set_defaults(func=cmd_head)

    p = sub.add_parser("find", help="show records where FIELD contains VALUE")
    p.add_argument("table")
    p.add_argument("field")
    p.add_argument("value")
    p.add_argument("--limit", type=int, default=20)
    p.set_defaults(func=cmd_find)

    p = sub.add_parser("csv", help="export one table to CSV")
    p.add_argument("table")
    p.add_argument("-o", "--out")
    p.set_defaults(func=cmd_csv)

    p = sub.add_parser("sqlite", help="export tables into one SQLite database")
    p.add_argument("-o", "--out")
    p.add_argument("--only", help="comma-separated table names")
    p.add_argument("--skip-big", action="store_true",
                   help=f"skip tables larger than {BIG_MB} MB")
    p.add_argument("--append", action="store_true",
                   help="keep an existing database file")
    p.set_defaults(func=cmd_sqlite)

    args = parser.parse_args()
    if args.data_dir:
        global DATA_DIR
        DATA_DIR = Path(args.data_dir).resolve()
    args.func(args)


if __name__ == "__main__":
    main()
