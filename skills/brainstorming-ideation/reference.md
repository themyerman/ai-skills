# brainstorming-ideation — technique catalog

Companion to **[`SKILL.md`](SKILL.md)**. Use **2–4** patterns per session; do not run the whole list.

---

## By phase (quick pick)

| Phase | Examples |
|-------|----------|
| **Discover** | Five Whys, assumption inventory, journey pain map, “what’s immovable?” |
| **Diverge** | SCAMPER, inversion, mash-up, rapid timer, mind-map outline, morphological box |
| **Converge** | Kill criteria, option matrix, pre-mortem on shortlist, smallest experiment |

---

## Pattern index (30+)

Each row is a **prompt pattern**: apply it literally or adapt one sentence to your domain.

| # | Pattern | Core prompt (adapt) |
|---|---------|---------------------|
| 1 | **Five Whys** | “Why does that happen?” repeated until you hit a controllable root or policy wall. |
| 2 | **How Might We (HMW)** | Reframe blockers as “How might we …?” so they stay solvable. |
| 3 | **Inversion** | “How would we *guarantee* failure?” then invert each item into a guardrail or success test. |
| 4 | **Pre-mortem** | “It’s a year from now and this failed—tell the story of *how*.” Mine for risks and tests. |
| 5 | **Perspective multiplication** | List 3–5 stakeholders; for each, “What does ‘good’ look like?” and “What scares them?” |
| 6 | **Other people’s shoes** | Answer as a named role (operator, security, new hire, SRE, legal partner)—rotate lenses. |
| 7 | **Analog / mash-up** | “Who solved a similar *constraint shape* in another industry?” Steal structure, not branding. |
| 8 | **Constraint relaxation** | “If {money, time, headcount, latency} were not binding, what would we build?” Then tighten back. |
| 9 | **Constraint tightening** | “If we had half the {time, budget, lines of code}, what survives?” |
| 10 | **First principles** | “What are we *sure* is true? What did we inherit without proving?” Rebuild from facts only. |
| 11 | **Worst idea first** | Generate deliberately bad options; flip each into a constraint or a legitimate variant. |
| 12 | **SCAMPER — Substitute** | “What component, vendor, language, or team could be swapped?” |
| 13 | **SCAMPER — Combine** | “What two existing things could merge into one flow or artifact?” |
| 14 | **SCAMPER — Adapt** | “What existing pattern (in or outside the org) fits with minimal change?” |
| 15 | **SCAMPER — Modify** | “What if we 10× one attribute: throughput, safety, visibility, cost?” |
| 16 | **SCAMPER — Put to other use** | “What else could this component, dataset, or API serve?” |
| 17 | **SCAMPER — Eliminate** | “What could we delete with almost no user pain?” |
| 18 | **SCAMPER — Reverse / Rearrange** | “What if order, ownership, or deployment were backwards?” |
| 19 | **Assumption reversal** | Write hidden assumptions; negate one at a time and explore the world if it were false. |
| 20 | **Second-order effects** | “If this ships, what changes *next week* for {users, on-call, data, cost}?” |
| 21 | **Build / buy / partner** | Three columns; force at least one credible row per column before dismissing. |
| 22 | **Automation ladder** | Manual → documented runbook → script → scheduled job → service with owner. Where are we? |
| 23 | **Platform vs point fix** | “Is this a one-off patch or something that should become a shared capability?” |
| 24 | **Bundling / unbundling** | “What if this feature were split across two teams—or merged with an adjacent one?” |
| 25 | **Journey pain map** | Step the user through the workflow; mark pain, wait, rework; ideate only at red dots. |
| 26 | **Morphological box** | Pick 2–3 axes (e.g. sync/async, push/pull, batch/stream); fill cells; prune illegal combos. |
| 27 | **Random stimulus** | Pick an unrelated object or headline; force 3 analogies to the problem (discard 2). |
| 28 | **Time horizon stretch** | “Same goal in {6 months, 3 years, 10 years}—what changes in architecture or org?” |
| 29 | **Competitor / neighbor copy** | “What would {peer team, vendor X} do?” then “What must we *not* copy?” |
| 30 | **API-only / no-API** | “What if we had *only* an HTTP surface?” vs “*no* new public API—only CLI/internal?” |
| 31 | **Rapid freewriting** | Timer (8–15 min); list ideas without editing; *then* cluster (solo brainwriting). |
| 32 | **Brainwriting rounds** | Round 1: N ideas solo. Round 2: extend someone else’s (or your prior) idea without judging. |
| 33 | **Round-robin build** | Each participant adds *one* extension; in chat, simulate with “your turn / my turn” turns. |
| 34 | **Mind map (markdown)** | Central node as `##`; branches as `###` / bullets; one pass breadth-first, then prune. |
| 35 | **Innovation challenge frame** | Name a prize narrative (“best learning per dollar”); score ideas against that *single* axis. |
| 36 | **Kill criteria** | “We will *not* pursue X if {metric, policy, latency, cost} crosses this line.” |
| 37 | **Smallest experiment** | For each idea: “What’s the cheapest falsification in a day or less?” |
| 38 | **Provocative premise (PO)** | “Suppose {no auth, infinite bandwidth, zero storage}—what architecture emerges?” then walk back. |
| 39 | **Silent async doc** | Shared doc: parallel bullets, no threading debate until volume target hit—then merge. |
| 40 | **Quantity sprint** | “List 20 options in 10 minutes—no qualifiers.” Merge duplicates only after the sprint. |

---

## Classic brainstorming rules (group sessions)

When facilitating **humans**, restate these at the start:

- All ideas welcome in the diverge phase; defer judgment.  
- Quantity over quality early; duplicates OK.  
- Build on others (“yes, and”).  
- One conversation at a time when verbal; or use async doc / brainwriting for equity.  
- Explain what happens *after* (bucketing, owners, spikes)—see **[`SKILL.md`](SKILL.md)** outputs.

**Recording:** number or letter ideas so people can refer to “option 7” without rereading walls of text.

---

## From brainstorm to action (merge with SKILL.md)

| Step | Output |
|------|--------|
| Clarify | One-line goal + constraint bullet list |
| Bucket | Now / Next / Park / Blocked |
| Assign | Owner or “spike” + time box per Now item |
| Hand off | **[`product-management`](../product-management/SKILL.md)** for PRD-lite and prioritization grids |

---

## Source

Curated for **ai-skills**; patterns are widely documented in facilitation and design-thinking literature. **Override** with your org’s workshop or L10 / hackathon formats when they conflict.
