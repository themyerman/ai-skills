---
name: docs-clear-writing
description: >-
  Clear writing of all kinds: technical docs (READMEs, install guides, how-tos,
  runbooks), blog posts, social media (Mastodon, Instagram, Patreon), and web
  copy (headlines, CTAs, about pages, product descriptions). Hub: readmes,
  installation-guides, user-instructions-howto, plain-english, content-writing.
  Pairs with executive-reports (exec narrative) and python-scripts-and-services
  documentation (where to put files). Triggers: document this, user guide,
  onboarding, SOP, plain language, README rewrite, blog post, caption,
  Patreon post, web copy, about page, social media.
---

# docs-clear-writing

## What this is

The **umbrella** for **how** to write **clear** technical text: **scannable** headings, **task-based** flow, **verify** steps, and **honest** limits. We also standardize **plain-English, layman-friendly** wording in **[plain-english.md](plain-english.md)** (professional tone—**not** cutesy or over-long). It is **not** the **org chart** of files in a particular language repo—for **Python** tools, **[`python-scripts-and-services` / `documentation.md`](../python-scripts-and-services/documentation.md)** says **where** (README vs `WORK.md` vs `docs/`) and defers here for **craft**. For **leadership / exec** narrative, BLUF, and “who reads which part,” use **[`executive-reports`](../executive-reports/SKILL.md)**—a **specialist** in this **family**, not a duplicate of this skill.

## Router: which file to open

| You are writing… | Open |
|------------------|------|
| **Shared principles** (audience, voice, must/should, anti-patterns) | **[reference.md](reference.md)** |
| **Project README**, root `README` voice, “get running in 10 minutes” | **[readmes.md](readmes.md)** |
| **Install / setup** (prereqs, version pins, verify, “if it fails”) | **[installation-guides.md](installation-guides.md)** |
| **Procedures, SOPs, “how to,”** operator steps with decisions and rollback | **[user-instructions-howto.md](user-instructions-howto.md)** |
| **Exec / stakeholder** summary, rollup, appendices, partner lens | **[`executive-reports`](../executive-reports/SKILL.md)** |
| **Plain English**, **accessible** wording, **jargon** discipline (not chatty) | **[plain-english.md](plain-english.md)** |
| **Blog posts, social media** (Mastodon, Instagram, Patreon), **web copy** | **[content-writing.md](content-writing.md)** |
| **Where** docs live in a **Python** project (README, `docs/`, `WORK.md`) and **Jira/CLI** links | **[`documentation.md`](../python-scripts-and-services/documentation.md)** |

## When to use

- A **new** or **confusing** doc, **onboarding** path, or **runbook** after an incident
- **Rewriting** a wall of text into something people can follow under stress
- **Reconciling** “we have a README and three Confluence pages that disagree”

**Drafting** or **revising** with a **model:** pair this skill (what **good** docs look like) with **[`using-ai-assistants`](../using-ai-assistants/SKILL.md)** (context, **verify** model output, **red** lines).

## When to use something else

- **Code review** of the change set → **[`code-review.md`](../python-scripts-and-services/code-review.md)**
- **Flask** or **template** mechanics → **python-scripts-and-services** **[`flask-serving`](../python-scripts-and-services/flask-serving.md)**
- **Formal** security or **Jira** program in your org → your **internal** runbooks; **[`shift-left-program`](../shift-left-program/SKILL.md)** is a thin habits layer only.

## Topic files (this folder)

- **[readmes.md](readmes.md)** — README and front-door pages.  
- **[installation-guides.md](installation-guides.md)** — setup, environments, “green light” checks.  
- **[user-instructions-howto.md](user-instructions-howto.md)** — one goal per page, steps, branches, failure recovery.  
- **[plain-english.md](plain-english.md)** — **layman-friendly** and **professional**; **define** **terms**; **no** flippant **bloat**.
- **[content-writing.md](content-writing.md)** — blog posts, social media (Mastodon, Instagram, Patreon), and web copy.

## Source

**Authored for** **`ai-skills`**. **Not** a slice of **`.claude/CLAUDE.md`**.
