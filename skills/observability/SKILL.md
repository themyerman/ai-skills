---
name: observability
description: >-
  Observability for Python services and CLIs: logs (what happened), metrics
  (how much/how often), traces (where time went), health check endpoints
  (/health, /ready), RED method (Rate, Errors, Duration), prometheus_client,
  structured log fields, SLI/SLO basics, alerting principles, what not to log.
  Triggers: observability, metrics, health check, /health, /ready, prometheus,
  RED method, SLO, SLI, instrumentation, alerting, dashboard, tracing, monitor,
  instrument, uptime, latency, counter, histogram, gauge, run_id, duration_ms.
---

# observability

## What this is

Practical patterns for making **Python internal tools and Flask services** observable: knowing when they are broken, how long things take, and what happened in a run. This covers the **three pillars**, a simple instrumentation model (**RED**), health endpoints, structured log fields, and **SLI/SLO basics** for internal tooling.

For **Python log format, levels, and correlation**: [python-internal-tools / logging-structured.md](../python-internal-tools/logging-structured.md) is the companion file — this skill refers to it rather than duplicating it.

For **what not to log** (PII, tokens, secrets): [data-handling-pii](../data-handling-pii/SKILL.md) and [python-internal-tools / security.md](../python-internal-tools/security.md).

---

## 1. Three pillars

| Pillar | Question it answers | Where you see it |
|--------|---------------------|-----------------|
| **Logs** | What happened, and when? | File, stdout, Splunk/ELK/Datadog |
| **Metrics** | How much, how often, how fast? | Prometheus, Datadog, log aggregator counts |
| **Traces** | Where did the time go across calls? | Jaeger, Zipkin, OTel collector |

**For most internal tools and CLIs**, you need logs (already covered) and a handful of key counters. Full distributed tracing is valuable for multi-service call chains; for a Jira CLI or a small Flask service, structured logs with timing fields give most of the value at a fraction of the setup cost.

**Org note:** Check your org's published logging and observability policies for retention, aggregation, and data-handling requirements. This skill is a coding-habits layer, not a policy substitute.

---

## 2. Health check endpoints

Every Flask service needs at least one health endpoint. Two are better.

| Endpoint | Question | Passes when |
|----------|----------|-------------|
| `/health` | Is the process alive? | Process is running and can handle HTTP |
| `/ready` | Can it serve traffic? | Process is live AND dependencies (DB, etc.) are reachable |

Return `200` with `{"status": "ok"}` on success. Return `503` with `{"status": "error", "detail": "..."}` on failure. Never return `200` with an error body — load balancers and uptime monitors key off the status code.

```python
# app/health.py
from __future__ import annotations

import logging
import time

from flask import Blueprint, jsonify

from src.db import get_db_connection  # your connection factory

logger = logging.getLogger(__name__)

health_bp = Blueprint("health", __name__)


@health_bp.route("/health")
def liveness() -> tuple:
    """Is the process alive?"""
    return jsonify({"status": "ok"}), 200


@health_bp.route("/ready")
def readiness() -> tuple:
    """Can we serve traffic? Check DB connectivity."""
    try:
        conn = get_db_connection()
        conn.execute("SELECT 1")
        conn.close()
        return jsonify({"status": "ok"}), 200
    except Exception as exc:
        logger.error("readiness check failed: %s", exc)
        return jsonify({"status": "error", "detail": str(exc)}), 503
```

Register the blueprint in your app factory:

```python
from app.health import health_bp
app.register_blueprint(health_bp)
```

**For CLIs without HTTP:** expose a lightweight "smoke test" function that checks config, DB connectivity, and any required credentials at startup. Call it before processing any items — this is the CLI equivalent of `/ready`.

```python
def check_ready(config: dict) -> None:
    """Fail fast if the tool cannot run successfully."""
    conn = init_db(config["db_path"])
    conn.execute("SELECT 1")
    conn.close()
    if not config.get("jira", {}).get("token"):
        raise RuntimeError("Jira token not configured — set jira.token in config.yaml")
```

---

## 3. The RED method

RED stands for **Rate, Errors, Duration**. These three things tell you almost everything you need to know about a service endpoint or batch job.

