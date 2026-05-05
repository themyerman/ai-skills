---
name: context-budget
description: >-
  Audit Cursor context overhead: skills, rules, MCP servers, CLAUDE.md, attached
  files. Flags bloat and yields prioritized token-saving moves.
  Triggers: context full, too many skills, slow session, MCP creep, /context-budget.
---

# Context Budget

Analyze **token overhead** across loaded components in a session and surface **actionable** optimizations to reclaim context space.

## Cursor mapping

| Component idea | In Cursor / this repo |
|----------------|------------------------|
| **Agent files** | Subagents or **Task** payloads—audit **description length** if your harness loads them globally |
| **`skills/*/SKILL.md`** | **`ai-skills/skills/*/SKILL.md`** (and symlinks under **`.cursor/skills/`**) plus **`@`-attached** skill files |
| **Rules** | **`.cursor/rules/**`, **`.cursorrules`**, project rules |
| **MCP config** | Cursor **MCP** settings / enabled servers |
| **`CLAUDE.md` chain** | **`.claude/CLAUDE.md`**, project **`CLAUDE.md`**, attached guide files |

## When to Use

- Session feels sluggish or output quality degrades
- You recently added many skills, rules, or MCP servers
- You want to know how much context headroom you have
- Planning more components and need to know if there is room

## How It Works

### Phase 1: Inventory

Scan component directories and **estimate** token consumption.

**Agents** (if present as `*.md` in your harness)

- Count lines and tokens per file (words × 1.3)
- Extract `description` frontmatter length
- Flag: files >200 lines (heavy), description >30 words (bloated frontmatter)

**Skills** (`skills/*/SKILL.md` in **ai-skills** or `.cursor/skills`)

- Count tokens per `SKILL.md`
- Flag: files >400 lines
- De-dupe identical copies if skills are linked from multiple paths

**Rules** (`.cursor/rules/**/*.md` or equivalent)

- Count tokens per file
- Flag: files >100 lines
- Detect overlap between rule files

**MCP Servers** (Cursor MCP config)

- Count configured servers and total tool count
- Estimate schema overhead at ~500 tokens per tool
- Flag: servers with >20 tools, servers wrapping trivial CLI (`gh`, `git`) you could run directly

**CLAUDE.md** (project + user-level)

- Count tokens per file in any loaded guide chain
- Flag: combined total >300 lines of **always-on** instructions

### Phase 2: Classify

| Bucket | Criteria | Action |
|--------|----------|--------|
| **Always needed** | Referenced from standing rules, default `@` skill, or matches project type | Keep |
| **Sometimes needed** | Domain-specific; not loaded every thread | On-demand **`@`** attach |
| **Rarely needed** | Overlap, obsolete, or no project match | Remove, archive, or lazy-load |

### Phase 3: Detect Issues

- **Bloated descriptions** — long YAML `description:` or frontmatter loaded often
- **Heavy skill files** — >400 lines always attached
- **Redundant components** — rules duplicating `CLAUDE.md`
- **MCP over-subscription** — many servers / tools with overlapping duties
- **CLAUDE.md bloat** — prose that should be a scoped rule or skill

### Phase 4: Report

Produce a short report:

```text
Context Budget Report
═══════════════════════════════════════

Total estimated overhead: ~XX,XXX tokens
Model window: (user's model)

Component breakdown: agents / skills / rules / MCP / guides

Issues (ranked by savings):
...

Top 3 optimizations:
1. ...
2. ...
3. ...
```

## Related (this repo)

- **[`using-ai-assistants`](../using-ai-assistants/SKILL.md)** — habits, **`@`** discipline, secrets
