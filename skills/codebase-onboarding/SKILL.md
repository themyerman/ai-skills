---
name: codebase-onboarding
description: >-
  Structured onboarding for an unfamiliar repo: recon, architecture map,
  conventions, onboarding guide + starter CLAUDE.md. Use Glob/Grep first.
  Triggers: onboard me, explain codebase, generate CLAUDE.md, new repo walkthrough.
---

# Codebase onboarding

Analyze an unfamiliar codebase and produce a **structured onboarding guide** and optional **starter `CLAUDE.md`**.

## When to use

- First time in a project with **Cursor** (or Claude Code)  
- Joining a new team or repository  
- "Help me understand this codebase" / "Walk me through this repo"  
- "Generate or refresh **`CLAUDE.md`**"  

**Related:** **`ai-skills`** canonical guide lives under **[`.claude/CLAUDE.md`](../../.claude/CLAUDE.md)**—symlink from a parent workspace when useful; **do not** replace project-specific instructions blindly.

## How it works

### Phase 1 — Reconnaissance

Parallel checks (Glob / Grep / list dirs)—do **not** read every file:

1. Package manifests — `pyproject.toml`, `package.json`, `go.mod`, …  
2. Framework fingerprints — Flask, FastAPI, Next, Django, …  
3. Entry points — `main.py`, `app/`, `src/`, CLI consoles  
4. Directory tree — top **two** levels; ignore `node_modules`, `.git`, `dist`, `__pycache__`  
5. Tooling — `ruff`, `pytest`, ESLint, Dockerfile, `.github/workflows/`, `.env.example`  
6. Tests — `tests/`, `pytest.ini`, `jest.config.*`, …  

### Phase 2 — Architecture mapping

Summarize:

- **Tech stack** — languages, frameworks, DB, CI  
- **Architecture pattern** — monolith, monorepo, services  
- **Key directories** — purpose of each top-level folder  
- **One request path** — entry → validation → logic → persistence (adjust to repo type)  

### Phase 3 — Conventions

Naming, error handling, DI vs direct imports, async style, **git** branch/commit patterns **if** history is available (skip if shallow clone).

### Phase 4 — Artifacts

**Output 1 — Onboarding guide** (markdown): Overview, stack table, architecture, entry points, directory map, common commands ("how to run tests/lint"), "where to look" table.

**Output 2 — Starter `CLAUDE.md`** (if requested): Short project instructions—stack, test/lint commands, structure, conventions—**≤ ~100 lines**. If a **`CLAUDE.md`** already exists, **merge** and mark what was added.

## Best practices

1. **Recon with Glob/Grep**, not bulk Read  
2. **Verify**, don't guess—trust manifests **and** code  
3. **Respect existing `CLAUDE.md`**  
4. **Stay scannable** — deep detail stays in code  
5. **Flag unknowns** explicitly  

## Anti-patterns

- **`CLAUDE.md`** longer than ~100 lines without strong reason  
- Listing every dependency  
- Duplicating the README instead of adding structure  
