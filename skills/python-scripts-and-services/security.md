# Security, APIs, and threat thinking

<!-- Related: formal security program → [shift-left-security/](../shift-left-security/SKILL.md). Jira/CLI: [jira.md](jira.md). LLM in app code: [llm-integrations-safety](../llm-integrations-safety/SKILL.md). Secrets, CI, K8s: [secrets-management](../secrets-management/SKILL.md). -->

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

## 5. Threat thinking *for people writing code*

This section is about code-level habits — not about running a formal security program. It answers: “what could go wrong in this script, API client, or pipeline?”

**Two layers — keep them separate:**

| Layer | What it is | Where to go |
|--------|------------|------------|
| Formal threat model / security review | Your org’s AppSec process — design reviews, architecture sign-off, formal TM artifacts | Your org’s internal runbooks; [shift-left-security/](../shift-left-security/SKILL.md) for a lightweight habits overview |
| This section | Day-to-day: “what could go wrong at this boundary?” | Right here — five questions, pattern table, logging guide. A short note in `docs/` is often enough; it is not a substitute for a formal review when your org requires one. |

You don’t need a 50-page process to think like an attacker in code. Ask these at every boundary — CLI input, HTTP, DB write, config load, subprocess args, LLM prompts that see user-supplied text (see [llm-integrations-safety](../llm-integrations-safety/SKILL.md)).

### The five questions

1. **What data am I handling?** Classify it: credentials, PII, internal system details, user-provided strings. Each category has different handling requirements. For a deeper look at PII, exports, and minimization, see [`data-handling-pii`](../data-handling-pii/SKILL.md).
2. **Where does it go?** Trace the data flow: input → processing → storage → output. Every hop is a potential leak or injection point.
3. **What if the input is malicious?** Assume every string from outside your process is adversarial. Validate type, length, character set, and structure before use.
4. **What if an external system lies?** APIs return unexpected shapes, wrong status codes, HTML instead of JSON, and empty responses. Handle all of these explicitly.
5. **What’s the blast radius if this breaks?** A bug in a read-only reporting script is low severity. A bug in something that writes to production or sends alerts is high severity. Design accordingly.

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

These bullets cover the common cases. If your org has a published logging or data retention policy, that takes precedence. For PII classification and broader data handling, see [`data-handling-pii`](../data-handling-pii/SKILL.md).

[logging-structured.md](logging-structured.md) adds *correlation* and *field* habits; it does not override the policy site.

Log at the right level:
- `DEBUG`: internal state useful during development
- `INFO`: significant operations completed successfully (run started, N issues fetched)
- `WARNING`: something unexpected happened but we recovered (fetch skipped, content truncated)
- `ERROR`: something failed and the user needs to know

### When to escalate beyond this section

**Still at the code level:** if the feature touches credentials, PII, new external APIs, paths to DB/filesystem, or runs unattended in production, do a deeper pass: write a short `docs/*.md` note (what can go wrong, blast radius) and tighten the tests. That complements the five questions — it is not the same as a formal threat model or security review when your org requires one.

**Hand off** when the change is security-significant in design (new auth flow, new external data integration, new service boundary), when you need a formal threat model, or when policy says to escalate early. See [shift-left-security/](../shift-left-security/SKILL.md) for a lightweight overview of when to escalate and how.

---
