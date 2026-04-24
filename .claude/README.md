# Optional: `.claude/` in this repo

**Cursor does not use this folder.** Cursor loads project skills from **`<your-workspace>/.cursor/skills/*`**, which is what [`../README.md`](../README) explains how to keep in sync with [`../skills/`](../skills).

This directory exists only if you also want a **path under `.claude/`** in the **same git repo** to see the same files (e.g. another tool that only looks under `.claude/skills`).

- **`../skills/<name>/`** — real files.  
- **`.claude/skills/<name>` →** symlinks to `../../skills/<name>` (no duplicate content).

**`CLAUDE.md`** in **this** directory is the **versioned** merged developer guide. A parent workspace (e.g. a **`<REPOS>/.claude/CLAUDE.md`**) may be a **symlink** to this file. The first sections of the guide are **universal**; the **addenda** are **optional** illustrations of two common **internal** tool shapes. The **python-internal-tools** and **llm-integrations-safety** skills **slice** that file for Cursor. **[`shift-left-program`](../skills/shift-left-program/SKILL.md)** is a **thin** org-neutral complement (not a reslice of `CLAUDE.md`). The **shell-csv-pipelines** skill is **bash/CSV** habits. The **executive-reports** skill is **leadership** writing. **using-ai-assistants** is **meta** (working with **AI** in the **editor**). The **web-*** skills and **docs-clear-writing** are **browser** and **instructional** **prose** guides. **Canonical** goal→folder list: **[`../SKILLS.md`](../SKILLS.md)**.

**You can delete `.claude/`** entirely if you only care about **`.cursor/skills`** and do not need the `CLAUDE.md` path under `.claude/`.
