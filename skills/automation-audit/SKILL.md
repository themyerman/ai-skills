---
name: automation-audit-ops
description: >-
  Evidence-first automation inventory: hooks, CI, MCP, wrappers. Map live vs
  broken vs redundant; keep / merge / cut / fix-next before rewriting.
  Triggers: what automations exist, overlap audit, CI inventory, hooks creep.
---

# Automation Audit Ops

Use when the user asks what automations are **live**, which jobs are **broken**, where **overlap** exists, or what tooling is doing useful work **right now**.

Audit-first: produce an **evidence-backed inventory** and **keep / merge / cut / fix-next** before rewriting anything.

## CI tooling (adapt to your stack)

When present, MCP tools or CLI access to CI systems help inspect live automation:

| System | Typical access method |
|--------|-----------------------|
| GitHub Actions | `gh` CLI, workflow YAML, run logs |
| Jenkins | Jenkins CLI or API |
| Bamboo | Bamboo API or admin UI |
| Jira + CI linkage | Jira REST API or admin tooling |

Prefer configured tools over blind **`curl`** when auditing your org's CI — fall back to repo files + **`gh`** CLI + hosting UI.

## Skill stack (this repo)

- **[`environment-audit`](../environment-audit/SKILL.md)** — connectors, MCP, hooks, env inventory
- **[`pre-pr-checklist`](../pre-pr-checklist/SKILL.md)** — prove post-fix state
- **`gh` / CI YAML** — read **`.github/workflows/`**, job logs when MCP absent
- **`README` / `WORK.md`** — durable notes when reconciling "what we think" vs "what runs"

## When to Use

- "What automations do I have?" "What's live?" "What's broken?" "What overlaps?"
- Task spans cron, Actions, hooks, MCP, wrappers, app integrations
- Multiple ways to do the same thing—need **one canonical lane**

## Guardrails

- Start **read-only** unless the user asked for fixes
- Label each item: configured · authenticated · recently verified · stale · missing
- Do not claim a tool is live **only** because config references it
- Do not merge/delete overlap until the **evidence table** exists

## Workflow

### 1. Inventory the real surface

- Repo hooks and hook scripts
- CI workflows (GitHub Actions, Jenkins, Bamboo, etc.)
- MCP configs and enabled servers
- Wrapper scripts and automation entrypoints

Group by: local · CI · external systems · notifications

### 2. Classify live state

For each automation: configured / authenticated / verified / stale / missing — and problem type: breakage · auth · redundancy · gap.

### 3. Trace proof

Cite file paths, workflow run URLs, logs, config keys—not guesses.

### 4. keep / merge / cut / fix-next

One call per overlapping surface.

## Output format

```text
CURRENT SURFACE
- automation — source — live state — proof

FINDINGS
- breakage / overlap / stale / missing

RECOMMENDATION
- keep | merge | cut | fix next

NEXT MOVE
- concrete lane (skill, hook, workflow) to strengthen
```

## Pitfalls

- Do not answer from memory when the repo can be read
- Do not treat "in config" as "working"
- Do not widen into a rewrite when the user asked for inventory
