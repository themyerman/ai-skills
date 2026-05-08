# Documentation: README, WORK.md, and `docs/`

<!-- Split from the developer guide. Canonical: [`../../.claude/CLAUDE.md`](../../.claude/CLAUDE.md). Jira/CLI: [jira.md](jira.md). Security: [security.md](security.md). -->

**How to write clearly** (install guides, runbooks, README copy): **[`docs-clear-writing`](../docs-clear-writing/SKILL.md)** — *this* file is **where** in the repo; **docs-clear-writing** is **how** to structure and phrase instructional docs. **[`executive-reports`](../executive-reports/SKILL.md)** is for **leadership** narrative and BLUF.

Use three layers for internal tools; pick what fits the repo’s size.

| Where | Use for |
|-------|--------|
| **README.md** (repo root) | New developer **onboarding**: what it does, install, one working command, config reference, and flags. This is the **public** face; keep it accurate and copy-pastable. |
| **WORK.md** (optional, root) | **Running log**: backlog, **decisions** you don’t want to bury in Jira, “what shipped this week,” and when to update other docs. Good for a small team; avoid duplicating the README. |
| **`docs/`** | Deeper material: **threat models** (YAML/MD), API notes, runbooks, ADRs. Prose that would clutter the README or is **versioned** with the code. |

**Rule of thumb:** if a stranger can’t run the tool in 10 minutes, fix the **README** first. If a maintainer can’t find why you chose a Jira policy, that belongs in **WORK.md** or **`docs/`**.

---

## Cross-references (no duplicate of `CLAUDE` §11–13 here)

Earlier versions of this file **copied** **§11–13** from [`.claude/CLAUDE.md`](../../.claude/CLAUDE.md); that text **diverged** from the guide. **Now:**

| Topic | Where the canonical text lives |
|--------|-------------------------------|
| **AI in the editor** (Cursor, **context**, **verify**) | [`using-ai-assistants` / SKILL](../using-ai-assistants/SKILL.md) — see [CLAUDE §11](../../.claude/CLAUDE.md#11-working-with-ai-in-the-editor) (one-line **pointer**) |
| **Common Python** mistakes (table) | [CLAUDE §12](../../.claude/CLAUDE.md#12-common-mistakes-to-avoid) |
| **README** / **install** / **prose** **style** | [`docs-clear-writing` / SKILL](../docs-clear-writing/SKILL.md), especially [`readmes.md`](../docs-clear-writing/readmes.md) — see [CLAUDE §13](../../.claude/CLAUDE.md#13-readmes-install-guides-and-how-tos) |
| **This** file (README vs `WORK` vs `docs/`) | The **“Where / Use for”** table at the top of this file only |

