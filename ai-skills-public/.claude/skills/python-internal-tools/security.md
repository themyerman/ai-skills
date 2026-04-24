# Security, APIs, and threat thinking

<!-- Split from the developer guide. Canonical: [`../../.claude/CLAUDE.md`](../../.claude/CLAUDE.md). **Formal** org threat model / security program → your internal runbooks and [shift-left-program/](../shift-left-program/SKILL.md) (lightweight) — *not* duplicated here. Jira/CLI: [jira.md](jira.md). LLM: [llm-integrations-safety](../llm-integrations-safety/SKILL.md). **Slack / wiki / email, CI, K8s, leak response** (broad eng, not Python-only): [secrets-management](../secrets-management/SKILL.md). -->

## 4. Security & API Integration

### Never hardcode credentials

All secrets go in `config.yaml` (gitignored) or environment variables. Never in source code, never in URLs.

```python
{"Authorization": f"Bearer {token}"}   # correct
# NOT: f"https://api.example.com?token={token}"
```

### Validate input at system boundaries

User-facing inputs (CLI args, HTTP params, YAML config values) must be validated before use. Write a dedicated validator function and test it exhaustively:

```python
MAX_JQL_LENGTH = 4000

def validate_jql(jql: str) -> None:
    if not isinstance(jql, str):
        raise ValueError("JQL must be a string")
    if not jql.strip():
        raise ValueError("JQL is empty or blank")
    if len(jql) > MAX_JQL_LENGTH:
        raise ValueError(f"JQL exceeds maximum length of {MAX_JQL_LENGTH}")
    if "\x00" in jql:
        raise ValueError("JQL contains null byte")
    for ch in jql:
        if ord(ch) < 32 and ch not in ("\t", "\n", "\r"):
            raise ValueError(f"JQL contains control character {ord(ch):#x}")
        if ord(ch) == 0x7F:
            raise ValueError("JQL contains DEL character")
```

Things to always validate: emptiness, type, length, character set (reject null bytes and control chars), path traversal (`..`).

### Use parameterized queries — always

Never format user data into SQL strings.

```python
# WRONG — SQL injection risk
conn.execute(f"SELECT * FROM issues WHERE issue_key = '{key}'")

# RIGHT — parameterized
conn.execute("SELECT * FROM issues WHERE issue_key = %s", (key,))
```

The `%s` placeholder works for SQLite, PostgreSQL, and MySQL. Do not use `?` (SQLite-only).

### Use requests.Session for HTTP clients

Create one `Session` per client instance. This reuses connections, applies default headers once, and is easier to test:

```python
class JiraClient:
    def __init__(self, base_url: str, token: str) -> None:
        self._base_url = base_url.rstrip("/")
        self._session = requests.Session()
        self._session.headers.update({
            "Authorization": f"Bearer {token}",
            "Accept": "application/json",
            "Content-Type": "application/json",
        })
        self._session.timeout = 30

    def get(self, path: str, **kwargs: object) -> requests.Response:
        return self._session.get(f"{self._base_url}/{path.lstrip('/')}", **kwargs)
```

Never call `requests.get(url)` directly in a loop — each call opens a new connection.

### Retry transient HTTP failures with backoff

Retry on 429 and 5xx. Do not retry on 4xx (client errors are your bug). Respect `Retry-After` when present:

```python
import time

_RETRYABLE = frozenset({429, 500, 502, 503, 504})

def _request_with_retry(
    session: requests.Session,
    method: str,
    url: str,
    max_retries: int = 3,
    **kwargs: object,
) -> requests.Response:
    for attempt in range(max_retries):
        resp = session.request(method, url, **kwargs)
        if resp.status_code not in _RETRYABLE:
            return resp
        if attempt < max_retries - 1:
            wait = int(resp.headers.get("Retry-After", 2 ** attempt))
            logger.warning("HTTP %s — retrying in %ds", resp.status_code, wait)
            time.sleep(wait)
    return resp
```

### Subprocess safety

Never pass `shell=True` or interpolate user input into a command string. Always use a list of arguments:

```python
# WRONG — shell injection risk
subprocess.run(f"git log {branch}", shell=True)

# RIGHT
subprocess.run(["git", "log", branch], check=True, capture_output=True, text=True)
```

Validate any user-supplied values before passing them as arguments. If the value can contain spaces or special characters, treat it as untrusted.

### Limit what you store

Truncate external content before writing to the database. This prevents runaway storage and protects against excessively large payloads:

```python
(description_preview or "")[:8000]
url[:4096]
content_text[:10_000]
```

### Detect login walls

When fetching content from APIs, a 200 response with HTML body often means you hit a login redirect, not real content. Check content-type:

```python
if "html" in r.headers.get("content-type", "").lower():
    return "", "skipped"   # login wall — don't store garbage
```

### Checklist when adding a new external API

