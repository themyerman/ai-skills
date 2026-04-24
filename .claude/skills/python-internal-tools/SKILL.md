---
name: python-internal-tools
description: >-
  Python internal services and CLIs: layout, venv, pyproject, ruff, pytest,
  httpx/requests, Jira client, logging, config yaml+env, SQLite, Flask+Jinja,
  PR and code review. Topic files: reference (§1–3,6–8), security, jira,
  flask-serving, testing, packaging. Triggers: new repo, internal tool, FastAPI
  or Flask, httpx, PAT, JQL, merge readiness, pre-merge, dependency pin,
  threat model, org security handoff. For light shift-left / escalation ideas:
  shift-left-program. For LLM
  in app code: llm-integrations-safety. For Slack/wiki/email and vault
  hygiene (broad eng): secrets-management. PII, exports, tickets, logs: data
  handling pii. Prose: docs-clear-writing. Slices
  resynced from .claude/CLAUDE.md (see Source in SKILL).
---

# python-internal-tools

## What this is

A **practical, split guide** to production Python for internal services and scripts. The canonical text is [`../../.claude/CLAUDE.md`](../../.claude/CLAUDE.md) in **ai-skills** — see **## Source** for how **reference** / **security** track **§** moves vs. **curated** topic files. **Addenda** in the guide (example product layouts) are **optional** and **not** required to use the skills.

| File | What to open |
|------|----------------|
| **[reference.md](reference.md)** | **§1–3, 6–8** — project tree, config/venv/imports, DB sketch, **testing** basics, **code style** (slices of the dev guide; **not** a dump of every topic). |
| **[jira.md](jira.md)** | Jira-integrated tools, **JQL**, **PAT/REST/allowlist** exemplar, **CLI** (`--preview`, bulk). |
| **[http-clients-reliability.md](http-clients-reliability.md)** | **Retries**, **429/5xx**, `Retry-After`, **backoff**, **idempotency** for **writes**; `Session` + **timeouts**; examples: Jira/REST client and **LLM** **HTTP** client. |
| **[logging-structured.md](logging-structured.md)** | **Context** and **run** ids, **INFO** vs **ERROR**, `getLogger(__name__)`; **complements** *On logging* in [security](security.md). |
| **[config-flags.md](config-flags.md)** | **yaml + env** precedence, **fail-fast** required keys, **lightweight feature flags**; **optional** Pydantic. |
| **[packaging.md](packaging.md)** | **`pyproject`**, **editable** install, **console_scripts**, **internal** wheel. |
| **[testing-strategy.md](testing-strategy.md)** | **What** to mock, **contract** tests, **parametrize**, **Flask** test client, **coverage**; extends [reference](reference.md) §7. |
| **[code-review.md](code-review.md)** | **PR / pre-merge** review: author + reviewer checklists, **blockers**, comment template; ties to [testing](testing-strategy.md), [security](security.md), [shift-left-program](../shift-left-program/SKILL.md) (org process context). |
| **[data-validation.md](data-validation.md)** | **Boundaries** (Flask, argparse, Jira JSON, CSV); **Pydantic**; extends [security](security.md) (input validation, threat table). |
| **[flask-serving.md](flask-serving.md)** | **Flask + Jinja** internal UI: `app/` vs `src/`, **Basic** auth, **security headers**, `g` + DB. |
| **[sqlite-patterns.md](sqlite-patterns.md)** | **WAL**, `busy_timeout`, migrations, **concurrency**; see doc for a typical `db` / `storage` pattern. |
| **[security.md](security.md)** | **Credentials**, HTTP session, **SQL/shell**, **boundary threat**; **formal** TM / program handoff → your org + [shift-left-program/](../shift-left-program/SKILL.md) (lightweight). |
| **[`shift-left-program/`](../shift-left-program/SKILL.md)** | **Thin** ideas: champions, **CI** defaults, when to **escalate**—**not** a full AppSec or GRC program. |
| **[`secrets-management/`](../secrets-management/SKILL.md)** | **Broad eng**: **repos** and **code** (config, **tests**, **Docker**, **CI**), **Slack/wiki** plaintext, **stores**, **K8s**, **leak** **response**; extends [security](security.md) past **Python**-only. Align with **your** org’s **published** **policy** **index**. |
| **[`data-handling-pii/`](../data-handling-pii/SKILL.md)** | **PII** / **sensitive** data: **classification**, **minimization**, **logs**, **Jira/CSV/exports**, **wiki/Slack**, **LLM+ticket** text; not legal advice. Pairs with [llm-integrations-safety](../llm-integrations-safety/SKILL.md) and [security](security.md). |
| **[documentation.md](documentation.md)** | **README**, `WORK.md`, `docs/`, and **where** to put them in the repo. **How** to write (install, how-tos): [`docs-clear-writing`](../docs-clear-writing/SKILL.md). |
| `llm-integrations-safety` | **§9** — **LLM** + untrusted text. |

## If the code calls an LLM

Use **`llm-integrations-safety`**. This skill still covers the rest of the stack.

## Source

**Canonical** developer guide: **[`../../.claude/CLAUDE.md`](../../.claude/CLAUDE.md)**.

- **`reference.md`** and **`security.md`** are **slices** of the **numbered** sections. When **§1–3**, **4–5**, or **6–8** are **moved, merged, or split** in `CLAUDE.md`, **re-slice** those two files (or **manually** align them) so they stay a faithful **subset** of the long guide.  
- **Other** topic files (**jira**, **http-clients**, **logging**, **config**, **packaging**, **testing**, **code-review**, **data**, **flask**, **sqlite**, **documentation**, …) are **curated**: **edit** them when **your** team’s **patterns** change, not for every `CLAUDE` wording tweak.  
- **Prose** craft for **READMEs**, **install**, **how-tos** lives in the sibling **docs-clear-writing** skill; see [documentation](documentation.md) for **where** to put files in a Python repo.
