---
name: brainstorming-ideation
description: >-
  Facilitated brainstorming and ideation: interactive discovery (one question at
  a time), diverge then converge, time-boxed quantity-first generation, SCAMPER
  and 30+ structured prompt patterns in reference.md. Outputs design notes,
  option matrices, phased plans, and agent-sized task bullets. Triggers:
  brainstorm, ideation, blue sky, options before we commit, stuck on one
  design, pre-mortem, what if, mind map, SCAMPER, inversion, five whys,
  brainwriting, rapid ideation, workshop, diverge converge, architecture
  alternatives, creative problem solving, judgment-free ideation.
---

# brainstorming-ideation

## What this is

A **general** facilitation pattern for exploring problems and solution shapes before you lock scope. It emphasizes deferring judgment, **quantity** early, **time limits**, and explicit convergence into something you can ship, spike, or reject.

**This skill is not** a replacement for org portfolio process, formal security review, or legal review. It **complements** **[`product-management`](../product-management/SKILL.md)** (prioritization and PRD-lite): use this skill when you need wide option generation and structured sorting; hand off to **product-management** once the problem, constraints, and top options are clear enough to prioritize.

## When to use

- You want many directions (technical, UX, process, org) before picking one.
- The team is stuck on a single design or "the way we've always done it."
- You need a facilitator-style session in chat: rules, phases, outputs.
- You want markdown you can paste into a design doc, ADR, epic, or agent prompt (see **Outputs** below).

## Session contract (tell the user up front)

1. **Goal** — What decision or artifact this session should unblock (one line).  
2. **Constraints** — Time, policy, platform, headcount, no-go areas (bullets).  
3. **Phases** — Discover (questions) → Diverge (ideas, no scoring) → Converge (buckets, kill criteria) → Next steps (owners, spikes, links to other skills).  
4. **Judgment rule** — No dismissal of ideas in Diverge; critique only in Converge using agreed criteria.

## Interactive discovery

Default to **one primary question per assistant turn** (or a very small bundle), then wait for the answer. Use questions to surface:

- Who is affected and what they are trying to do when this hurts?  
- What have you already ruled out, and why?  
- What would "too good to be true" look like vs minimally acceptable?  
- What data, systems, or approvals are immovable?

Stop discovery when answers repeat; move to Diverge.

## Diverge → converge

**Diverge**

- Time-box (for example 5–15 minutes of chat or a fixed number of idea slots).  
- Aim for quantity; duplicates are OK; build on prior ideas ("yes, and …").  
- Pull techniques from **[`reference.md`](reference.md)** (SCAMPER, inversion, personas, mash-ups, Five Whys, pre-mortem, etc.)—pick **2–4** per session, not the whole catalog.

**Converge**

- Bucket: Now / Next / Park / Blocked (policy, risk, dependency).  
- For top candidates: assumption it rests on, smallest experiment or spike, kill criterion.  
- Offer one recommended path only if the user asks; otherwise present tradeoffs fairly.

## Outputs (actionable markdown)

Offer at least one of these, tailored to the session:

| Output | Use when |
|--------|----------|
| **Option matrix** | Rows = ideas, columns = effort, risk, dependency, fit |
| **Design spec skeleton** | Goal, non-goals, constraints, chosen approach, open questions |
| **Phased plan** | Spike → MVP → hardening (or research → pilot → scale) |
| **Agent task list** | 5–15 short bullets, each testable or reviewable on its own |

For long-form prose polish (README, ADR, runbook): **[`docs-clear-writing`](../docs-clear-writing/SKILL.md)**. For stakeholder one-pagers after direction is set: **[`executive-reports`](../executive-reports/SKILL.md)**.

## Guardrails

- RAI, surveillance, or worker-monitoring ideas: consult your org's responsible AI protocols; ideation is when risk evaluation starts for product work.  
- Threat model or security review: route per your org's formal security intake process when required.  
- PII or real tickets in examples: **[`data-handling-pii`](../data-handling-pii/SKILL.md)**; use synthetic fixtures in chat.  
- Secrets in integration sketches: **[`secrets-management`](../secrets-management/SKILL.md)**.

## Related

- Prioritize and write problem / outcome / PRD-lite: **[`product-management`](../product-management/SKILL.md)**  
- Pattern catalog (SCAMPER, inversion, etc.): **[`reference.md`](reference.md)**  
- Partnering with models safely (context, verification): **[`using-ai-assistants`](../using-ai-assistants/SKILL.md)**

## Source

Authored for **ai-skills**. Technique names in `reference.md` follow common facilitation and design-thinking usage; adapt to your org's workshop norms.
