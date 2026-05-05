---
name: data-pipelines
description: >-
  Use when building or debugging a pipeline, ETL process, batch job, or scheduled
  data processor — including incremental loads, backfill runs, chunked pagination,
  idempotent record processing, dead-letter error handling, data quality checks,
  and pipeline state tracking. Triggers: pipeline, ETL, batch, data pipeline,
  incremental load, backfill, idempotent, chunk, pagination, scheduled job,
  data quality, extract transform load, cron job, process records.
---

# data-pipelines

## What this is

Patterns for building reliable, recoverable data pipelines in Python — covering batch
processing, incremental ETL, Jira data extraction, API pagination, failure handling,
idempotency, and pipeline state tracking.

These patterns apply to internal tooling that processes tickets, API
responses, and log records on a schedule or in bulk. They complement
`python-internal-tools` (structure, config, testing) and `shell-csv-pipelines`
(file-based transforms). Use the patterns here whenever your code runs repeatedly,
processes records in volume, or needs to recover from partial failure.

---

## 1. When to use a pipeline vs a script

A single-run script is the right tool for one-time work: a migration, a data fix, an
ad hoc export. Add pipeline patterns when any of these apply:

- **Runs on a schedule** (cron, CI scheduled job, or org automation)
- **Processes large datasets in chunks** (Jira JQL with hundreds of tickets, API pages,
  log files)
- **Needs recovery from partial failure** — a crash midway must not restart from zero
- **Output is consumed by other systems** — downstream consumers depend on consistent,
  complete output

If none of those apply, a simple script is cleaner. Add complexity only when the
use case demands it.

---

## 2. Idempotency — the core principle

A pipeline that runs twice must produce the same result as running once. Without
idempotency, reruns create duplicate rows, double-send notifications, or corrupt
aggregations.

Implement idempotency at the record level:

```python
# Track processed IDs in a DB table
conn.execute("""
    CREATE TABLE IF NOT EXISTS processed_items (
        item_id TEXT PRIMARY KEY,
        processed_at TEXT NOT NULL
    )
""")

def already_processed(conn, item_id: str) -> bool:
    row = conn.execute(
        "SELECT 1 FROM processed_items WHERE item_id = ?", (item_id,)
    ).fetchone()
    return row is not None

def mark_processed(conn, item_id: str) -> None:
    conn.execute(
        "INSERT OR IGNORE INTO processed_items (item_id, processed_at) VALUES (?, ?)",
        (item_id, datetime.utcnow().isoformat()),
    )

def process_item(conn, item: dict) -> None:
    item_id = item["key"]
    if already_processed(conn, item_id):
        logger.debug("skipping already-processed item: %s", item_id)
        return
    # ... do actual work ...
    mark_processed(conn, item_id)
    conn.commit()
```

For PostgreSQL, replace `INSERT OR IGNORE` with `INSERT ... ON CONFLICT DO NOTHING`.

Rule: check "already processed" before every item. Do not rely on a global run-level
flag — the crash may have happened mid-chunk.

---

## 3. Incremental vs full refresh

**Full refresh** wipes and reloads all data each run. Simple to implement, but expensive
for large datasets and slow when the source API is rate-limited.

**Incremental** processes only records new or changed since the last run. Use a `last_run_at`
timestamp or a cursor (e.g. a sequence ID) stored in the DB.

```python
def get_last_cursor(conn, pipeline_name: str) -> str | None:
    """Return the last processed cursor value for this pipeline, or None."""
    row = conn.execute(
        "SELECT cursor_value FROM pipeline_cursors WHERE pipeline_name = ?",
        (pipeline_name,),
    ).fetchone()
    return row[0] if row else None


def save_cursor(conn, pipeline_name: str, cursor_value: str) -> None:
    conn.execute(
        """
        INSERT INTO pipeline_cursors (pipeline_name, cursor_value, updated_at)
        VALUES (?, ?, ?)
        ON CONFLICT(pipeline_name) DO UPDATE SET
            cursor_value = excluded.cursor_value,
            updated_at = excluded.updated_at
        """,
        (pipeline_name, cursor_value, datetime.utcnow().isoformat()),
    )
    conn.commit()


def run_incremental(conn, jira_client, pipeline_name: str) -> int:
    """Fetch and process only records updated since the last cursor."""
    cursor = get_last_cursor(conn, pipeline_name)
    jql = 'project = "MYPROJECT" AND updated > "{cursor}"'.format(
        cursor=cursor or "2020-01-01 00:00"
    )
    processed = 0
    latest_updated = cursor
    for chunk in paginate_jql(jira_client, jql):
        for issue in chunk:
            process_issue(conn, issue)
            # Track the latest updated timestamp seen in this run
            updated = issue["fields"]["updated"]
            if latest_updated is None or updated > latest_updated:
                latest_updated = updated
            processed += 1
    if latest_updated and latest_updated != cursor:
        save_cursor(conn, pipeline_name, latest_updated)
    return processed
```

