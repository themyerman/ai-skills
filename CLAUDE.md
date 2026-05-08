# Skill routing

Before non-trivial work, if the task matches a goal below, read the corresponding SKILL.md then follow it to reference files as needed.

| I need to… | Open |
|------------|------|
| **Partner well with AI** in the editor (context, verify, no secrets, escalation) | [`using-ai-assistants/`](skills/using-ai-assistants/SKILL.md) |
| **Onboard** to an unfamiliar repo (map + starter CLAUDE.md) | [`codebase-onboarding/`](skills/codebase-onboarding/SKILL.md) |
| **Python** service/tool: structure, venv, config, pytest, ruff, pyproject, logging, HTTP client, Flask UI, SQLite, PR review | [`python-scripts-and-services/`](skills/python-scripts-and-services/SKILL.md) |
| **Code review** / merge readiness of a Python change | [`python-scripts-and-services/code-review.md`](skills/python-scripts-and-services/code-review.md) |
| **Debugging** Python: pdb, cProfile, line_profiler, memory leaks, traceback reading | [`debugging-profiling/`](skills/debugging-profiling/SKILL.md) |
| **Async Python**: asyncio, httpx.AsyncClient, gather, semaphore rate-limiting | [`async-python/`](skills/async-python/SKILL.md) |
| **Background jobs**: cron scripts, RQ, Celery, task idempotency, retry, dead-letter handling | [`background-jobs/`](skills/background-jobs/SKILL.md) |
| **Data pipelines**: ETL patterns, idempotency, incremental load, chunking/pagination, backfill, data quality | [`data-pipelines/`](skills/data-pipelines/SKILL.md) |
| **Database migrations**: Alembic setup, autogenerate, zero-downtime patterns, SQLite quirks, CI gate | [`database-migrations/`](skills/database-migrations/SKILL.md) |
| **Before a big merge**: all tests green, README / docs, security-relevant changes reviewed | [`ship-checklist/`](skills/ship-checklist/SKILL.md) |
| **Git workflow**: branch naming, commit messages, PR hygiene, rebase vs merge, tags and releases | [`git-workflow/`](skills/git-workflow/SKILL.md) |
| **Docker**: Dockerfile best practices, multi-stage builds, non-root user, .dockerignore, compose for dev | [`docker-containerization/`](skills/docker-containerization/SKILL.md) |
| **Dependency security**: pip-audit, CVE triage, pinning + pip-compile, Dependabot, supply chain hygiene, SBOM | [`dependency-security/`](skills/dependency-security/SKILL.md) |
| **CI/CD pipelines**: GitHub Actions, job caching, matrix builds, secrets, reusable workflows, deploy on merge | [`ci-cd-pipelines/`](skills/ci-cd-pipelines/SKILL.md) |
| **Verification loop** before PR (lint, types, tests, quick secret grep) | [`pre-pr-checklist/`](skills/pre-pr-checklist/SKILL.md) |
| **Evidence-first terminal work** (run, inspect, verify, commit, push with proof) | [`shell-discipline/`](skills/shell-discipline/SKILL.md) |
| **Context / token audit** (skills, rules, MCP creep) | [`token-budget/`](skills/token-budget/SKILL.md) |
| **Jira** from the agent (REST API, JQL, PAT) | [`jira-integration/`](skills/jira-integration/SKILL.md) |
| **Automation inventory** (hooks, CI, MCP, overlap) | [`automation-audit/`](skills/automation-audit/SKILL.md) |
| **Observability**: health check endpoints, metrics (RED method), structured log fields, alerting, SLOs | [`observability/`](skills/observability/SKILL.md) |
| **Bash** / awk / cut on CSVs; set -euo pipefail; when to use Python instead | [`shell-csv-pipelines/`](skills/shell-csv-pipelines/SKILL.md) |
| **macOS shell scripts** (sips, osascript, keychain, launchd, AI API wrappers) | [`shell-macos-scripts/`](skills/shell-macos-scripts/SKILL.md) |
| **Workspace capability audit** (what's configured vs missing) | [`environment-audit/`](skills/environment-audit/SKILL.md) |
| **Blameless postmortem** / incident learning (no individual blame) | [`blameless-postmortems/`](skills/blameless-postmortems/SKILL.md) |
| **Incident response** (during an outage): triage, war room, hotfix, comms templates | [`incident-response/`](skills/incident-response/SKILL.md) |
| **On-call runbooks**: writing runbooks that work at 2am, exact commands, templates | [`on-call-runbooks/`](skills/on-call-runbooks/SKILL.md) |
| **LLM in app code**: mock client, prompt injection, screen in/out, anomaly checks | [`llm-integrations-safety/`](skills/llm-integrations-safety/SKILL.md) |
| **Prompt engineering**: system messages, few-shot examples, structured output, eval loops, token budget | [`prompt-engineering/`](skills/prompt-engineering/SKILL.md) |
| **PII / sensitive data**: minimization, safe logs, exports (not legal advice) | [`data-handling-pii/`](skills/data-handling-pii/SKILL.md) |
| **Credentials and secrets**: no plaintext in chat or CI; .env, Docker, K8s, gitleaks; leak response | [`secrets-management/`](skills/secrets-management/SKILL.md) |
| **Shift-left security culture** | [`shift-left-security/`](skills/shift-left-security/SKILL.md) |
| **Pre-PR / pre-release security review**: threat model stub, punchlist, needs-review determination | [`security-review-advisor/`](skills/security-review-advisor/SKILL.md) |
| **Executive or stakeholder one-pager**: BLUF, who-reads-what, limitations, appendices | [`executive-reports/`](skills/executive-reports/SKILL.md) |
| **Brainstorm / ideation**: diverge then converge, SCAMPER, structured patterns | [`brainstorming-ideation/`](skills/brainstorming-ideation/SKILL.md) |
| **Decision-making**: decision matrix, RICE, DACI, reversible vs irreversible, pre-mortem, decision record | [`decision-making/`](skills/decision-making/SKILL.md) |
| **Systems thinking**: feedback loops, second-order effects, archetypes, causal maps | [`systems-thinking/`](skills/systems-thinking/SKILL.md) |
| **Technical RFCs**: design proposals, problem statement, alternatives considered, feedback lifecycle | [`technical-rfcs/`](skills/technical-rfcs/SKILL.md) |
| **Product thinking**: problem, user, outcome, prioritization, roadmap, PRD-lite, stakeholders | [`product-management/`](skills/product-management/SKILL.md) |
| **Spec / PRD, user stories, scope** | [`product-writing/`](skills/product-writing/SKILL.md) |
| **Acceptance criteria** | [`product-writing/`](skills/product-writing/SKILL.md) |
| **Decision record / ADR** | [`product-writing/`](skills/product-writing/SKILL.md) |
| **HTML + small JS**: semantics, forms, fetch, Jinja/Flask boundary | [`web-frontend-basics/`](skills/web-frontend-basics/SKILL.md) |
| **CSS**: flex/grid, spacing, responsive, tables | [`web-layout-css/`](skills/web-layout-css/SKILL.md) |
| **Accessibility**: WCAG habits, keyboard, ARIA, contrast, live regions, reduced motion | [`web-accessibility/`](skills/web-accessibility/SKILL.md) |
| **README, install, how-to, runbook, ADR, changelog, migration, FAQ, API doc prose, plain English** | [`docs-clear-writing/`](skills/docs-clear-writing/SKILL.md) |
| **Static sites on GitHub Pages**: plain HTML/CSS/JS, CNAME, custom domains, Actions workflows, docs/ vs root deployment | [`static-site-github-pages/`](skills/static-site-github-pages/SKILL.md) |
| **Storytelling**: narrative arc, three-act structure, hooks, stakes, concrete detail | [`storytelling/`](skills/storytelling/SKILL.md) |
| **Persuasive writing**: BLUF, business case, objections, so-what test, audience framing | [`persuasive-writing/`](skills/persuasive-writing/SKILL.md) |
| **Visual communication**: diagram design, chart types, Tufte data-ink ratio, CARP, Mermaid | [`visual-communication/`](skills/visual-communication/SKILL.md) |
| **Print production** (DPI, color profiles, bleed, file formats) | [`visual-design/`](skills/visual-design/SKILL.md) |
| **Design feedback** (composition, color, type hierarchy) | [`visual-design/`](skills/visual-design/SKILL.md) |
| **Blues tradition** (history, Delta/Chicago/Piedmont, form, imagery, visual art informed by blues) | [`blues-tradition/`](skills/blues-tradition/SKILL.md) |
| **Blues songwriting** (lyric craft, AAB verse, floating verse, call and response, imagery, editing) | [`blues-songwriting/`](skills/blues-songwriting/SKILL.md) |
| **Indigenous history of the Americas** (pre-contact, colonization, removal, boarding schools, sovereignty, AIM, contemporary issues) | [`indigenous-history-americas/`](skills/indigenous-history-americas/SKILL.md) |
| **Indigenous art of the Americas** (conversation, context, critique) | [`indigenous-art-americas/`](skills/indigenous-art-americas/SKILL.md) |
| **Indigenous bias awareness** (terms, behaviors, historical context) | [`indigenous-bias-awareness/`](skills/indigenous-bias-awareness/SKILL.md) |
| **Digital art in context** (history, critical discourse, collector vocabulary) | [`digital-art-context/`](skills/digital-art-context/SKILL.md) |
| **Tom Myer's art language** (visual signature, catalog, series, best sellers, new work) | [`tom-myer-art-language/`](skills/tom-myer-art-language/SKILL.md) |
