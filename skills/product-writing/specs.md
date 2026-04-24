# Writing specs and PRDs

**Hub:** [SKILL.md](SKILL.md)

A spec is done when an engineer can start work without scheduling a meeting to ask what you meant.

---

## 1. Structure

```
# [Feature name]

## Problem
What is broken or missing? For whom? What's the cost of not fixing it?

## Users
Who is this for? One sentence per persona if there are multiple.

## What we're building
Narrative description — what the user can do after this ships that they couldn't before.
Keep to 2–4 sentences. This is not a list of features; it's an outcome.

## User stories
- As a [user], I want [goal] so that [benefit].
(List only the stories this spec covers.)

## Acceptance criteria
See acceptance-criteria.md for format. List them here or link to the ticket.

## Out of scope
Explicit list of things this spec does NOT cover. This is as important as what's in scope.
If you're not sure whether something is in scope, it goes here.

## Open questions
| Question | Owner | Due |
|----------|-------|-----|
| Do we need to handle X? | @name | date |

## Not in this doc
Implementation details, unless a technical constraint directly shapes the requirement.
Timeline and resourcing.
```

---

## 2. Rules

**Describe the problem before the solution.** If your spec starts with "we will build a button that…" you've skipped the problem. Start with what's broken or missing for the user.

**One outcome per spec.** If the narrative section needs more than four sentences, you probably have two specs. Ship the smaller one first.

**Out of scope is mandatory.** Unwritten scope assumptions become bugs and arguments later. If someone will reasonably ask "does this include X?" and the answer is no, write it down.

**Open questions block shipping.** Every open question needs an owner and a date. A spec with unresolved questions is a draft, not a spec.

**Don't specify implementation.** What the system does, not how. "Users can filter by date" not "add a date picker component with a range selector." Exception: if a technical constraint is a hard requirement ("must work offline"), say so.

---

## 3. Length

Short enough that someone reads it before the kickoff meeting. Long enough that they don't need to ask you five questions afterward.

Most features need 1–2 pages. If your spec is longer than three pages, split it or move the detail to appendices.

---

## 4. Common mistakes

| Mistake | Fix |
|---------|-----|
| Spec describes the UI in detail, not the behavior | Describe what the user can accomplish, not what the screen looks like |
| No out-of-scope section | Write one; start with the first thing someone will ask about |
| Open questions left open | Every question needs an owner and a date, or remove it |
| Acceptance criteria missing or vague | See [acceptance-criteria.md](acceptance-criteria.md) |
| Problem statement is actually a solution | Rewrite the problem section starting with "Users currently can't…" or "When X happens, Y breaks" |
