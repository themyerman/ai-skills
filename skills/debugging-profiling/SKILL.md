---
name: debugging-profiling
description: >-
  Debug Python code, set breakpoints with pdb, read tracebacks, profile CPU with
  cProfile or line_profiler, profile memory with tracemalloc, debug HTTP clients and
  SQLite queries, find common Python bugs (mutable defaults, late binding, None identity),
  optimize hot loops and performance bottlenecks, understand why code is slow, snakeviz
  visualization, kernprof, PYTHONBREAKPOINT, correlation IDs in logs.
---

# debugging-profiling

## What this is

A reference for diagnosing and fixing problems in Python internal tools and services. Covers interactive debugging with `pdb`, targeted logging, traceback interpretation, CPU and memory profiling, HTTP and SQLite inspection, and a catalog of common Python bugs with minimal reproducers.

**Related skills:** `python-scripts-and-services`, `python-scripts-and-services/logging-structured.md`, `observability`.

---

## 1. `breakpoint()` and pdb

`breakpoint()` (Python 3.7+) drops into the pdb debugger at any line. Insert it anywhere in your code and run the script normally.

```python
def process_issue(key: str, data: dict) -> dict:
    breakpoint()   # execution pauses here; inspect key, data, locals
    result = transform(data)
    return result
```

### Key pdb commands

| Command | What it does |
|---|---|
| `n` | Next line (step over function calls) |
| `s` | Step into the next function call |
| `c` | Continue until the next breakpoint or end |
| `p expr` | Print the value of an expression |
| `pp expr` | Pretty-print (useful for dicts and lists) |
| `l` | List the surrounding source lines |
| `w` | Where — print the full call stack |
| `b lineno` | Set a breakpoint at a line number in the current file |
| `b file.py:42` | Set a breakpoint in another file |
| `q` | Quit the debugger (raises `BdbQuit`) |
| `u` / `d` | Move up / down the call stack |
| `h` | Help |

### Conditional breakpoints

Break only when a condition is true — useful when you need to catch a specific iteration:

```python
# In code
breakpoint()   # then at the pdb prompt:
# (Pdb) b src/jira_client.py:88, status_code == 429
```

Or set it in source directly using `pdb.set_trace()` with a condition:

```python
import pdb
if key == "PROJ-9999":
    pdb.set_trace()
```

### Disabling breakpoints in production

Set the environment variable to skip all `breakpoint()` calls without touching code:

```bash
PYTHONBREAKPOINT=0 python main.py --bulk
```

Set `PYTHONBREAKPOINT=0` in any production environment's shell profile or systemd unit file so a stray `breakpoint()` call never halts a prod process.

---

## 2. Logging for debugging

### Temporarily raise the log level

```python
import logging

# Quick CLI debugging — add to the top of main() or the entry script
logging.basicConfig(level=logging.DEBUG)
```

For selective module-level debugging without flooding everything:

```python
logging.getLogger("src.jira_client").setLevel(logging.DEBUG)
```

### Use `%r` format strings, not f-strings

```python
# WRONG — f-string evaluated immediately, even if the log level filters it out
logger.debug(f"response body: {body}")

# RIGHT — lazy evaluation; body is only formatted if DEBUG is active
logger.debug("response body: %r", body)
```

`%r` (repr) is especially useful because it shows the exact type and escapes special characters, making it clear if a string contains a newline, null byte, or unexpected whitespace.

### Add correlation IDs to trace a request end-to-end

When a single logical operation touches multiple modules or makes multiple API calls, a correlation ID ties all the log lines together:

```python
import uuid

def process_batch(keys: list[str]) -> None:
    run_id = uuid.uuid4().hex[:8]
    logger.info("batch start run_id=%s keys=%d", run_id, len(keys))
    for key in keys:
        logger.debug("run_id=%s processing key=%s", run_id, key)
        _process_one(key, run_id=run_id)
    logger.info("batch complete run_id=%s", run_id)
```

Then in the shell: `grep run_id=3a7f9c2b app.log` shows the full lifecycle of that run.

### When to use logging vs breakpoints

