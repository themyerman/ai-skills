# Reference: clear technical writing (shared principles)

Use with **[readmes.md](readmes.md)**, **[installation-guides.md](installation-guides.md)**, **[user-instructions-howto.md](user-instructions-howto.md)**, and **[plain-english.md](plain-english.md)** (word choice and **tone**; **complements** the sections below). For **executive** **structure** (BLUF, appendices), see **[`executive-reports`](../executive-reports/SKILL.md)**.

## 1. Start from the reader

- **Name the audience** in the doc (e.g. “**Operators** with repo clone and VPN”) or the doc will be written for the author.  
- **Name the outcome**: “**After** this, you can …” in one sentence at the top of **procedural** docs.  
- **Separate** *tutorial* (first-time happy path) from *reference* (flags, env, API tables). **Don’t** interleave long flag tables in the middle of a tutorial—link or append them.

## 2. Scannable structure

- **One idea per short paragraph**; use **bullets** for lists of parallel items, ** numbered** lists only for **sequence** or **ranking**.  
- **Descriptive** headings, not “More details” or “Part 2.” A reader skimming the **ToC** should know **where** to land.  
- **Front-load**: first screen answers “**Is this the right page?**”

## 3. Voice and certainty

- **Imperative** for steps: “**Run** …” not “**You** should run …”  
- **Must** / **should** / **may** consistently: **must** = breakage or bad security if skipped; **should** = best practice; **may** = optional.  
- **One term per concept** (pick **install** *or* **set up**, not both for the same action without defining them).  
- **No** mystery links: the **verb** is on the line (“**Open** the […](#)”) not “[click here](#).”
- For **layman-friendly** phrasing, **jargon** rules, and **what** to **avoid** (cutesy, long-winded), see **[plain-english.md](plain-english.md)**—in **addition** to this section, not **instead** of it.

## 4. Truth and limits

- **What you tested** (OS, Python version, date). **Known gaps** in a small **“Limitations”** or **“Out of scope”** block.  
- **If behavior depends** on org policy, say so and point to the **owning** team, not a vague “check with your admin.”

## 5. Failure is part of the doc

- A procedure without **“if it fails”** is incomplete: **symptom → likely cause → next step** (or **link to troubleshooting**).  
- **Never** “just google it” for **security** (tokens, CAs); give **one** vetted path or state **out of scope**.

## 6. Visuals

- **Screenshot** when the **UI** is unguessable; **re-record** or **date** the caption if it goes stale.  
- **Diagram** when **roles** or **data flow** are easier than prose; **threat/DFD** in `docs/` per [python-scripts-and-services / documentation.md](../python-scripts-and-services/documentation.md).

## 7. Maintenance

- **Date** the doc or the **“last verified with …”** line in install guides.  
- If **code and doc** drift, **fix the doc in the same PR** when possible; otherwise **file** a doc debt **issue** and put **TBD** in the false section.  
- **Changelog** or **release notes**: **user-visible** first; **internal** refactor last.

## 8. Related skills

| Need | See |
|------|-----|
| **Exec** tone, appendices, BLUF | [executive-reports](../executive-reports/SKILL.md) |
| **Python** repo `README` / `WORK` / `docs/` layout | [python-scripts-and-services / documentation.md](../python-scripts-and-services/documentation.md) |
| **PR** for doc+code | [code-review.md](../python-scripts-and-services/code-review.md) |
| **html** in browser UI (not prose craft) | [web-frontend-basics](../web-frontend-basics/SKILL.md) |
| **Plain**, **accessible** **wording** (not cutesy) | [plain-english](plain-english.md) |

## 9. One-page checklist (any long doc)

- [ ] **Audience** and **outcome** in the first screen  
- [ ] **Accurate** product name, **commands** **copy-pastable** (no **smart** quotes)  
- [ ] **Procedures** have **verify** and **failure** paths  
- [ ] **Terminology** consistent; **acronyms** **expanded** once  
- [ ] **Wording** passes a **[plain-English](plain-english.md)** read (or you **intend** a **domain-only** audience)  
- [ ] **No** only **color** to convey state (a11y: [web-accessibility](../web-accessibility/SKILL.md)) if it’s a **web** runbook
