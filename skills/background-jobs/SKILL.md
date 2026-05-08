---
name: background-jobs
description: >-
  Background job, task queue, celery, RQ, redis queue, async task, worker,
  scheduled task, cron, periodic task, job queue, enqueue, retry task,
  deferred processing, long-running task, queue depth, dead letter queue,
  worker process.
---

# background-jobs

## What this is

A practical guide for Python internal tools developers who need to run work
outside the request/response cycle. Covers the full spectrum from a five-line
crontab entry to Celery with multiple queues. Starts with the simplest option
and explains when to graduate to something more complex.

**Related skills:**
- `python-scripts-and-services` — config, logging, project layout, testing
- `llm-integrations-safety` — async LLM calls are a common reason to reach for a task queue
- `observability` — monitoring queue depth and worker health

---

## 1. When to use what — decision table

Choose the simplest option that satisfies your constraints.

| Situation | Recommended approach |
|-----------|----------------------|
| Task runs in <2s, user is waiting for the result | Run inline — no queue needed |
| Scheduled batch (nightly report, hourly sync, daily cleanup) | Cron + Python script |
| User-triggered, takes 5–60s, user should not wait | Background job / task queue (RQ or Celery) |
| User-triggered, needs retry on transient failure | Task queue with retry |
| Need status tracking ("your export is 40% done") | Task queue — store status in DB |
| Multiple priority lanes (urgent vs bulk) | Celery with multiple queues |
| Large team, existing Celery infrastructure | Celery |
| Purely scheduled, simple, no retry needed | Cron — do not add a task queue |

**Default rule:** reach for cron first. Add a task queue only when you need a
specific feature it provides (retry, status tracking, user-triggered async,
priority queues). Task queues add a Redis dependency and worker processes to
operate — that cost is only worth paying when the features are necessary.

---

## 2. Cron + Python script (simplest approach)

For scheduled tasks that run on a fixed interval without user interaction, a
crontab entry pointing at a Python script is often all you need.

### Crontab entry

```cron
# Run nightly at 02:15; redirect all output to a log file.
# Set PATH so the venv python is found.
15 2 * * * /home/deploy/myapp/.venv/bin/python /home/deploy/myapp/scripts/nightly_sync.py \
    >> /var/log/myapp/nightly_sync.log 2>&1
```

Key points:
- Use the absolute path to the venv Python, not `python3` — cron has a minimal PATH.
- Redirect both stdout and stderr (`>> logfile 2>&1`) so failures are visible.
- Append (`>>`) rather than overwrite (`>`); rotate with `logrotate`.

### Prevent overlapping runs with flock

If the previous run might still be executing when the next fires, use `flock`
to skip rather than pile up:

```cron
15 2 * * * /usr/bin/flock -n /tmp/myapp_nightly_sync.lock \
    /home/deploy/myapp/.venv/bin/python /home/deploy/myapp/scripts/nightly_sync.py \
    >> /var/log/myapp/nightly_sync.log 2>&1
```

`flock -n` returns immediately with a non-zero exit code if the lock is already
held; cron logs the failure and tries again at the next interval.

### Script structure

```python
"""Nightly sync — fetches new records from the upstream API and writes to DB.

Run via cron; safe to kill and restart (all writes are idempotent upserts).
"""
from __future__ import annotations

import logging
import sys
from pathlib import Path

import yaml

# Local src imports
from src.db import init_db
from src.sync import sync_records

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s: %(message)s",
)
logger = logging.getLogger(__name__)


def main() -> int:
    config_path = Path(__file__).parent.parent / "config.yaml"
    config = yaml.safe_load(config_path.read_text())

    conn = init_db(config["db"]["path"])
    try:
        synced = sync_records(conn, config)
        logger.info("Sync complete: %d records processed", synced)
        return 0
    except Exception:
        logger.exception("Sync failed")
        return 1
    finally:
        conn.close()


if __name__ == "__main__":
    sys.exit(main())
```

---

## 3. RQ (Redis Queue) — lightweight task queue

RQ is the right choice for most internal tools that need a task queue. It has
no config file, minimal concepts (queues, jobs, workers), and ships with an
optional dashboard. The only dependency is Redis.

### Install

```
rq==1.16.2
redis==5.0.1
```

### Enqueue a task

