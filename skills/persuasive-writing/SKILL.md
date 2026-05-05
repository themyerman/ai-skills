---
name: persuasive-writing
description: >-
  Persuasive writing for engineers: move people to action with security
  recommendations, architecture proposals, business cases, and incident
  summaries that drive real decisions. Rhetoric applied to technical work —
  not manipulation, not documentation. BLUF (bottom line up front), audience
  mapping, ethos/logos/pathos for technical readers, the "so what" test,
  proactive objection handling, quantified business cases, and security
  findings that actually get remediated. Triggers: persuasion, persuasive
  writing, make the case, business case, security recommendation, proposal,
  get buy-in, BLUF, bottom line up front, objections, so what, audience,
  rhetoric, move to action, approval, recommendation, stakeholder writing,
  executive communication.
---

# persuasive-writing

## What this is

A skill for engineers who need to move people to action: get a security finding remediated, win approval for a tooling investment, turn an incident summary into lasting change, or propose an architecture that actually gets adopted. This is rhetoric applied to technical work.

**This is not** [`docs-clear-writing`](../docs-clear-writing/SKILL.md) (how to write accurate, well-structured documentation). It is not [`storytelling`](../storytelling/SKILL.md) (narrative structure for talks and posts). It is specifically about **changing minds and driving decisions** — getting a good outcome from people who need to be convinced, not just informed.

**This is also not manipulation.** The line is here: persuasion helps your reader see something true and relevant. Manipulation bypasses their judgment. In engineering, you are trying to get a good decision made, not win an argument. These techniques only work sustainably in that direction.

---

## 1. Know your audience's actual concern

The most common persuasion failure is writing for yourself instead of your reader.

An engineer writes about technical elegance. The CISO cares about risk surface and audit findings. A developer writes about implementation complexity. The product manager cares about user impact and schedule. A security architect writes about CVE severity. The VP of Engineering cares about which team owns the fix and what it costs.

Before writing, answer three questions:

1. **What is this person accountable for?** (Their job, their metrics, their committee)
2. **What keeps them up at night?** (Their active risks, their current pressure)
3. **What would success look like in their terms?** (Not yours — theirs)

If you cannot answer these, you are not ready to write. Your document will be technically correct and unpersuasive. The reader will read it, nod, and do nothing.

**Audience mapping quick table:**

| Reader | Usually accountable for | Usually worried about | Frame your ask as |
|--------|------------------------|----------------------|-------------------|
| CISO | Risk posture, audit findings, board reporting | Undetected breaches, compliance gaps, regulatory action | Risk reduction, measurable evidence |
| VP Engineering | Delivery, headcount, platform reliability | Velocity loss, incident cost, retention | Time saved, incidents prevented, cost |
| Product manager | User outcomes, roadmap, OKRs | User pain, competitor gaps, missed commitments | User impact, OKR contribution |
| Engineering manager | Team throughput, on-call burden, morale | Toil, burnout, rework cycles | Hours saved, alert fatigue reduced |
| Security engineer | Technical correctness, exploitability | Real attack surface, not theoretical risk | Exploit path, likelihood, concrete fix |

---

## 2. BLUF — bottom line up front

State your conclusion, recommendation, or ask in the first sentence. Not background. Not context. Not methodology. The point.

**Wrong:**
> Our current triage process relies on a manual script written in 2021. Over the past year, ticket volume has grown significantly. The script was not designed for this scale. We have been exploring alternatives. After analysis, we believe an automated pipeline would be beneficial.

**Right:**
> We recommend replacing the manual triage script with an automated pipeline; it will save 8 hours/week and reduce missed critical tickets from an average of 3/month to near zero.

Then support it. Readers want the conclusion first, then decide if they need the reasoning. Engineers bury the BLUF because they want to show their work first — they were trained that way in school. Reports are not proofs. Your reader is not grading your derivation.

**The test:** Cover everything after your first paragraph. Does the reader know what you want them to do and why? If not, your BLUF is not written yet.

For one-pager formats and executive audiences: **[`executive-reports`](../executive-reports/SKILL.md)**.

---

## 3. Ethos, logos, pathos — for engineers

Aristotle's three modes of persuasion are not soft skills. They are the structural load-bearing elements of any argument that works. Engineers trust evidence and logic, but they also respond to credibility and consequences.

### Ethos (credibility)

Credibility is established by:
- Citing your evidence (and linking to it, not summarizing it away)
- Acknowledging what you do not know
- Being honest about tradeoffs, including the downsides of your own recommendation

Engineers trust peers who admit uncertainty more than those who never do. "We don't have production data on this — here's how we'd validate it" is more persuasive than a confident claim you cannot back up.

**Credibility killers:** cherry-picked data, omitted counterarguments, overstated certainty, recommendations you are personally benefiting from without disclosing it.

### Logos (logic)

Show your reasoning chain explicitly. If A then B, therefore C. Decision matrices. Data. Benchmarks. Failure rate trends. Cost projections.

Engineers will follow the logic even if they distrust the conclusion — and if the logic holds, the conclusion often follows. Make every step visible. "We ran 200 tickets through the new pipeline in staging; 98% classified correctly" is logos. "We think it'll work better" is not.

