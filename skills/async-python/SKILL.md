---
name: async-python
description: >-
  async, asyncio, await, concurrent, httpx, aiohttp, asyncio.gather, semaphore,
  event loop, async Python, parallel requests, async def, coroutine, TaskGroup,
  async HTTP, asyncio.run, asyncio.sleep, run_in_executor, asyncio.Semaphore,
  concurrent HTTP calls, async context manager, non-blocking, cooperative
  multitasking.
---

# async-python

## What this is

A practical guide to `asyncio` for internal Python tools that make many
concurrent API calls — Jira pagination across projects, batch URL fetching,
parallel enrichment pipelines. Covers when to use async, the core primitives,
`httpx` as an async HTTP client, concurrency limiting with semaphores, error
handling, mixing sync and async code, and a copy-paste-ready Jira fetch
function.

**Related skills:**
- `python-scripts-and-services` — config, logging, project layout, testing
- `python-scripts-and-services/http-clients-reliability.md` — retries, backoff, timeouts
- `data-pipelines` — ETL, incremental load, chunking; async is often the right
  tool inside a pipeline stage
- `background-jobs` — for CPU-bound work or work that must survive process
  restart, a task queue beats async

---

## 1. When to use async — and when not to

Async is a tool for a specific problem. Reaching for it when the problem does
not exist adds complexity with no benefit.

### Use async when

- Making **many concurrent I/O-bound calls**: fetching 50 Jira issues in
  parallel, paginating across 10 projects simultaneously, enriching a list of
  URLs from an API.
