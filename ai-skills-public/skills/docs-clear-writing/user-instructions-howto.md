# User instructions, how-tos, and runbooks

**Hub:** [SKILL.md](SKILL.md) · **Principles:** [reference.md](reference.md) · **After install:** [installation-guides.md](installation-guides.md)

How-tos and runbooks answer: “I need to …” for people who can already run the system (or can escalate access).

## 1. One goal per page

- The **title** is the **outcome** (e.g. *Rotate the Jira token*, *Backfill scores for one project*), not “Notes on the batch job.”
- If a page has **two unrelated** goals, split it. Related steps (e.g. export and re-import) can share a page with one **H2** per goal.

## 2. Steps readers can follow

- **Numbered** list for order-dependent work; sub-steps (1a, 1b) only when one step is heavy.
- **Decision points:** if X then … / if not then … in one visible structure—not a single rambling **if** sentence.
- For CLI: show **expected** and **example** **output** in a fenced code block, copy-pasteable.

## 3. Preconditions (before step 1)

- **Who** may run the procedure (role).
- **State** the system should be in (e.g. maintenance window, or “no writes”).
- **Downtime** or **data impact** (destructive ops) and **backup** if needed.

## 4. Rollback and risk

- If the change is **reversible**, one short paragraph: how to undo (restore backup, re-run with `--undo`, open a revert ticket).
- If it is **irreversible**, say so plainly and tie to your change-approval process.

## 5. Troubleshooting

- For frequently used runbooks, add **3–5** “If you see … → check …” lines at the bottom, or one **`docs/troubleshooting.md`** and link to it from here and from [readmes](readmes.md).

## 6. On-call and incidents

- Symptom → first read (dashboard, log, metric) → action → if still bad, then what. Note **staleness** (“re-check if the metric is older than 5 minutes”).

## 7. SOPs vs scratch

- SOPs that repeat: consider **version** and **last reviewed** if your org requires. One-off **scratch** notes in `docs/notes/` with a **date**—not the only “official” runbook.

## 8. Checklist

- [ ] **Outcome** clear in the **title**
- [ ] **Preconditions** and **safety** (backup / auth) before step 1
- [ ] **“Done”** or **verify** at end of happy path
- [ ] At least one **rollback** or **escalation** path for risky work
- [ ] **Narrative** for leadership (BLUF, appendices) goes to [executive-reports](../executive-reports/SKILL.md), not mixed into a **CLI** runbook

## 9. When to use executive-reports

- A **one-pager** for VPs and **procedural** **CLI** runbook are different artifacts. Link out to **executive-reports**; keep this file for **operator** **steps** only.