| Signal | What to measure | Example |
|--------|-----------------|---------|
| **Rate** | Requests (or runs) per second / per minute | 12 Jira triage runs/hour |
| **Errors** | Error rate (failed / total) | 0.2% of API calls fail |
| **Duration** | Latency distribution (p50, p95, p99) | p95 triage run = 8.4 s |

Apply RED to:
- Every **Flask route** that does real work
- Every **batch run** (start → end duration; pass/fail)
- Every **external API call** (Jira, LLM, GHE)

You do not need Prometheus to use RED. A structured log line at the end of each operation with `duration_ms`, `error_count`, and `item_count` lets a log aggregator compute all three signals.

---

## 4. What to instrument in Python

Two approaches. Use whichever fits your deployment.

### Option A: prometheus_client (when Prometheus is available)

```python
# src/metrics.py
from __future__ import annotations

from prometheus_client import Counter, Gauge, Histogram, start_http_server

# Counters — only go up; reset on restart.
runs_total = Counter(
    "jira_triage_runs_total",
    "Total triage runs started",
    ["status"],  # label: 'started' | 'completed' | 'failed'
)

items_processed = Counter(
    "jira_triage_items_total",
    "Issues processed across all runs",
)

api_errors = Counter(
    "jira_api_errors_total",
    "Jira API calls that returned an error",
    ["status_code"],
)

# Histogram — measures distribution of durations.
run_duration_seconds = Histogram(
    "jira_triage_run_duration_seconds",
    "Wall-clock time per triage run",
    buckets=[1, 2, 5, 10, 30, 60, 120, 300],
)

# Gauge — can go up or down; useful for queue depth or current run count.
active_runs = Gauge(
    "jira_triage_active_runs",
    "Triage runs currently in progress",
)


def start_metrics_server(port: int = 9090) -> None:
    """Expose /metrics for Prometheus scraping."""
    start_http_server(port)
```

Usage in a batch run:

```python
import time
from src.metrics import runs_total, items_processed, run_duration_seconds, active_runs

def run_triage(conn, config: dict) -> int:
    runs_total.labels(status="started").inc()
    active_runs.inc()
    start = time.monotonic()
    n = 0
    try:
        for issue in fetch_open_issues(config):
            triage_issue(conn, issue, config)
            items_processed.inc()
            n += 1
        runs_total.labels(status="completed").inc()
        return n
    except Exception:
        runs_total.labels(status="failed").inc()
        raise
    finally:
        run_duration_seconds.observe(time.monotonic() - start)
        active_runs.dec()
```

### Option B: structured log lines (when Prometheus is not available)

For many internal tools, a consistent log line at the end of each major operation is enough. A log aggregator (Splunk, ELK, Datadog) can count and chart these without any metrics infrastructure.

```python
import logging
import time

logger = logging.getLogger(__name__)


def run_triage(conn, config: dict) -> int:
    start = time.monotonic()
    n = 0
    error_count = 0
    status = "completed"

    try:
        for issue in fetch_open_issues(config):
            try:
                triage_issue(conn, issue, config)
                n += 1
            except Exception as exc:
                logger.warning("triage failed for %s: %s", issue["key"], exc)
                error_count += 1
    except Exception:
        status = "failed"
        raise
    finally:
        duration_ms = int((time.monotonic() - start) * 1000)
        logger.info(
            "run complete status=%s item_count=%d error_count=%d duration_ms=%d",
            status, n, error_count, duration_ms,
        )

    return n
```

The log aggregator can then parse `status=`, `item_count=`, `error_count=`, and `duration_ms=` as fields and build dashboards without any additional instrumentation.

---

## 5. Key things to count (Jira / internal tools)

Concrete events worth instrumenting. Log or count these for every non-trivial service.

| Event | Counter / log field | Why |
|-------|---------------------|-----|
| Run started | `runs_started` | Confirms the scheduler fired |
| Run completed | `runs_completed`, `status=completed` | Confirms work finished |
| Run failed | `runs_failed`, `status=failed` | First signal something broke |
| Items processed | `item_count` | Throughput; spike = unexpected data volume |
| Items skipped | `skip_count` | Sanity check on filters |
| API call duration | `api_duration_ms` | Tracks Jira/LLM latency trends |
| API retries | `retry_count` | Rising retries = upstream instability |
| API errors (4xx/5xx) | `api_error_count`, `status_code=...` | Distinguish auth failures from server errors |
| Anomaly events detected | `anomaly_count` | Tracks injection / safety signals (§9 patterns) |
| LLM tokens used | `llm_tokens` | Cost tracking; spike = prompt length issue |
| DB write failures | `db_error_count` | Storage layer health |

