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

Cross-role habits for getting reliable work from an AI assistant without treating it as infallible. Complements (does not replace) your org's acceptable use, data classification, and InfoSec policies.

## When to use

- You're new to Cursor / IDE assistants and want a sane default workflow.
- You're reviewing work that was partly model-generated.
- You're deciding: "draft with AI + human verify" vs "human owns from scratch."

## Habits

### 1. Set context on purpose

- Goal in one line; done-when in one line (artifact, test, or sign-off you need).
- Attach or @ the smallest set of files / symbols that must stay true. Avoid "whole repository" as the default.
- State constraints: internal vs external, "no new third-party deps without approval," "match this pattern in ai-skills."

### 2. Work in small wins

- Prefer one failure mode per turn or PR: repro → change → check.
- Ask for reviewable diffs, not a single blob that rewrites ten modules.

### 3. Verify, don't vibe-check

- Run tests, read the diff, reproduce before/after for bugs. The model is faster search and typing, not a warranty.
- If the answer cites APIs, paths, or version numbers, confirm in the real tree, lockfile, or official docs.

### 4. Red lines

- No long-lived secrets, tokens, production passwords, or sensitive personal/customer data in prompts, scratch buffers, or logs you'll paste. Follow your org's policy; this file is a reminder only.
- If you're not sure whether a class of data can go to a vendor or model provider, check with security / legal / data owner before trying it.

### 5. Escalation to humans (still required)

- Architecture, compliance sign-off, resourcing, jurisdiction questions, threat trade-offs, formal security review: these need owners and processes, not a model.
- For in-product LLM features (mock client, system prompt, I/O screening, audit): [`llm-integrations-safety`](../llm-integrations-safety/SKILL.md).
- For Python merge readiness: [`code-review`](../python-scripts-and-services/code-review.md). For security process: your internal runbooks; [`shift-left-security`](../shift-left-security/SKILL.md) is context only.

## This vs llm-integrations-safety

| Topic | Open |
|--------|------|
| You and colleagues using an AI assistant in the editor to write/ship normal code and docs | this skill |
| Your product calls an LLM API for features | `llm-integrations-safety` |

## Related

- Writing and editing prose (README, runbook, exec summary): [`docs-clear-writing`](../docs-clear-writing/SKILL.md) and [`executive-reports`](../executive-reports/SKILL.md)
- Routing the rest of ai-skills: [`../../SKILLS.md`](../../SKILLS.md)

## Source

Authored for ai-skills; not derived from `.claude/CLAUDE.md`.
