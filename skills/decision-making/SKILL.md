---
name: decision-making
description: >-
  Structured decision-making after option generation: reversible vs irreversible
  (two-way vs one-way doors), decision matrix with weighted scoring, RICE for
  initiative prioritization, DACI for role clarity, pre-mortem, lightweight
  decision records, and traps to avoid (analysis paralysis, HiPPO, false
  consensus). Natural partner to brainstorming-ideation (generate options →
  choose between them). Triggers: decision, decide, choose between, options,
  RICE, DACI, decision matrix, reversible, two-way door, one-way door,
  pre-mortem, tradeoffs, which option, compare options, decision record,
  decision fatigue, analysis paralysis, prioritize options, pick one.
---

# decision-making

## What this is

A **structured** approach to choosing between real candidates — after the option space is open, before you commit. It covers the full decision lifecycle: classifying the decision, scoring options, assigning ownership, stress-testing the choice, and recording it so you don't relitigate it.

**This skill is not** a replacement for formal processes: large architectural proposals go to **[`technical-rfcs`](../technical-rfcs/SKILL.md)** and **[`major-change-readiness`](../major-change-readiness/SKILL.md)**; initiative prioritization with a PRD goes to **[`product-management`](../product-management/SKILL.md)**. Use this skill when you need a decision method, not a program.

## When to use this skill

Use **after** option generation when you have 2+ real candidates and need to pick one. Also useful standalone for:

- Recurring team decisions (integration approach, library choice, deployment strategy).
- Cross-functional choices where multiple stakeholders have input but one person must decide.
- Anything you will need to justify later (to your team, a future hire, or yourself in six months).

**Quick decision table:**

| Situation | Method |
|-----------|--------|
| Low stakes, easy to reverse, familiar space | Gut call — decide in 5 minutes, write one sentence |
| 2–5 options, multiple criteria, some reversibility uncertainty | Decision matrix (§ below) |
| 3+ competing initiatives, resource constraints | RICE scoring (§ below) |
| Cross-functional, unclear who decides | DACI first, then matrix or RICE |
| High stakes, hard to reverse, architectural | Technical RFC + DACI; use this skill as pre-work |

---

## Reversible vs irreversible (two-way vs one-way doors)

**Classify your decision first.** Jeff Bezos's framing: most decisions are two-way doors — you can walk back through if wrong. A few are one-way doors. The cost of getting this wrong is asymmetric.

**One-way doors** (hard or expensive to reverse — apply more rigor):
- Database schema changes and public API contracts.
- Vendor lock-in (proprietary storage formats, SDK-only access, long contracts).
- Core architecture choices (sync vs async, monolith vs service split, auth model).
- Data-handling commitments with compliance implications.

**Two-way doors** (easy to reverse — move faster):
- Feature flags and config changes.
- Small refactors within a module boundary.
- Library version upgrades with a clear rollback path.
- UI copy and workflow order.

**Rule of thumb:** if reversing the decision would take more than one sprint and affect more than one team, treat it as a one-way door. One-way doors deserve the decision matrix, explicit DACI, and a written record. Two-way doors can use the quick template at the bottom of this file and move on.

---

## Decision matrix

Use when you have 3+ options and multiple criteria that matter differently.

**How to build one:**

1. List your options as rows.
2. List your criteria as columns. Keep it to 4–6 criteria; more creates noise.
3. Assign a **weight** to each criterion (1 = nice to have, 2 = important, 3 = must-win).
4. Score each option on each criterion (1 = poor, 3 = adequate, 5 = excellent).
5. Multiply score × weight for each cell. Sum the row. Higher total wins.
6. Sanity-check the winner against your gut: if it feels wrong, a criterion is missing or mis-weighted — name it and add it.

**Worked example: choosing a Jira integration approach**

Context: a team is building an internal triage tool that needs to read and write Jira issues. Three options: (A) direct REST client with a PAT, (B) a middleware/abstraction layer, (C) direct database connection to the Jira DB.

| Criterion | Weight | A: REST + PAT | B: Middleware | C: Direct DB |
|-----------|--------|--------------|---------------|--------------|
| **Security posture** (least privilege, no raw DB) | 3 | 5 (15) | 4 (12) | 1 (3) |
| **Maintainability** (follows supported API, upgradeable) | 3 | 5 (15) | 4 (12) | 1 (3) |
| **Capability** (full read/write, JQL, attachments) | 2 | 5 (10) | 3 (6) | 5 (10) |
| **Setup complexity** (time to first working call) | 2 | 4 (8) | 3 (6) | 2 (4) |
| **Auditability** (request logs, token scope visible) | 2 | 5 (10) | 4 (8) | 1 (2) |
| **Team familiarity** | 1 | 5 (5) | 3 (3) | 1 (1) |
| **Total** | | **63** | **47** | **23** |