Log these at **INFO** at the end of each run, not per-item (which would flood logs). Per-item **WARNING** is fine for individual failures.

---

## 6. Alerting principles

**Alert on symptoms, not causes.** A symptom is something the user feels: runs failing, latency above threshold, no successful runs in N hours. A cause is something internal: a disk is 80% full, a thread pool is saturated. Cause-based alerts fire too early, too often, and without context.

| Good alert (symptom) | Bad alert (cause) |
|----------------------|-------------------|
| Error rate > 5% for 10 min | CPU > 70% |
| No successful run in 2 hours | DB file size > 500 MB |
| p95 latency > 30 s | Retry count > 0 |
| /ready returning 503 | Thread pool queue depth > 10 |

**Set thresholds from baselines, not intuition.** Look at a week of normal runs. If p95 is usually 8 s, set the latency alert at 25 s — not 10 s (too sensitive) or 120 s (too late). If you have no baseline, start permissive and tighten.

**Avoid alert fatigue.** Alerts that fire frequently and resolve themselves train people to ignore them. Three reliable alerts are more valuable than twenty noisy ones. Start with:
1. Run success rate drops below your SLO target
2. No successful run in the expected window (e.g. 2× the schedule interval)
3. `/ready` returning 503 for more than 2 minutes

**Define an on-call response.** Every alert must have a runbook entry: what does this alert mean, what are the first three things to check, and who owns it. An alert without a runbook is a pager that says "something is wrong, good luck."

---

## 7. Structured log fields for observability

End each major operation with a single log line that contains all the information needed to understand the outcome. This makes the log line self-contained for dashboards and grep.

**Recommended fields:**

| Field | Type | Example | Notes |
|-------|------|---------|-------|
| `run_id` | int or str | `42` | DB primary key or UUID; links log to DB row |
| `status` | str | `completed` / `failed` / `skipped` | Always present |
| `item_count` | int | `18` | Items successfully processed |
| `error_count` | int | `2` | Items that failed; 0 is explicit good news |
| `duration_ms` | int | `4312` | Wall-clock time; easier to parse than float seconds |
| `skip_count` | int | `3` | Optional; clarifies why item_count < total |
| `retry_count` | int | `1` | Optional; non-zero indicates upstream instability |

**Example:**

```python
logger.info(
    "run complete run_id=%d status=%s item_count=%d error_count=%d "
    "skip_count=%d retry_count=%d duration_ms=%d",
    run_id, status, item_count, error_count, skip_count, retry_count, duration_ms,
)
```

Log parsers (Splunk, Datadog, ELK) can extract `key=value` pairs automatically when field names are consistent across all log lines from the same service. Pick names and stick to them — inconsistent field names break dashboards.

For **Flask requests**, log at the end of the request cycle with `method=`, `path=`, `status_code=`, `duration_ms=`. Flask's default access log does this; for internal tools, wire it through a `@app.after_request` handler so you can add custom fields like `run_id` or `user`.

---

## 8. What NOT to log

Log lines are often aggregated into systems with broad access and long retention. Treat log output as semi-public.

**Never log:**
- API tokens, passwords, or any credential — even partially. Use `token=***` if you must indicate a token was present.
- Full API responses from external systems — they may contain other users' data.
- Full Jira ticket descriptions or comments — they may contain PII or sensitive content.
- Personal data (email addresses, names, phone numbers) from tickets or config.
- LLM prompt content or LLM responses in full — log a truncated excerpt or a hash for correlation only.
- SQL query parameters that might contain user data.

**Log enough to debug, not enough to reconstruct the data:**

```python
# WRONG — logs the full ticket body
logger.info("processing issue: %s body=%s", key, issue["fields"]["description"])

# RIGHT — log identity and size only
logger.info(
    "processing issue key=%s body_len=%d",
    key, len(issue["fields"].get("description") or ""),
)
```

For detail on PII in logs, see [data-handling-pii](../data-handling-pii/SKILL.md). For credential hygiene in logs, see [python-internal-tools / security.md](../python-internal-tools/security.md).

