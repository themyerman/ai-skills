<!-- Sourced from ai-skills/.claude/CLAUDE.md — §1–3 + §6–8 here; Jira, security, docs, LLM in linked files. -->

# Developer Guide: Writing Production-Quality Python with Claude

Single-file canonical: **[`../../.claude/CLAUDE.md`](../../.claude/CLAUDE.md)**. This file keeps **§1–3, 6–8** (project structure through code style). Splits: **[jira.md](jira.md)** (Jira, JQL, CLI in Jira-centred tools), **[security.md](security.md)** (APIs, credentials, threat thinking), **[documentation.md](documentation.md)** (README, `WORK.md`, `docs/`, and related). **LLM (§9):** **[llm-integrations-safety/](../llm-integrations-safety/SKILL.md)**.

---

## Optional addendum: service with `src/`, web UI, and LLM (illustrative layout)

*Example: see **`.claude/CLAUDE.md`** in this repo. LLM and anomaly code for §9 is often in **`src/anomaly.py`**, with config and storage wired in one pipeline—**your** module names and paths may differ; the **patterns** in the canonical guide are what matter.*

---

## 1. Project Structure

Organize code so each concern lives in exactly one place.

```
src/           # Business logic only. No Flask, no argparse.
scripts/       # CLI entry points that wire together src modules.
app/           # Web layer (Flask, FastAPI). Imports from src.
tests/         # One test file per src module.
config/        # Only when the project has multiple config files.
docs/          # Longer design notes, ADRs, analysis.
```

Rules:
- `src/` modules do not import from `app/` or `scripts/`.
- CLI scripts (`scripts/`) are thin wrappers — they parse args, wire deps, then call `src/`.
- Never put credentials, environment-specific paths, or hardcoded URLs in `src/`.

---

## 2. Configuration

### Config location rule

- **Single config file** → keep it at the project root (`config.yaml`, `config.example.yaml`).
- **Multiple config files** → use a `config/` subdirectory (`config/config.yaml`, `config/queries.yaml`, `config/llm_prompt_review.yaml`, etc.).

Don't put a lone `config.yaml` inside a `config/` directory — that adds a folder with no benefit.

### Always provide an example config

`config.example.yaml` is committed. The real `config.yaml` is gitignored. The example has every key, commented out where optional, with a description of what each value is for:

```yaml
jira:
  base_url: "https://your-domain.atlassian.net"
  token: "your-api-token-here"   # Generate at Account Settings > Security > API tokens
  # username: "you@example.com"  # Only needed for Basic auth (Data Center)

# Optional: GitHub Enterprise token for fetching linked file content.
# ghe:
#   token: "your-ghe-token"
```

The real `config.yaml` is always in `.gitignore`. Check this before the first commit.

### Load config once, pass it as a dict

Don't call `load_config()` inside library functions. Load once in the entry point and pass `config: dict` down:

```python
# In script:
full_config = load_config()
run_query(..., config=full_config)

# In library:
def run_query(..., config: dict) -> ...:
    jira_cfg = config.get("jira") or {}
    ...
```

This makes library functions testable without touching the filesystem.

### Validate config at startup — fail fast

Check all required config values immediately when the process starts, before doing any real work. A missing token should crash with a clear error at second 0, not at minute 10 when the first API call fails:

```python
def get_jira_config(config: dict) -> dict:
    jira = config.get("jira") or {}
    if not jira.get("base_url"):
        raise ValueError("config.yaml: jira.base_url is required")
    if not jira.get("token"):
        raise ValueError("config.yaml: jira.token is required")
    return jira
```

Call these validators at the top of `main()`, before any I/O.

---

## 3. Dependency Management

### Use a virtual environment — always

Never install packages into your system Python. One venv per project:

```bash
python3 -m venv .venv
source .venv/bin/activate   # or .venv\Scripts\activate on Windows
pip install -r requirements.txt
```

Add `.venv/` to `.gitignore`.

### Pin versions in requirements.txt

Unpinned dependencies (`requests`) break silently when upstream releases a breaking change. Pin everything:

```
requests==2.32.3
PyYAML==6.0.2
anthropic==0.40.0
```

