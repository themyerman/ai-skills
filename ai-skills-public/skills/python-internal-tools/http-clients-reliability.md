# HTTP clients: reliability and production behavior

<!-- Typical: Jira `jira_client.py` (retries, `Retry-After`), and an **LLM** `llm_client.py` with the same ideas. [security.md](security.md) (Session, timeouts, no secrets in logs). Jira: [jira.md](jira.md). -->

Internal tools spend a lot of time calling **REST** APIs (Jira, **internal** **services,** **GitHub,** **wikis**). Reliability is not “retry until it works” — it is **predictable** retries, **clear** failure modes, and **safe** logging.

---

## 1. One `Session` (or client) per logical unit of work

- Reuse **TLS**, **connection pool**, and **default headers** via `requests.Session` (or an `httpx` client with limits). **Do not** call `requests.get` in a tight loop for the same host.
- Set **default timeout** on the session or every call (e.g. **15–30s** read/connect as appropriate). **Never** leave infinite timeout on network code that runs in **cron** or **web** requests.

---

## 2. What to retry (and what not to)

- **Retry** (with backoff): **429**, **502**, **503**, **504**; honor **`Retry-After`** when present (cap to a **max** wait to avoid blocking a worker forever).
- **Do not** retry blindly on **4xx** except **429** — **401/403/404** usually mean **config, auth, or bad path**; fix the bug or **fail fast** after one attempt.
- **Idempotency:** for **PUT/POST** that are **not** idempotent, **only** retry if the server documents it or you have a **dedup** key. Otherwise **at-most-once** is safer than double-submit.

**Typical pattern** (e.g. a `JiraClient._request`): loop `0..N-1`, on retryable status **sleep** `int(Retry-After or 2**attempt)` seconds, log **method, path, status, attempt** — **not** request body or full URL with secrets.

---

## 3. Backoff and limits

- **Exponential backoff** with a **ceiling** (e.g. max 60s) avoids hammering a sick upstream.
- **Jitter** (optional) reduces thundering herds if many workers retry at once.
- **Max attempts** (e.g. 3–5) — then **return** the last response or **raise** a **typed** error the caller can handle.
- Distinguish **“give up and surface to human”** from **“degrade: skip and continue batch.”**

---

## 4. Timeouts, cancellation, and deadlines

- Use **separate** connect vs read timeouts if the library allows (`httpx`, `urllib3` timeouts on `Session`).
- For **long** streaming or LLM calls, a **higher** read timeout is OK if **documented**; still avoid **infinite** wait.
- **Async:** use **`asyncio.wait_for`** (or httpx’s timeouts) and **do not** block the event loop with `time.sleep` in async code.

---

## 5. Response handling

- **Check** `r.ok` or **explicit** status before **`r.json()`** — a **200 + HTML** login page is a **bug**, not “success” — see *Detect login walls* in [security.md](security.md).
- **Parse errors:** catch **`JSONDecodeError`**; treat as **transient** or **bug** based on **status** and **content-type**.
- **Rate limits:** some APIs return **429** with a **JSON** body; log **enough** to support a ticket, **not** the whole response if it can contain PII.

---

## 6. LLM and vendor SDKs

- **LLM**-specific: **[llm-integrations-safety](../llm-integrations-safety/SKILL.md)** (mock in CI, `SECURITY NOTICE`, no silent mock in prod).
- For **CIS/Anthropic**-style clients, mirror the same: **retries** on 429/5xx, **no** log of full **prompt/response** in **INFO** [[security.md](security.md#on-logging)].

---

## 7. When to reach for a library

- **Tenacity** / **backoff** / **urllib3 Retry** — useful if many call sites; keep **one** **policy** (max attempts, which codes) in **config** or constants.
- **httpx** — async + HTTP/2; good when you outgrow ad-hoc `requests` in **scripts**; still **one client** per process scope.

---

## 8. Checklist (new client)

- [ ] `Session` + default headers + **timeout**  
- [ ] **Retry** only **429/5xx**; **`Retry-After`**, **max** attempts, **max** wait  
- [ ] **No** retry on most **4xx**  
- [ ] **Idempotency** understood for **writes**  
- [ ] **No** auth token in logs or error strings  
- [ ] **Login wall** and **content-type** checks for “success”
