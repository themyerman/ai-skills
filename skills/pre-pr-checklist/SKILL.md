---
name: verification-loop
description: >-
  Pre-PR verification: build (if any), types, lint, tests, quick secret grep,
  diff review. Python defaults (pytest, ruff, mypy/pyright); Node section below.
  Triggers: before PR, after feature, run full verify, quality gates.
---

# Verification loop

Run **before a PR** or after a **substantial** change. **Skip phases** that do not apply to the stack (e.g. no `package.json` → skip npm build).

**Pair with:** **[`major-change-readiness`](../major-change-readiness/SKILL.md)** (README / `WORK` / TM when needed) and **[`terminal-ops`](../terminal-ops/SKILL.md)** (evidence-style reporting).

## When to use

- After a feature or refactor  
- Before opening / updating a PR  
- When you need a **single** pass of quality gates  

## Phase 1 — Build / install (if applicable)

**Python (packaging / extensions)**

```bash
python -m pip install -e ".[dev]" 2>&1 | tail -30
# or: python -m build  # when publishing wheels
```

**Node**

```bash
npm run build 2>&1 | tail -20
# or: pnpm build
```

If the project has **no compile step**, skip with **N/A**.

## Phase 2 — Type check

**Python**

```bash
ruff check . 2>&1 | head -40   # fast sanity; not a typechecker
mypy . 2>&1 | head -40
# or: pyright . 2>&1 | head -40
```

**TypeScript**

```bash
npx tsc --noEmit 2>&1 | head -30
```

Fix **blocking** type errors before relying on green tests.

## Phase 3 — Lint

**Python**

```bash
ruff check . 2>&1 | head -40
```

**JavaScript / TypeScript**

```bash
npm run lint 2>&1 | head -30
```

## Phase 4 — Tests

**Python**

```bash
pytest -q 2>&1 | tail -40
# coverage if configured:
pytest --cov=. --cov-report=term-missing -q 2>&1 | tail -30
```

**Node**

```bash
npm run test -- --coverage 2>&1 | tail -50
```

Report passed/failed/skipped and coverage **if** the repo uses it—do not invent a threshold; follow **`pyproject` / CI** config.

## Phase 5 — Security quick pass

This is **not** a full pentest. Triager patterns only; pair with **[`secrets-management`](../secrets-management/SKILL.md)** and **`gitleaks`** / CI.

**Python / general**

```bash
rg -n "password\\s*=\\s*['\\\"]|api_key|BEGIN RSA PRIVATE KEY|-----BEGIN OPENSSH" --glob '!**/node_modules/**' --glob '!**/.git/**' . 2>/dev/null | head -20
```

**Node-only extras (if applicable)**

```bash
rg -n "console\\.log" src/ 2>/dev/null | head -15
```

Never paste live secrets into chat—report **paths** only.

## Phase 6 — Diff review

```bash
git diff --stat
git diff --name-only
```

Check for unintended files, debug prints, config drift.

## Output format

```text
VERIFICATION REPORT
==================

Build:     [PASS/FAIL/N/A]
Types:     [PASS/FAIL/N/A]
Lint:      [PASS/FAIL/N/A]
Tests:     [PASS/FAIL] (summary)
Security:  [PASS/FAIL or notes]
Diff:      [files]

Overall:   [READY / NOT READY] for PR

Issues:
1. ...
```

## Continuous mode

On long sessions, re-run **minimal** proving commands after each coherent chunk of work (or use **`terminal-ops`** discipline).

## Source

Authored for **ai-skills**. **Python-first** phases; **`rg`** preferred over **`grep`** for portability; security phase aligned with **`secrets-management`** expectations.
