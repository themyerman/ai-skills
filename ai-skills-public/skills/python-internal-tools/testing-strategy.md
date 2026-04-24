# Testing strategy (beyond “run pytest”)

<!-- Baseline: [reference.md](reference.md) §7. **Jira** mocks: [jira.md](jira.md). **Example:** tests that patch `requests` for retry / `Retry-After` (your project’s `test_jira_client` or similar). -->

The guide already says: **real SQLite in tests** with **`tmp_path`**, **no** DB mocks, **mock HTTP** and **LLM** at the boundary, **idempotence** for `init_db` — [reference](reference.md) **§7 Testing philosophy**. This file adds **strategy**: **what** to test, **where** fakes are OK, and how to **tighten** without **brittle** snapshots of internals.

---

## 1. Test at **boundaries**, not every private helper

- **Unit tests** the **public** or **stability-implied** API of a module: “given **input X**, **DB** state is **Y**,” not “`helper_foo` called 3 times.”
- **Integration-ish** one layer up: `JiraClient` with **mocked** `requests` (e.g. patch at **`request`**) to assert **retries** and **paths** — keep a **dedicated** test file for 429 + `Retry-After` (see your HTTP client’s tests).  
- **End-to-end** in CI only when you have a **dedicated** stack; most internal tools keep **no live Jira** in CI (use **recorded** fixtures or **small** JSON under `tests/fixtures/`)

---

## 2. Fakes: **allowlist**

| **Fake / mock** | **OK** |
|----------------|--------|
| `requests` / `httpx` to **Jira, CIS,** third APIs | **Yes** — `unittest.mock.patch` or a **test double** with same interface as your **client** class. |
| **Time** / **random** for **determinism** | **Yes** — `freezegun` or `random.seed(0)` in the **test** only. |
| **Subprocess** | **Yes** when testing “we **build** the argv right”; **or** use **true** `subprocess` in a **separate** slow job with **toy** script. |
| **SQLite** | **Prefer real** file or `:memory:`. **No** `MagicMock` for `conn`. |
| **LLM** | **Yes** — inject **`mock_llm_client`**; see [llm-integrations-safety](../llm-integrations-safety/SKILL.md). |
| **Your** `load_config` | **Sometimes** pass **`dict` literal**; **not** a mock if you can **build** a temp yaml file with **`tmp_path`**. |

---

## 3. **Contract** tests for HTTP

- If you own both **sides** of a **shim** (e.g. **CIS** JSON shape), keep **one** test with **realistic** `response.json()` payload **pasted** from a **redacted** capture, **versioned** in `fixtures/`. **Update** when the vendor **documents** a change.  
- **VCR** / **pytest-httptest**-style — good if **many** endpoints; **re-record** on **API** bumps; **redact** tokens in **cassettes** (or **gitignore** them and **generate in CI** from **secrets** — heavier).

---

## 4. **Parametrize** the matrix you care about

- **Retry** after **429** with **`Retry-After: 0`** and **`5`**, **3** max attempts, **exponential** fallback — validate in the same `JiraClient` (or httpx) test module.
- **JQL** rejections: **empty**, **null byte**, **too long** — see [security’s validate_jql](security.md) + tests **per** rule.

---

## 5. **Property-based** (optional)

- **Hypothesis** for **parsers** (Jira key regex, **URL** extractors) — use when **bugs** come from **weird** Unicode, not for **all** business logic. **Start** with **2–3** hand examples, then add **property** if **edge** cases still slip.

---

## 6. **Flask**

- **Test client** for **200** and **one** `GET` on **data**-heavy page with **min** DB in **tmp_path**; **not** 50 **full** HTML assert — assert **one** `key` in `response.get_data(as_text=True)` or use **`html` in response.data** for **structural** checks.  
- **CSRF** if you add **POST** forms — [flask-serving](flask-serving.md#8-what-this-doc-is-not).  

---

## 7. **Coverage** and **gating**

- **Coverage** in CI: **treat** 80% as a **default**; **allow** `pragma: no cover` for **rare** error branches with a **comment** why. **Don’t** **game** the metric with **useless** asserts.  
- **`xfail`** only for **known** product bugs; **quarantine** and **ticket**.

---

## 8. **Checklist (new feature)**

- [ ] **Happy path** + at least **one** **“bad input”** path  
- [ ] **Boundary** the **I/O** (HTTP / DB) — **mocks** only on those  
- [ ] **No** **mocking** the **DB** for **persistence** logic  
- [ ] **Deterministic** (no `time.time()` in assertion without **control**)  
- [ ] **Fixture** for **Jira/JSON** in **`tests/fixtures/`** if reused
