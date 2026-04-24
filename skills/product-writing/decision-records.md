# Decision records (ADRs)

**Hub:** [SKILL.md](SKILL.md)

A decision record captures why a decision was made — not just what was decided. Six months later, when someone asks "why do we do it this way?", the record answers the question and prevents relitigating settled choices.

---

## 1. Format

```markdown
# [Short noun phrase — the decision, not the problem]
e.g. "Use PostgreSQL for the session store" not "Database decision"

**Date:** YYYY-MM-DD  
**Status:** Proposed | Accepted | Deprecated | Superseded by [link]  
**Decided by:** [names or team]

## Context
What situation forced this decision? What constraints existed?
What would happen if no decision were made?
Keep to 2–4 sentences.

## Decision
What was decided, stated plainly.
Start with "We will…" or "We are…"

## Alternatives considered
| Option | Why rejected |
|--------|-------------|
| Option A | Reason |
| Option B | Reason |

## Consequences
What changes as a result? What new problems does this create?
What becomes easier, what becomes harder?
Include known trade-offs honestly.
```

---

## 2. When to write one

Write a decision record when:
- The decision is **hard to reverse** — undoing it would cost significant time or money.
- The decision will **surprise future contributors** — someone reading the code in a year would reasonably wonder why.
- The decision **was debated** — if there was a real choice between alternatives, record why you chose what you chose.
- The decision **contradicts a common default** — "we're not using X even though it's the standard here, because…"

Don't write one for every decision. Choosing a variable name doesn't need an ADR. Choosing not to use the company's standard auth library does.

---

## 3. Status field

- **Proposed** — decision is being discussed, not yet accepted.
- **Accepted** — the decision stands and is in effect.
- **Deprecated** — the decision no longer applies but the record is kept for history.
- **Superseded by [link]** — a newer decision replaced this one; link to it.

Update the status when circumstances change. A record that says "Accepted" for a decision that was reversed is actively misleading.

---

## 4. Where to store them

`docs/decisions/` is the conventional location. File names: `001-use-postgresql-for-sessions.md`. Number them sequentially so they're easy to reference ("see ADR 012").

Commit them in the same PR as the change they describe. A decision record merged a week after the code is less trustworthy.

---

## 5. Common mistakes

**Recording the decision without the context.** "We chose PostgreSQL" is useless without "because we needed row-level locking and our cloud provider's managed offering was too expensive."

**No alternatives section.** If you didn't consider alternatives, say so briefly ("We evaluated one option; alternatives were not considered due to time constraints"). An empty alternatives section looks like the record was written after the fact.

**Never updating the status.** A superseded decision left as "Accepted" actively misleads. When you reverse or replace a decision, update the old record and link to the new one.

**Writing it after the fact.** Decision records written to justify a decision already made often omit the real context. Write them during or immediately after the decision.