```python
# scripts/trigger_export.py
from __future__ import annotations

from redis import Redis
from rq import Queue

from src.exports import generate_report

redis_conn = Redis(host="localhost", port=6379)
q = Queue(connection=redis_conn)

# Enqueue the task; returns immediately.
# Arguments are serialized and stored in Redis — do NOT pass secrets here.
job = q.enqueue(generate_report, report_id=42, user_email="user@example.com")
print(f"Queued job {job.id}")
```

### Define a task

```python
# src/exports.py
from __future__ import annotations

import logging

logger = logging.getLogger(__name__)


def generate_report(report_id: int, user_email: str) -> str:
    """Generate a report and email it. Called by RQ workers.

    This function runs in a separate worker process. Load config from
    environment or file here — do not expect the caller's state.
    """
    import yaml
    from pathlib import Path

    config = yaml.safe_load((Path(__file__).parent.parent / "config.yaml").read_text())

    logger.info("Generating report %d for %s", report_id, user_email)
    # ... actual work ...
    return f"report_{report_id}.csv"
```

### Start a worker

```bash
# From the project root with the venv active:
rq worker --url redis://localhost:6379
```

For production, run workers under a process supervisor (systemd, supervisor).
Run at least two workers so one failure does not stop the queue.

### Check job status

```python
from redis import Redis
from rq.job import Job

redis_conn = Redis(host="localhost", port=6379)
job = Job.fetch("job-id-here", connection=redis_conn)

print(job.get_status())   # queued | started | finished | failed | stopped
print(job.result)         # return value when finished
print(job.exc_info)       # traceback when failed
```

### When to use RQ over cron

- A user clicks a button and triggers the work (not a fixed schedule).
- You need retry on transient failures (network, DB lock).
- You want a simple web dashboard to inspect failed jobs (`rq-dashboard`).
- Task duration is unpredictable (could be 5s or 5 minutes).

---

## 4. Celery — when you actually need it

Use Celery when you need features RQ does not provide: multiple named queues
with priority routing, complex canvas workflows (chains, chords, groups), or
you are joining an existing Celery deployment.

Do not choose Celery because it is more popular. It adds configuration
complexity and a steeper operational burden.

### Minimal project layout

```
myapp/
  celery.py       # Celery app instance
  tasks.py        # Task definitions
  config.yaml
```

### celery.py — app instance

```python
"""Celery application instance.

Import this in tasks.py and anywhere tasks are enqueued.
"""
from __future__ import annotations

from celery import Celery

app = Celery(
    "myapp",
    broker="redis://localhost:6379/0",
    backend="redis://localhost:6379/1",
    include=["myapp.tasks"],
)

app.conf.update(
    task_serializer="json",
    result_serializer="json",
    accept_content=["json"],
    timezone="UTC",
    enable_utc=True,
    task_acks_late=True,       # ack after task completes, not when received
    task_reject_on_worker_lost=True,
)
```

### tasks.py — task definition

```python
"""Celery tasks for myapp."""
from __future__ import annotations

import logging

from myapp.celery import app

logger = logging.getLogger(__name__)


@app.task(
    bind=True,
    max_retries=3,
    default_retry_delay=60,    # seconds before first retry
)
def process_record(self, record_id: int) -> dict:
    """Process a single record. Retries up to 3 times on transient errors."""
    try:
        # ... actual work ...
        return {"status": "ok", "record_id": record_id}
    except (ConnectionError, TimeoutError) as exc:
        # Retry with exponential backoff: 60s, 120s, 240s.
        raise self.retry(exc=exc, countdown=60 * (2 ** self.request.retries))
    except ValueError:
        # Logic error — do NOT retry. Log and let the task fail.
        logger.error("Bad input for record %d", record_id)
        raise
```

### Start a worker

```bash
# Single worker, all queues:
celery -A myapp.celery worker --loglevel=info

# Named queue with concurrency:
celery -A myapp.celery worker -Q priority --concurrency=4 --loglevel=info
```

### Beat scheduler for periodic tasks

Celery Beat replaces cron when tasks are already in Celery. Do not run both
cron and Beat for the same task.

```python
# In celery.py, add:
from celery.schedules import crontab

app.conf.beat_schedule = {
    "nightly-sync": {
        "task": "myapp.tasks.nightly_sync",
        "schedule": crontab(hour=2, minute=15),
    },
}
```

```bash
# Run Beat in a separate process (never in the same process as a worker):
celery -A myapp.celery beat --loglevel=info
```

---

## 5. Task idempotency

Tasks may run more than once: retries, duplicate enqueues, worker crashes that
replay the message. Design every task to be safe to run twice.

### Pattern: check-and-return-early