Use `pip freeze > requirements.txt` after installing, then trim to only direct dependencies. For packages that are only needed in development, use a separate `requirements-dev.txt`:

```
pytest==8.3.3
ruff==0.8.4
mypy==1.13.0
```

### pyproject.toml vs requirements.txt

- **Installable packages / libraries** → `pyproject.toml` (use `hatchling` or `setuptools`)
- **Scripts and internal tools** → `requirements.txt` is fine

Don't mix both in the same project without a reason.

### Standard .gitignore patterns

Every Python project needs at minimum:

```
# Config with secrets
config.yaml
.env

# Python artifacts
__pycache__/
*.py[cod]
*.egg-info/
dist/
build/

# Virtual environment
.venv/
venv/

# Runtime output
logs/
*.log
```

### Use ruff for linting and formatting

`ruff` replaces flake8, isort, and black in one fast tool. Add to `requirements-dev.txt` and run before committing:

```bash
ruff check .          # lint
ruff format .         # format (replaces black)
ruff check --fix .    # auto-fix safe issues
```

Minimal `pyproject.toml` config:

```toml
[tool.ruff]
line-length = 100

[tool.ruff.lint]
select = ["E", "F", "I", "UP"]   # pycodestyle, pyflakes, isort, pyupgrade
```

### Import ordering

Follow the standard three-group order, separated by blank lines. `ruff` enforces this automatically:

```python
# 1. Standard library
import json
import logging
from pathlib import Path

# 2. Third-party
import requests
import yaml

# 3. Local
from .config import load_config
from .jira_client import JiraClient
```

## 6. Database Patterns

### Support multiple backends from the start

Abstract the differences between SQLite, PostgreSQL, and MySQL into one place. Expose `conn.backend` and write two code paths only where needed:

```python
def _replace_into_sql(conn: DbConnection) -> str:
    if conn.backend == "mysql":
        return "REPLACE INTO"
    return "INSERT OR REPLACE INTO"   # SQLite
```

For PostgreSQL upserts, use `ON CONFLICT ... DO UPDATE`. For SQLite, use `INSERT OR REPLACE`. Never scatter `if backend == "sqlite"` checks throughout every function.

### Write migrations, not drop-and-recreate

When adding columns to existing tables, use `ALTER TABLE ... ADD COLUMN`. Check first:

```python
cur = conn.execute("PRAGMA table_info(runs)")
columns = [row[1] for row in cur.fetchall()]
if "scorer_version" not in columns:
    conn.execute(
        "ALTER TABLE runs ADD COLUMN scorer_version TEXT NOT NULL DEFAULT 'rules_suggester'"
    )
    conn.commit()
```

`CREATE TABLE IF NOT EXISTS` + migrations = safe to run on existing databases without data loss.

### Delete in dependency order

When cascade deletes aren't guaranteed (SQLite without FK enforcement), delete child rows first:

```python
conn.execute("DELETE FROM score_hits WHERE score_id IN (SELECT id FROM scores WHERE run_id = %s)", (run_id,))
conn.execute("DELETE FROM scores WHERE run_id = %s", (run_id,))
conn.execute("DELETE FROM issues WHERE run_id = %s", (run_id,))
conn.execute("DELETE FROM runs WHERE id = %s", (run_id,))
```

---

## 7. Testing Philosophy
**Repos without a local app database** (e.g. a **Jira-only** tool) usually mock Jira over HTTP; there is no SQLite. If you add SQLite or another store later, the `tmp_path` SQLite guidance below still applies.

### Use real databases in tests

Avoid mocking databases. Use `tmp_path` (pytest built-in) for throwaway SQLite files:

```python
def test_insert_run_returns_run_id(self, tmp_path: Path) -> None:
    conn = init_db(tmp_path / "test.db")
    run_id = insert_run(conn, "all_in_triage", "project = X", 10)
    conn.close()
    assert isinstance(run_id, int)
    assert run_id >= 1
```

Mock databases let mocked tests pass while real migrations break. SQLite is fast enough to use for every test.

### Test idempotency explicitly

If your init function claims to be idempotent, prove it:

```python
def test_init_db_idempotent_does_not_drop_data(self, tmp_path: Path) -> None:
    conn = init_db(db_path)
    run_id = insert_run(conn, "q", "jql", 1)
    conn.commit()
    conn.close()
    conn2 = init_db(db_path)   # second init on same file
    row = conn2.execute("SELECT id FROM runs WHERE id = ?", (run_id,)).fetchone()
    assert row is not None     # data survived
```

### Test edge cases at input boundaries

For every function that accepts user input:

```python
def test_rejects_empty(self) -> None:
    with pytest.raises(ValueError, match="non-empty"):
        validate_query_name("")

def test_rejects_invalid_characters(self) -> None:
    with pytest.raises(ValueError, match="only letters"):
        validate_query_name("../etc/passwd")   # path traversal
    with pytest.raises(ValueError, match="only letters"):
        validate_query_name("query\x00injection")   # null byte

def test_rejects_non_string(self) -> None:
    with pytest.raises(ValueError):
        validate_query_name(None)
```

Test: empty string, whitespace-only, None, wrong type, too long, invalid characters, boundary values.

### Group tests in classes with docstrings

Pytest classes don't need `__init__`. Use them to group tests by function under test:

```python
class TestInsertRun:
    """Tests for insert_run()."""

    def test_returns_run_id(self, tmp_path: Path) -> None: ...
    def test_persists_scorer_version(self, tmp_path: Path) -> None: ...
    def test_default_scorer_version(self, tmp_path: Path) -> None: ...
```

### Use fixtures for shared test state

Don't inline complex setup in every test. Use `@pytest.fixture`:

```python
@pytest.fixture
def rules_pmp1(tmp_path: Path) -> Path:
    """Rules with points_per_match: 1 and fixed weights for deterministic score assertions."""
    rules = yaml.safe_load(RULES_PATH.read_text()) or {}
    rules["points_per_match"] = 1
    out = tmp_path / "rules.yaml"
    out.write_text(yaml.dump(rules))
    return out
```

### Test the negative path

Test that things that should NOT happen, don't:

```python
def test_score_run_non_rules_suggester_returns_zero(self, tmp_path: Path) -> None:
    """When scorer_version is llm_calc but no llm_client is provided, score nothing."""
    n = score_run(conn, run_id)   # no llm_client passed
    assert n == 0
    assert len(conn.execute("SELECT id FROM scores WHERE run_id = ?", (run_id,)).fetchall()) == 0
```

### Use mock objects for external APIs, not for databases

Mocking is appropriate for:
- External HTTP calls (use `unittest.mock.patch` on `requests.Session`)
- LLM API calls (provide a `mock_llm_client()` factory in the module itself)

Never mock: the database, the filesystem, or your own module functions.

---

## 8. Code Style

### Module-level docstrings and loggers

Every module should start with:

```python
"""One-line description of what this module does.

Longer description if needed: what it supports, what it skips, any important caveats.
"""

from __future__ import annotations
import logging

logger = logging.getLogger(__name__)
```

`logging.getLogger(__name__)` gives each module its own named logger, making log output easy to trace.

### Annotate all function signatures

Add type annotations to every function — parameters and return type. This is not optional. It catches bugs, drives better IDE support, and makes the code self-documenting:

```python
from __future__ import annotations
from pathlib import Path

def fetch_issue(client: JiraClient, key: str) -> dict | None:
    ...

def extract_links(text: str) -> list[dict[str, str]]:
    ...

def init_db(path: Path | str) -> DbConnection:
    ...
```

For complex repeated types, use `TypeAlias`:

```python
from typing import TypeAlias

FetchResult: TypeAlias = tuple[str, str, str]  # (content_type, content_text, status)
```

Run `mypy` to enforce annotations:

```bash
mypy src/ --ignore-missing-imports
```

### Constants at module level

Use uppercase for constants. Prefer `frozenset` for immutable membership tests (O(1) lookup):

```python
_MAX_CONTENT_CHARS = 10_000
_TIMEOUT = 15
_SKIP_TYPES = frozenset({"miro", "google_docs", "repo"})
```

Underscore prefix means "module-internal, not part of public API."

### Catch specific exceptions — never bare except