### Pathos (consequence)

Numbers become emotional when attached to real consequences.

- "O(n²) time complexity" — technical fact, zero pathos
- "45 minutes to triage 200 tickets today; 3 hours by Q3 at our growth rate, meaning the on-call engineer can't finish before the SLA window closes" — now there is consequence

Pathos does not mean manipulating feelings. It means making the human cost or benefit concrete. What does failure actually look like for real people? What does success feel like for the team?

The strongest arguments use all three. A recommendation with logos but no ethos is untrustworthy. One with ethos but no logos is hand-waving. One missing pathos is technically correct but unmotivating.

---

## 4. The "so what" test

After every sentence or bullet, ask: **so what?** Why should the reader care about this fact?

If you cannot answer, cut it or reframe it.

| Before | After |
|--------|-------|
| "The current script runs in O(n²) time." | "The current script takes 45 minutes on 200 tickets; at projected growth it will exceed our 30-minute SLA window by Q3." |
| "We found 3 critical CVEs in our dependencies." | "Two of the 3 critical CVEs have public exploits; our dependency fetcher runs unauthenticated and is exposed to the internet." |
| "The API lacks rate limiting." | "Without rate limiting, a single misconfigured client can exhaust our Jira quota for the entire team, making the triage dashboard unavailable during peak hours." |
| "Logging is inconsistent across services." | "When the authentication service dropped last month, we spent 4 hours correlating logs manually because formats differ. Standardized logging cuts incident resolution time." |

The test is ruthless. Every fact either earns its place by connecting to a consequence the reader cares about, or it comes out.

---

## 5. Handling objections proactively

Raise the strongest objections yourself, before the reader does.