```python
def generate_report(report_id: int, user_email: str) -> str:
    conn = get_db_connection()

    # Check if work already done before starting.
    existing = conn.execute(
        "SELECT output_path FROM reports WHERE id = %s AND status = 'done'",
        (report_id,),
    ).fetchone()
    if existing:
        logger.info("Report %d already complete, skipping", report_id)
        return existing[0]

    # ... generate the report ...

    # Use upsert so a second run overwrites cleanly instead of inserting a duplicate.
    conn.execute(
        "INSERT INTO reports (id, output_path, status) VALUES (%s, %s, 'done') "
        "ON CONFLICT (id) DO UPDATE SET output_path = EXCLUDED.output_path, status = 'done'",
        (report_id, output_path),
    )
    conn.commit()
    return output_path
```

Rules for idempotent tasks:
- Read current state before writing.
- Use database upserts (`INSERT ... ON CONFLICT DO UPDATE`), not plain `INSERT`.
- Use unique IDs (record ID, not timestamp) as idempotency keys.
- File writes: write to a temp path, then rename atomically.
- External API calls: check if the resource already exists before creating.

---

## 6. Retry strategies

### What to retry

Retry only on transient failures. Do not retry on logic errors.

| Error type | Retry? | Reason |
|------------|--------|--------|
| Network timeout | Yes | Likely recoverable |
| HTTP 429 Too Many Requests | Yes | Rate limit; back off and try again |
| HTTP 500/502/503/504 | Yes | Server-side transient error |
| DB connection refused | Yes | Transient |
| DB deadlock / lock timeout | Yes | Transient |
| HTTP 400 Bad Request | No | Your bug — retry won't fix it |
| HTTP 404 Not Found | No | Resource missing — retry won't fix it |
| ValueError / TypeError | No | Logic error in your code |
| Record not found in DB | No | Data problem, not transient |

### Exponential backoff

```python
# RQ: specify retry at enqueue time.
from rq import Retry

job = q.enqueue(
    process_record,
    record_id=42,
    retry=Retry(max=3, interval=[10, 30, 60]),  # waits: 10s, 30s, 60s
)
```

```python
# Celery: retry in the task (see tasks.py above).
raise self.retry(exc=exc, countdown=60 * (2 ** self.request.retries))
# Retries at: 60s, 120s, 240s.
```

### Max retry limit

Set a hard limit (3–5 retries) on all tasks. Unlimited retries cause jobs to
accumulate in the queue and mask persistent failures.

---

## 7. Dead letter / failed task handling

A failed task should be visible, not silent. Every failure needs a log entry
with the task ID and input arguments, and a way to inspect or requeue the job.

### RQ failed job registry

```python
from redis import Redis
from rq.job import Job
from rq.registry import FailedJobRegistry

redis_conn = Redis(host="localhost", port=6379)
from rq import Queue

q = Queue(connection=redis_conn)
registry = FailedJobRegistry(queue=q)

for job_id in registry.get_job_ids():
    job = Job.fetch(job_id, connection=redis_conn)
    print(f"Failed job {job_id}: {job.exc_info}")
```

To requeue a failed job:

```bash
rq requeue --all --queue default
```

### Celery: inspect failed tasks

```bash
# List active, reserved, and failed tasks:
celery -A myapp.celery inspect active
celery -A myapp.celery inspect reserved

# Purge the queue (use carefully):
celery -A myapp.celery purge
```

### Always log before failing

```python
@app.task(bind=True, max_retries=3)
def process_record(self, record_id: int) -> dict:
    try:
        return do_work(record_id)
    except Exception as exc:
        logger.error(
            "Task failed: process_record | task_id=%s record_id=%d error=%s",
            self.request.id,
            record_id,
            exc,
            exc_info=True,
        )
        if self.request.retries < self.max_retries:
            raise self.retry(exc=exc, countdown=60)
        raise   # exhausted retries — let Celery mark as failed
```

---

## 8. Monitoring background jobs

Track these signals. A growing queue with idle workers means jobs are failing
before the worker picks them up (likely a serialization or import error).

| Signal | Healthy state | Warning state |
|--------|---------------|---------------|
| Queue depth | Draining or stable | Growing over time |
| Workers running | At least 1 (>1 for HA) | 0 — nothing is processing |
| Failed job count | Low, bounded | Growing unchecked |
| Job duration p95 | Consistent with workload | Spiking or suddenly flat |
| Job throughput | Matches enqueue rate | Enqueue > finish rate |

### Quick queue depth check (RQ)