| Situation | Use |
|---|---|
| Intermittent bug you can't reproduce reliably | Logging — add debug lines and let it run |
| Bug you can reproduce on demand | `breakpoint()` — inspect state interactively |
| Production issue (no interactive terminal) | Logging only; never ship `breakpoint()` |
| Understanding control flow through many modules | Logging with correlation ID |
| Narrowing to a specific expression or variable | `breakpoint()` + `pp expr` |
| Failure only on specific input | Conditional breakpoint |

---

## 3. Reading tracebacks

### Read from the bottom up

Python tracebacks show the call chain from outermost frame (top) to the failing line (bottom). The error message and the relevant line are at the bottom.

```
Traceback (most recent call last):
  File "main.py", line 42, in <module>
    main()
  File "main.py", line 31, in main
    results = run_query(conn, jql)
  File "src/db.py", line 88, in run_query       ← your code
    rows = conn.execute(sql, params).fetchall()
  File "/usr/lib/python3.11/sqlite3/dbapi2.py", line 22, in execute
    ...                                          ← library frame; skip it
sqlite3.OperationalError: no such table: issues  ← read this first
```

Workflow: read the error type and message first, then scan up the stack for the first frame in YOUR code (`src/`, `scripts/`, your package). That is almost always where the fix lives.

### Skip library frames

Frames from the standard library or third-party packages (paths containing `site-packages`, `/usr/lib`, `.venv`) are usually not your bug. Focus on frames in your own code.

### Chained exceptions: `__cause__` vs `__context__`

When you see "During handling of the above exception, another exception occurred" or "The above exception was the direct cause", Python is showing a chained exception:

```python
# __cause__: explicit chain with "raise X from Y" — intentional
try:
    result = conn.execute(sql)
except sqlite3.OperationalError as e:
    raise RuntimeError("DB query failed — check schema migration") from e

# __context__: implicit chain — a second exception raised inside an except block
try:
    result = conn.execute(sql)
except sqlite3.OperationalError:
    log_failure()   # if this raises, Python shows both exceptions
```

In both cases, read the *last* exception first. The earlier one is context — it explains how you got there.

### Reproducing in isolation

Paste the failing line and its local variables into a Python REPL to test without the full stack:

```python
# From the traceback: conn.execute(sql, params) failed
# Reproduce:
import sqlite3
conn = sqlite3.connect(":memory:")
conn.execute("CREATE TABLE runs (id INTEGER PRIMARY KEY)")
sql = "SELECT * FROM issues WHERE run_id = ?"
params = (1,)
conn.execute(sql, params)   # reproduces: no such table: issues
```

This confirms the problem and lets you iterate quickly.

---

## 4. `cProfile` — CPU profiling

### Measure first; optimize second

"It's slow" is not actionable. Profile first to find out *where* time is actually spent. Optimizing the wrong function wastes time and adds complexity.

### Running cProfile

```bash
python -m cProfile -s cumtime scripts/run_triage.py --scout PROJ-1234
```

Flags:
- `-s cumtime` — sort by cumulative time (total time in a function including its callees). Usually the most useful sort for finding bottlenecks.
- `-s tottime` — sort by time spent *inside* the function only (excluding callees). Use this to find functions with expensive inline code.
- `-o profile.out` — write binary output for later analysis with `pstats`.

### Reading cProfile output

```
   ncalls  tottime  percall  cumtime  percall filename:lineno(function)
    12000    4.321    0.000    4.321    0.000 {method 'execute' of 'sqlite3.Connection'}
        1    0.003    0.003    8.742    8.742 src/scorer.py:44(score_run)
      120    0.001    0.000    4.318    0.036 src/scorer.py:91(_score_one_issue)
```

- `ncalls` — how many times the function was called
- `tottime` — time inside this function, not counting calls to other functions
- `cumtime` — total time including callees
- `percall` (first) — tottime / ncalls
- `percall` (second) — cumtime / ncalls

In this example, `score_run` is called once and takes 8.7 s total. Most of that is inside `_score_one_issue` (called 120 times), which spends almost all its time in `sqlite3.Connection.execute`. The hot path is: 120 issues × 1 DB query each. Fix: batch the query.

