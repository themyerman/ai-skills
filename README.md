# ai-skills (public edition)

This tree is a **shareable, employer-neutral** copy: org-specific process skills were **removed** and replaced with a **thin** [`shift-left-program`](skills/shift-left-program/SKILL.md). Internal policy **links,** short **URLs,** and proprietary program **names** were **generalized** or **deleted.** Have **legal** and **security** stakeholders review the bundle if you need compliance-grade assurance.

Markdown **agent skills** (mostly for **Cursor**). **Source of truth** for file layout: `skills/<name>/`.

**[Which skill when? → `SKILLS.md`](SKILLS.md)** — **routing** matrix (goal → skill), **default web reading order** (front-end → layout CSS → a11y), and **Jira/REST** vs **shell+CSV** split.

**For any reader:** this bundle is **self-contained** for learning patterns—**no** access to a particular product codebase is required. **Substitute** your own product names, paths, and Jira/CLI examples.

**Cursor** loads skills from **`<workspace>/.cursor/skills/*`**. Point that folder at this repo with one script (symlinks; no duplicate copies to maintain):

```bash
./scripts/install-cursor-symlinks.sh /path/to/your/workspace
```

With **no argument**, the script uses the **parent of this repo** (e.g. `.../REPOS/ai-skills` → `.../REPOS/.cursor/skills/`). After you **add a new** folder under `skills/`, **re-run** the same script. **Verify:** `ls -la <workspace>/.cursor/skills` should show `->` into `.../ai-skills/skills/<name>`.

**Troubleshooting:** `chmod +x scripts/install-cursor-symlinks.sh` if the script won’t run. If `.cursor/skills/<name>` is a **real directory** from an old copy, **remove** it and re-run. If you **can’t** use symlinks, use `rsync` when the repo changes (heavier).

## Layout

| Path in **this git repo** | Role |
|----------------------------|------|
| **`skills/<skill-name>/`** | **Source of truth** — all `SKILL.md`, `reference.md`, etc. |
| **`scripts/install-cursor-symlinks.sh`** | Points **`.cursor/skills/*`** in a workspace at these folders (links **every** folder under `skills/`). |
| **`.claude/CLAUDE.md`** | **Source of truth** (committed here): developer guide + optional addenda. **`<REPOS>/.claude/CLAUDE.md`** may symlink here. **No** dependency on any private product repo. |
| **`.claude/skills/`** (optional) | In-repo mirror symlinks; see [`.claude/README.md`](.claude/README.md) only if you use something that reads that path. **Cursor only cares about `.cursor/skills/`.** |

## Skills in this repo

| Skill | Folder in git |
|-------|---------------|
| **using-ai-assistants** (work with **Cursor** / **agents**: context, **verify** output, **red** lines, **escalation**; not InfoSec **policy** itself) | [`skills/using-ai-assistants/`](skills/using-ai-assistants/) |
| **shift-left-program** (thin, org-neutral: champions, **CI** defaults, **when** to **escalate**; **not** a full GRC program) | [`skills/shift-left-program/`](skills/shift-left-program/) |
| **python-internal-tools** (layout, config, DB, tests, code review, style, plus `jira.md` / `security.md` / `documentation.md` and other topic splits) | [`skills/python-internal-tools/`](skills/python-internal-tools/) |
| **llm-integrations-safety** (LLM mock, providers, `SECURITY NOTICE`, I/O screening, audit) | [`skills/llm-integrations-safety/`](skills/llm-integrations-safety/) |
| **data-handling-pii** (classification, **minimization,** **logs,** **exports;** not legal advice) | [`skills/data-handling-pii/`](skills/data-handling-pii/) |
| **secrets-management** (Slack, **CI,** **repos,** **leak** **response) | [`skills/secrets-management/`](skills/secrets-management/) |
| **shell-csv-pipelines** (bash/awk, CSV/Jira exports, `set -euo pipefail`, ShellCheck) | [`skills/shell-csv-pipelines/`](skills/shell-csv-pipelines/) |
| **executive-reports** (BLUF, appendices, plain English) | [`skills/executive-reports/`](skills/executive-reports/) |
| **web-frontend-basics** (semantic HTML, forms, small JS, `fetch`, links to Flask) | [`skills/web-frontend-basics/`](skills/web-frontend-basics/) |
| **web-layout-css** (flex/grid, responsive, tables/cards, print) | [`skills/web-layout-css/`](skills/web-layout-css/) |
| **web-accessibility** (WCAG-style checks, keyboard, ARIA, contrast, motion) | [`skills/web-accessibility/`](skills/web-accessibility/) |
| **docs-clear-writing** (README, install, how-tos, runbooks; hub to **executive-reports**) | [`skills/docs-clear-writing/`](skills/docs-clear-writing/) |

## Adding a new skill

1. Add **`skills/<new-skill-name>/SKILL.md`** (+ optional `reference.md`, `examples.md`, …).
2. Re-run **`scripts/install-cursor-symlinks.sh`** so the new directory appears under **`.cursor/skills/<new-skill-name>`** as a symlink.
3. List the skill in the table above and in [`SKILLS.md`](SKILLS.md) (**By goal** and any **split** callouts you need).
4. *(Optional.)* In this repo, `ln -sfn "../../skills/<new-skill-name>" .claude/skills/<new-skill-name>` if you use [`.claude/`](.claude/README.md).

## Other tools (Claude, etc.)

**Claude / full guide:** Edit and version **`.claude/CLAUDE.md` in this repo**. A sibling workspace layout (e.g. a **`<REPOS>/.claude/CLAUDE.md`**) can be a **symlink** to that file. This repo’s `skills/.../SKILL.md` files (or a one-liner in a product prompt) are enough for most work—no need to match `.cursor/skills/`.

## License

See [LICENSE](LICENSE) (MIT). The provenance blurb is in [PUBLIC-EDITION.md](PUBLIC-EDITION.md).