Option A wins. The direct DB option (C) scores poorly on security and maintainability — the matrix makes that explicit and depersonalizes what might otherwise be a debate between two advocates.

**When the matrix misleads:** if two options are within 5% of each other, the difference is noise. Flip to the reversibility test — pick the easier-to-reverse option and set a review date.

---

## RICE scoring

Use for prioritizing among **initiatives** (features, projects, improvements) when you have limited capacity and need to defend your order.

**Formula:** `RICE = (Reach × Impact × Confidence) ÷ Effort`

| Factor | What it measures | Scale |
|--------|-----------------|-------|
| **Reach** | How many people or events affected per quarter | Raw number (users, tickets, events) |
| **Impact** | How much it moves the needle per person/event | 0.25 (minimal) / 0.5 / 1 / 2 / 3 (massive) |
| **Confidence** | How sure you are of reach and impact estimates | 50% / 80% / 100% |
| **Effort** | Person-weeks to ship (design + eng + review) | Raw number |

**Worked example: three security-tooling initiatives**

| Initiative | Reach | Impact | Confidence | Effort (weeks) | RICE score |
|------------|-------|--------|------------|----------------|------------|
| Auto-label stale tickets via JQL | 200 tickets/qtr | 1 | 80% | 2 | (200 × 1 × 0.8) ÷ 2 = **80** |
| LLM-assisted triage summaries | 50 tickets/qtr | 2 | 50% | 6 | (50 × 2 × 0.5) ÷ 6 = **8.3** |
| Jira link health checker for docs | 500 links/qtr | 0.5 | 100% | 1 | (500 × 0.5 × 1.0) ÷ 1 = **250** |

The link health checker wins despite modest impact-per-item because reach is high, confidence is high, and effort is tiny.

**Warning — RICE is easy to game.** Confidence scores are the most abused lever. If your team consistently scores confidence at 100%, the model is broken. Force honest calibration: "what would make this 80% instead of 100%?" Name those risks explicitly. A project with inflated confidence that fails is worse for team trust than a lower RICE score that delivered.

---

## DACI — who decides

Assign roles **before** the discussion starts, not during it. Unclear ownership is the most common reason decisions stall or get relitigated.

| Role | Responsibility | Count |
|------|----------------|-------|
| **Driver** | Owns the process — gathers input, runs the meeting, writes the record, drives to closure | Exactly 1 |
| **Approver** | Has final say — the decision is theirs to make | Exactly 1 (not a committee) |
| **Contributors** | Provide input, expertise, concerns — do not decide | As many as needed |
| **Informed** | Notified after the decision is made — no input role | Whoever needs to know |

**The most common failure:** multiple Approvers. "The team decides" means no one decides. If two people both have veto, name the tiebreaker explicitly before you start.

**Worked example: choosing a new secrets storage approach**

| Role | Person |
|------|--------|
| Driver | Platform eng lead — schedules review, collects options, writes record |
| Approver | Engineering manager — owns the risk and resourcing call |
| Contributors | Security champion (compliance constraints), Senior SWE (implementation tradeoffs), DevOps (rollout complexity) |
| Informed | All engineers on the affected repos |

The security champion raises constraints; the senior SWE scores options; the manager decides. Contributors cannot block — they can only raise concerns the Approver must acknowledge.

**When to escalate DACI:** if the Approver does not have authority over all affected systems, escalate to their manager before the decision meeting, not after.

---

## The pre-mortem

Before committing, run a fast failure analysis: "It is six months from now and this decision failed badly. What happened?"

Ask each contributor to write their top 3 failure modes independently (2 minutes), then share. Failures that appear on multiple lists are your real risks.

**Common outputs from pre-mortems:**

- An assumption that looked solid but was actually untested ("we assumed Jira API rate limits wouldn't be an issue at scale").
- A dependency that no one owned ("we assumed platform would upgrade the shared library before our deadline").
- A stakeholder who wasn't consulted ("the data governance team would have blocked this if they'd known").

For each top failure mode, add one mitigation or a trip-wire (a condition that tells you the decision is failing before it fully fails).

The pre-mortem is short — 15–30 minutes for most decisions. For deeper facilitated technique, see **[`brainstorming-ideation`](../brainstorming-ideation/SKILL.md)** (the pre-mortem technique is in its `reference.md`).

---

## Documenting the decision

Write down:

1. **What was decided** — one sentence.
2. **Why** — the 2–3 key reasons; reference the matrix or RICE scores if you used them.
3. **What was explicitly rejected and why** — this prevents revisiting dead ends.
4. **Who decided** — the Approver's name (DACI).
5. **When** — date.

