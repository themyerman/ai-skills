---
name: database-migrations
description: >-
  Use when managing database schema changes in Python projects: Alembic setup and
  configuration, creating and running migrations, rollback, zero-downtime column
  additions, SQLite-specific patterns, migration testing, and CI/CD deploy gates.
  Triggers: database migration, Alembic, schema migration, ALTER TABLE, migrate,
  upgrade, downgrade, alembic revision, alembic upgrade, schema change, add column,
  drop column, SQLAlchemy migration, DB schema, migrate database, alembic init,
  alembic autogenerate, schema evolution, database versioning.
---

# database-migrations

## What this is

Patterns for managing database schema changes safely in Python — from simple
`ALTER TABLE` with a `PRAGMA` check (right for small SQLite tools) to Alembic
(right when schema evolves frequently, multiple devs share a DB, or you need
rollback). Covers setup, creating and running migrations, zero-downtime patterns,
SQLite quirks, testing, and CI/CD deploy gates.

**Related:** [`python-internal-tools/sqlite-patterns.md`](../python-internal-tools/sqlite-patterns.md),
[`python-internal-tools/reference.md`](../python-internal-tools/reference.md) (§6 DB patterns),
[`data-pipelines/SKILL.md`](../data-pipelines/SKILL.md) (pipeline state tracking),
[`python-internal-tools/testing-strategy.md`](../python-internal-tools/testing-strategy.md).

---

## 1. When to use Alembic vs manual migrations

### Use manual migrations (ALTER TABLE + PRAGMA check) when

- The tool has **1–3 tables** and schema rarely changes (months between changes)
- **SQLite only** — no plans for Postgres or MySQL
- **One developer** or a very small team, no shared staging DB
- You want **no extra dependencies** (`alembic`, `SQLAlchemy` add weight)
- Changes are additive only (new columns with defaults, new tables)

**Pattern** (from `sqlite-patterns.md`):

```python
def _migrate_schema(conn: sqlite3.Connection) -> None:
    cur = conn.execute("PRAGMA table_info(runs)")
    columns = {row[1] for row in cur.fetchall()}
    if "scorer_version" not in columns:
        conn.execute(
            "ALTER TABLE runs ADD COLUMN scorer_version TEXT NOT NULL DEFAULT 'rules_suggester'"
        )
        conn.commit()
        logger.info("migrated: added scorer_version column to runs")
```

Call `_migrate_schema(conn)` once in `init_db()`, after `CREATE TABLE IF NOT EXISTS`.

### Use Alembic when

- Schema evolves **frequently** (weekly or faster)
- **Multiple developers** share a database or run migrations independently
- You need **rollback** (`downgrade`) — manual migrations typically can't undo themselves
- You have **multiple environments** (dev / staging / prod) that must stay in sync
- The project already uses **SQLAlchemy** models
- You're adding constraints, indexes, or foreign key changes (not just columns)

### Decision criteria

| Signal | Manual | Alembic |
|--------|--------|---------|
| Tables | 1–3 | 4+ or growing |
| Change frequency | Months | Weeks or faster |
| Team size | 1–2 | 3+ |
| Rollback needed | Rarely | Yes |
| Environments | 1 (dev only) | Dev + staging + prod |
| SQLAlchemy models already present | No | Yes |

