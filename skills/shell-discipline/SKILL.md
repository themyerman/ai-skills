---
name: terminal-ops
description: >-
  Evidence-first repo execution for Cursor: run commands, inspect git, debug CI,
  narrow fixes, report inspected / verified / committed / pushed with proof.
  Triggers: fix this, run tests, debug CI, push, check repo, prove it worked.
---

# Terminal Ops

Use this when the user wants **real repo execution**: run commands, inspect git state, debug CI or builds, make a narrow fix, and report **exactly** what changed and what was verified.

This skill is intentionally narrower than general coding guidance. It is an **operator workflow** for evidence-first terminal execution.

## Skill stack (in this repo)

Pull these in when relevant:

- **[`verification-loop`](../verification-loop/SKILL.md)** — proving steps after changes (lint, types, tests)
- **[`python-scripts-and-services/testing-strategy.md`](../python-scripts-and-services/testing-strategy.md)** — when the fix needs regression coverage
- **[`secrets-management`](../secrets-management/SKILL.md)** — secrets, auth, or credentials in play
- **`gh` / hosting UI** — when the task depends on CI runs, PR state, or release status (no separate `github-ops` skill here)
- **`README` / `WORK.md` / `docs/`** — when the verified outcome should be captured per **[`documentation.md`](../python-scripts-and-services/documentation.md)**

## When to Use

- User says **fix**, **debug**, **run this**, **check the repo**, or **push it**
- The task depends on **command output**, **git state**, **test results**, or a **verified local fix**
- The answer must distinguish **changed locally**, **verified locally**, **committed**, and **pushed**

## Guardrails

- Inspect before editing
- Stay read-only if the user asked for audit/review only
- Prefer repo-local scripts and helpers over improvised ad hoc wrappers
- Do not claim fixed until the proving command was rerun
- Do not claim pushed unless the branch actually moved upstream

## Workflow

### 1. Resolve the working surface

Settle:

- Exact repo path
- Branch
- Local diff state
- Requested mode: inspect · fix · verify · push

### 2. Read the failing surface first

Before changing anything:

- Inspect the error
- Inspect the file or test
- Inspect git state
- Use any already-supplied logs or context before re-reading blindly

### 3. Keep the fix narrow

Solve one dominant failure at a time:

- Use the smallest useful proving command first
- Only escalate to a bigger build/test pass after the local failure is addressed
- If a command keeps failing with the same signature, stop broad retries and narrow scope

### 4. Report exact execution state

Use exact status words:

- inspected
- changed locally
- verified locally
- committed
- pushed
- blocked

## Output Format

```text
SURFACE
- repo
- branch
- requested mode

EVIDENCE
- failing command / diff / test

ACTION
- what changed

STATUS
- inspected / changed locally / verified locally / committed / pushed / blocked
```

## Pitfalls

- Do not work from stale memory when the live repo state can be read
- Do not widen a narrow fix into repo-wide churn
- Do not use destructive git commands without explicit user consent
- Do not ignore unrelated local work

## Verification

- The response names the **proving command** or test
- Git-related work names the **repo path** and **branch**
- Any push claim includes the **target branch** and exact result

## Source

Authored for **ai-skills**. Skill stack points at **`ai-skills`** equivalents.
