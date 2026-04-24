# Logging, context, and correlation

<!-- Use **`logging.getLogger(__name__)`** in each module. PII and secrets: [security.md](security.md) (*On logging*). This note adds **context** and **ops** habits. -->

The dev guide’s **“On logging”** in [security.md](security.md) is the **safety** baseline (no tokens, no raw HTTP bodies, levels). This file is how to make logs **actionable** when a **script**, **Flask** request, or **batch** fails in production.

### Your org (read current published policy, not this page)

- **Index:** your employer’s **Application Security** (incl. logging, **NHI** / **agentic** use where applicable), **Logging** / **Monitoring,** **retention,** and **Observability** **policies**—**exact** titles/versions in **house** only.
- **Operational** logging expectations (UTC, **central** aggregation, **retention**, **integrity** of log stores) are defined in those **live** documents—not here. If a pattern in this file and your org’s **policy** disagree, **the policy wins**.

---

## 1. `logging.getLogger(__name__)`

- **One** logger per module: `logger = logging.getLogger(__name__)` so log lines are **routable** and show **source**.
- **Avoid** `print` in library code; **CLI** may print **user-facing** status, but **ops** and **triage** should use **loggers** so **level** and **format** can be unified.

---

## 2. Add **run** / **operation** context

- **CLIs and workers:** on **start**, log a **one-line** summary: `run_id=`, `batch=`, `query=`, `issue count=`, **config** slice—**no** secrets. Score and batch jobs should log which **run** and **N issues**; mirror that in **your** tool.
- **Tie** database **primary keys** into log lines when debugging (`run_id=12`, `issue=PROJ-123`) so grep finds the **row**.
- **Flask:** you can set **`g.request_id`**, **middleware** `before_request` uuid, and log it on **ERROR**; keep **headers** and **PII** out of logs [flask-serving.md](flask-serving.md).

---

## 3. Structured vs plain text

- **Plain** `"%(levelname)s %(name)s: %(message)s"` is **fine** for many internal tools.
- **Structured (JSON)**: consider when logs go to **Splunk/ELK/Datadog** — one **JSON** object per line, **field names** stable. Use **`structlog`** or **`python-json-logger`** only if the team **commits**; otherwise **KISS** with a **consistent** `key=value` prefix in the message.
- **Whatever** you choose, **document** the **format** in `README.md` so on-call can **grep**.

---

## 4. What to add on each level

- **DEBUG:** per-item progress only when **needed** (can be **noisy**; gate with `--verbose` or `LOG_LEVEL`).
- **INFO:** **lifecycle**: started, **N** items processed, **ended**; **idempotent** skips (e.g. “duplicate link skipped”).
- **WARNING:** **recoverable** oddities — retry, **fallback**, **truncation**, Jira 404 for **optional** follow-up.
- **ERROR:** **failed** unit of work with **enough** to file a bug — **key**, **path**, **exception** type; **use** `logger.exception` in `except` **blocks** to capture **traceback** in **one** place, not **huge** str(e) in every branch.

---

## 5. Correlation across **processes**

- If **cron** kicks **A** then **B**, log the **same** `batch_id` or **date** in both, or a **parent** `job` name, so you can **join** lines in log search.
- For **Jira** automation, the **issue key** is often the best **correlation** id for humans.

---

## 6. Anti-patterns

- **Logging** full **Jira** or **LLM** payloads at **INFO** (use **redaction** or **size cap**; *Limit what you store* in [security.md](security.md) is the same **mindset** for logs).
- **A log line per row** of a **huge** CSV in **INFO** — use **counters** + **one** summary, or **DEBUG** with a **sampling** flag.
- **Different** `basicConfig` in every **script** — centralize in **`main()`** or **one** `logging_init()` when you have **several** entry points.

---

## 7. Checklist

- [ ] `getLogger(__name__)`; **no** `print` in `src/`  
- [ ] **Start/end** and **key** business ids on **INFO**  
- [ ] **Errors** with **`exception`** and **enough** context, **not** full bodies  
- [ ] **On-call** can find **one** “what ran” line per **job**