When in doubt: start with manual migrations. Migrate to Alembic when the pain of
tracking manual changes becomes obvious (e.g., a developer runs a migration twice,
or you can't tell which environment has which columns).

---

## 2. Alembic setup

### Install

```bash
pip install alembic sqlalchemy
# Add to requirements.txt (pinned):
# alembic==1.13.1
# SQLAlchemy==2.0.28
```

### Initialize

```bash
alembic init migrations
```

This creates:

```
alembic.ini          # Alembic config (set sqlalchemy.url here)
migrations/
  env.py             # Runtime environment — configure target_metadata
  script.py.mako     # Template for new migration files
  versions/          # Generated migration files go here
```

### Configure alembic.ini

Set the database URL. For a file-backed SQLite tool:

```ini
# alembic.ini
sqlalchemy.url = sqlite:///data/app.db
```

For a tool that reads the URL from `config.yaml`, leave the `sqlalchemy.url` line
as-is (or comment it out) and override it in `env.py` instead (see below).

### Configure env.py

The critical change: point `target_metadata` at your SQLAlchemy `Base.metadata` so
autogenerate can compare models to the live DB.

```python
# migrations/env.py
from logging.config import fileConfig
from sqlalchemy import engine_from_config, pool
from alembic import context

# Import your models so their metadata is registered
from src.models import Base   # adjust import path to your project

config = context.config
fileConfig(config.config_file_name)

target_metadata = Base.metadata   # <-- the key line


def run_migrations_offline() -> None:
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )
    with connectable.connect() as connection:
        context.configure(connection=connection, target_metadata=target_metadata)
        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
```

### Reading the DB URL from config.yaml (optional)

If your project loads `config.yaml` at runtime, override `sqlalchemy.url` in `env.py`
before `engine_from_config` is called:

```python
# migrations/env.py (addition)
import yaml
from pathlib import Path

_config_path = Path(__file__).parent.parent / "config.yaml"
if _config_path.exists():
    _app_cfg = yaml.safe_load(_config_path.read_text()) or {}
    _db_url = (_app_cfg.get("database") or {}).get("url")
    if _db_url:
        config.set_main_option("sqlalchemy.url", _db_url)
```

### Minimal SQLAlchemy models (for autogenerate)

Autogenerate compares `Base.metadata` to the live DB schema. Your models must be
imported in `env.py` before autogenerate runs:

```python
# src/models.py
from __future__ import annotations
from sqlalchemy import Column, Integer, String, Text, DateTime
from sqlalchemy.orm import DeclarativeBase
import datetime


class Base(DeclarativeBase):
    pass


class Run(Base):
    __tablename__ = "runs"

    id = Column(Integer, primary_key=True)
    query_name = Column(String(100), nullable=False)
    jql = Column(Text, nullable=False)
    issue_count = Column(Integer, nullable=False, default=0)
    scorer_version = Column(String(50), nullable=False, default="rules_suggester")
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
```

---

## 3. Creating migrations

### Autogenerate (detect model changes vs current DB)

```bash
alembic revision --autogenerate -m "add scorer_version column"
```

Alembic compares `Base.metadata` to the current DB schema and writes a migration
file in `migrations/versions/` with `upgrade()` and `downgrade()` filled in.

**Always review the generated file before running it.** Autogenerate:
- Detects: new tables, new columns, dropped columns, type changes, index changes
- Misses: server defaults, some constraints, custom types, data migrations
- Can fabricate changes for SQLite (SQLite's limited `PRAGMA table_info` means
  Alembic sometimes sees phantom differences in column defaults or nullability)

### Manual (empty migration for custom SQL)

```bash
alembic revision -m "backfill scorer_version for existing rows"
```

Creates an empty migration with stubs for `upgrade()` and `downgrade()`. Fill
in the body yourself. Use this for data migrations, custom SQL, or changes
autogenerate can't express.

---

## 4. Running migrations

### Common commands

```bash
# Apply all pending migrations (most common deploy command)
alembic upgrade head

# Apply exactly one pending migration
alembic upgrade +1

# Roll back the most recent migration
alembic downgrade -1

# Roll back all migrations (empty DB schema)
alembic downgrade base

# Show what version the DB is currently at
alembic current

# Show all revisions in order
alembic history

# Show history with verbose detail (includes docstrings)
alembic history --verbose

# Check whether there are unapplied migrations (exit 1 if yes)
alembic check
```

### Safe deploy sequence

Run this in your deploy script — never in app startup code:

```bash
#!/bin/bash
set -euo pipefail

echo "=== Backing up database ==="
cp data/app.db "data/app.db.bak.$(date +%Y%m%dT%H%M%S)"

echo "=== Running migrations ==="
alembic upgrade head

echo "=== Verifying migration state ==="
alembic current

echo "=== Starting app ==="
python main.py
```

If `alembic upgrade head` fails, the script stops (due to `set -e`) and the app
never starts. The backup preserves the pre-migration state for SQLite rollback.

---

## 5. Migration file anatomy

Every migration file in `migrations/versions/` follows this structure:

```python
# migrations/versions/20240315_001_add_scorer_version.py
"""Add scorer_version column to runs table.

Revision ID: a1b2c3d4e5f6
Revises: 9f8e7d6c5b4a
Create Date: 2024-03-15 10:22:45.123456
"""
from __future__ import annotations

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic
revision: str = "a1b2c3d4e5f6"
down_revision: str | None = "9f8e7d6c5b4a"
branch_labels: str | tuple[str, ...] | None = None
depends_on: str | tuple[str, ...] | None = None


def upgrade() -> None:
    op.add_column(
        "runs",
        sa.Column(
            "scorer_version",
            sa.String(length=50),
            nullable=False,
            server_default="rules_suggester",
        ),
    )


def downgrade() -> None:
    op.drop_column("runs", "scorer_version")
```

### Common `op` operations

```python
# Add a column
op.add_column("table_name", sa.Column("col", sa.Text(), nullable=True))

# Drop a column
op.drop_column("table_name", "col")

# Create an index
op.create_index("ix_runs_query_name", "runs", ["query_name"])

# Drop an index
op.drop_index("ix_runs_query_name", table_name="runs")

# Rename a column (not supported in SQLite — see §7)
op.alter_column("table_name", "old_name", new_column_name="new_name")

# Execute arbitrary SQL (data migrations, SQLite workarounds)
op.execute("UPDATE runs SET scorer_version = 'rules_suggester' WHERE scorer_version IS NULL")

# Create a table
op.create_table(
    "scores",
    sa.Column("id", sa.Integer(), primary_key=True),
    sa.Column("run_id", sa.Integer(), nullable=False),
    sa.Column("issue_key", sa.String(50), nullable=False),
    sa.Column("score", sa.Integer(), nullable=False, server_default="0"),
)

# Drop a table
op.drop_table("scores")
```

### Adding a NOT NULL column with a default value to an existing table

This is the most common migration. The `server_default` populates existing rows at
the DB level:

```python
def upgrade() -> None:
    op.add_column(
        "runs",
        sa.Column(
            "scorer_version",
            sa.String(length=50),
            nullable=False,
            server_default=sa.text("'rules_suggester'"),
        ),
    )

def downgrade() -> None:
    op.drop_column("runs", "scorer_version")
```

`server_default` differs from `default`: `server_default` is a SQL expression the
DB fills in for existing rows during `ALTER TABLE`; `default` is a Python-side
value SQLAlchemy uses only at INSERT time.

---

## 6. Zero-downtime migrations

### Why you can't add a NOT NULL column in one step to a live table

On large tables in production databases (PostgreSQL, MySQL), `ALTER TABLE ... ADD
COLUMN ... NOT NULL` locks the table while the DB rewrites every row. For SQLite
this rarely matters (single file, low concurrency), but for Postgres/MySQL with
live traffic it causes downtime.

### The three-step pattern

Split into three separate migration files deployed in sequence:

**Step 1 — Add column as nullable (no lock, instant):**

```python
# migrations/versions/step1_add_label_nullable.py
def upgrade() -> None:
    op.add_column("issues", sa.Column("label", sa.String(50), nullable=True))

def downgrade() -> None:
    op.drop_column("issues", "label")
```

Deploy step 1. The app continues running. New rows get `label = NULL`.

**Step 2 — Backfill existing rows (data migration, no lock):**

```python
# migrations/versions/step2_backfill_label.py
def upgrade() -> None:
    op.execute(
        "UPDATE issues SET label = 'unreviewed' WHERE label IS NULL"
    )

def downgrade() -> None:
    # Backfill is not reversible in a meaningful way; clear the column
    op.execute("UPDATE issues SET label = NULL")
```

Deploy step 2. Backfill runs as a normal DML operation — no table lock in Postgres.
For very large tables, batch the backfill (chunk by `id` range) to avoid long
transactions.

**Step 3 — Add NOT NULL constraint (after all rows are populated):**

```python
# migrations/versions/step3_label_not_null.py
def upgrade() -> None:
    op.alter_column("issues", "label", nullable=False)

def downgrade() -> None:
    op.alter_column("issues", "label", nullable=True)
```

Deploy step 3. The constraint addition is fast because no rows have `NULL`.

### Timing between steps

- **Steps 1 and 2** can be in the same deploy if the table is small.
- **Step 3** goes in a subsequent deploy, after confirming no NULLs remain:

```sql
SELECT COUNT(*) FROM issues WHERE label IS NULL;  -- must be 0 before step 3
```

---

## 7. SQLite-specific patterns

### What SQLite's ALTER TABLE supports

SQLite supports `ADD COLUMN` and (since 3.35.0) `DROP COLUMN`. It does **not**
support: renaming columns (before 3.25.0), adding constraints after the fact,
changing column types, or most other `ALTER TABLE` variants.

### The recreate-table pattern (for unsupported changes)

When you need to rename a column, change a type, add a constraint, or drop a column
on SQLite < 3.35:

```python
# migrations/versions/20240320_rename_raw_text_to_body.py
def upgrade() -> None:
    # 1. Create new table with correct schema
    op.execute("""
        CREATE TABLE issues_new (
            id        INTEGER PRIMARY KEY,
            run_id    INTEGER NOT NULL,
            issue_key TEXT    NOT NULL,
            body      TEXT,                   -- renamed from raw_text
            score     INTEGER NOT NULL DEFAULT 0
        )
    """)
    # 2. Copy data
    op.execute("""
        INSERT INTO issues_new (id, run_id, issue_key, body, score)
        SELECT                  id, run_id, issue_key, raw_text, score
        FROM issues
    """)
    # 3. Drop old table
    op.execute("DROP TABLE issues")
    # 4. Rename new table
    op.execute("ALTER TABLE issues_new RENAME TO issues")

def downgrade() -> None:
    op.execute("""
        CREATE TABLE issues_old (
            id        INTEGER PRIMARY KEY,
            run_id    INTEGER NOT NULL,
            issue_key TEXT    NOT NULL,
            raw_text  TEXT,
            score     INTEGER NOT NULL DEFAULT 0
        )
    """)
    op.execute("""
        INSERT INTO issues_old (id, run_id, issue_key, raw_text, score)
        SELECT                  id, run_id, issue_key, body,     score
        FROM issues
    """)
    op.execute("DROP TABLE issues")
    op.execute("ALTER TABLE issues_old RENAME TO issues")
```

Wrap the whole thing in a transaction (Alembic does this by default) so a failure
mid-way leaves the old table intact.

### When to prefer manual migrations for SQLite-only tools

If all of the following are true, stay with manual `PRAGMA table_info` migrations
and skip Alembic entirely:

- SQLite is the only backend, with no plans to change
- Schema changes are rare (a few per year)
- The team is 1–2 people with a single environment

The manual pattern from `sqlite-patterns.md` covers this case with zero extra
dependencies and no migration file management overhead.

---

## 8. Testing migrations

Test migrations the same way you test application code: with real databases on disk,
not mocks. Use `tmp_path` (pytest built-in) for throwaway SQLite files.

### Test that upgrade runs clean on an empty DB

```python
# tests/test_migrations.py
import subprocess
from pathlib import Path
import pytest


@pytest.fixture
def migration_db(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> Path:
    """Empty SQLite DB wired to Alembic via environment override."""
    db_path = tmp_path / "test.db"
    monkeypatch.setenv("DATABASE_URL", f"sqlite:///{db_path}")
    return db_path


class TestMigrations:
    """Tests for Alembic migration correctness."""

    def test_upgrade_head_on_empty_db(self, migration_db: Path) -> None:
        result = subprocess.run(
            ["alembic", "upgrade", "head"],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0, result.stderr
        assert migration_db.exists()

    def test_downgrade_base_fully_reverses(self, migration_db: Path) -> None:
        subprocess.run(["alembic", "upgrade", "head"], check=True)
        result = subprocess.run(
            ["alembic", "downgrade", "base"],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0, result.stderr

    def test_upgrade_head_is_idempotent(self, migration_db: Path) -> None:
        """Run upgrade head twice; data inserted between runs must survive."""
        import sqlite3

        subprocess.run(["alembic", "upgrade", "head"], check=True)

        # Insert a row between runs
        conn = sqlite3.connect(migration_db)
        conn.execute(
            "INSERT INTO runs (query_name, jql, issue_count) VALUES (?, ?, ?)",
            ("test", "project = X", 1),
        )
        conn.commit()
        conn.close()

        # Second upgrade must be a no-op
        result = subprocess.run(
            ["alembic", "upgrade", "head"],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0, result.stderr

        # Data must survive
        conn = sqlite3.connect(migration_db)
        row = conn.execute("SELECT query_name FROM runs WHERE query_name = 'test'").fetchone()
        conn.close()
        assert row is not None, "data was lost during second upgrade head"
```

### Configuring Alembic to use the test DB

Override `DATABASE_URL` in `env.py` so tests can inject a `tmp_path` DB path
without editing `alembic.ini`:

```python
# migrations/env.py (addition)
import os

_url_override = os.environ.get("DATABASE_URL")
if _url_override:
    config.set_main_option("sqlalchemy.url", _url_override)
```

### Test individual migration files in isolation

For data migrations (step 2 of zero-downtime, backfills), test the SQL logic
directly without running the full migration chain:

```python
def test_backfill_sets_default_label(self, tmp_path: Path) -> None:
    import sqlite3

    db = tmp_path / "test.db"
    conn = sqlite3.connect(db)
    conn.executescript("""
        CREATE TABLE issues (id INTEGER PRIMARY KEY, issue_key TEXT, label TEXT);
        INSERT INTO issues VALUES (1, 'PROJ-1', NULL);
        INSERT INTO issues VALUES (2, 'PROJ-2', NULL);
    """)
    # Run the backfill SQL directly
    conn.execute("UPDATE issues SET label = 'unreviewed' WHERE label IS NULL")
    conn.commit()
    rows = conn.execute("SELECT label FROM issues").fetchall()
    assert all(r[0] == "unreviewed" for r in rows)
```

---

## 9. Migration in CI/CD

### Migration as a deploy step

Run `alembic upgrade head` as part of the deploy script, **before** starting the
app. If migration fails, the app must not start.

```bash
#!/bin/bash
# deploy.sh
set -euo pipefail

echo "[deploy] backing up database"
# For SQLite: copy the file. For Postgres: pg_dump or snapshot.
cp data/app.db "data/app.db.bak.$(date +%Y%m%dT%H%M%S)" 2>/dev/null || true

echo "[deploy] running migrations"
alembic upgrade head          # exits non-zero on failure; set -e stops the script

echo "[deploy] verifying migration state"
alembic current               # logs which revision the DB is at

echo "[deploy] starting application"
exec python main.py           # exec replaces shell with the app process
```

For Kubernetes or container deployments, run migrations in an **init container** or
a **pre-deploy job** — not in the app container entrypoint. This ensures the schema
is ready before any app replicas start.

### CI gate: reject PRs with unapplied migrations

Use `alembic check` to fail a CI job if a developer added a model change but forgot
to generate the migration:

```yaml
# .github/workflows/ci.yml  (or equivalent CI config)
- name: Check for unapplied migrations
  run: |
    alembic check
  # alembic check exits 1 if there are pending migrations not yet reflected in versions/
```

Note: `alembic check` compares `Base.metadata` to the migration history (not to a
live DB). It catches missing migration files, not whether a given environment has
run them.

### Check migration state in health endpoint (optional)

For long-running services, expose migration state in a health check so you can
detect drift between environments:

```python
# app/health.py
from alembic.runtime.migration import MigrationContext
from alembic.script import ScriptDirectory
from alembic.config import Config
from sqlalchemy import create_engine


def migration_is_current(db_url: str) -> bool:
    alembic_cfg = Config("alembic.ini")
    script = ScriptDirectory.from_config(alembic_cfg)
    engine = create_engine(db_url)
    with engine.connect() as conn:
        context = MigrationContext.configure(conn)
        current_heads = set(context.get_current_heads())
        expected_heads = set(script.get_heads())
        return current_heads == expected_heads
```

---

## 10. Common mistakes

| Mistake | Correct approach |
|---------|-----------------|
| Editing a migration file after it has been applied to any environment | Never edit applied migrations. Create a new migration to correct the mistake. |
| Using `--autogenerate` blindly without reviewing the output | Always open and read the generated file. SQLite dialect often adds phantom diffs. |
| Omitting `downgrade()` | Always write a `downgrade()`, even if it just logs "not reversible" and raises `NotImplementedError`. |
| Running migrations in app startup code | Run migrations in deploy scripts or init containers, not in `main()` or `app/__init__.py`. |
| Using `DROP TABLE` then `CREATE TABLE` to change schema | Use `ALTER TABLE ADD COLUMN` (or the recreate pattern for SQLite) to preserve data. |
| Not testing `downgrade base` | A broken `downgrade()` means no rollback when you need it most. Test it. |
| Applying step 3 (NOT NULL constraint) before backfill is complete | Always verify `SELECT COUNT(*) FROM table WHERE col IS NULL` is 0 before the final constraint step. |
| Hardcoding the DB URL in `alembic.ini` for all environments | Override `sqlalchemy.url` in `env.py` from config or environment variables. |
| Using autogenerate with SQLite and trusting the diff | SQLite's `PRAGMA table_info` is lossy. Treat autogenerated SQLite migrations as a draft, not a final answer. |
| Forgetting to import models in `env.py` | Without the import, `Base.metadata` is empty and autogenerate generates no-op migrations. |
| Long-running data migrations inside a single transaction | Batch large backfills by ID range to avoid locking and long transaction timeouts. |
| No backup before `alembic upgrade head` in production | For SQLite: `cp app.db app.db.bak`. For Postgres: snapshot or `pg_dump`. Always. |

## Related

- **Python project layout, config, venv, SQLite patterns:** [`python-internal-tools`](../python-internal-tools/SKILL.md) (see `sqlite-patterns.md`)
- **CI gate for running migrations on every PR:** [`ci-cd-pipelines`](../ci-cd-pipelines/SKILL.md)
- **Zero-downtime deploy checklist:** [`docker-containerization`](../docker-containerization/SKILL.md)
- **Observability: track migration run success/failure:** [`observability`](../observability/SKILL.md)
- **Routing:** [`../../SKILLS.md`](../../SKILLS.md)
