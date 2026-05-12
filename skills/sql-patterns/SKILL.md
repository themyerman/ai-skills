---
name: sql-patterns
description: >-
  SQL and PostgreSQL patterns: indexing strategies, query optimization, EXPLAIN
  reading, window functions, CTEs, N+1 detection, connection pooling, pagination,
  common performance traps. Practical patterns for developers writing queries.
  Triggers: slow query, index, EXPLAIN, N+1, window function, CTE, pagination,
  connection pool, PostgreSQL, SQLite, query optimization.
---

# sql-patterns

Practical SQL for developers — not DBA-level tuning, but the patterns that prevent the most common performance and correctness problems.

---

## Indexing

### When to add an index

Add an index when:
- A column appears in WHERE, JOIN ON, or ORDER BY clauses in frequent queries
- A query is slow and EXPLAIN shows a sequential scan on a large table
- A foreign key column is used in joins (PostgreSQL does not auto-index foreign keys)

Don't add an index when:
- The table is small (under ~10k rows) — sequential scans are often faster
- The column has very low cardinality (e.g. a boolean) — index won't help much
- The table has heavy write load — indexes slow down INSERT/UPDATE/DELETE

### Common index types

```sql
-- Standard B-tree index (default, covers most cases)
CREATE INDEX idx_orders_user_id ON orders (user_id);

-- Composite index — column order matters; leftmost columns must be present in WHERE
CREATE INDEX idx_orders_user_status ON orders (user_id, status);

-- Partial index — index only rows matching a condition
CREATE INDEX idx_orders_pending ON orders (created_at)
  WHERE status = 'pending';

-- Index on expression
CREATE INDEX idx_users_lower_email ON users (lower(email));

-- Covering index — includes extra columns so the query never hits the table
CREATE INDEX idx_orders_cover ON orders (user_id) INCLUDE (total, created_at);
```

### Create indexes concurrently in production

```sql
-- Without CONCURRENTLY: locks the table for writes during build
CREATE INDEX idx_orders_user_id ON orders (user_id);

-- With CONCURRENTLY: safe for production — no write lock, but slower
CREATE INDEX CONCURRENTLY idx_orders_user_id ON orders (user_id);
```

---

## Reading EXPLAIN

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM orders WHERE user_id = 42;
```

Key things to look for:

| Node type | What it means |
|-----------|--------------|
| `Seq Scan` | Reading every row — fine for small tables, bad for large ones |
| `Index Scan` | Using an index — good |
| `Index Only Scan` | Using a covering index — best |
| `Bitmap Heap Scan` | Bulk index lookup — good for range queries |
| `Hash Join` / `Merge Join` | Join strategy — usually fine |
| `Nested Loop` | Join strategy — can be slow if the inner side is large |

Read the cost numbers as `startup_cost..total_cost`. Actual time is in `actual time=X..Y`. High actual-vs-estimated row count discrepancy means stale statistics — run `ANALYZE`.

---

## CTEs

Common Table Expressions make complex queries readable. Use them freely — PostgreSQL 12+ inlines them by default so they're not a performance penalty.

```sql
-- Break a complex query into named steps
WITH
  active_users AS (
    SELECT id FROM users WHERE last_active > NOW() - INTERVAL '30 days'
  ),
  recent_orders AS (
    SELECT user_id, COUNT(*) AS order_count
    FROM orders
    WHERE created_at > NOW() - INTERVAL '30 days'
    GROUP BY user_id
  )
SELECT u.id, u.email, COALESCE(o.order_count, 0) AS orders
FROM active_users u
LEFT JOIN recent_orders o ON o.user_id = u.id;
```

Use `WITH MATERIALIZED` to force PostgreSQL to execute the CTE once (useful when the planner makes poor choices):

```sql
WITH MATERIALIZED expensive_subquery AS (
  SELECT ...
)
SELECT * FROM expensive_subquery WHERE ...;
```

---

## Window functions

Window functions compute values across a set of rows related to the current row — without collapsing them like GROUP BY does.

```sql
-- Rank users by order count within each region
SELECT
  user_id,
  region,
  order_count,
  RANK() OVER (PARTITION BY region ORDER BY order_count DESC) AS regional_rank
