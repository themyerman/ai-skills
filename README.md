# ai-skills

Personal collection of Claude/Cursor agent skill docs covering Python tooling, web development, security, writing, visual design, creative work, and more.

## Why skill files?

Claude's built-in knowledge is broad but shallow in specialized areas — and it resets between conversations. Skill files solve both problems.

A skill file is a curated, opinionated reference that Claude reads before working on a specific type of task. Instead of relying on Claude to reconstruct best practices from general training, skill files load the specific conventions, vocabulary, patterns, and judgment calls that matter for *your* work. The result is consistent behavior across sessions and projects without repeating yourself.

They also let you encode knowledge that doesn't exist in Claude's training at all — house style, personal preferences, domain-specific workflows, or subject-matter expertise you bring yourself.

Skills live in `skills/<name>/` as markdown files. Each skill has a `SKILL.md` (entry point) and one or more topic reference files.

## How it's wired up

`~/.claude/ai-skills` symlinks to this repo, so Claude Code picks up the skills automatically across all projects via `~/.claude/CLAUDE.md`.

For Cursor, run the installer script to symlink skills into a workspace:

```bash
./scripts/install-cursor-symlinks.sh /path/to/your/workspace
```

## Skills

**Python & backend**

| Skill | What it covers |
|-------|----------------|
| [python-scripts-and-services](skills/python-scripts-and-services/SKILL.md) | Project structure, config, DB, testing, Flask, CLI |
| [async-python](skills/async-python/SKILL.md) | asyncio, httpx.AsyncClient, gather, semaphore rate-limiting |
| [debugging-profiling](skills/debugging-profiling/SKILL.md) | pdb, cProfile, line_profiler, memory leaks, traceback reading |
| [data-pipelines](skills/data-pipelines/SKILL.md) | ETL patterns, idempotency, incremental load, chunking, backfill |
| [database-migrations](skills/database-migrations/SKILL.md) | Alembic setup, autogenerate, zero-downtime patterns, SQLite quirks |
| [background-jobs](skills/background-jobs/SKILL.md) | Cron, RQ, Celery, task idempotency, retry, dead-letter handling |

**Web & frontend**

| Skill | What it covers |
|-------|----------------|
| [web-frontend-basics](skills/web-frontend-basics/SKILL.md) | Semantic HTML, forms, small JS, fetch |
| [web-layout-css](skills/web-layout-css/SKILL.md) | Flex/grid, responsive, tables/cards, print |
| [web-accessibility](skills/web-accessibility/SKILL.md) | WCAG habits, keyboard, ARIA, contrast, motion |
| [static-site-github-pages](skills/static-site-github-pages/SKILL.md) | Plain HTML/CSS/JS on GitHub Pages, CNAME, Actions workflows |

**DevOps & tooling**

| Skill | What it covers |
|-------|----------------|
| [ci-cd-pipelines](skills/ci-cd-pipelines/SKILL.md) | GitHub Actions, caching, matrix builds, secrets, deploy on merge |
| [docker-containerization](skills/docker-containerization/SKILL.md) | Dockerfile best practices, multi-stage builds, compose for dev |
| [git-workflow](skills/git-workflow/SKILL.md) | Branch naming, commit messages, PR hygiene, rebase vs merge |
| [shell-discipline](skills/shell-discipline/SKILL.md) | Evidence-first terminal work: run, inspect, verify, commit |
| [shell-csv-pipelines](skills/shell-csv-pipelines/SKILL.md) | Bash/awk on CSVs, `set -euo pipefail`, ShellCheck |
| [shell-macos-scripts](skills/shell-macos-scripts/SKILL.md) | sips, osascript, keychain, launchd, AI API wrappers |
| [environment-audit](skills/environment-audit/SKILL.md) | Workspace capability audit — what's configured vs missing |

**Security**

| Skill | What it covers |
|-------|----------------|
| [secrets-management](skills/secrets-management/SKILL.md) | Credentials, CI, leak response |
| [dependency-security](skills/dependency-security/SKILL.md) | pip-audit, CVE triage, pinning, Dependabot, SBOM |
| [shift-left-program](skills/shift-left-program/SKILL.md) | Security champions, CI defaults, escalation |
| [data-handling-pii](skills/data-handling-pii/SKILL.md) | PII classification, minimization, safe logs/exports |
| [llm-integrations-safety](skills/llm-integrations-safety/SKILL.md) | LLM mock clients, prompt injection, I/O screening |

**Observability & incidents**

