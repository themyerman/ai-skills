# Code review & PRs (internal Python)

<!-- Triggers: code review, PR, pull request, ship this, merge readiness, pre-merge, reviewer. Complements: [testing-strategy](testing-strategy.md), [security](security.md), [shift-left-program](../shift-left-program/SKILL.md). -->

This file is the **Python-internal-tools** slice for **human or agent** review before merge. It does **not** replace team policy, required approvers, or your org’s **formal** security or threat-model program when that applies.

---

## 1. What this review is for

| Goal | Not in scope for this doc alone |
|------|----------------------------------|
| Catch **merge blockers** (security smell, missing tests, broken config contract) | Final **AppSec** sign-off or a **formal** org security process (if your team uses one) |
| Keep **diffs reviewable** (size, factoring, commit message clarity) | **Style** nits that **ruff** / CI already enforces (unless config is wrong) |
| Tighten **tests** and **observability** for the change | Re-architecting the product **without** a design request |

---

## 2. Author checklist (before you ask for review)

- [ ] **Scope** is one **coherent** change; if huge, **split** PRs (stacked branches are OK).  
- [ ] **`config.example.yaml`** (or env doc) updated if you added **keys** or **defaults** — [config-flags](config-flags.md).  
- [ ] **Tests** run **locally** (or same **CI** job you expect on push) — [testing-strategy](testing-strategy.md).  
- [ ] **Secrets** not in the diff; **PII** in logs called out or removed — [security](security.md).  
- [ ] **`README` / `WORK.md` / `docs/`** touched if user-facing **behavior** or **ops** changed — [documentation](documentation.md).  
- [ ] If the change is **significant** for **security** or **threat**-relevant design, the **formal** org path (per runbooks) **before** or **in parallel** with code review is already **considered** — [shift-left-program](../shift-left-program/SKILL.md), **[`CLAUDE.md` §5](../../.claude/CLAUDE.md)**.  

---

## 3. Reviewer pass (order matters)

### A. **Intent & API**

- **What** user or operator problem does this PR solve? **Title** and **description** should say it in one read.  
- **Public** surface (CLI flags, HTTP routes, `pyproject` entry points) is **documented** and **backward compatible** or **versioned** / **called out** in notes.

### B. **Security & boundaries**

- New **HTTP**, **subprocess**, **SQL**, **path**, **YAML/JSON** handling — see [security](security.md) and [data-validation](data-validation.md).  
- **New dependency** — pin; **transitive** risk called out; no **accidental** wide version ranges without reason — [packaging](packaging.md).  
- **LLM** path touched — [llm-integrations-safety](../llm-integrations-safety/SKILL.md).

### C. **Reliability & ops**

- **Retries**, **timeouts**, **idempotency** for **writes** — [http-clients-reliability](http-clients-reliability.md).  
- **Logging** for new **failure** paths — [logging-structured](logging-structured.md), *On logging* in [security](security.md).  
- **Migrations** / **SQLite** behavior under **concurrency** if relevant — [sqlite-patterns](sqlite-patterns.md).

### D. **Tests**

- **Happy** + at least one **unhappy** path for new logic — [testing-strategy](testing-strategy.md) §8.  
- **Mocks** only at **I/O** boundaries; **real** DB for persistence logic.  
- **No** new **flaky** time/network dependence without **control** in test.

### E. **Size & style**

- Prefer **under ~400** lines of **product** change per PR where possible; otherwise **call out** what is **mechanical** (rename) vs **risky**.  
- **Types** and **`from __future__ import annotations`** consistent with [reference](reference.md) §8.  
- **Ruff/CI** green; don’t spend review time on what **lint** already fixes.

---

## 4. Red flags (hold merge)

- **Secrets** or **tokens** in code, tests, or fixtures (even “test” keys that look real).  
- **Broad** `except` or **swallowed** errors on **I/O** paths.  
- **User / ticket** text to **LLM** without **screening** and **audit** path when the product does that.  
- **New** external integration **without** **config** or **allowlist** story.  
- **Obvious** missing test for a **regression** the PR **claims** to fix.  

---

## 5. Suggested review comment template

Use this structure so the author can **route** work (and so an **agent** can output consistent feedback).

```text
## Summary
(1–2 sentences: what changed, why merge or why not yet.)

## Blockers
- (none | list)

## Suggestions (non-blocking)
- …

## Tests
- **Covered:** …
- **Gap:** … (if any)

## Cross-links
- Security / org program: (n/a | see …)
```

---

## 6. When to pull in other skills

| Question | Use |
|----------|-----|
| Jira / **Allowlist** / **preview** behavior | [jira](jira.md) |
| **Flask** / internal UI | [flask-serving](flask-serving.md) |
| **Instructional** docs (README, install, runbook, **plain** English) | [docs-clear-writing](../docs-clear-writing/SKILL.md) (hub); [plain-english.md](../docs-clear-writing/plain-english.md) (wording); [documentation](documentation.md) (Python **layout**) |
| **Formal** security or **threat** **model** **(when** your **org** **requires** **it** **)** | [shift-left-program/SKILL.md](../shift-left-program/SKILL.md) + **internal** runbooks |
| **Shell** / CSV **one-offs** (not this package) | [shell-csv-pipelines](../shell-csv-pipelines/SKILL.md) in **ai-skills** |
| **HTML / CSS / UI** or **a11y** of a page (default read order) | [web-frontend-basics](../web-frontend-basics/SKILL.md) → [web-layout-css](../web-layout-css/SKILL.md) → [web-accessibility](../web-accessibility/SKILL.md) ([`SKILLS.md` chart](../../SKILLS.md#web-ui-default-reading-order)) |

*This file is **curated**; it is not a reslice of [CLAUDE.md](../../.claude/CLAUDE.md). Update when your team’s review **bar** changes.*