```python
from redis import Redis
from rq import Queue

redis_conn = Redis(host="localhost", port=6379)
q = Queue(connection=redis_conn)

print(f"Queued:  {len(q)}")
print(f"Workers: {len(q.workers)}")  # rq >= 1.16

from rq.registry import (
    StartedJobRegistry,
    FinishedJobRegistry,
    FailedJobRegistry,
)
print(f"Started: {StartedJobRegistry(queue=q).count}")
print(f"Finished: {FinishedJobRegistry(queue=q).count}")
print(f"Failed:  {FailedJobRegistry(queue=q).count}")
```

### rq-dashboard

RQ ships with an optional web UI. Install and run locally during development:

```bash
pip install rq-dashboard
rq-dashboard --redis-url redis://localhost:6379
```

Do not expose rq-dashboard publicly; it has no auth by default.

### Celery Flower

```bash
pip install flower
celery -A myapp.celery flower --port=5555
```

Again: run behind an authenticated reverse proxy or restrict to internal
network only.

---

## 9. Secrets and config in workers

Workers run in a separate process (often on a separate host) from the web app.
They need access to the same config, but that config must not travel through
the queue.

### Do NOT pass secrets as task arguments

Task arguments are serialized and stored in Redis. Anyone with Redis access can
read them.

```python
# WRONG — token is visible in Redis
q.enqueue(send_report, jira_token="abc123", report_id=42)

# RIGHT — load config inside the task from env or file
q.enqueue(send_report, report_id=42)
```

### Load config at task start

```python
# src/exports.py
def send_report(report_id: int) -> None:
    """Worker loads its own config — never from task args."""
    import yaml
    from pathlib import Path

    config = yaml.safe_load((Path(__file__).parent.parent / "config.yaml").read_text())
    token = config["jira"]["token"]
    # ... use token ...
```

### Worker startup config validation

Validate required config keys when the worker process starts, not when the
first task runs. Use a Celery signal or a worker init script:

```python
# In celery.py:
from celery.signals import worker_ready

@worker_ready.connect
def validate_config(**kwargs: object) -> None:
    import yaml
    from pathlib import Path

    config = yaml.safe_load((Path("config.yaml")).read_text())
    if not config.get("jira", {}).get("token"):
        raise RuntimeError("config.yaml: jira.token is required")
```

This makes misconfigured workers fail loudly at startup rather than silently
dropping jobs.

---

## 10. When NOT to use a task queue

A task queue adds real operational cost:
- A Redis instance to run, monitor, and back up.
- Worker processes to deploy, scale, and restart on failure.
- Failed-job state to inspect and occasionally clear.
- A new failure mode: the queue grows and nothing is processed.

Skip the task queue if any of these are true:

- **The task runs in <2s** — just run it inline; the user can wait.
- **No user is waiting** and the task is scheduled — use cron instead.
- **You do not need retry** — cron jobs that fail just try again the next run.
- **You do not need status tracking** — if the caller does not need to check
  "is it done?", you do not need a queue.
- **The task runs once and is not user-triggered** — this is a script, not a job.

Start with cron + script. Graduate to RQ when you have a specific need it solves.
Graduate to Celery only when RQ is not enough.

---

## Quick reference

```
Decision:
  <2s + user waiting        → inline
  scheduled, no retry       → cron + flock
  user-triggered, need retry → RQ
  multiple queues / Beat    → Celery

RQ:
  pip install rq redis
  rq worker                             # start worker
  q.enqueue(fn, arg=val)                # enqueue
  Job.fetch(id, connection=r).status    # check status

Celery:
  pip install celery redis
  celery -A myapp.celery worker         # start worker
  celery -A myapp.celery beat           # start scheduler
  process_record.delay(record_id=42)    # enqueue

Idempotency: check-and-return-early + DB upserts
Retry: transient only (timeout, 5xx, lock) — never on logic errors
Dead letter: RQ FailedJobRegistry / Celery inspect
Secrets: never in task args — load from config file in the task
```

## Related

- **Python project layout, config, venv, pytest:** [`python-scripts-and-services`](../python-scripts-and-services/SKILL.md)
- **Async concurrency within a worker (asyncio + httpx):** [`async-python`](../async-python/SKILL.md)
- **Monitoring workers: RED metrics, SLOs, structured logs:** [`observability`](../observability/SKILL.md)
- **Data pipelines that fan out work to queues:** [`data-pipelines`](../data-pipelines/SKILL.md)
- **Routing:** [`../../SKILLS.md`](../../SKILLS.md)
