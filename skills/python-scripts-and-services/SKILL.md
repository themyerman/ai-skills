---
name: python-scripts-and-services
description: >-
  Python internal services and CLIs: layout, venv, pyproject, ruff, pytest,
  httpx/requests, Jira client, logging, config yaml+env, SQLite, Flask+Jinja,
  PR and code review. Topic files: reference (§1–3,6–8), security, jira,
  flask-serving, testing, packaging. Triggers: new repo, internal tool, FastAPI
  or Flask, httpx, PAT, JQL, merge readiness, pre-merge, dependency pin,
  threat model, org security handoff. For light shift-left / escalation ideas:
  shift-left-security. For LLM
  in app code: llm-integrations-safety. For Slack/wiki/email and vault
  hygiene (broad eng): secrets-management. PII, exports, tickets, logs: data
  handling pii. Prose: docs-clear-writing. Slices
  resynced from .claude/CLAUDE.md (see Source in SKILL).
---

# python-scripts-and-services

## What this is

A practical guide to production Python for internal services and scripts. See [## Source](#source) for how `reference.md` / `security.md` track the main guide versus the curated topic files.

| File | What to open |
|------|----------------|
| [reference.md](reference.md) | §1–3, 6–8 — project tree, config/venv/imports, DB sketch, testing basics, code style. |
| [jira.md](jira.md) | Jira-integrated tools, JQL, PAT/REST/allowlist exemplar, CLI (`--preview`, bulk). |
| [http-clients-reliability.md](http-clients-reliability.md) | Retries, 429/5xx, `Retry-After`, backoff, idempotency for writes; `Session` + timeouts. |
| [logging-structured.md](logging-structured.md) | Context and run IDs, INFO vs ERROR, `getLogger(__name__)`; complements *On logging* in security.md. |
| [config-flags.md](config-flags.md) | yaml + env precedence, fail-fast required keys, lightweight feature flags; optional Pydantic. |
| [packaging.md](packaging.md) | `pyproject`, editable install, `console_scripts`, internal wheel. |
| [testing-strategy.md](testing-strategy.md) | What to mock, contract tests, parametrize, Flask test client, coverage; extends reference.md §7. |
| [code-review.md](code-review.md) | PR / pre-merge review: author + reviewer checklists, blockers, comment template. |
| [data-validation.md](data-validation.md) | Boundaries (Flask, argparse, Jira JSON, CSV); Pydantic; extends security.md input validation. |
| [flask-serving.md](flask-serving.md) | Flask + Jinja internal UI: `app/` vs `src/`, Basic auth, security headers, `g` + DB. |
| [sqlite-patterns.md](sqlite-patterns.md) | WAL, `busy_timeout`, migrations, concurrency. |
| [security.md](security.md) | Credentials, HTTP session, SQL/shell, boundary threat thinking; escalation → shift-left-security. |
| [`shift-left-security/`](../shift-left-security/SKILL.md) | Lightweight habits: CI defaults, when to escalate — not a full security program. |
| [`secrets-management/`](../secrets-management/SKILL.md) | Repos and code (config, tests, Docker, CI), Slack/wiki plaintext, secret stores, K8s, leak response. Extends security.md beyond Python. |
| [`data-handling-pii/`](../data-handling-pii/SKILL.md) | PII / sensitive data: classification, minimization, logs, Jira/CSV/exports, wiki/Slack, LLM+ticket text. Not legal advice. |
| [documentation.md](documentation.md) | README, `WORK.md`, `docs/`, and where to put them. For prose craft: [`docs-clear-writing`](../docs-clear-writing/SKILL.md). |
| `llm-integrations-safety` | §9 — LLM + untrusted text. |

## If the code calls an LLM

Use `llm-integrations-safety`. This skill still covers the rest of the stack.

## Source

Canonical developer guide: [`../../.claude/CLAUDE.md`](../../.claude/CLAUDE.md).

- `reference.md` and `security.md` are slices of the numbered sections. When §1–3, 4–5, or 6–8 are moved, merged, or split in `CLAUDE.md`, re-slice those two files so they stay a faithful subset of the long guide.
- Other topic files (jira, http-clients, logging, config, packaging, testing, code-review, data, flask, sqlite, documentation, …) are curated: edit them when your patterns change, not for every `CLAUDE.md` wording tweak.
- Prose craft for READMEs, install guides, and how-tos lives in docs-clear-writing; see [documentation](documentation.md) for where to put files in a Python repo.