Schema for the cursor table:

```sql
CREATE TABLE IF NOT EXISTS pipeline_cursors (
    pipeline_name TEXT PRIMARY KEY,
    cursor_value  TEXT NOT NULL,
    updated_at    TEXT NOT NULL
);
```

---

## 4. Chunking and pagination

Never load all records into memory. Process in chunks of 50–500 items (tune to API
rate limits, response size, and available memory). For Jira, the practical max per
page is 100; use 50 as a safe default.

```python
import logging
from collections.abc import Iterator

logger = logging.getLogger(__name__)

_PAGE_SIZE = 50


def paginate_jql(
    jira_client,
    jql: str,
    page_size: int = _PAGE_SIZE,
) -> Iterator[list[dict]]:
    """Yield successive pages of Jira issues matching jql.

    Each yielded value is a list of issue dicts. Stops when the API
    returns fewer results than page_size.
    """
    start_at = 0
    while True:
        resp = jira_client.search_issues(
            jql=jql,
            start_at=start_at,
            max_results=page_size,
            fields=["summary", "status", "updated", "assignee"],
        )
        issues = resp.get("issues", [])
        if not issues:
            break
        logger.debug(
            "fetched page startAt=%d count=%d", start_at, len(issues)
        )
        yield issues
        if len(issues) < page_size:
            break
        start_at += len(issues)
```

General pattern for any paginated source:

```python
def paginate_api(client, resource: str, page_size: int = 100) -> Iterator[list[dict]]:
    page = 0
    while True:
        batch = client.get(resource, params={"page": page, "per_page": page_size})
        if not batch:
            break
        yield batch
        if len(batch) < page_size:
            break
        page += 1
```

---

## 5. Failure modes and recovery

Common failure points:

| Failure | Cause | Recovery |
|---|---|---|
| Network timeout | Slow API, long query | Retry with backoff (see §4 of CLAUDE.md) |
| Rate limit (HTTP 429) | Too many requests | Retry after `Retry-After` header |
| Malformed record | Unexpected API response shape | Log and write to `failed_items` |
| DB error | Disk full, locked file, schema mismatch | Let it propagate; fix before rerun |
| Crash mid-chunk | OOM, SIGKILL, unhandled exception | Resume from last committed chunk |

Process and commit one chunk at a time. A crash loses at most one chunk of work:

```python
def run_pipeline(conn, jira_client, jql: str) -> tuple[int, int]:
    """Process all issues matching jql. Returns (processed, failed)."""
    processed = failed = 0
    for chunk in paginate_jql(jira_client, jql):
        for issue in chunk:
            try:
                if already_processed(conn, issue["key"]):
                    continue
                process_issue(conn, issue)
                mark_processed(conn, issue["key"])
                processed += 1
            except Exception:
                logger.exception("failed to process issue %s", issue.get("key"))
                write_failed_item(conn, issue["key"], issue, error=format_exc())
                failed += 1
        conn.commit()   # commit after each full chunk
    return processed, failed
```

Use a `status` column when you need finer-grained recovery:

```sql
CREATE TABLE IF NOT EXISTS work_items (
    item_id    TEXT PRIMARY KEY,
    status     TEXT NOT NULL DEFAULT 'pending',  -- pending | processing | done | failed
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);
```

Reset `processing` items to `pending` at startup — they were interrupted mid-run:

```python
def reset_stale_processing(conn) -> int:
    cur = conn.execute(
        "UPDATE work_items SET status = 'pending' WHERE status = 'processing'"
    )
    conn.commit()
    return cur.rowcount
```