- The bottleneck is **waiting on network or disk**, not CPU computation.
- You need **concurrency without threads**: no locks, no race conditions from
  shared mutable state (when coroutines don't yield in a critical section).

### Do not use async when

- The work is **CPU-bound** (parsing, scoring, transformations): use
  `multiprocessing` instead. Async won't help — the event loop is single-
  threaded and CPU work blocks everything else.
- You are making a **single HTTP call**: `requests` is fine. The overhead of
  `asyncio.run()` is not worth it.
- You are **adding to an existing sync codebase**: the cost of threading async
  through every call site is high. Consider `asyncio.run()` at one top-level
  call, or use a thread pool instead.
- You need the job to **survive a process restart**: use a task queue (see
  `background-jobs`). Async work disappears if the process dies.

### Decision table

| Situation | Recommended approach |
|-----------|----------------------|
| Single HTTP call | `requests` — sync is fine |
| 10+ concurrent HTTP calls, I/O-bound | `asyncio` + `httpx.AsyncClient` |
| CPU-bound batch work | `multiprocessing.Pool` |
| Work must survive restart / retry | Task queue (RQ or Celery) |
| Scheduled periodic batch | Cron + sync Python script |
| Adding async to existing sync CLI | `asyncio.run()` at the top level only |
| Streaming large HTTP responses | `httpx` async streaming |

---

## 2. `asyncio` basics

### Core concepts

`async def` defines a **coroutine function**. Calling it returns a coroutine
object — it does not run yet. `await` suspends the current coroutine and yields
control back to the event loop, which can run other coroutines while waiting.
`asyncio.run()` creates the event loop, runs a coroutine to completion, and
tears the loop down.

```python
import asyncio

async def fetch_one(url: str) -> str:
    """Simulated async fetch — replace with real httpx call."""
    await asyncio.sleep(0.1)   # yields to event loop; other coroutines run here
    return f"result for {url}"

async def main() -> None:
    # Run two fetches concurrently — total time ~0.1s, not 0.2s.
    result_a, result_b = await asyncio.gather(
        fetch_one("https://example.com/a"),
        fetch_one("https://example.com/b"),
    )
    print(result_a, result_b)

asyncio.run(main())   # entry point — call exactly once at the top level
```

### Key rules

- `await` only works inside an `async def` function.
- `asyncio.run()` starts and owns the event loop — call it once at the top
  level, not inside a coroutine that is already running.
- The event loop is **single-threaded**: coroutines take turns. One blocking
  call (e.g. `time.sleep()`, a sync DB query) freezes everything else.

---

## 3. `httpx` async client

`httpx` is the standard async HTTP client for internal Python tools. Its API
mirrors `requests` but works with `async`/`await`.

### Install

```
httpx==0.27.2
```

### Session-style usage with `AsyncClient`

Create one `AsyncClient` per logical client, reuse it for all requests. Use
`async with` to ensure the connection pool is closed:

```python
import httpx

async with httpx.AsyncClient(timeout=30.0) as client:
    resp = await client.get("https://jira.example.com/rest/api/2/issue/PROJ-1")
    resp.raise_for_status()
    data = resp.json()
```

### Setting default headers

```python
async with httpx.AsyncClient(
    base_url="https://jira.example.com",
    headers={
        "Authorization": f"Bearer {token}",
        "Accept": "application/json",
        "Content-Type": "application/json",
    },
    timeout=30.0,
) as client:
    resp = await client.get("/rest/api/2/issue/PROJ-1")
```

### Fetch multiple Jira issues concurrently

```python
import asyncio
import httpx

async def fetch_issue(client: httpx.AsyncClient, key: str) -> dict:
    """Fetch one Jira issue; return parsed JSON or empty dict on error."""
    try:
        resp = await client.get(f"/rest/api/2/issue/{key}")
        resp.raise_for_status()
        return resp.json()
    except httpx.HTTPStatusError as exc:
        logger.warning("HTTP %s fetching %s: %s", exc.response.status_code, key, exc)
        return {}
    except httpx.RequestError as exc:
        logger.warning("Request error fetching %s: %s", key, exc)
        return {}

async def fetch_issues(keys: list[str], base_url: str, token: str) -> list[dict]:
    """Fetch all issues concurrently; returns results in input order."""
    async with httpx.AsyncClient(
        base_url=base_url,
        headers={"Authorization": f"Bearer {token}", "Accept": "application/json"},
        timeout=30.0,
    ) as client:
        return await asyncio.gather(*(fetch_issue(client, k) for k in keys))
```

---

## 4. `asyncio.gather` and `asyncio.TaskGroup`

### `asyncio.gather`

Runs a collection of coroutines concurrently and returns their results in the
same order as the inputs. If any coroutine raises, `gather` cancels the rest
and re-raises the first exception (by default).

```python
results = await asyncio.gather(coro_a(), coro_b(), coro_c())
# results[0] = return value of coro_a()
# results[1] = return value of coro_b()
# results[2] = return value of coro_c()
```

Use `return_exceptions=True` to collect exceptions as values instead of
crashing on the first failure — useful when processing a batch where some
items may fail:

```python
results = await asyncio.gather(*coroutines, return_exceptions=True)
for item, result in zip(keys, results):
    if isinstance(result, Exception):
        logger.warning("Failed %s: %s", item, result)
    else:
        process(result)
```

### `asyncio.TaskGroup` (Python 3.11+)

`TaskGroup` is safer than `gather`: when one task raises, it cancels all
remaining tasks in the group and re-raises. This avoids silent task leaks.

```python
import asyncio

async def main() -> None:
    results: list[dict] = []
    async with asyncio.TaskGroup() as tg:
        tasks = [tg.create_task(fetch_issue(client, k)) for k in keys]
    # All tasks are done here; any exception is re-raised by TaskGroup.
    results = [t.result() for t in tasks]
```

### When to use each

| Situation | Use |
|-----------|-----|
| Batch where some items may fail; continue processing rest | `gather(return_exceptions=True)` |
| Batch where any failure should abort all | `TaskGroup` (Python 3.11+) or `gather` (default) |
| Python 3.9/3.10 | `gather` — `TaskGroup` requires 3.11 |
| Need results in input order | Both (`gather` directly, `TaskGroup` via task list) |

### Limit concurrency with a semaphore

Without a concurrency limit, `gather` fires all coroutines at once. Against a
rate-limited API (Jira allows ~10 concurrent requests before returning 429),
this will trigger throttling. Always set a limit:

```python
semaphore = asyncio.Semaphore(10)   # max 10 concurrent requests

async def fetch_with_limit(client, key, sem):
    async with sem:   # blocks here if 10 are already in flight
        return await fetch_issue(client, key)

results = await asyncio.gather(
    *(fetch_with_limit(client, k, semaphore) for k in keys)
)
```

---

## 5. Semaphore for rate limiting

A semaphore is a counter that limits how many coroutines can be inside a
critical section simultaneously. The pattern below is the canonical way to
fetch a large list of URLs without overwhelming the upstream API.

### Helper pattern

```python
import asyncio
import logging
import httpx

logger = logging.getLogger(__name__)

async def _fetch_one(
    client: httpx.AsyncClient,
    url: str,
    semaphore: asyncio.Semaphore,
) -> tuple[str, str]:
    """Fetch one URL; returns (url, body) or (url, '') on error."""
    async with semaphore:
        try:
            resp = await client.get(url)
            resp.raise_for_status()
            return url, resp.text
        except httpx.HTTPStatusError as exc:
            logger.warning("HTTP %s: %s", exc.response.status_code, url)
            return url, ""
        except httpx.RequestError as exc:
            logger.warning("Request error: %s — %s", url, exc)
            return url, ""


async def fetch_all(
    urls: list[str],
    *,
    concurrency: int = 10,
    timeout: float = 30.0,
    headers: dict[str, str] | None = None,
) -> dict[str, str]:
    """Fetch all URLs concurrently; returns {url: body}.

    Args:
        urls: List of URLs to fetch.
        concurrency: Max simultaneous in-flight requests (default: 10).
        timeout: Per-request timeout in seconds (default: 30).
        headers: Optional default headers (e.g. Authorization).

    Returns:
        Dict mapping each URL to its response body, or '' on error.
    """
    semaphore = asyncio.Semaphore(concurrency)
    async with httpx.AsyncClient(
        headers=headers or {},
        timeout=timeout,
        follow_redirects=True,
    ) as client:
        pairs = await asyncio.gather(
            *(_fetch_one(client, url, semaphore) for url in urls),
            return_exceptions=False,
        )
    return dict(pairs)
```

### Calling `fetch_all` from sync code

```python
results = asyncio.run(
    fetch_all(
        urls=my_url_list,
        concurrency=10,
        headers={"Authorization": f"Bearer {token}"},
    )
)
```

---

## 6. Error handling in async code

`try`/`except` works normally inside `async def`. The key decisions are:
- **Log and continue** (use `return_exceptions=True`): one bad item should not
  stop a batch of 500.
- **Fail fast** (default `gather` or `TaskGroup`): one bad item means the whole
  operation is invalid (e.g. a critical dependency failed).

### Log and continue (batch processing)

```python
results = await asyncio.gather(*coroutines, return_exceptions=True)
successes = []
for key, result in zip(keys, results):
    if isinstance(result, BaseException):
        logger.warning("Skipping %s: %s", key, result)
    else:
        successes.append(result)
```

### Fail fast (abort on first error)

```python
# Default gather — raises on first exception, cancels the rest.
results = await asyncio.gather(*coroutines)
```

### Timeouts on individual coroutines

```python
import asyncio

try:
    result = await asyncio.wait_for(fetch_issue(client, key), timeout=15.0)
except asyncio.TimeoutError:
    logger.warning("Timeout fetching %s", key)
    result = {}
```

---

## 7. Mixing sync and async

Async and sync code cannot freely call each other. Here are the three patterns
you will need.

### Pattern 1: `asyncio.run()` at the top level

The cleanest approach: keep all async code inside one coroutine, call it from
the sync entry point.

```python
def main() -> int:
    results = asyncio.run(_async_main())
    store_results(results)
    return 0

async def _async_main() -> list[dict]:
    return await fetch_all(keys, ...)
```

### Pattern 2: run blocking sync code inside async with `run_in_executor`

When you need to call a blocking library (e.g. SQLite via `sqlite3`, a sync
requests call) from inside an async function, offload it to a thread pool. This
prevents the blocking call from freezing the event loop.

```python
import asyncio
from concurrent.futures import ThreadPoolExecutor

_executor = ThreadPoolExecutor(max_workers=4)

async def store_result_async(conn, key: str, data: dict) -> None:
    """Write to SQLite from async code without blocking the event loop."""
    loop = asyncio.get_running_loop()
    await loop.run_in_executor(_executor, _sync_store, conn, key, data)

def _sync_store(conn, key: str, data: dict) -> None:
    """Blocking SQLite write — runs in a thread, not the event loop."""
    conn.execute(
        "INSERT OR REPLACE INTO results (key, data) VALUES (?, ?)",
        (key, str(data)),
    )
    conn.commit()
```

Use `run_in_executor` sparingly. If you are doing a lot of DB work, structure
the code so all DB writes happen after the async fetch phase completes —
collect results, exit `asyncio.run()`, write sync.

### Pattern 3: `loop.run_until_complete()` for one-off calls from sync

When you are deep in a sync call stack and cannot restructure to use
`asyncio.run()` at the top, you can get the event loop and run one coroutine
to completion. This is the least clean option — use it only when refactoring
is not feasible.

```python
import asyncio

loop = asyncio.new_event_loop()
try:
    result = loop.run_until_complete(fetch_all(urls))
finally:
    loop.close()
```

Do not use `asyncio.get_event_loop()` to get a loop — it is deprecated and
behaves differently across Python versions. Always create a new loop explicitly.

---

## 8. Async with Flask

Flask's default WSGI server is synchronous. You can use async inside a Flask
app, but with constraints.

### Running async inside a sync Flask view

The simplest approach: call `asyncio.run()` inside a sync view function. This
works and is fine for internal tools where request concurrency is low.

```python
from flask import Flask, jsonify
import asyncio

app = Flask(__name__)

@app.route("/fetch-issues")
def fetch_issues_view():
    keys = request.args.getlist("key")
    results = asyncio.run(fetch_all_issues(keys, config=app.config))
    return jsonify(results)
```

Limitation: `asyncio.run()` blocks the WSGI thread for the duration of the
async operation. Under gunicorn with multiple workers, this is usually
acceptable for internal tools. Under high concurrency it will become a
bottleneck.

### Flask 2.0+ async views

Flask 2.0 supports `async def` view functions when `asgiref` is installed:

```
flask>=2.0
asgiref==3.8.1
```

```python
@app.route("/fetch-issues")
async def fetch_issues_view():
    keys = request.args.getlist("key")
    results = await fetch_all_issues(keys, config=app.config)
    return jsonify(results)
```

This still runs under a sync WSGI server — Flask wraps the async view in a
thread. True async concurrency in Flask requires an ASGI server (e.g. uvicorn).

### When to switch to FastAPI

Use FastAPI if you need native ASGI with async views running concurrently on a
single worker — for example, a service that makes many outbound calls per
request and needs low latency under load. For most internal tools, sync Flask +
`asyncio.run()` inside views is sufficient.

| Situation | Recommendation |
|-----------|----------------|
| Internal tool, low traffic, async batch in one endpoint | Sync Flask + `asyncio.run()` |
| Flask 2.0+, moderate async use | Async views with `asgiref` |
| High-concurrency service, many async outbound calls | FastAPI + uvicorn |

---

## 9. Common async mistakes

### Forgetting `await`

Calling a coroutine without `await` returns the coroutine object, not its
result. This is a silent bug — no error is raised in most cases.

```python
# WRONG — result is a coroutine object, not a dict
result = fetch_issue(client, "PROJ-1")

# RIGHT
result = await fetch_issue(client, "PROJ-1")
```

Your IDE and `mypy` will often catch this. Python 3.11+ emits a
`RuntimeWarning: coroutine 'fetch_issue' was never awaited` at runtime.

### Calling `asyncio.run()` inside a running event loop

`asyncio.run()` creates a new event loop. Calling it inside an already-running
loop (e.g. inside an async view or another coroutine) raises `RuntimeError`.

```python
# WRONG — inside an async function
async def main():
    results = asyncio.run(fetch_all(keys))   # RuntimeError

# RIGHT — await instead
async def main():
    results = await fetch_all(keys)
```

In Jupyter notebooks, the event loop is always running — use `await` directly
or use `nest_asyncio` as a workaround.

### Blocking the event loop with `time.sleep`

`time.sleep()` is synchronous. It blocks the entire event loop — no other
coroutine can run during the sleep. Use `await asyncio.sleep()` instead.

```python
import time
import asyncio

# WRONG — freezes the event loop
async def bad_backoff():
    time.sleep(2)

# RIGHT — yields to the event loop during the wait
async def good_backoff():
    await asyncio.sleep(2)
```

The same applies to any blocking call: sync DB queries, `subprocess.run()`,
`requests.get()`, heavy CPU computation. Move them to `run_in_executor` or
restructure to run after the async phase.

### Creating a Task without awaiting it

`asyncio.create_task()` schedules a coroutine as a Task. If you lose the
reference and never await it, exceptions are silently swallowed (Python logs a
`Task exception was never retrieved` warning but does not crash).

```python
# RISKY — if task raises, the exception is lost
asyncio.create_task(fire_and_forget())

# RIGHT — keep the reference and await or gather it
task = asyncio.create_task(do_work())
# ... later ...
result = await task
```

For genuine fire-and-forget, attach a done callback that logs exceptions:

```python
def _log_task_exception(task: asyncio.Task) -> None:
    if not task.cancelled() and task.exception():
        logger.error("Background task failed: %s", task.exception())

task = asyncio.create_task(background_work())
task.add_done_callback(_log_task_exception)
```

---

## 10. Practical template: concurrent Jira fetches

Copy-paste-ready function. Given a list of Jira issue keys, fetches all in
parallel with a semaphore, returns results as a dict keyed by issue key.

```python
"""jira_async.py — concurrent Jira issue fetcher.

Usage:
    results = asyncio.run(
        fetch_jira_issues(
            keys=["PROJ-1", "PROJ-2", "PROJ-3"],
            base_url="https://jira.example.com",
            token="your-pat-token",
        )
    )
    # results = {"PROJ-1": {...issue dict...}, "PROJ-2": {}, ...}
    # Empty dict means the fetch failed (logged at WARNING level).
"""
from __future__ import annotations

import asyncio
import logging
from typing import Any

import httpx

logger = logging.getLogger(__name__)

_DEFAULT_CONCURRENCY = 10   # Jira allows ~10 before throttling
_DEFAULT_TIMEOUT = 30.0     # seconds


async def _fetch_one_issue(
    client: httpx.AsyncClient,
    key: str,
    semaphore: asyncio.Semaphore,
) -> tuple[str, dict[str, Any]]:
    """Fetch one Jira issue; returns (key, issue_dict) or (key, {}) on error."""
    async with semaphore:
        try:
            resp = await client.get(f"/rest/api/2/issue/{key}")
            resp.raise_for_status()
            return key, resp.json()
        except httpx.HTTPStatusError as exc:
            logger.warning(
                "HTTP %s fetching %s: %s",
                exc.response.status_code,
                key,
                exc.response.text[:200],
            )
            return key, {}
        except httpx.RequestError as exc:
            logger.warning("Request error fetching %s: %s", key, exc)
            return key, {}


async def fetch_jira_issues(
    keys: list[str],
    base_url: str,
    token: str,
    *,
    concurrency: int = _DEFAULT_CONCURRENCY,
    timeout: float = _DEFAULT_TIMEOUT,
    fields: str = "*all",
) -> dict[str, dict[str, Any]]:
    """Fetch multiple Jira issues concurrently.

    Args:
        keys: List of Jira issue keys, e.g. ["PROJ-1", "PROJ-2"].
        base_url: Jira base URL, e.g. "https://jira.example.com".
        token: Jira personal access token (PAT).
        concurrency: Max simultaneous in-flight requests. Default: 10.
        timeout: Per-request timeout in seconds. Default: 30.
        fields: Comma-separated Jira fields to return. Default: "*all".

    Returns:
        Dict mapping each issue key to its parsed JSON response.
        Keys that failed to fetch map to an empty dict {}.

    Example:
        results = asyncio.run(
            fetch_jira_issues(
                keys=["PROJ-1", "PROJ-2"],
                base_url="https://jira.example.com",
                token=config["jira"]["token"],
            )
        )
        for key, issue in results.items():
            if not issue:
                logger.warning("Could not fetch %s", key)
                continue
            summary = issue["fields"]["summary"]
    """
    if not keys:
        return {}

    semaphore = asyncio.Semaphore(concurrency)
    async with httpx.AsyncClient(
        base_url=base_url.rstrip("/"),
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/json",
        },
        params={"fields": fields},
        timeout=timeout,
        follow_redirects=True,
    ) as client:
        pairs = await asyncio.gather(
            *(_fetch_one_issue(client, key, semaphore) for key in keys),
            return_exceptions=False,
        )

    return dict(pairs)


# --- Sync wrapper for callers that cannot use asyncio.run() directly ---

def fetch_jira_issues_sync(
    keys: list[str],
    base_url: str,
    token: str,
    *,
    concurrency: int = _DEFAULT_CONCURRENCY,
    timeout: float = _DEFAULT_TIMEOUT,
) -> dict[str, dict[str, Any]]:
    """Synchronous wrapper around fetch_jira_issues.

    Use this from sync code (Flask views, scripts, pytest).
    Do NOT call from inside a running event loop — use await instead.
    """
    return asyncio.run(
        fetch_jira_issues(
            keys,
            base_url,
            token,
            concurrency=concurrency,
            timeout=timeout,
        )
    )
```

### Testing the template

```python
# tests/test_jira_async.py
import asyncio
import pytest
import httpx
import respx   # pip install respx — mocks httpx at the transport layer

from jira_async import fetch_jira_issues


@pytest.mark.anyio   # pip install anyio[asyncio] pytest-anyio
async def test_fetch_returns_issue_data():
    keys = ["PROJ-1", "PROJ-2"]
    with respx.mock(base_url="https://jira.example.com") as mock:
        mock.get("/rest/api/2/issue/PROJ-1").respond(
            200, json={"key": "PROJ-1", "fields": {"summary": "First"}}
        )
        mock.get("/rest/api/2/issue/PROJ-2").respond(
            200, json={"key": "PROJ-2", "fields": {"summary": "Second"}}
        )
        results = await fetch_jira_issues(
            keys, base_url="https://jira.example.com", token="fake-token"
        )

    assert results["PROJ-1"]["fields"]["summary"] == "First"
    assert results["PROJ-2"]["fields"]["summary"] == "Second"


@pytest.mark.anyio
async def test_fetch_returns_empty_dict_on_404():
    with respx.mock(base_url="https://jira.example.com") as mock:
        mock.get("/rest/api/2/issue/PROJ-99").respond(404)
        results = await fetch_jira_issues(
            ["PROJ-99"], base_url="https://jira.example.com", token="fake-token"
        )

    assert results["PROJ-99"] == {}


def test_sync_wrapper_works():
    """Test the sync wrapper using respx in sync context."""
    with respx.mock(base_url="https://jira.example.com"):
        respx.get("https://jira.example.com/rest/api/2/issue/PROJ-1").respond(
            200, json={"key": "PROJ-1", "fields": {"summary": "Test"}}
        )
        from jira_async import fetch_jira_issues_sync
        results = fetch_jira_issues_sync(
            ["PROJ-1"], base_url="https://jira.example.com", token="fake-token"
        )
    assert results["PROJ-1"]["fields"]["summary"] == "Test"
```

### Install requirements

```
# requirements.txt
httpx==0.27.2

# requirements-dev.txt
anyio==4.4.0
pytest-anyio==0.0.0   # or anyio[trio] for trio backend
respx==0.21.1
```

---

## Quick reference

```
Decision:
  Single HTTP call                      → requests (sync is fine)
  Many concurrent I/O calls             → asyncio + httpx.AsyncClient
  CPU-bound work                        → multiprocessing
  Work that must survive process death  → task queue (RQ / Celery)

Entry point:
  asyncio.run(main())                   # call once at top level

Concurrency:
  asyncio.gather(*coroutines)           # run concurrently, results in order
  asyncio.gather(..., return_exceptions=True)  # don't crash on first failure
  asyncio.TaskGroup() (3.11+)           # safer: cancels all if one fails
  asyncio.Semaphore(10)                 # limit concurrent in-flight requests

HTTP:
  httpx.AsyncClient(base_url=..., headers=..., timeout=30.0)
  async with client: resp = await client.get(path)

Blocking sync inside async:
  loop.run_in_executor(executor, sync_fn, *args)

Common mistakes:
  Forgot await        → coroutine object returned, not value
  asyncio.run() in loop → RuntimeError: use await instead
  time.sleep()        → blocks event loop; use await asyncio.sleep()
  Lost task reference → exceptions silently swallowed

Test mocking:
  respx.mock()        → mock httpx at transport layer (no real HTTP)
```

## Related

- **Python project layout, config, venv, pytest:** [`python-scripts-and-services`](../python-scripts-and-services/SKILL.md)
- **Background workers and task queues (asyncio ↔ RQ/Celery):** [`background-jobs`](../background-jobs/SKILL.md)
- **HTTP client reliability, retries, 429/5xx, backoff:** [`python-scripts-and-services / http-clients-reliability.md`](../python-scripts-and-services/http-clients-reliability.md)
- **Debugging async code, tracebacks, profiling:** [`debugging-profiling`](../debugging-profiling/SKILL.md)
- **Observability for async services (RED metrics, structured logs):** [`observability`](../observability/SKILL.md)
- **Routing:** [`../../SKILLS.md`](../../SKILLS.md)