### Filtering with `pstats`

```python
import pstats
p = pstats.Stats("profile.out")
p.sort_stats("cumtime")
p.print_stats(20)                    # top 20 functions
p.print_stats("src/scorer")         # only lines matching this pattern
```

### Visualizing with snakeviz

```bash
pip install snakeviz
python -m cProfile -o profile.out scripts/run_triage.py
snakeviz profile.out                 # opens a browser flame chart
```

snakeviz makes it easy to see at a glance which call subtrees consume most time.

---

## 5. `line_profiler` — line-by-line CPU timing

Use `line_profiler` when cProfile tells you a function is slow but you need to know *which line* inside it is the problem.

### Install

```bash
pip install line_profiler
```

Add to `requirements-dev.txt`, not `requirements.txt`.

### Usage

Decorate the function you want to inspect:

```python
@profile   # added only for profiling; remove before committing
def _score_one_issue(conn: DbConnection, issue_id: int, rules: list[dict]) -> int:
    text = conn.execute("SELECT body FROM issues WHERE id = ?", (issue_id,)).fetchone()[0]
    hits = []
    for rule in rules:
        if re.search(rule["pattern"], text):
            hits.append(rule)
    return len(hits)
```

Run with `kernprof`:

```bash
kernprof -l -v scripts/run_triage.py --scout PROJ-1234
```

Output shows time per line:

```
Line #  Hits    Time  Per Hit  % Time  Line Contents
     5   120   2.1e4    175.0    42.1  text = conn.execute(...).fetchone()[0]
     7   120   1.3e3     10.8     2.6  hits = []
     8  3600   2.8e4      7.7    55.3  if re.search(rule["pattern"], text):
```

The `re.search` loop accounts for 55% of time. Fix: pre-compile patterns once at startup with `re.compile()`.

---

## 6. Memory profiling

### `tracemalloc` (stdlib — no install needed)

```python
import tracemalloc

tracemalloc.start()

# ... run the code you want to measure ...
load_all_jira_issues(conn)

snapshot = tracemalloc.take_snapshot()
top_stats = snapshot.statistics("lineno")

print("Top 10 memory allocations:")
for stat in top_stats[:10]:
    print(stat)
```

Compare two snapshots to find what grew:

```python
tracemalloc.start()
snap1 = tracemalloc.take_snapshot()

process_batch(keys)   # the operation under test

snap2 = tracemalloc.take_snapshot()
top_stats = snap2.compare_to(snap1, "lineno")
for stat in top_stats[:5]:
    print(stat)
```

### `memory_profiler` — line-by-line memory

```bash
pip install memory_profiler
```

```python
from memory_profiler import profile

@profile
def load_all_issues(conn: DbConnection) -> list[dict]:
    rows = conn.execute("SELECT * FROM issues").fetchall()   # ← allocates all at once
    return [dict(row) for row in rows]
```

```bash
python -m memory_profiler scripts/run_triage.py
```

### Common causes of memory bloat in internal tools

| Cause | Symptom | Fix |
|---|---|---|
| `fetchall()` on a large result set | Memory spikes once, stays high | Use `fetchmany(chunk)` or iterate cursor |
| Keeping a `requests.Session` open with response content | Gradual growth over many requests | Call `response.close()` or use `with session.get(url) as r:` |
| Unbounded in-memory cache (`dict` that only grows) | Linear growth with number of items processed | Use `functools.lru_cache(maxsize=512)` or `cachetools.TTLCache` |
| Storing full API response bodies in a list | Single spike proportional to response size | Truncate to `[:10_000]` before storing (see §4 in CLAUDE.md) |
| Circular references preventing garbage collection | Memory never reclaimed | Use `weakref` or restructure ownership |

---

## 7. Debugging HTTP clients

### Log requests and responses with a `requests` event hook

