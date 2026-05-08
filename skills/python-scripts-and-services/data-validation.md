# Data validation at boundaries

<!-- Ties to [security.md](security.md#validate-input-at-system-boundaries) (JQL example) and [jira.md](jira.md) for Jira key shape. Typed config: [config-flags.md](config-flags.md). Central **validate_issue_key** / JQL / exclusions patterns in your `jira` + config code. -->

**Validate** as soon as **untrusted** or **externally produced** data **enters** your process: **CLI** args, **query params**, **JSON** from Jira, **file** upload paths, **YAML** you didn’t hand-author. After validation, treat values as **typed** for the rest of the **call path**.

---

## 1. **Where** the boundary is

- **Flask** `request.args` / `request.json` / **form** fields.  
- **argparse** string flags that become **paths** or **issue keys**.  
- **Jira** REST: **issue_key**, **JQL**, custom **field** ids, **proforma** payloads.  
- **CSV** rows (even “internal” exports can have **mojibake** and **injection**-weird text).  
- **Config** loaded from disk — if **merged** with **env**, validate **after** merge.

**Do not** **sprinkle** ad hoc `if not x` — **one** `validate_foo` per concern, **reused** by CLI and **HTTP** if the same data appears in both.

---

## 2. **What** to check (order of cost)

1. **Type** — is it `str` / `int` / the **right** container?  
2. **Presence** — non-**empty** after **strip** where that matters.  
3. **Length** — JQL, **description** snippets, **paths**; reject **huge** strings early.  
4. **Character set** — **null** bytes, **control** chars, **newlines** in a **one-line** key.  
5. **Semantic** rules — **Jira** key `^[A-Z][A-Z0-9_]+-\d+` (your org’s pattern if different), **JQL** max **length** and **banned** fragments if you have policy.  
6. **Path** safety — **no** `..` in user-provided file paths, **resolve** under a **chroot** or **allowlisted** base dir (path traversal in [security.md](security.md) *Common threat patterns* table).

---

## 3. **Pydantic** and friends

- **`BaseModel` with field validators** for **config** and **inbound** JSON: **one** place for **“field X is required”** and **types**.  
- **`pydantic-settings`** if you like **env** with **parsing**; align with [config-flags](config-flags.md).  
- For **Jira** issue JSON, **submodel** the **one** or **two** **nested** **objects** you read — not the **full** 200+ **fields**.

---

## 4. **Jira-**specific helpers

- **Issue key** — **central** function used by **JiraClient** and **triage** (one **validate_issue_key**-style entry point).  
- **JQL** — **dedicated** validator, **separate** from `str` in **type hints** (e.g. `ValidJql` **NewType** only **after** validation) if you want **mypy** to help.  
- **Exclusions** in yaml — at **load**, ensure **type** and **date** **formats**; **log** a **sum** of **excluded** keys at **ingest** end, not **per key** in **INFO**.

---

## 5. **CSV and flat files**

- For **Pandas/CSV** reading: **dtypes** or **converters** for **int** columns; **fail** on **unexpected** column **names** if the **file** is **not** a **free** form.  
- **Stream** very large **files** — don’t `read()` **multi-GB** into a **str** in **one** go.

---

## 6. **Error surface**

- **Raise** `ValueError` (or a **small** **custom** `ValidationError`) with a **user-fixable** message: **“JQL is empty”** not **“invalid”**.  
- In **Flask**, map **ValueError** to **400** with a **body**; **log** the **key** and **param name**, **not** a **2MB** echo of **input**.

---

## 7. **With LLM** outputs

- If you **parse** model **JSON**, use **Pydantic** (or `json` + **assert shape**) **before** **storing** — [llm-integrations-safety](../llm-integrations-safety/SKILL.md). **Never** trust the **format** is stable across **prompt** versions; **version** the **expected** **schema** in a **const** and **test** a **sample** of **historical** rows in CI.

---

## 8. **Checklist**

- [ ] **One** **validator** per **external** **shape**; **reused** across **CLI** and **HTTP** if applicable  
- [ ] **Type → length → charset → semantics** order  
- [ ] **No** **SQL** f-strings; **parametrize** (see [security](security.md) *Use parameterized queries*)  
- [ ] **LLM** and **Jira** JSON get **strict** or **Pydantic** first  
- [ ] **Errors** **actionable** for a **human**
