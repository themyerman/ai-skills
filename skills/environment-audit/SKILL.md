---
name: workspace-surface-audit
description: >-
  Read-only audit: repo, MCP, rules, env keys (names only), ai-skills coverage.
  What works now vs gaps; top next moves for Cursor workflows.
  Triggers: setup Cursor, what MCPs, what am I missing, audit workspace.
---

# Workspace Surface Audit

Answer: **what can this workspace do right now**, and **what should we add next**?

Read-only unless the user asks for implementation.

## When to Use

- “Set up Cursor”, “what MCPs should I use?”, “what am I missing?”
- Before installing more skills, hooks, or connectors
- Reviewing `.env`, MCP settings, rules—without printing secret **values**
- Deciding if something should be a **skill**, **rule**, **hook**, or **MCP**

## Rules

- **Never print secret values**—only provider names, capability names, paths, “key present or not”
- Prefer **`ai-skills`** patterns over “install random plugins” when they cover the workflow
- Separate: **available now** · **available but awkward** · **not available**

## Audit inputs

1. **Repo** — `pyproject.toml`, `package.json`, `README`, framework configs, **`.github/workflows/`**
2. **Agent config** — `.mcp.json` / Cursor MCP UI, `.cursor/rules`, **`CLAUDE.md`**, **`AGENTS.md`**
3. **Environment** — `.env.example`; surface **key names** only (e.g. `JIRA_TOKEN` exists—no value)
4. **Tooling** — enabled MCP servers, LSPs
5. **`ai-skills`** — which existing **[`SKILLS.md`](../../SKILLS.md)** routes already match this repo

## Process

### Phase 1: Inventory

Compact list:

- Languages / frameworks detected
- MCP servers configured
- Rules / always-on docs
- CI entrypoints
- Relevant **`ai-skills`** folders for this stack

Call out **primitive-only** gaps (e.g. “Stripe env key exists but no operator runbook in-repo”).

### Phase 2: Benchmark

Compare against common **Cursor** extensions / MCP ideas. For each:

1. What it does  
2. Whether **`ai-skills`** already covers it  
3. Whether you only have a low-level primitive  

### Phase 3: Turn gaps into decisions

| Gap type | Preferred shape |
|----------|-----------------|
| Repeatable operator workflow | Skill (`ai-skills` or project-local) |
| Automatic enforcement | Hook / CI gate |
| Delegated role | Agent prompt pack (project) |
| External bridge | MCP |
| Bootstrap guidance | Onboarding doc / **`codebase-onboarding`** |

Default to **skills** that orchestrate existing tools when the need is operational.

## Output format

1. **Current surface** — usable now  
2. **Parity** — already matched by **`ai-skills`** or project docs  
3. **Primitive-only gaps** — tool exists, workflow thin  
4. **Missing integrations** — not available  
5. **Top 3–5 next moves** — concrete, ordered by impact  

## Recommendation rules

- At most **1–2** ideas per category
- Favor high-intent workflows: onboarding, CI debug, Jira ops, docs
- If **`ai-skills`** already has a strong slice, **`@`** that skill instead of inventing a parallel doc

## Related

- **[`codebase-onboarding`](../codebase-onboarding/SKILL.md)** — structured repo recon  
- **[`automation-audit`](../automation-audit/SKILL.md)** — overlap / CI inventory  
- **[`using-ai-assistants`](../using-ai-assistants/SKILL.md)** — context and safety habits  

## Source

Authored for **ai-skills**. Adapt to your editor (Cursor, VS Code + Claude, Claude Code) as needed.
