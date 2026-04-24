# Executive and leadership writing (reference)

*Plain language up front, evidence and reproducibility in the back*—apply the same **shape** to your org’s rollups, monthly snapshots, and program one-pagers.

**Sentence-level plain language** (jargon, verbs, “layman-friendly” without talking down): **[`docs-clear-writing` / `plain-english.md`](../docs-clear-writing/plain-english.md)**. **Instructional** docs (runbooks, install) use the same hub: **[`docs-clear-writing` / `SKILL.md`](../docs-clear-writing/SKILL.md)** — this `reference` focuses on **leadership** one-pager **shape** and **evidence** placement; the two skills **pair**, they don’t duplicate.

---

## 1. Front of the document (load-bearing lines)

- **Title** that names the *topic* and the *kind* of artifact, e.g. a clear `… — executive summary` (or *monthly series*, *rollup*) so a reader knows this is a **narrated snapshot**, not the raw database.
- Right under the H1, **metadata** a busy person can scan in 10 seconds:
  - **Report date**
  - **What this is** — one or two **plain-English** sentences: what was measured, over what *kind* of window, and what **single question** or **metric family** the story turns on.
  - **Scope** — time range, batch/run IDs, population definition, or *explicit* “this is not the same as …”
  - **Audience** when it helps: *who* this is for and what decision it supports.
- If you only do one thing after the title, do **“What this is”**: it orients everyone before they hit a table.

---

## 2. BLUF / TL;DR (don’t bury the lede)

- **Lead** with a short section titled **TL;DR**, **BLUF**, or **Key takeaways** (bullets, not one giant paragraph).
- In those bullets, give **one plain ratio or headline** (e.g. “about 1 in 12 …”) **and** the **caveat in the same breath** (descriptive, not a target, not a compliance number).
- **Preempt misuse:** say explicitly what leadership **should not** do with the number (*do not* turn *X%* into a goal, leaderboard, or coverage target unless that is a separate, human-owned decision).
- Tie percentages to **interpretation** (“starting list for review,” “capacity and clearer rules,” “documentation and readiness signal”) so the *meaning* isn’t only the *size*.

---

## 3. “Who should read which part”

- A **small routing table** (role → read this first) is worth the space. It reduces the chance that an executive lands in **Appendix C** and thinks that’s the point.
- Optional **lens** sections: e.g. **Partner lens** (engineering) vs **Program lens** (security) — what *they* should take away, in **lay terms**, without duplicating the whole report.

---

## 4. Body: purpose, then method, then results, then meaning

- **Purpose and context** — why this report **exists** and what **program** or **process** it supports. One short paragraph: this is a **process audit** / **rollup** / **snapshot** (use the right label) and **not** a substitute for formal sign-off or human triage, when that’s true.
- **Methodology (high level)** — a **table** in **plain terms** (inputs → store → filter → score → store). **Avoid** only pasting file paths: add a *human* gloss (“ten batch runs from separate key files,” “one model call per ticket,” “excluded before scoring”). Put **reproducible paths and scripts** in appendices or a short “Configuration” table that **points** to the authoritative file.
- **Results** — lead with **aggregate** tables, then **breakdowns** that matter to the message. **Interpretation (brief):** 2–4 sentences under a dense table: what the shape **suggests**, what *not* to over-read, and *monitor vs conclude*.
- **Per-slice** tables (by run, by month) belong in the **main** document only if leadership must see them; otherwise **one** representative table + *see appendix* for the full grid.

---

## 5. Limitations and caveats (non-optional)

- A **dedicated** section: what the data **is** (e.g. *model* judgment from ticket text, *log*-derived metrics, *last* summary per key in a window) and what it **is not** (e.g. not a formal program security or compliance sign-off from Jira, not a complete census of all risk).
- Call out **exclusions** and **selection bias** in plain language. If **changing a config** (prompt, exclusion rules, time window) breaks time-series **comparability**, **say so**.
- If **totals** can be **misread** (e.g. summed across months **≠** unique people or unique tickets), **state the counting rule in one line** in the main body, not only in a footnote.

---

## 6. Appendices: what to push back

- **Long** prompt text, **full** config YAML, **line-by-line** or **token-level** evidence, **month-by-month** grids, **reconciliation** tables, **phrase mining** — *appendix*.
- At the **start of an appendix**, one line: **who can skip** it (*executives* / *casual readers* / *non-practitioners*).
- **Distribution note** when it matters: for **wide** handouts, a **short PDF** or email may **omit** appendices; keep the **authoritative** technical artifact in a **link**, repo path, or separate note so the short version does not fork truth.
- **Appendix ordering:** put **“how to read the verdicts / scale”** before the raw prompt if readers need the scale to understand the body.

---

## 7. Tone and language

- **Plain English first**: short sentences, **active** voice, **defined** terms the first time (e.g. what a **Tier** is in *portfolio* terms). For **word choice**, **jargon gating**, and **cutting clutter**, see **[plain-english.md](../docs-clear-writing/plain-english.md)**.
- **Jargon in tables** only when the audience already uses it; otherwise a **gloss** in the narrative (“Lean yes = leaning toward X, not a final program call”).
- **No mystery numerology**: if you use run IDs, batch labels, or tier names, **define or tabulate** them once, near first use.
- **Honest** uncertainty: “worth monitoring in future batches rather than over-fitting a narrative” is better than a fake precision story.

---

## 8. Tables and numbers

- Prefer **few** strong tables to **many** indistinguishable ones. Every table should answer a **stated** question in the text above it.
- **Column headers** that stand alone; **footnotes** for abbreviations if you must shrink column width.
- **Zeros** and **N/A** shown explicitly when **absence of data** is a finding (e.g. **no** items in a category).
- **Totals row** with clear whether sums are **within** a slice, **across** runs, etc.

---

## 9. Anti-patterns to avoid

- A first page of **file paths and script names** with no *why* — push paths to a **config** or **repro** appendix, keep the body **human-order**.
- **Percentages** without a **count** and a **denominator** rule, or with a **denominator** that shifts between sections without saying so.
- **Implying** audit or a “missed formal program gate” from an **automated** signal without the process limit called out in the same section.
- **Burying** the “do not use as KPI” warning **only** in an appendix.
- **Same** content in the body and appendix — either **link** or **one** canonical place.

---

## 10. Optional closing

- **Next steps** (who does what) — short, **action**-like bullets tied to the findings, not a generic “we will continue to monitor” unless you **attach** a trigger.
- **Revision** one-liner: *what would change* this report if re-run (prompt version, data window, exclusion set).

---

## Checklist before you ship

- [ ] “What this is” + **scope** + **date** on page one
- [ ] **BLUF** with **misuse** warnings in-line
- [ ] **Limitations** that match what you actually measured
- [ ] **Appendix** for anything a non-exec can skip; **label** for audience
- [ ] Counting rules for **any** % or “total” that could be double-read
- [ ] One read for **jargon** — would a non-expert executive understand the headline without Slack?