```python
import logging
import requests

logger = logging.getLogger(__name__)

def _log_request(r: requests.Response, *args: object, **kwargs: object) -> None:
    logger.debug(
        "HTTP %s %s -> %d (%d bytes)",
        r.request.method,
        r.request.url,
        r.status_code,
        len(r.content),
    )

session = requests.Session()
session.hooks["response"].append(_log_request)
```

### Inspect what was actually sent

```python
resp = session.get("https://jira.example.com/rest/api/2/issue/PROJ-1")

# See the exact request that was sent (headers, URL, body)
req = resp.request
print(req.method, req.url)
print(dict(req.headers))
print(req.body)
```

This is essential for debugging auth failures — it confirms whether the `Authorization` header was actually set.

### Replay captured traffic with `responses`

```bash
pip install responses
```

```python
import responses as rsps
import requests

@rsps.activate
def test_fetch_issue_retries_on_429() -> None:
    rsps.add(rsps.GET, "https://jira.example.com/rest/api/2/issue/PROJ-1",
             status=429, headers={"Retry-After": "1"})
    rsps.add(rsps.GET, "https://jira.example.com/rest/api/2/issue/PROJ-1",
             json={"key": "PROJ-1", "fields": {}}, status=200)

    result = fetch_issue_with_retry("PROJ-1")
    assert result["key"] == "PROJ-1"
    assert len(rsps.calls) == 2   # confirmed it retried
```

### curl equivalent in Python

```python
# Equivalent to: curl -v -H "Authorization: Bearer TOKEN" URL
import subprocess
result = subprocess.run(
    ["curl", "-v", "-H", f"Authorization: Bearer {token}", url],
    capture_output=True, text=True
)
print(result.stderr)   # curl sends verbose output to stderr
```

Use this to rule out Python client issues when an endpoint works in curl but not in your code.

---

## 8. Debugging SQLite

### Log every query

```python
import sqlite3

conn = sqlite3.connect("myapp.db")
conn.set_trace_callback(print)   # prints every SQL statement to stdout
```

For more selective logging, route to the module logger:

```python
conn.set_trace_callback(lambda sql: logger.debug("SQL: %s", sql.strip()))
```

Remove or gate behind `logger.isEnabledFor(logging.DEBUG)` before committing.

### Inspect schema live

```python
# List all tables
conn.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall()

# Inspect columns of a specific table
conn.execute("PRAGMA table_info(issues)").fetchall()
# Returns: [(cid, name, type, notnull, default_value, pk), ...]

# Check indexes on a table
conn.execute("PRAGMA index_list(issues)").fetchall()
```

### Check query plans for slow queries

```python
plan = conn.execute(
    "EXPLAIN QUERY PLAN SELECT * FROM issues WHERE run_id = ? AND status = ?",
    (run_id, "open")
).fetchall()
for row in plan:
    print(row)
# "SCAN TABLE issues" → no index, full table scan → add an index
# "SEARCH TABLE issues USING INDEX ..." → index in use, fast
```

If you see `SCAN TABLE` on a large table, add an index:

```python
conn.execute("CREATE INDEX IF NOT EXISTS idx_issues_run_id ON issues(run_id)")
```

---

## 9. Common Python bugs and how to find them

Each entry shows the bug, why it happens, and a minimal REPL reproducer.

### Mutable default argument

```python
# BUG
def append_item(item, collection=[]):
    collection.append(item)
    return collection

append_item("a")   # ["a"]
append_item("b")   # ["a", "b"]  ← not a fresh list!
```

The default `[]` is created once at function definition time and reused across calls.

```python
# FIX
def append_item(item, collection=None):
    if collection is None:
        collection = []
    collection.append(item)
    return collection
```

### Late binding in closures

```python
# BUG
fns = [lambda: i for i in range(3)]
[f() for f in fns]   # [2, 2, 2] — all return the final value of i

# FIX — capture the value at creation time with a default argument
fns = [lambda i=i: i for i in range(3)]
[f() for f in fns]   # [0, 1, 2]
```

### `==` vs `is` for None

```python
# BUG — works accidentally most of the time but is semantically wrong
if result == None:
    ...

# Correct — None is a singleton; always use identity comparison
if result is None:
    ...
if result is not None:
    ...
```

