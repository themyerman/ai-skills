# Which skill when? (routing matrix)

Use this table when you are **not sure** which folder to open. **Edit** skills only under **`skills/<name>/`** in this repo. **Re-run** [`scripts/install-cursor-symlinks.sh`](scripts/install-cursor-symlinks.sh) on your workspace when **new** top-level skills are **added** (one symlink per folder under **`skills/`**).

A **companion** copy of the routing tables — with explicit **agent** instructions and **`@` (REPOS)** paths for **Cursor** — is in [`.claude/CLAUDE.md`](.claude/CLAUDE.md) under **## Skill routing** (keep in sync with this file).

---

## By goal (pick one)

| I need to… | Open |
|------------|------|
| **Partner** well with **AI** in the **editor** (Cursor, **context**, **verify**, **no** secrets, **escalation**) — **any** **role** | **[`using-ai-assistants/`](skills/using-ai-assistants/SKILL.md)** |
| **Python** service/tool: structure, venv, config, **pytest**, `ruff`, `pyproject`, logging, Jira/HTTP client, **Flask** UI, **SQLite**, PR review | **[`python-internal-tools/`](skills/python-internal-tools/SKILL.md)** (see the **table** inside) |
| **Code review** / merge readiness of a **Python** change (blockers, tests, security handoff) | **python-internal-tools** [`code-review.md`](skills/python-internal-tools/code-review.md) |
| **Shift-left** / **org** **AppSec** program (lightweight: champions, automation, when to escalate—**not** a GRC copy) | **[`shift-left-program/`](skills/shift-left-program/SKILL.md)** |
| **LLM** in app code: **mock** client, `SECURITY NOTICE`, **prompt injection**, screen in/out, **anomaly** checks, no silent mock in **prod** | **[`llm-integrations-safety/`](skills/llm-integrations-safety/SKILL.md)** |
| **PII** / **sensitive** data: **classification**, **minimization**, **safe** **logs**, **exports**, **tickets** (not **legal** advice) | **[`data-handling-pii/`](skills/data-handling-pii/SKILL.md)** |
| **Credentials** and **secrets**: no plaintext in **Slack, email,** **wiki,** chat; **.env,** **CI,** **Docker,** K8s, gitleaks; **approved** stores; **leak** **response** | **[`secrets-management/`](skills/secrets-management/SKILL.md)** |
| **Bash** / `awk` / `cut` on **CSVs** or Jira **exports**; `set -euo pipefail`; when to use **Python** instead | **[`shell-csv-pipelines/`](skills/shell-csv-pipelines/SKILL.md)** |
| **Executive** or **stakeholder** one-pager: **BLUF**, who-reads-what, limitations, **appendices** for evidence | **[`executive-reports/`](skills/executive-reports/SKILL.md)** |
| **HTML** + small **JS**: semantics, **forms**, `fetch`, Jinja/**Flask** boundary | **[`web-frontend-basics/`](skills/web-frontend-basics/SKILL.md)** |
| **CSS**: flex/grid, spacing, **responsive**, tables, **print** for internal UIs | **[`web-layout-css/`](skills/web-layout-css/SKILL.md)** |
| **Accessibility**: **WCAG** habits, **keyboard**, **ARIA**, contrast, **live** regions, reduced motion | **[`web-accessibility/`](skills/web-accessibility/SKILL.md)** |
| **README**, **install** guide, **how-to**, **runbook**, **plain** English, **SOP** wording | **[`docs-clear-writing/`](skills/docs-clear-writing/SKILL.md)** — topic files: **readmes**, **installation-guides**, **user-instructions-howto**, **plain-english** |

---

## Web UI: default reading order

For a **new** or **touched** internal page (Jinja/Flask or static), read **in this order** so you do not **CSS**-first your way past broken **semantics**:

1. **[`web-frontend-basics`](skills/web-frontend-basics/SKILL.md)** — **structure** and **behavior** (HTML, forms, small JS).  
2. **[`web-layout-css`](skills/web-layout-css/SKILL.md)** — **layout** and **visuals**.  
3. **[`web-accessibility`](skills/web-accessibility/SKILL.md)** — **WCAG** / **keyboard** / **contrast** pass.

**Server** side (Flask, auth, headers, `static/`): **python-internal-tools** [`flask-serving.md`](skills/python-internal-tools/flask-serving.md). **Docs** **tone** (not **code**): **docs-clear-writing** [`plain-english.md`](skills/docs-clear-writing/plain-english.md).

---

## Jira/CSV split

| Situation | Skill |
|-----------|--------|
| **Jira** **REST** **client**, **JQL**, **PAT**, **allowlist**, **CLI** `--preview` / **bulk** | **python-internal-tools** [`jira.md`](skills/python-internal-tools/jira.md) |
| **Text** / **CSV** **in** the **shell** (pipes, `awk`, exports from files) | **`shell-csv-pipelines`** |

If both apply (e.g. export to CSV in shell then import in Python), use **each** where that **layer** is edited; **align** on **field** and **delimiters** in **one** runbook or README. If the **export** may contain **PII** (reporter, assignee, free text), also use **`data-handling-pii`**: treat the file as **sensitive** and avoid **re-publishing** in **logs** or **Slack**.

---

## `CLAUDE.md` vs **python-internal-tools** (drift)

- The **canonical** long **Python** guide is **[`.claude/CLAUDE.md`](.claude/CLAUDE.md)** in this repo.  
- **[`python-internal-tools/reference.md`](skills/python-internal-tools/reference.md)** and **[`security.md`](skills/python-internal-tools/security.md)** are **slices** of the **numbered** sections: when **§1–3, 4–5, or 6–8** **move** in `CLAUDE.md`, **re-slice** or **manually** update those two files.  
- **§11** (AI in the editor) and **§13** (README / doc craft) in `CLAUDE.md` are **pointers** to [`using-ai-assistants`](skills/using-ai-assistants/SKILL.md) and [`docs-clear-writing`](skills/docs-clear-writing/SKILL.md) — not duplicate prose. **§12** (common mistakes table) **stays** in `CLAUDE.md` only.  
- **Other** topic files (`jira`, `flask-serving`, …) are **curated**; update them when your **team’s** **patterns** change, not on every `CLAUDE` typo. [`documentation.md`](skills/python-internal-tools/documentation.md) explains **where** **files** go; it does **not** re-copy **§11–13**.

---

## Triggers and tone (all skills)

The **`description:`** in each **`SKILL.md`** (YAML front matter) is tuned for **Cursor** routing: it lists **phrases** and **task types**. If a skill is **rarely** **auto**-selected, add **triggers** there in a follow-up.

## Your organization: policies (read internal sources, not this repo)

**Authoritative** text for Information Security, Acceptable Use, logging, and application security lives in **your** employer’s **published** **policies**. Skills here are **habits and patterns**; they **do not** duplicate or replace those documents.

---

*Part of the [**ai-skills** README](README.md). Keep this file **in sync** when you **add** or **rename** a **top-level** **skill**.*