---

## 6. Dead-letter / error handling

Failed items must not silently disappear and must not block the pipeline. Write them
to a `failed_items` table with enough context to debug and reprocess.

Schema:

```sql
CREATE TABLE IF NOT EXISTS failed_items (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    item_id      TEXT NOT NULL,
    pipeline_name TEXT NOT NULL,
    error_message TEXT NOT NULL,
    raw_data     TEXT,            -- JSON of the original record, truncated
    failed_at    TEXT NOT NULL,
    retry_count  INTEGER NOT NULL DEFAULT 0
);
```

Write helper:

```python
import json
import traceback
from datetime import datetime


def write_failed_item(
    conn,
    item_id: str,
    raw_data: dict | None,
    pipeline_name: str,
    error: str | None = None,
) -> None:
    """Persist a failed item to the dead-letter table."""
    conn.execute(
        """
        INSERT INTO failed_items
            (item_id, pipeline_name, error_message, raw_data, failed_at)
        VALUES (?, ?, ?, ?, ?)
        """,
        (
            item_id,
            pipeline_name,
            error or traceback.format_exc(),
            json.dumps(raw_data)[:10_000] if raw_data else None,
            datetime.utcnow().isoformat(),
        ),
    )
    # caller commits
```

Reprocess dead-letter items separately, never inline in the main pipeline loop:

```python
def reprocess_failed(conn, jira_client, pipeline_name: str, limit: int = 50) -> int:
    """Attempt to reprocess up to `limit` failed items. Returns count reprocessed."""
    rows = conn.execute(
        """
        SELECT item_id FROM failed_items
        WHERE pipeline_name = ? AND retry_count < 3
        ORDER BY failed_at ASC LIMIT ?
        """,
        (pipeline_name, limit),
    ).fetchall()
    reprocessed = 0
    for (item_id,) in rows:
        try:
            issue = jira_client.get_issue(item_id)
            process_issue(conn, issue)
            conn.execute(
                "DELETE FROM failed_items WHERE item_id = ? AND pipeline_name = ?",
                (item_id, pipeline_name),
            )
            reprocessed += 1
        except Exception:
            logger.exception("reprocess failed for %s", item_id)
            conn.execute(
                """
                UPDATE failed_items
                SET retry_count = retry_count + 1, failed_at = ?
                WHERE item_id = ? AND pipeline_name = ?
                """,
                (datetime.utcnow().isoformat(), item_id, pipeline_name),
            )
        conn.commit()
    return reprocessed
```

---

## 7. Data quality checks

Assert data shape after loading, before committing or reporting. A loaded dataset that
passes a count and null check is far more trustworthy than one that doesn't.

```python
from dataclasses import dataclass


@dataclass
class QualityReport:
    passed: bool
    row_count: int
    null_violations: list[str]
    messages: list[str]


def check_data_quality(
    conn,
    table: str,
    run_id: int,
    expected_min: int,
    expected_max: int,
    required_columns: list[str],
) -> QualityReport:
    """Run basic quality assertions on a newly loaded batch.

    Returns a QualityReport. Callers should rollback or flag the run if not passed.
    """
    messages: list[str] = []
    null_violations: list[str] = []

    # Row count check
    (count,) = conn.execute(
        f"SELECT COUNT(*) FROM {table} WHERE run_id = ?", (run_id,)  # noqa: S608
    ).fetchone()
    if not expected_min <= count <= expected_max:
        messages.append(
            f"row count {count} outside expected range "
            f"[{expected_min}, {expected_max}]"
        )

    # Null checks on required columns
    for col in required_columns:
        (nulls,) = conn.execute(
            f"SELECT COUNT(*) FROM {table} WHERE run_id = ? AND {col} IS NULL",  # noqa: S608
            (run_id,),
        ).fetchone()
        if nulls > 0:
            null_violations.append(f"{col}: {nulls} nulls")

    passed = not messages and not null_violations
    if not passed:
        logger.warning(
            "data quality check FAILED table=%s run_id=%d issues=%s nulls=%s",
            table,
            run_id,
            messages,
            null_violations,
        )
    else:
        logger.info(
            "data quality check PASSED table=%s run_id=%d rows=%d",
            table,
            run_id,
            count,
        )

    return QualityReport(
        passed=passed,
        row_count=count,
        null_violations=null_violations,
        messages=messages,
    )
```