A one-paragraph decision record is enough for most choices. For large architectural decisions that need async input from many reviewers, use **[`technical-rfcs`](../technical-rfcs/SKILL.md)**. For formal ADR format, use **[`docs-clear-writing/adr-architecture-decisions.md`](../docs-clear-writing/adr-architecture-decisions.md)**.

Store the record where future teammates will find it: a `docs/decisions/` directory, a linked Confluence page, or the relevant Jira ticket. Do not store it only in a Slack thread.

---

## Avoiding common traps

**Analysis paralysis** — The team collects more data indefinitely because no one is comfortable deciding. Fix: set a decide-by date at the start. "We will decide by end of sprint 42 with the information we have." Deferral is also a decision, with its own consequences.

**HiPPO effect** — The Highest Paid Person's Opinion wins by default, overriding criteria and evidence. Fix: run the matrix or RICE before the senior person speaks. Present scored options, not a recommendation. Criteria depersonalize the debate.

**False consensus** — Everyone nodded in the meeting but disagreed privately. The decision unravels at implementation. Fix: at the end of the decision meeting, explicitly ask each contributor: "What is your biggest remaining concern with this choice?" Give people permission to name doubt. You want this surfaced now, not at the post-mortem.

**Deciding by not deciding** — The team defers and the status quo continues by inertia. Treat this as an explicit choice: "We are choosing to keep the current approach. The cost of that is X. We will revisit when Y." Name the trip-wire.

**Scope creep during the decision** — New options keep appearing after the decision window should have closed. Fix: freeze the option list when you enter the scoring phase. New options go on a backlog for the next decision cycle.

---

## Quick decision template

Paste this block into your `docs/decisions/` file, a Confluence page, or a Jira ticket comment. Fill in every field; leave nothing blank (use "N/A" explicitly if a field genuinely does not apply).

```markdown
## Decision: [Short title — what was decided]

**Status:** Proposed | Decided | Superseded by [link]  
**Date:** YYYY-MM-DD  
**Decided by:** [Name, role — the DACI Approver]  
**Driver:** [Name, role]

### Context

[2–3 sentences: what problem or opportunity prompted this decision, and what constraints shaped the options. Include the reversibility classification: one-way door or two-way door.]

### Options considered

| Option | Summary | Reason rejected / reason chosen |
|--------|---------|----------------------------------|
| A | … | Chosen — [key reason] |
| B | … | Rejected — [key reason] |
| C | … | Rejected — [key reason] |

### Decision rationale

[2–4 sentences: why this option over the others. Reference any matrix scores, RICE numbers, or pre-mortem outputs that informed the choice.]

### Risks and mitigations

| Risk | Likelihood | Mitigation or trip-wire |
|------|------------|-------------------------|
| [Risk 1] | High / Medium / Low | [What reduces it or signals it's happening] |
| [Risk 2] | … | … |

### What we explicitly ruled out and why

- [Option B]: [Reason — e.g. vendor lock-in risk too high given two-year runway]
- [Option C]: [Reason — e.g. requires DB access that violates least-privilege policy]
```

---

## When to escalate

This skill handles the decision method. For the following, hand off to the right skill before or after using this one:

- **Security and compliance decisions** (threat model scope, data classification, access controls): your org's formal security intake process
- **Large architectural changes** needing async written input from many engineers: **[`technical-rfcs`](../technical-rfcs/SKILL.md)** and **[`major-change-readiness`](../major-change-readiness/SKILL.md)**
- **Resource, headcount, or portfolio decisions** with executive visibility: **[`product-management`](../product-management/SKILL.md)** and **[`executive-reports`](../executive-reports/SKILL.md)**
- **Incident decisions** (rollback, hotfix, customer communication during an outage): **[`incident-response`](../incident-response/SKILL.md)**

---

## Related

- Generate the options before deciding: **[`brainstorming-ideation`](../brainstorming-ideation/SKILL.md)**
- Large decisions needing async written input: **[`technical-rfcs`](../technical-rfcs/SKILL.md)**
- Initiative prioritization with PRD-lite: **[`product-management`](../product-management/SKILL.md)**
- Formal ADR format: **[`docs-clear-writing/adr-architecture-decisions.md`](../docs-clear-writing/adr-architecture-decisions.md)**
- Pre-mortem as a full facilitated technique: **[`brainstorming-ideation/reference.md`](../brainstorming-ideation/reference.md)**
- Post-decision incident analysis: **[`blameless-postmortems`](../blameless-postmortems/SKILL.md)**

## Source

Authored for **ai-skills**. Frameworks (RICE, DACI, two-way/one-way doors, pre-mortem) follow common product and engineering usage; adapt labels and scales to your org's conventions.
