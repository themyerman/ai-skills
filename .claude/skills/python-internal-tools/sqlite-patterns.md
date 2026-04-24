# SQLite in internal tools

<!-- Typical: **`src/db.py`**, **`src/storage.py`**. Multi-backend and **parameterized** SQL: [reference.md](reference.md) §6. SQL injection: [security.md](security.md). -->

Use **SQLite** for **single-node**, **embedded** persistence: one file (or `:memory:` in tests), **no** separate database server, **fast** enough for many internal workflows. A common pattern is to default to SQLite and switch to **PostgreSQL** or **MySQL** via `DATABASE_URL` / config — the **same** query style can use **`%s` placeholders** in app code with an adapter that rewrites to **`?`** for `sqlite3` in a small **`_convert_placeholders`**-style helper.

---

## 1. When SQLite fits (and when it does not)

| Use SQLite | Prefer Postgres / MySQL |
|------------|-------------------------|
| One process (or a few) on one host, **file-backed** `data/app.db` | **Many** concurrent **writers** or **HA** / replicas required |
| **Tooling** and **analytics** where **WAL** + a long `busy_timeout` is enough | **Row-level** security, **advanced** types, or **compliance** features your org mandates on a **server** DB |
| **Tests** with `tmp_path` / `:memory:` | You already have a **shared** DBA-owned instance for the org |

---

## 2. Connection and pragmas (production-friendly defaults)

A typical `connect` path also sets:

- **`PRAGMA journal_mode=WAL`** — readers (e.g. **Flask**) can read while a **writer** holds a transaction; reduces **“database is locked”** for read-mostly UIs.
- **`PRAGMA synchronous=NORMAL`** — balance of safety and speed on local disk (understand your **durability** needs for **your** data class).
- **`PRAGMA busy_timeout = …`** (milliseconds) — how long to **retry** when the DB is busy, instead of failing immediately. Ingest-heavy jobs often use a **long** `busy_timeout`; use a **short** one if you need fast failure on contention.

Create parent **directories** for the DB file before `connect` if the path is new.

**Path:** use **`Path`**, `str`, or a `sqlite:///` URL resolved to a file path; avoid **surprise** `cwd` — resolve relative paths from **config** or project root.

---

## 3. One placeholder style in application SQL

Use **`%s`** in shared SQL strings if you have a **multi-backend** layer; let the SQLite adapter map to **`?`**. If you use **raw** `sqlite3` only, use **`?`** and do **not** format strings into SQL [security.md](security.md).

---

## 4. Migrations: `CREATE TABLE IF NOT EXISTS` + `ALTER` + `PRAGMA table_info`

- **Initial schema:** `CREATE TABLE IF NOT EXISTS` in one script or constant (e.g. a **`SCHEMA`** in your `storage` module).
- **Evolving schema:** for each new column, **`PRAGMA table_info(table_name)`**, then if the column is missing, **`ALTER TABLE … ADD COLUMN …`** with a **sensible `DEFAULT`**, then **`commit()`**. **Never** `DROP TABLE` **to add a column** on user data.
- **SQLite** allows **limited** `ALTER`; plan **new tables** or **rebuild** steps if you outgrow that (rare in small tools).

This matches the **“Write migrations, not drop-and-recreate”** pattern in [reference.md](reference.md#6-database-patterns).

---

## 5. Deletes and foreign keys

- **`REFERENCES … ON DELETE CASCADE`** in `CREATE TABLE` is **not enforced** unless you enable **`PRAGMA foreign_keys=ON`** on each connection (SQLite’s default is **off**). If you need **CASCADE** deletes, turn **foreign_keys** on at connect, **or** **delete in dependency order** in application code (child first) as in the **guide** [reference.md](reference.md#delete-in-dependency-order). If your app never enables FKs, **assume** no automatic cascade.
- If your schema declares **`ON DELETE CASCADE`**, check **`db`** / storage init for whether FKs are **enabled** on each connect before relying on cascade in raw SQLite.

---

## 6. Tests: real files, not mocks

- Use **`tmp_path / "test.db"`** and **`init_db`**, or `:memory:` for **fast** unit tests that do not need a file.
- **Prove idempotency:** `init_db` twice on the same path should **not** drop user rows (see [reference.md](reference.md#test-idempotency-explicitly)).
- **Do not mock** the database for “does my schema work” — use a **real** SQLite file in CI.

---

## 7. Concurrency and the Flask app

- **One writer** + **many readers** is the sweet spot for **WAL** + long **busy_timeout**.
- **Multiple** heavy **writers** (separate processes) to the **same** file can still **contend** — coordinate with a **queue**, **single** writer process, or **move** to **Postgres** if you **fight locks** too often.
- **Flask:** one **connection per request** (see [flask-serving.md](flask-serving.md)) — do not share a **global** `sqlite3` connection across threads.

---

## 8. Exports, backups, and one-off scripts

- **Read-only** reporting scripts can open **read-only** or normal connections; **do not** run **destructive** `PRAGMA` in production without intent.
- **Backup:** file copy when **idle**, or SQLite’s **backup API**; for **WAL**, understand **`-wal` / `-shm` sidecar** files and **checkpoint** behavior if you need a **consistent** copy under load.

---

## 9. What not to put here

- **Postgres-specific** `ON CONFLICT` / `RETURNING` details — keep them in the **abstraction** layer with **backend** checks [reference.md](reference.md#support-multiple-backends-from-the-start).
- **Entity design** and **threat** modeling of **stored** data — [security.md](security.md) and, for program TMs, [shift-left-program/](../shift-left-program/SKILL.md) + internal runbooks.

---

## File map (illustrative)

| Concern | Example path |
|---------|----------------|
| SQLite connect, WAL, busy, placeholder conversion | `src/db.py` |
| Schema, `init_db`, `ALTER` / `PRAGMA table_info` | `src/storage.py` |
| Config URL | `DATABASE_URL`, or `config.yaml` `database.url` |

If your tool is **SQLite-only** and will **never** need another backend, you can use **`sqlite3` directly** with **`?`** placeholders—keep **all** SQL in one module so a future **port** is still in one place.