FROM user_summary;

-- Running total
SELECT
  created_at::date AS day,
  revenue,
  SUM(revenue) OVER (ORDER BY created_at::date) AS running_total
FROM daily_revenue;

-- Previous row value (lag) — useful for computing deltas
SELECT
  created_at::date,
  active_users,
  active_users - LAG(active_users) OVER (ORDER BY created_at::date) AS day_over_day_change
FROM daily_metrics;

-- First/last value in a group
SELECT
  user_id,
  order_id,
  FIRST_VALUE(order_id) OVER (PARTITION BY user_id ORDER BY created_at) AS first_order
FROM orders;
```

---

## N+1 queries

The N+1 problem: fetching a list of N rows, then making one additional query per row. Kills performance at scale.

```python
# N+1: 1 query for users + N queries for their order counts
users = db.execute("SELECT id, name FROM users").fetchall()
for user in users:
    count = db.execute("SELECT COUNT(*) FROM orders WHERE user_id = ?", user["id"]).fetchone()
    print(user["name"], count[0])

# Fixed: 1 query with a JOIN
results = db.execute("""
    SELECT u.name, COUNT(o.id) AS order_count
    FROM users u
    LEFT JOIN orders o ON o.user_id = u.id
    GROUP BY u.id, u.name
""").fetchall()
```

Detection: if your query count scales with result count, you have an N+1. Log query counts in dev using SQLAlchemy's event hooks or Django's `assertNumQueries`.

---

## Pagination

### Offset pagination (simple, but degrades at scale)

```sql
-- Page 5, 20 items per page
SELECT * FROM orders ORDER BY created_at DESC LIMIT 20 OFFSET 80;
```

Problem: at large offsets, PostgreSQL scans and discards all prior rows. Slow on millions of rows.

### Cursor pagination (efficient at any scale)

```sql
-- First page
SELECT id, created_at, total FROM orders ORDER BY created_at DESC, id DESC LIMIT 20;

-- Next page — use the last row's values as the cursor
SELECT id, created_at, total FROM orders
WHERE (created_at, id) < ('2024-01-15 10:30:00', 12345)
ORDER BY created_at DESC, id DESC
LIMIT 20;
```

Always include a unique column (like `id`) in the cursor to handle ties in the primary sort column.

---

## Connection pooling

Opening a new database connection is expensive (10–50ms). Use a connection pool.

```python
# SQLAlchemy — configure pool size for your workload
from sqlalchemy import create_engine

engine = create_engine(
    "postgresql://user:pass@host/db",
    pool_size=10,          # persistent connections
    max_overflow=20,       # temporary connections above pool_size
    pool_timeout=30,       # wait up to 30s for a connection
    pool_pre_ping=True,    # check connections are alive before using
)
```

For serverless or high-concurrency workloads, use PgBouncer in transaction mode between your app and PostgreSQL.

---

## Upsert

```sql
-- Insert or update on conflict
INSERT INTO user_stats (user_id, login_count, last_login)
VALUES (42, 1, NOW())
ON CONFLICT (user_id) DO UPDATE SET
  login_count = user_stats.login_count + 1,
  last_login = EXCLUDED.last_login;
```

`EXCLUDED` refers to the row that was attempted to be inserted.

---

## Common traps

| Trap | Fix |
|------|-----|
| `SELECT *` in production queries | Name the columns you need — avoids over-fetching and breaks clearly when schema changes |
| `WHERE lower(email) = ?` without a functional index | Add `CREATE INDEX ON users (lower(email))` |
| Implicit type cast in WHERE (`WHERE id = '42'`) | Match the column type; casts can prevent index use |
| `COUNT(*)` on a huge table for pagination | Estimate with `pg_stat_user_tables.n_live_tup`; avoid exact counts in UI |
| Forgetting `LIMIT` on admin queries | Always add `LIMIT` to exploratory queries on production |

---

## Related

- Database migrations: [`database-migrations`](../database-migrations/SKILL.md)
- SQLite patterns in Python tools: [`python-scripts-and-services/sqlite-patterns.md`](../python-scripts-and-services/sqlite-patterns.md)
- Data pipelines with SQL: [`data-pipelines`](../data-pipelines/SKILL.md)