| Skill | What it covers |
|-------|----------------|
| [observability](skills/observability/SKILL.md) | Health checks, metrics (RED method), structured logs, SLOs |
| [incident-response](skills/incident-response/SKILL.md) | Triage, war room, hotfix, comms templates |
| [blameless-postmortems](skills/blameless-postmortems/SKILL.md) | Incident learning, timeline, contributing factors, no blame |
| [on-call-runbooks](skills/on-call-runbooks/SKILL.md) | Writing runbooks that work at 2am, exact commands, templates |

**AI & prompting**

| Skill | What it covers |
|-------|----------------|
| [using-ai-assistants](skills/using-ai-assistants/SKILL.md) | Working effectively with AI in the editor |
| [prompt-engineering](skills/prompt-engineering/SKILL.md) | System messages, few-shot, structured output, eval loops |
| [token-budget](skills/token-budget/SKILL.md) | Context/token audit — skills, rules, MCP creep |

**Product & process**

| Skill | What it covers |
|-------|----------------|
| [product-management](skills/product-management/SKILL.md) | Problem, user, outcome, prioritization, roadmap, PRD-lite |
| [product-writing](skills/product-writing/SKILL.md) | Specs/PRDs, acceptance criteria, decision records (ADRs) |
| [technical-rfcs](skills/technical-rfcs/SKILL.md) | Design proposals, problem statement, alternatives, feedback lifecycle |
| [decision-making](skills/decision-making/SKILL.md) | Decision matrix, RICE, DACI, reversible vs irreversible, pre-mortem |
| [jira-integration](skills/jira-integration/SKILL.md) | Jira REST API, JQL, PAT |
| [codebase-onboarding](skills/codebase-onboarding/SKILL.md) | Mapping an unfamiliar repo, starter CLAUDE.md |
| [ship-checklist](skills/ship-checklist/SKILL.md) | Before a big merge: tests, docs, security review |
| [pre-pr-checklist](skills/pre-pr-checklist/SKILL.md) | Verification loop: lint, types, tests, secret grep |
| [automation-audit](skills/automation-audit/SKILL.md) | Hooks, CI, MCP, overlap inventory |

**Writing & communication**

| Skill | What it covers |
|-------|----------------|
| [docs-clear-writing](skills/docs-clear-writing/SKILL.md) | READMEs, install guides, plain English, runbooks |
| [executive-reports](skills/executive-reports/SKILL.md) | BLUF structure, plain English for leadership |
| [persuasive-writing](skills/persuasive-writing/SKILL.md) | BLUF, business case, objections, so-what test, audience framing |
| [storytelling](skills/storytelling/SKILL.md) | Narrative arc, three-act structure, hooks, stakes, concrete detail |
| [systems-thinking](skills/systems-thinking/SKILL.md) | Feedback loops, second-order effects, archetypes, causal maps |
| [brainstorming-ideation](skills/brainstorming-ideation/SKILL.md) | Diverge then converge, SCAMPER, structured patterns |
| [visual-communication](skills/visual-communication/SKILL.md) | Diagram design, chart types, Tufte data-ink ratio, CARP, Mermaid |

**Visual design & art**

| Skill | What it covers |
|-------|----------------|
| [visual-design](skills/visual-design/SKILL.md) | Print production (DPI, color, bleed, formats) and design feedback |
| [digital-art-context](skills/digital-art-context/SKILL.md) | Digital art history, critical discourse, collector vocabulary |

**Indigenous & cultural**

| Skill | What it covers |
|-------|----------------|
| [indigenous-history-americas](skills/indigenous-history-americas/SKILL.md) | Pre-contact to contemporary — sovereignty, removal, boarding schools, AIM |
| [indigenous-art-americas](skills/indigenous-art-americas/SKILL.md) | Indigenous art of the Americas — pre-contact to contemporary, all regions |
| [indigenous-bias-awareness](skills/indigenous-bias-awareness/SKILL.md) | Anti-Indigenous bias — terms, behaviors, historical context |

**Blues & music**

| Skill | What it covers |
|-------|----------------|
| [blues-tradition](skills/blues-tradition/SKILL.md) | Delta/Chicago/Piedmont history, form, imagery, key figures |
| [blues-songwriting](skills/blues-songwriting/SKILL.md) | Lyric craft, AAB verse, floating verse, call and response, imagery |

## Adding a skill

1. Create `skills/<new-skill-name>/SKILL.md` (add `reference.md` and other topic files as needed).
2. Add a row to the table above.
3. Add an entry to `CLAUDE.md` (symlinked from `~/.claude/CLAUDE.md`).
4. Re-run `scripts/install-cursor-symlinks.sh` if you use Cursor.

## License

MIT — see [LICENSE](LICENSE).