"You might be concerned about the migration cost — here's why it's worth it" builds two things simultaneously: credibility (you've thought it through) and defuses resistance before it forms.

**Name the concern precisely, then address it specifically.**

Vague objections get vague rebuttals. Specific objections get specific answers.

**Wrong:**
> Some people might have concerns about this change. We believe those concerns are addressable.

**Right:**
> The most likely objection is migration cost: rewiring 14 services to the new auth layer will take an estimated 3 weeks of eng time. Here is why that is worth it: the current layer caused 2 incidents in the past 6 months, each costing 8–12 hours of on-call plus customer-facing downtime. The migration pays for itself if it prevents one incident.

**Checklist before you submit a proposal:**
- [ ] What will my skeptic's first objection be? Have I addressed it explicitly?
- [ ] What will my second-strongest objector say? Have I addressed that too?
- [ ] Am I raising objections I can answer — or dodging the hard ones?
- [ ] Have I conceded anything? If not, my reader will wonder what I am hiding.

If you address an objection and still cannot make the case, reconsider whether you have the right recommendation.

---

## 6. The business case structure

For proposals that need approval, use this order. Each section earns the right to make the next one.

### (a) Problem — quantified

Time, money, risk, user impact. Not feelings. Numbers.

> Manual triage takes 8–10 hours/week of senior engineer time across the team ($X at loaded cost). Three critical tickets were missed in Q1, two of which caused customer-facing incidents. Volume is growing 20% quarter-over-quarter; current tooling does not scale.

### (b) Proposed solution — concrete and scoped

What exactly are you proposing, and what is explicitly out of scope?

> Automated triage pipeline using existing Jira API + lightweight classifier. Scoped to the Security project queue only. Excludes: onboarding new queues, LLM integration (separate proposal), or changes to existing ticket schema.

### (c) Expected outcome — quantified

How will you know it worked?

> Reduces triage time to <1 hour/week. Target: zero missed critical tickets per quarter. Measurable via existing Jira dashboard.

### (d) Cost and effort — honest

The reader will estimate this themselves if you do not tell them. Your estimate is probably more accurate.

> Estimated 3 weeks of engineering (1 engineer), plus 2 weeks of parallel-run validation. No new infrastructure — runs in existing CI environment.

### (e) Risks and mitigations

The real ones, not the sanitized ones.

> Primary risk: classifier accuracy on edge cases. Mitigation: parallel run for 30 days; human review of all LOW-confidence assignments before action.

### (f) Ask — specific

What do you need, from whom, by when?

> Requesting: VP Engineering approval to allocate 1 engineer for 5 weeks starting next sprint. Decision needed by Friday to meet Q2 planning window.

This structure works because it builds trust before making a request. Do not reverse the order.

---

## 7. Security recommendations that get acted on

Security findings often get filed and forgotten. The root causes are consistent:

- Written for security engineers, not for the people who own the fix
- Risk described in abstract terms ("HIGH severity") without business translation
- The action is unclear — what exactly should I do, who should do it, how long will it take?

### Bad finding (recognizable because you have probably written this)

> **Finding: Insecure Direct Object Reference (IDOR)**
> Severity: HIGH
> The `/api/documents/{id}` endpoint does not verify that the requesting user has permission to access the specified document. This could allow unauthorized access to sensitive data. Recommend implementing proper authorization checks.

This gets filed and ignored. Why:

- "Could allow unauthorized access to sensitive data" — how likely? Has it happened? What data, exactly?
- "Implementing proper authorization checks" — what does that mean in this codebase? Who is the owner? How long does it take?
- No scenario. No urgency. No clear action.

### Good finding

> **Finding: Any authenticated user can read any document by guessing the ID**
>
> **What an attacker can do:** The `/api/documents/{id}` endpoint returns the full document — including attachments — for any valid document ID, without checking whether the requesting user has permission. Document IDs are sequential integers starting at 1. An authenticated user (any employee, any contractor) can enumerate all documents in the system by incrementing the ID in a simple loop. We confirmed this manually: we retrieved 3 documents belonging to other teams using only our own session token.
>
> **Likelihood and impact:** Likelihood is HIGH — exploitation requires only a browser and a valid login, no special tools. Impact is HIGH — the document store includes onboarding materials, salary band discussions, and security review artifacts based on the folder names we observed.
>
> **Remediation:** In `documents/views.py`, `get_document()` (line 84), add an ownership check before returning the document object. Reference the existing permission model in `auth/permissions.py:check_resource_access()` — the same pattern is already used for the `/api/projects/{id}` endpoint. Estimated effort: 2–4 hours for a developer familiar with this codebase.
>
> **Owner:** Documents service team (`#team-documents` in Slack)
>
> **Done when:** `check_resource_access()` is called for all document reads; automated test covers the unauthorized-access case; deployed to production.

The bad finding is technically accurate. The good finding gets fixed.

---

## 8. Revision for persuasion

After drafting, do a dedicated persuasion pass. Read specifically for:

**Sentences that explain what without saying why.** Find every place you stated a fact and ask the so-what test (section 4). Add the consequence or cut the fact.

**Passive voice hiding agency.** "Errors were found" obscures who found them and creates doubt. "Our scanner found 3 critical vulnerabilities in `auth-service`" is concrete and credible. Passive voice in security findings is particularly damaging — it makes real findings feel theoretical.

**Hedging that undermines confidence.** "It might be possible that we could potentially consider..." — cut to "We recommend." Engineers hedge because they are afraid of being wrong. But hedged recommendations do not get acted on. If you are not confident enough to make a direct recommendation, you have more analysis to do, not more qualifications to add.

**Conclusions buried at the end.** Move them to the top. Every time.

**One practical pass:** Highlight every sentence that starts with "The" or "This." These often signal information dumps rather than persuasive claims. "The current system lacks rate limiting" → "The lack of rate limiting means a single buggy client can take down the entire API for the team."

**The readback test:** Read your document aloud. Where you stumble, your reader will also stumble. Stumbling points are where you lost the argument.

---

## 9. When not to persuade

Some decisions should not be made by whoever writes best.

If the issue requires a formal process — legal review, exec approval at a specific level, a required security intake — write to inform and enable that process, not to shortcut it. A well-written business case does not replace a required security review. A persuasive incident summary does not substitute for a blameless postmortem with the right attendees.

Persuasion skills make you more effective inside those processes. They do not replace the processes.

Specific cases where you hand off rather than persuade:

- **Design proposals that need broad alignment:** use **[`technical-rfcs`](../technical-rfcs/SKILL.md)**. An RFC is a structured process for gathering feedback; persuading one stakeholder is not a substitute for it.
- **Decisions with significant reversibility risk:** use **[`decision-making`](../decision-making/SKILL.md)** to structure the decision itself, then write persuasively about the conclusion.

Know when you are in a persuasion context (help someone choose) versus a governance context (fulfill a required process). They require different writing.

---

## Checklist before you send

- [ ] BLUF in the first sentence: conclusion, recommendation, or ask stated directly
- [ ] Audience mapped: I know what this person is accountable for and what their concern is
- [ ] So-what test passed: every fact connects to a consequence the reader cares about
- [ ] Strongest objection raised and addressed specifically
- [ ] Numbers quantified: time, money, risk, or user impact — not vague assertions
- [ ] Ask is specific: who needs to do what, by when
- [ ] Passive voice audit done: no hidden agency in findings or recommendations
- [ ] Conclusions are at the top, not the bottom
- [ ] Formal process required? If so, this document informs that process — does not replace it

---

## Related

- Executive one-pager format: **[`executive-reports`](../executive-reports/SKILL.md)**
- Instructional and technical writing (READMEs, runbooks, ADRs): **[`docs-clear-writing`](../docs-clear-writing/SKILL.md)**
- Design proposals and RFC process: **[`technical-rfcs`](../technical-rfcs/SKILL.md)**
- Decision structuring (DACI, RICE, pre-mortem): **[`decision-making`](../decision-making/SKILL.md)**
- Ideation before you have a recommendation: **[`brainstorming-ideation`](../brainstorming-ideation/SKILL.md)**
- Product problem/outcome framing: **[`product-management`](../product-management/SKILL.md)**

## Source

Authored for **ai-skills**. Rhetorical framework (ethos, logos, pathos) follows Aristotle's *Rhetoric*; BLUF convention from U.S. military staff writing; business case structure adapted from standard product and engineering proposal norms.