Example usage in a pipeline run:

```python
report = check_data_quality(
    conn,
    table="issues",
    run_id=run_id,
    expected_min=1,
    expected_max=5000,
    required_columns=["issue_key", "status", "updated_at"],
)
if not report.passed:
    conn.rollback()
    update_pipeline_run(conn, run_id, status="failed_quality")
    return
conn.commit()
```

---

## 8. State tracking table

Every pipeline run should write a record to a `pipeline_runs` table. This gives you
an audit trail, makes failure investigation easier, and lets monitoring queries work
without parsing logs.

Schema:

```sql
CREATE TABLE IF NOT EXISTS pipeline_runs (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    pipeline_name    TEXT    NOT NULL,
    started_at       TEXT    NOT NULL,
    completed_at     TEXT,
    status           TEXT    NOT NULL DEFAULT 'running',  -- running | done | failed | failed_quality
    items_processed  INTEGER NOT NULL DEFAULT 0,
    items_failed     INTEGER NOT NULL DEFAULT 0,
    error_message    TEXT
);
```

Helpers:

```python
from datetime import datetime


def start_pipeline_run(conn, pipeline_name: str) -> int:
    """Insert a run record and return its id."""
    cur = conn.execute(
        """
        INSERT INTO pipeline_runs (pipeline_name, started_at, status)
        VALUES (?, ?, 'running')
        """,
        (pipeline_name, datetime.utcnow().isoformat()),
    )
    conn.commit()
    return cur.lastrowid


def complete_pipeline_run(
    conn,
    run_id: int,
    status: str,
    items_processed: int,
    items_failed: int,
    error_message: str | None = None,
) -> None:
    conn.execute(
        """
        UPDATE pipeline_runs
        SET completed_at    = ?,
            status          = ?,
            items_processed = ?,
            items_failed    = ?,
            error_message   = ?
        WHERE id = ?
        """,
        (
            datetime.utcnow().isoformat(),
            status,
            items_processed,
            items_failed,
            error_message,
            run_id,
        ),
    )
    conn.commit()
```

Main function pattern:

```python
def main() -> int:
    config = load_config()
    conn = init_db(config["db_path"])
    run_id = start_pipeline_run(conn, "jira_security_ingest")
    processed = failed = 0
    try:
        processed, failed = run_pipeline(conn, build_jira_client(config), config)
        status = "done" if failed == 0 else "done_with_errors"
        complete_pipeline_run(conn, run_id, status, processed, failed)
        logger.info(
            "pipeline finished run_id=%d processed=%d failed=%d",
            run_id, processed, failed,
        )
        return 0 if failed == 0 else 1
    except Exception:
        logger.exception("pipeline crashed run_id=%d", run_id)
        complete_pipeline_run(conn, run_id, "failed", processed, failed,
                              error_message=traceback.format_exc())
        return 1


if __name__ == "__main__":
    sys.exit(main())
```

---

## 9. Backfill strategy

When you need to reprocess historical data (schema change, bug fix, new enrichment),
use a `--start-date` / `--end-date` CLI flag. Run in smaller date chunks to stay within
API rate limits. Idempotency (§2) makes reruns safe — already-processed items are
skipped automatically unless you explicitly clear the `processed_items` table.