`== None` can give surprising results if an object defines `__eq__`; `is None` never lies.

### Silent integer / float division

```python
# Python 3 does true division, but this still bites people who come from Python 2
# or who copy-paste old code
total = 7
count = 2

ratio = total / count    # 3.5  ← float in Python 3 (usually what you want)
ratio = total // count   # 3    ← integer floor division (silent data loss if unexpected)

# To deliberately floor-divide and make it obvious:
ratio = total // count
assert isinstance(ratio, int)
```

### Mutating a dict while iterating over it

```python
d = {"a": 1, "b": 2, "c": 3}

# BUG — raises RuntimeError: dictionary changed size during iteration
for key in d:
    if d[key] < 2:
        del d[key]

# FIX — iterate over a copy of the keys
for key in list(d.keys()):
    if d[key] < 2:
        del d[key]
```

### Datetime timezone naivety

```python
from datetime import datetime

# BUG — naive datetime; comparison with timezone-aware datetime raises TypeError
created = datetime(2024, 1, 15, 10, 0, 0)

from datetime import timezone
now = datetime.now(tz=timezone.utc)

created < now   # TypeError: can't compare offset-naive and offset-aware datetimes

# FIX — always use timezone-aware datetimes at system boundaries
from datetime import datetime, timezone
created = datetime(2024, 1, 15, 10, 0, 0, tzinfo=timezone.utc)
created < now   # True — works correctly
```

Best practice: parse all timestamps from APIs with `datetime.fromisoformat()` (Python 3.11+) or `dateutil.parser.parse()` with `tzinfo` attached; store and compare in UTC throughout.

---

## 10. Performance quick wins

Apply these only after profiling confirms the location. Do not preemptively optimize.

### `frozenset` for membership tests in loops

```python
# SLOW — list membership test is O(n)
SKIP_TYPES = ["miro", "google_docs", "repo", "confluence", "drive"]
if url_type in SKIP_TYPES:   # scans the list every call
    ...

# FAST — frozenset membership test is O(1)
_SKIP_TYPES = frozenset({"miro", "google_docs", "repo", "confluence", "drive"})
if url_type in _SKIP_TYPES:
    ...
```

### Cache repeated attribute or method lookups in tight loops

```python
# SLOW — Python resolves re.search on every iteration
for pattern in patterns:
    if re.search(pattern, text):
        ...

# FAST — bind the name once
_search = re.search
for pattern in patterns:
    if _search(pattern, text):
        ...

# BETTER — pre-compile patterns at module load time (also removes repeated compilation)
_COMPILED = [re.compile(p) for p in RAW_PATTERNS]
for rx in _COMPILED:
    if rx.search(text):
        ...
```

### `defaultdict` over guard-and-set

```python
from collections import defaultdict

# SLOW (and verbose)
counts = {}
for item in items:
    if item.status not in counts:
        counts[item.status] = 0
    counts[item.status] += 1

# FAST (and clear)
counts = defaultdict(int)
for item in items:
    counts[item.status] += 1
```

### Generator expressions when you don't need the full list

```python
# Builds the entire list in memory before sum() sees it
total = sum([score for score in scores if score > 0])

# Generator — values are produced one at a time; no intermediate list
total = sum(score for score in scores if score > 0)
```

Only matters when the sequence is large; for small lists the difference is negligible.

### `str.join()` for string concatenation in loops

```python
# SLOW — creates a new string object on every iteration: O(n²)
result = ""
for line in lines:
    result += line + "\n"

# FAST — single allocation at the end: O(n)
result = "\n".join(lines) + "\n"
```

## Related

- **Python project layout, config, venv, pytest:** [`python-scripts-and-services`](../python-scripts-and-services/SKILL.md)
- **Async code: event loop hangs, coroutine tracing:** [`async-python`](../async-python/SKILL.md)
- **Observability: structured logs and metrics to narrow where to look:** [`observability`](../observability/SKILL.md)
- **Incident triage in production:** [`incident-response`](../incident-response/SKILL.md)
- **Routing:** [`../../SKILLS.md`](../../SKILLS.md)