---

## 9. SLI/SLO basics

**SLI (Service Level Indicator):** The actual measurement. A number you can compute from logs or metrics.

**SLO (Service Level Objective):** The target for that measurement. A promise to yourself (or your users) about acceptable behavior.

**For internal tools, keep it simple.** Start with one or two SLOs and review them monthly.

**Example SLOs for a Jira triage CLI:**

| SLO | SLI | Target |
|-----|-----|--------|
| Run success rate | `completed_runs / started_runs` (rolling 7 days) | ≥ 99% |
| Scheduled run frequency | Successful runs in the expected window | 0 missed windows per week |
| Triage latency | p95 duration per run | ≤ 30 s |

**Example SLOs for a Flask internal service:**

| SLO | SLI | Target |
|-----|-----|--------|
| Availability | `/ready` returning 200 (checked every 5 min) | ≥ 99.5% |
| Error rate | HTTP 5xx / total requests (rolling 1 hour) | ≤ 1% |
| Latency | p95 response time on main routes | ≤ 2 s |

**How to use SLOs:**

- An SLO **breach** should trigger an alert. An SLO **approaching** breach (error budget burning fast) is an early warning.
- Review SLOs monthly. If you never breach them, you may be able to relax targets and reduce alert noise. If you breach them regularly, either fix the service or adjust the SLO to reflect what is actually achievable.
- SLOs are not a performance review tool. They are a shared understanding of what "working" means.

**Error budget:** `(1 - SLO target) × time window`. For a 99.5% availability SLO over 30 days: `0.005 × 30 × 24 × 60 = 216 minutes` of allowed downtime. Tracking error budget consumption helps prioritize reliability work.

---

## 10. Checklist for adding observability to a new service

Use this when you ship a new Flask service or CLI.

**Health endpoint (Flask):**
- [ ] `/health` returns `200 {"status": "ok"}` when the process is running
- [ ] `/ready` checks DB connectivity (and any other critical deps) — returns `503` on failure
- [ ] Both endpoints are registered and tested with the Flask test client
- [ ] `/health` is excluded from auth middleware (public endpoint for uptime monitors)

**Key counters / log fields:**
- [ ] Runs/requests: started, completed, failed
- [ ] Items processed and error count
- [ ] `duration_ms` in the terminal log line for every major operation
- [ ] `run_id` or `request_id` present in log lines for correlation to DB rows
- [ ] External API call failures logged at WARNING with status code

**Alerting:**
- [ ] At least one symptom-based alert defined (success rate or availability)
- [ ] Alert threshold derived from a baseline (observed data, not a guess)
- [ ] Each alert has a runbook entry (what to check, who owns it)

**What not to log:**
- [ ] No tokens, passwords, or credentials in any log line
- [ ] No full API responses or Jira ticket bodies in logs
- [ ] No PII (names, email addresses) from tickets or config

**SLO (optional for new internal tools, recommended after first month in production):**
- [ ] One SLO defined for run success rate or availability
- [ ] Review reminder in backlog for 30 days post-launch

---

## Related

- **Structured log format, levels, correlation IDs:** [python-internal-tools / logging-structured.md](../python-internal-tools/logging-structured.md)
- **What not to log (PII, sensitive data):** [data-handling-pii](../data-handling-pii/SKILL.md)
- **Credential and secret hygiene in logs:** [python-internal-tools / security.md](../python-internal-tools/security.md)
- **Flask health endpoint + security headers + auth:** [python-internal-tools / flask-serving.md](../python-internal-tools/flask-serving.md)
- **Docker HEALTHCHECK (maps to /health):** [docker-containerization](../docker-containerization/SKILL.md)
- **Incident review after an SLO breach:** [blameless-postmortems](../blameless-postmortems/SKILL.md)
- **Monitoring background workers and job queues:** [`background-jobs`](../background-jobs/SKILL.md)
- **Debugging tracebacks and slow queries:** [`debugging-profiling`](../debugging-profiling/SKILL.md)
- **Routing:** [`../../SKILLS.md`](../../SKILLS.md)

## Source

Authored for **ai-skills**. Prometheus metric names and SLO targets are illustrative — calibrate to your team's infrastructure and review cycle. Consult your organization's security logging and monitoring policy for platform-level retention requirements.