- [ ] Credentials in config.yaml, never in code
- [ ] Config section documented in config.example.yaml
- [ ] Token in Authorization header (Bearer or Basic), never in URL
- [ ] Request timeout set (15–30s default)
- [ ] Use `requests.Session`, not one-off `requests.get()`
- [ ] Retry on 429 and 5xx; do not retry on 4xx
- [ ] Check `r.ok` before reading `r.json()`
- [ ] Detect login-wall responses (200 + HTML body)
- [ ] Truncate response content before storing
- [ ] Log failures at WARNING or ERROR, not DEBUG
- [ ] Graceful degradation: return `("", "skipped")` when credentials are absent
- [ ] Test with `unittest.mock.patch("requests.Session")` for unit tests

---

## 5. Threat thinking *for people writing code* (not the full org program)

The long guide’s **[`.claude/CLAUDE.md` §5](../../.claude/CLAUDE.md) is short (quick questions and org handoff). **This** section keeps the full **code-habit** table, logging list, and escalation text for the skill.

**Two layers (don’t conflate them):**

| Layer | What it is | Where to go |
|--------|------------|------------|
| **Program / team threat model** | **Your** org’s **formal** TM, **SDLC** or **AppSec** **process** (artifacts in repo, **DOR** or **arch** **review,** and so on) | **Internal** runbooks, portals, and [shift-left-program/](../shift-left-program/SKILL.md) for a **thin** habits layer only. |
| **This section** | **Day-to-day** “what could go wrong in *this* script, API client, or pipeline?” at **boundaries** (strings in, data out) | Right here: five questions + pattern table + logging. A **note in `docs/`** can be enough to *think*; it is **not** a substitute for a **required** team TM when your **org** program says you need one. |

You don’t need a 50-page process to think like an attacker in code. Ask these at every boundary — **CLI** input, **HTTP**, **DB write**, **config** load, **subprocess** args, **LLM** prompts that see ticket text (see **llm-integrations-safety**).

### The five questions

1. **What data am I handling?** Classify it: credentials, PII, internal system details, user-provided strings. Each category has different handling requirements. For a **broader** take on **PII**, **exports**, **Jira/Slack/wiki**, and **minimization**, see **[`data-handling-pii`](../data-handling-pii/SKILL.md)**.
2. **Where does it go?** Trace the data flow: input → processing → storage → output. Every hop is a potential leak or injection point.
3. **What if the input is malicious?** Assume every string from outside your process is adversarial. Validate type, length, character set, and structure before use.
4. **What if an external system lies?** APIs return unexpected shapes, wrong status codes, HTML instead of JSON, and empty responses. Handle all of these explicitly.
5. **What's the blast radius if this breaks?** A bug in a read-only reporting script is low severity. A bug in something that writes to production or sends alerts is high severity. Design accordingly.

### Common threat patterns and mitigations

| Threat | Where it appears | Mitigation |
|---|---|---|
| SQL injection | Any query built from user input | Parameterized queries, always |
| Shell injection | `subprocess` calls with user input | Never `shell=True`; always use arg lists |
| Path traversal | File paths from config or CLI args | Validate against allowlist or `Path.resolve()` |
| Credential leak | Logs, error messages, URLs | Never log tokens; use headers not URL params |
| Login-wall confusion | HTTP fetches returning 200 + HTML | Check `content-type` before treating as success |
| Unbounded storage | Storing API response text | Truncate all external content before INSERT |
| Token scope creep | One token used for multiple systems | Separate tokens per system (Jira ≠ wiki) |
| Deserialization | `yaml.load()` with untrusted input | Use `yaml.safe_load()` always |
| Dependency confusion | `pip install` from untrusted indexes | Pin versions in requirements, use private indexes |

### On logging

Log enough to reconstruct what happened in an incident — but never log:
- Tokens, passwords, or API keys (even partially)
- PII (names, emails, user IDs) unless explicitly required and approved
- Full request/response bodies from external APIs (they may contain secrets)

**At your org:** read the **current** **Application Security** and **Logging** / **Observability** / **retention** policies in **your** **published** set—**not** this file—for what must not appear in application or system logs. If the live **policy** and the bullets **above** disagree, **the policy wins**. For **AUP,** data classes, and broader data handling, use **[`data-handling-pii`](../data-handling-pii/SKILL.md)**.

[logging-structured.md](logging-structured.md) adds *correlation* and *field* habits; it does not override the policy site.

Log at the right level:
- `DEBUG`: internal state useful during development
- `INFO`: significant operations completed successfully (run started, N issues fetched)
- `WARNING`: something unexpected happened but we recovered (fetch skipped, content truncated)
- `ERROR`: something failed and the user needs to know

### When to *escalate* beyond this section

**Still at the code / tool level:** if the feature touches **credentials, PII, new external APIs,** paths to **DB/filesystem,** or runs **unattended** in production, do a **deeper** review: write a short `docs/*.md` bullet list (what can go wrong, blast radius) and tighten tests. That **complements** the five questions; it is **not** the same as a **formal** team **threat** model or **program** sign-off when your org requires it.

**Hand off** to the **official** org path (security, architecture, or program **threat** **modeling**) when the change is or could be **significant** for **security** design, you need a **formal** threat model, you are **onboarding** a new **vendor** that touches **data,** or **policy** says to **escalate** early. Use your **internal** runbooks and **champions**; **[shift-left-program/](../shift-left-program/SKILL.md)** is only a **high-level** nudge, not a substitute for your employer’s process.

---