Always name the exception you're catching. Bare `except:` and `except Exception:` hide bugs:

```python
# WRONG — swallows KeyboardInterrupt, SystemExit, and real bugs
try:
    result = fetch(url)
except:
    pass

# WRONG — too broad, hides programming errors
try:
    result = fetch(url)
except Exception:
    logger.warning("fetch failed")

# RIGHT — only catch what you know how to handle
try:
    result = fetch(url)
except requests.Timeout:
    logger.warning("fetch timed out: %s", url)
    return None
except requests.ConnectionError as e:
    logger.warning("connection error fetching %s: %s", url, e)
    return None
```

If you must catch broadly, always re-raise or log with full traceback:

```python
except Exception:
    logger.exception("unexpected error processing %s", item_id)
    raise
```

### Use context managers for resources

Files, database connections, and HTTP sessions need guaranteed cleanup. Always use `with`:

```python
# Files
with open(path) as f:
    data = json.load(f)

# Database connections
with contextlib.closing(sqlite3.connect(db_path)) as conn:
    conn.execute("SELECT ...")

# Anything with __enter__/__exit__
with requests.Session() as session:
    resp = session.get(url)
```

If your class manages a resource, implement `__enter__` and `__exit__` (or use `contextlib.contextmanager`).

### Use dataclasses for structured data

Named tuples and bare dicts are hard to read and refactor. Use `@dataclass` when a function returns or accepts multiple related values:

```python
from dataclasses import dataclass, field

@dataclass
class FetchResult:
    content_type: str
    content_text: str
    status: str          # 'ok', 'skipped', 'error', 'not_found'
    error_detail: str = ""

# Caller code is readable:
result = fetch_url(url)
if result.status == "ok":
    store(result.content_text)
```

Compare to `return (content_type, content_text, status, error_detail)` — position bugs waiting to happen.

### Lazy imports for optional dependencies

When a feature requires an extra package, import it only when needed with a clear install message:

```python
def _anthropic_client(cfg: dict) -> object:
    try:
        import anthropic
    except ImportError:
        raise RuntimeError("anthropic package not installed — run: pip install anthropic")
    ...
```

This keeps import time fast and gives users a clear action to take.

### Use `from __future__ import annotations`

Add this to every file. It enables the `X | Y` union syntax and forward references on Python 3.9:

```python
from __future__ import annotations

def init_db(path_or_config: Path | str | dict | None = None) -> DbConnection:
    ...
```

### Guard CLI entry points with `if __name__ == "__main__"`

Any script that can be run directly AND imported as a module must have this guard. Without it, `import myscript` in tests executes the whole script:

```python
def main() -> int:
    ...

if __name__ == "__main__":
    sys.exit(main())
```

### Separate pure logic from I/O

Functions that read config or hit the network should not be mixed with pure transformation logic.

```python
# Pure (easy to test, no side effects)
def score_text(text: str, rules_path: Path | None = None) -> tuple[int, dict]:
    ...

# I/O (test with real DB or real HTTP)
def score_run(conn: DbConnection, run_id: int, ...) -> int:
    ...
```

### Return consistent types

When a function can fail gracefully, return a sentinel rather than raising:

```python
def fetch_url_content(url: str, url_type: str, config: dict) -> FetchResult:
    """Returns a FetchResult with status 'ok', 'skipped', 'not_found', or 'error'."""
    if url_type in _SKIP_TYPES:
        return FetchResult(url_type, "", "skipped")
    ...
```

Callers can check `result.status` without catching exceptions.

---

*This file omits §4–5 (see [security.md](security.md)), §9 LLM (see [llm-integrations-safety](../llm-integrations-safety/SKILL.md)), split topics: [jira.md](jira.md), [http-clients-reliability.md](http-clients-reliability.md), [logging-structured.md](logging-structured.md), [config-flags.md](config-flags.md), [packaging.md](packaging.md), [testing-strategy.md](testing-strategy.md), [data-validation.md](data-validation.md), [flask-serving.md](flask-serving.md), [sqlite-patterns.md](sqlite-patterns.md), [documentation.md](documentation.md). The canonical guide: [`../../.claude/CLAUDE.md`](../../.claude/CLAUDE.md).*
