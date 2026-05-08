---
name: major-change-readiness
description: >-
  Gate before a major commit or merge: all tests green, CI same as reviewers,
  README and WORK.md current, docs and threat model aligned when security-relevant.
  Triggers: big PR, release branch, before merge, ship it checklist, threat model
  update, all pytest pass, documentation drift, major refactor readiness.
---

# ship-checklist

## What this is

A **repeatable gate** so **large** or **security-relevant** changes do not land with **green-only-in-my-head**, **stale** operator docs, or an **outdated** **threat model**. It **aggregates** pointers—**not** a substitute for your org's **AppSec** program or **CI** policy.

## When to use

- You are about to **merge** a **large** refactor, **new** external integration, or **behavior** that changes **operator** or **security** assumptions.  
- You want an **agent** or **author** to **verify** "everything we said we'd do before this ships" in **one** pass.  
- **Pair** with **[`code-review.md`](../python-scripts-and-services/code-review.md)** (Python **diff** quality) and your org's formal security intake process when **threat model** / **planning** applies.

## Core gate (do not skip)

| Gate | Why |
|------|-----|
| **All automated tests pass** | Same **command** / **CI job** reviewers will run (e.g. **`pytest`**, **`ruff check`**, **`mypy`** if the repo uses them). **No** "I'll fix tests in a follow-up." |
| **`README.md` updated** | **Install**, **flags**, **config** paths, and **one** **known-good** command still work—see **[`documentation.md`](../python-scripts-and-services/documentation.md)** and **[`docs-clear-writing`](../docs-clear-writing/SKILL.md)**. |
| **`WORK.md` updated** (if the repo uses it) | **Decisions**, **backlog**, or **ops** notes **match** what shipped—see **documentation.md**. |
| **`docs/`** as needed | **Runbooks**, **ADRs**, **API** notes when **surface** or **failure** modes changed. |
| **Threat model / TM artifacts** | If the change **moves** **trust boundaries**, **data**, **new** **HTTP**/**subprocess**/**LLM** surface, or is security-relevant: **update** **`docs/`** TM (e.g. YAML/MD) **or** follow your org's formal security review process. |

## Security and quality extras (strongly recommended)

| Topic | Where |
|--------|--------|
| **Secrets** in the **diff** / **history** | **[`secrets-management`](../secrets-management/SKILL.md)**; **CI** patterns in **[`secrets-scanning-ci.md`](../python-scripts-and-services/secrets-scanning-ci.md)** (Python repo). |
| **Repo ownership contact** | Keep repo contact metadata (e.g. owner, team Slack channel) accurate for security reachability. |
| **SAST / dependency / manual security pass** | **[`security-code-audit.md`](../python-scripts-and-services/security-code-audit.md)** + **[`security.md`](../python-scripts-and-services/security.md)**. |
| **Tests worth shipping** | **[`testing-strategy.md`](../python-scripts-and-services/testing-strategy.md)** (boundaries, **perf**, **flakiness**). |
| **HTTP APIs you own** | **[`api-http-service-design.md`](../python-scripts-and-services/api-http-service-design.md)**. |
| **Browser UI** (Jinja/**Flask**, templates, **`static/`**) | **[`web-frontend-basics`](../web-frontend-basics/SKILL.md)** · **[`flask-serving.md`](../python-scripts-and-services/flask-serving.md)**. |

## Printable checklist

**[reference.md](reference.md)** — full **checkbox** list you can paste into a PR or run locally.

## Related

- **Python merge review:** [`code-review.md`](../python-scripts-and-services/code-review.md)  
- **Where README / WORK / docs live:** [`documentation.md`](../python-scripts-and-services/documentation.md)  
- **Blameless learning after incidents:** [`blameless-postmortems`](../blameless-postmortems/SKILL.md)  
- **Routing:** [`../../SKILLS.md`](../../SKILLS.md)

## Source

Authored for **ai-skills**. Override with team release or org security gates when stricter.