```python
import argparse
from datetime import date, timedelta


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Security Jira ingest pipeline")
    p.add_argument("--start-date", metavar="YYYY-MM-DD", help="Backfill from this date")
    p.add_argument("--end-date",   metavar="YYYY-MM-DD", help="Backfill to this date (inclusive)")
    p.add_argument("--chunk-days", type=int, default=7,
                   help="Days per chunk when backfilling (default: 7)")
    p.add_argument("--force-reprocess", action="store_true",
                   help="Clear processed_items before running (makes reruns re-process all)")
    return p.parse_args()


def date_chunks(
    start: date, end: date, chunk_days: int
) -> list[tuple[date, date]]:
    """Split [start, end] into non-overlapping chunks of chunk_days days."""
    chunks = []
    cursor = start
    while cursor <= end:
        chunk_end = min(cursor + timedelta(days=chunk_days - 1), end)
        chunks.append((cursor, chunk_end))
        cursor = chunk_end + timedelta(days=1)
    return chunks


def run_backfill(conn, jira_client, args: argparse.Namespace) -> int:
    start = date.fromisoformat(args.start_date)
    end   = date.fromisoformat(args.end_date)
    if args.force_reprocess:
        logger.warning("--force-reprocess: clearing processed_items table")
        conn.execute("DELETE FROM processed_items")
        conn.commit()
    chunks = date_chunks(start, end, args.chunk_days)
    logger.info("backfill: %d chunks from %s to %s", len(chunks), start, end)
    total_processed = total_failed = 0
    for chunk_start, chunk_end in chunks:
        jql = (
            f'project = "MYPROJECT" '
            f'AND updated >= "{chunk_start}" '
            f'AND updated <= "{chunk_end} 23:59"'
        )
        logger.info("backfill chunk %s to %s", chunk_start, chunk_end)
        processed, failed = run_pipeline(conn, jira_client, jql)
        total_processed += processed
        total_failed += failed
    logger.info(
        "backfill complete processed=%d failed=%d", total_processed, total_failed
    )
    return 0 if total_failed == 0 else 1
```

---

## 10. Monitoring a pipeline

Log at the start and end of every run with duration, item counts, and error counts.
Use structured log fields that can be parsed by log aggregation tools.

```python
import time


def run_with_monitoring(conn, jira_client, pipeline_name: str, jql: str) -> tuple[int, int]:
    """Run the pipeline and emit structured start/end log lines."""
    start_ts = time.monotonic()
    run_id = start_pipeline_run(conn, pipeline_name)
    logger.info(
        "pipeline_start pipeline=%s run_id=%d jql=%r",
        pipeline_name, run_id, jql,
    )
    processed = failed = 0
    try:
        processed, failed = run_pipeline(conn, jira_client, jql)
    finally:
        elapsed = time.monotonic() - start_ts
        status = "done" if failed == 0 else "done_with_errors"
        complete_pipeline_run(conn, run_id, status, processed, failed)
        logger.info(
            "pipeline_end pipeline=%s run_id=%d status=%s "
            "processed=%d failed=%d elapsed_s=%.1f",
            pipeline_name, run_id, status, processed, failed, elapsed,
        )
    return processed, failed
```

Alert thresholds to define per pipeline:

| Signal | Threshold | Action |
|---|---|---|
| Run did not start | Cron missed by > 30 min | Page on-call |
| Error rate | > 5% of items failed | Slack alert |
| Duration | > 2x rolling baseline | Slack alert |
| Items processed | < 10% of normal volume | Slack alert (possible upstream gap) |

For internal tooling, a simple check in the `pipeline_runs` table is often enough:

```python
def check_last_run_health(conn, pipeline_name: str, max_age_hours: int = 25) -> bool:
    """Return True if the pipeline ran successfully within max_age_hours."""
    row = conn.execute(
        """
        SELECT status, completed_at FROM pipeline_runs
        WHERE pipeline_name = ?
        ORDER BY started_at DESC LIMIT 1
        """,
        (pipeline_name,),
    ).fetchone()
    if row is None:
        logger.warning("no runs found for pipeline %s", pipeline_name)
        return False
    status, completed_at = row
    if status not in ("done", "done_with_errors"):
        logger.warning("last run status=%s pipeline=%s", status, pipeline_name)
        return False
    age_hours = (
        datetime.utcnow() - datetime.fromisoformat(completed_at)
    ).total_seconds() / 3600
    if age_hours > max_age_hours:
        logger.warning(
            "last successful run was %.1fh ago pipeline=%s", age_hours, pipeline_name
        )
        return False
    return True
```

---

## Related skills

| Need | Skill |
|---|---|
| Async task execution, job queues | `background-jobs` |
| SQLite schema, migrations, parameterized queries | `python-internal-tools` (reference.md §6) |
| Pipeline monitoring, structured logging | `observability` |
| File-based CSV/TSV transforms, awk pipelines | `shell-csv-pipelines` |
| Jira REST client, JQL, PAT setup | `python-internal-tools` (jira.md) |
| PII in Jira fields, log scrubbing | `data-handling-pii` |
| LLM scoring step inside a pipeline | `llm-integrations-safety` |
