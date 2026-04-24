---
name: using-ai-assistants
description: >-
  Habits for working with AI chat and agent tools (Cursor, IDE assistants,
  team copilots): pack context, define done-when, verify outputs, read diffs,
  one failure mode per turn, no secrets/PII in prompts, when to escalate to humans.
  Triggers: how to use Cursor, agent mode, copilot, pair with LLM, better prompts,
  delegate to AI, review generated code, corporate policy-adjacent workflow
  (not a substitute for legal/InfoSec).
---

# using-ai-assistants

## What this is

**Cross-role** (not tied to a language) **operating** habits: how to get **reliable** work from an **agent** without treating it as **infallible**. It **complements** (and does not replace) your org’s **acceptable use**, **data classification**, and **InfoSec** policies.

## When to use

- You are new to **Cursor** / **IDE** assistants and want a **sane default** workflow.  
- You **sponsor** or **review** work that was **partly** model-generated.  
- You are deciding: **“draft with AI + human verify”** vs **“human owns from scratch.”**

## Habits

### 1. Set context on purpose

- **Goal** in one line; **done when** in one line (artifact, test, or sign-off you need).  
- Attach or **@** the **smallest** set of **files** / **symbols** that must stay true. Avoid “whole repository” as the default.  
- State **constraints**: internal vs external, “**no** new third-party deps without approval,” “match this **`SKILL` / pattern** in `ai-skills`.”

### 2. Work in small wins

- Prefer **one** failure mode per **turn** or **PR**: **repro** → **change** → **check**.  
- Ask for **reviewable** diffs, not a **single** blob that rewrites ten modules.

### 3. Verify, don’t vibe-check

- **Run** tests, **read** the diff, **reproduce** before/after for bugs. The model is **faster** search and typing, not a **warranty**.  
- If the answer **cites** APIs, **paths**, or **version** numbers, **confirm** in the real tree, lockfile, or official docs.

### 4. Red lines

- **No** long-lived **secrets**, tokens, production **passwords**, or **sensitive** personal/employee/**customer** data in prompts, **scratch** buffers, or **logs** you will paste. Follow **your** org’s **policy**; this file is a **reminder** only.  
- If you are not sure a **class** of data may be sent to a **vendor** or **model** provider, use the **escalation** path your org defines (security / legal / data owner) **before** “just trying it.”

### 5. Escalation to humans (still required)

- **Architecture**, **compliance** sign-off, **re-org**, **resourcing**, **jurisdictions**, **threat** trade-offs, **formal** org **security** program: **owners** and **processes**, not the model.  
- For **in-product** **LLM** features (mock client, system prompt, **I/O** screening, audit): **[`llm-integrations-safety`](../llm-integrations-safety/SKILL.md)**.  
- For **Python** merge **readiness**: **[`code-review`](../python-internal-tools/code-review.md)**. For org **Jira** / **security** **process:** your **internal** runbooks; **[`shift-left-program`](../shift-left-program/SKILL.md)** is context only.

## This vs **llm-integrations-safety**

| Topic | Open |
|--------|------|
| **You** and colleagues using a **tooling** **assistant** in the **editor** to write/ship **normal** code and docs | **this skill** |
| **Your** product **calls** an **LLM** **API** for features | **`llm-integrations-safety`** (plus **security** review as your org requires) |

## Related

- **Writing** and **editing** prose (README, runbook, exec summary): [`docs-clear-writing`](../docs-clear-writing/SKILL.md) and [`executive-reports`](../executive-reports/SKILL.md)  
- **Routing** the rest of **ai-skills**: [`../../SKILLS.md`](../../SKILLS.md)

## Source

Authored for **ai-skills**; not derived from **`.claude/CLAUDE.md`**. **Override** with **org**-specific **governance** when they conflict with anything here.
