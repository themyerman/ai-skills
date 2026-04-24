# Config loading, environment, and feature flags

<!-- Pattern: `config.yaml` + `config.example.yaml` in repo root or `config/`. *Load config once* in [reference.md](reference.md) §2. Secrets: [security.md](security.md). -->

Internal tools are usually driven by a **root** or **`config/*.yaml`**, sometimes **overridden** by **environment variables**. This note standardizes **load order**, **validation at startup**, and **feature toggles** without a heavy framework.

---

## 1. Committed **example** vs local **real** config

- **Commit** `config.example.yaml` (or `config/config.example.yaml`) with **all** keys, **commented** optional values.
- **Gitignore** the real `config.yaml` (and `.env` if you use it).  
- **Reference** the example path in `README` **Setup**; never commit **tokens** even “for test.”

---

## 2. Load **once** at the entry point

- **`load_config()`** in `main()`, then pass `config: dict` into functions (see [reference.md](reference.md) *Load config once*). **Avoid** re-reading the file in hot paths; **reloading** is a **rare** explicit `SIGHUP` or admin only.

---

## 3. **Fail fast** on required keys

- If **`jira.base_url`** (or your API base) is missing, **exit** in **`main()`** with a **clear** message before any network. Same for **PATs** in dev—**don’t** half-start and fail at **minute 20** of a batch. See **get_jira** on [jira.md](jira.md) and “Validate config at startup” in [reference.md](reference.md).

---

## 4. Environment **override** order (suggested)

1. **Explicit** CLI **flags** (highest) — e.g. `--config other.yaml`  
2. **Process environment** — `DATABASE_URL`, `LOG_LEVEL` for **12-factor**-style  
3. **File** from `--config` or default path  
4. **Built-in defaults** in code (lowest)

**Document** the order in `README` so on-call is not **surprised** that `env` beats `yaml`.

---

## 5. Feature **flags** (lightweight, not LaunchDarkly)

- **Booleans** in YAML, e.g. `behaviour.include_preview_runs: true` — use **boring** names, **one** place in config.
- For **killswitch**-style: **`features.enable_something: true`**, default **False** in **code** for **risky** paths, **True** in **example** only if safe.
- **Do not** scatter **`if os.environ.get("DEBUG")`**: prefer **`config.get("debug", false)`** with a **documented** key.
- If you need **A/B** or per-team rollout, you’ve outgrown “one yaml”—use a **real** system or a **separate** small `flags.yaml` **with** a **schema** comment at top.

---

## 6. **Typed** config (optional)

- For **larger** tools: **`pydantic`** v2 `BaseModel` for the **config tree**, or **`TypedDict`** for **simpler** static checks. **Validate** once at **startup**; fail with **Pydantic**’s error message (or wrap with “fix key X”).
- **Tradeoff:** adds **dependency**; worth it when **10+** keys and **nested** structure.

---

## 7. Layering: **per-environment** file

- Optional: `config/prod.yaml` **merged** on top of **base** — only if the team can **reproduce** merges; otherwise **one** file per **deploy** and **no** merge.

---

## 8. Checklist (new tool)

- [ ] **Example** + **real** in `.gitignore`  
- [ ] **Validate** required fields before **I/O**  
- [ ] **One** `config` object passed through **call graph** (not globals)  
- [ ] **Documented** `env` vs file **precedence**  
- [ ] **Flags** in **one** place; **kills** dangerous paths with **default off**
