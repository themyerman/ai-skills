---
name: storytelling
description: >-
  Narrative craft for technical work: three-act arc, setup-conflict-resolution,
  the "but / therefore" rule, opening hooks, stakes by audience, concrete
  details over abstractions, storytelling in presentations, the failure story
  (postmortems), and anti-patterns. For engineers and technical communicators
  writing design docs, incident reports, READMEs, RFCs, and presentations.
  Triggers: storytelling, narrative, story structure, three-act, incident
  narrative, technical story, how to write, make it compelling, hook, opening
  line, setup conflict resolution, and therefore but, stakes, concrete details,
  presentation narrative, write for audience, failure story, postmortem
  narrative, design doc structure, RFC intro, make it memorable.
---

# storytelling

## What this is

A **practical guide** to narrative craft applied to technical writing. Not fiction writing. Not rhetoric. The insight is narrow and empirical: humans remember and act on stories, not information dumps. The same facts arranged as a story vs listed as bullets produce dramatically different outcomes — more decisions made, more action taken, more trust built.

**This skill is not** a replacement for substance. A story told about a bad idea is still a bad idea. The goal is to make your real content land — so the right people understand it, care about it, and act on it.

**Pairs with:** [`docs-clear-writing`](../docs-clear-writing/SKILL.md) for instructional prose; [`executive-reports`](../executive-reports/SKILL.md) for stakeholder one-pagers; [`blameless-postmortems`](../blameless-postmortems/SKILL.md) for failure narratives; [`technical-rfcs`](../technical-rfcs/SKILL.md) for design proposals.

---

## 1. Why engineers need storytelling

Most technical writing is organized by **structure** — sections, bullets, headings, numbered lists. The reader gets information but no reason to care. They scan for what applies to them, find something plausible, and stop reading.

A story creates **tension and resolution**. Tension means the reader doesn't know what happens next. Resolution means they find out, and it connects to something they were already worried about. That mechanism is not a stylistic preference — it is how human attention works.

**The same facts, two approaches:**

*Bullets:*
> **Background**
> - We adopted Redis for session caching in 2022.
> - Cache TTL is set to 24 hours.
> - We use JWT for auth tokens.
> - We have 12 microservices.

*Story:*
> In 2022, we moved session state into Redis to stop our auth service from being a single point of failure. It worked — until last quarter, when a Redis misconfiguration let stale sessions accumulate. Twelve microservices were quietly serving expired auth tokens as valid. We didn't know until users started reporting that they couldn't log out.

The second version contains roughly the same facts. But it tells you why they matter, who is affected, and what went wrong. You want to know what happened next. That's the mechanism.

---

## 2. The three-act arc for technical content

Every coherent technical story has three acts, even if they're compressed into three sentences.

**Act 1 — The world as it was**
Context, what existed before, why it was fine at the time. The reader needs to understand what "normal" looked like before the problem is meaningful.

**Act 2 — The problem emerges**
Conflict, stakes, what broke, who was affected. This is the engine of the story. Without it, you have an anecdote or a tutorial, not a narrative.

**Act 3 — The resolution**
What changed, what was learned, what the world looks like now. The resolution doesn't have to be triumphant — in postmortems it often isn't — but it needs to close the loop.

**How this maps to real documents:**

| Document type | Act 1 | Act 2 | Act 3 |
|---------------|-------|-------|-------|
| **Incident report** | The system before the incident; what we assumed was safe | What triggered the failure; who was affected; how long | What we changed; what we added; what we now know |
| **Feature RFC** | Current state; why it was adequate before; what has changed | Why the current approach no longer works; the specific friction or failure | The proposed design; what it resolves; what it leaves open |
| **README background section** | What problem the project solves; what existed before it | Why the existing solutions were insufficient | What this project does differently and for whom |

**Incident report — three-act structure (compressed):**

> *Act 1:* Our ticket routing service had processed over 200,000 security tickets since 2023 with no data loss. We used a SQLite-backed queue with a single writer process, which was fine under our original load.
>
> *Act 2:* On March 14, we scaled the ingestion pipeline to handle a 4x traffic spike. Two writer processes started simultaneously. SQLite's locking behavior caused one to silently drop writes. For six hours, 40% of incoming tickets were lost — not queued, not errored, gone.
>
> *Act 3:* We replaced the SQLite queue with a Postgres-backed table with advisory locking. We added a dead-letter log for any write that fails. We now assert writer-process count in CI before any deployment.

---

## 3. Setup, conflict, resolution at the sentence level

The three-act arc doesn't only work at the document level. A **single paragraph** can have this structure. So can a single sentence.

The minimal story unit: **"We used X. Then Y happened. So we switched to Z."**

That is a story. "We use Z" is just a fact. The conflict — *then Y happened* — is what makes the fact meaningful and memorable.

**Before and after:**

*Before (just facts):*
> We use exponential backoff on all outbound HTTP calls. Retry logic is configured in `src/http_client.py`. The maximum retry count is 5 with a base delay of 2 seconds.

*After (micro-narrative):*
> We originally called downstream APIs with no retry logic. When the payment provider started intermittently returning 503s, our service failed hard and surfaced errors to users. We added exponential backoff in `src/http_client.py` — up to 5 retries, starting at 2 seconds — and the user-facing error rate dropped to zero during the next 503 episode.

Both versions describe the same system. The second one explains why it exists, which makes it actually useful when someone has to change it.

**At the sentence level:**

| Version | Type |
|---------|------|
| "Rate limiting is handled in the middleware layer." | Fact |
| "Without rate limiting, one misconfigured client could saturate the API for every other tenant. We handle it in the middleware layer so no request reaches the application tier uncontrolled." | Micro-narrative |

The micro-narrative takes two more sentences. It prevents the next engineer from removing the rate limiting because they didn't understand why it was there.

---

## 4. The "and therefore / but" rule

Trey Parker and Matt Stone, the creators of South Park, describe their script-review process this way: if scenes connect with "and then," you have a boring sequence. If scenes connect with "but" or "therefore," you have a story.

**"And then" (boring sequence):**
> We added Redis caching. And then we added retry logic on cache misses. And then we added a circuit breaker. And then we added a metrics dashboard.

That is a changelog, not a story. Each item is technically accurate and completely inert.

**"But / therefore" (story):**
> We added Redis caching to reduce database load. **But** it introduced stale data: users were seeing outdated security ticket statuses for up to 15 minutes. **Therefore** we built a targeted cache invalidation layer that fires on any ticket status transition. **But** invalidation events were being lost during Redis restarts. **Therefore** we added a durable write-ahead log for invalidation messages before they're processed.

Each transition earns the next one. The reader understands not just what was built but why each layer was necessary.

**Apply this when writing:**
- System evolution narratives
- ADR rationale sections
- Incident timeline prose (not just timestamps — the causal chain)
- Feature motivation in RFCs

The test: can you read your paragraphs aloud and replace every transition with "and then"? If yes, you have a list, not a story. Rewrite until the transitions are "but" or "therefore."

---

## 5. Stakes and audience

A story without stakes is an anecdote. Stakes are the answer to: **what is at risk if this isn't resolved?**

Stakes must match the audience. The same incident has different stakes for different people.

**The same incident, two audiences:**

*For the engineering team:*
> For six hours on Tuesday, our write path had a race condition. Two goroutines were writing to the same job queue position. One write always lost. We processed 47% of the expected job volume. The fix is a mutex on the queue writer — 12 lines in `queue/worker.go`. The test that should have caught this is now written and merged.

*For the VP of Engineering:*
> Last Tuesday from 2am to 8am, our automated security triage processed fewer than half the expected volume due to a concurrency bug in the job queue. No data was lost — unprocessed jobs were retried automatically — but our SLA for initial triage was missed for 214 tickets. The fix is deployed. We've added a regression test and a queue-depth alert so we'll catch this pattern in the next five minutes if it recurs.

Same facts. Different stakes. The engineers need to understand the technical failure so they can prevent it. The VP needs to understand the customer impact, the risk posture, and the assurance that it won't recur. Mixing these produces documents that serve neither audience well.

**Common stakes for technical audiences:**
- User impact (errors seen, data lost, features unavailable, SLA missed)
- Security exposure (what an attacker could do, for how long, against what data)
- Engineering cost (how long the workaround takes, how much it slows the team)
- System reliability (blast radius of recurrence, failure mode distribution)

Name the stakes explicitly. "This is a problem" is not a stake. "Users could not complete checkout for 47 minutes on a Tuesday afternoon" is a stake.

---

## 6. Concrete details over abstractions

Abstract language is the enemy of memory. Concrete language creates a mental image that sticks.

**Abstract:**
> The system experienced performance degradation that impacted the user experience.

**Concrete:**
> The p99 latency hit 8.3 seconds. Users submitting security tickets were seeing browser timeouts before their submission was acknowledged. The support queue received 31 tickets in 90 minutes — all from users who weren't sure their submission had gone through, so they submitted again.

The concrete version tells you: what the metric was (8.3s), what users experienced (browser timeout), what they did as a result (resubmitted), and the downstream effect (31 support tickets, duplicate submissions). You can act on that. You cannot act on "performance degradation."

**The concreteness checklist:**

| Abstract | Make it concrete |
|----------|-----------------|
| "The system was slow" | "p99 latency: 8.3s; users timing out during checkout" |
| "A significant number of requests failed" | "14,000 requests returned 500 in a 20-minute window" |
| "Users were affected" | "Users in the APAC region couldn't log in for 40 minutes (3:10am–3:50am UTC)" |
| "We improved performance" | "p99 dropped from 8.3s to 420ms after the index was added" |
| "The deployment had issues" | "Two of seven pods entered CrashLoopBackOff; the third attempt succeeded after a config rollback" |
| "Authentication was broken" | "JWTs signed with the old secret were rejected; every session created in the previous 6 hours was invalidated" |

Applied to code-level writing: name the specific function, file, and line. "There was a bug in the auth module" is abstract. "`validate_token()` in `src/auth.py:142` was accepting expired JWTs because the `leeway` parameter was set to `86400` seconds" is concrete.

Specific, sensory detail — exact numbers, real system names, specific error messages, actual user behavior — is what makes a technical story feel real rather than approximate.

---

## 7. The opening hook

The first sentence of a design doc, incident report, or presentation is usually wasted. Most engineers open with context or background: "This document describes..." or "In Q3 we began an initiative to..." Both are ways of clearing your throat before you say anything.

The opening hook earns the reader's attention by putting the stakes, the question, or the scene first — before any background.

**Three hook patterns:**

**Pattern A — The provocative fact**
Lead with the most alarming or surprising specific fact from your story.

> Last Tuesday, 40% of incoming security tickets were silently dropped for six hours — not queued, not errored, gone.

**Pattern B — The question**
Open with the question the document answers. This works especially well for RFCs and design docs, where the reader wants to know whether to read on.

> Why does our triage automation reliably triage 200 tickets per hour in staging but stall at 40 in production?

**Pattern C — The scene**
Drop the reader into a specific moment. This works well for incident reports and postmortems, where grounding in the real event matters.

> At 2:07am on a Wednesday, the on-call engineer opened Slack to 47 unread alerts. All of them said the same thing: `queue_depth: 0`. The queue wasn't empty — it wasn't being read.

**After the hook, provide context.** The hook creates the tension; the context explains what the reader needs to understand the rest of the story. But context earned by tension is read differently than context presented cold.

**Before and after:**

*Before (context-first, no hook):*
> This document covers the incident that occurred on March 14 involving the ticket ingestion pipeline. The pipeline is responsible for receiving security tickets from five upstream sources and routing them to the appropriate triage queue. The incident began at approximately 2am UTC.

*After (hook-first):*
> On March 14, our ticket ingestion pipeline silently dropped 40% of incoming security tickets for six hours — a failure mode we had no alert for and no way to detect without manually counting rows. This document explains what happened and what we changed.

The second version has the same information. It also has a reason to keep reading.

---

## 8. Storytelling in presentations

A slide deck that lists information is not a presentation. It's a document formatted as slides. The difference: a presentation has a narrative arc that the audience moves through in sequence, without the ability to skip ahead. Every slide must earn its place in that sequence.

**Situation-complication-resolution for technical presentations:**

| Phase | Purpose | Slides |
|-------|---------|--------|
| **Situation** | Establish shared context. What does everyone in the room already know? | 1–2 |
| **Complication** | Introduce the problem. Why is the current situation not acceptable? What changes if we don't act? | 2–4 |
| **Resolution** | Your proposal, decision, or recommendation. What should the audience do or believe after this talk? | 3–6 |

**One idea per slide.** If you need a second idea, use a second slide. A slide with six bullet points is six slides compressed into one, which means none of them lands. A slide with a single clear statement and a supporting visual or data point is a slide the audience can absorb in the two seconds before you speak.

**The visual should reinforce the narrative, not duplicate the text.** If your slide says "Latency increased 10x" and shows a chart of latency increasing 10x, the chart reinforces the claim. If your slide says "Latency increased 10x" and shows a table with 47 columns, the chart is noise.

**The last slide is the resolution.** It answers: what do you want the audience to do or believe when they leave this room? Not "Questions?" — that's a placeholder. The last slide should be your most important point, repeated clearly: the decision you need made, the risk you need acknowledged, the action you need taken.

**Before and after (single slide concept):**

*Before (information dump):*
> **Security Triage Pipeline — Current State**
> - Uses SQLite-backed queue
> - Single writer process
> - 24-hour job TTL
> - No dead-letter logging
> - Deployed in 2022
> - Processed 200k+ tickets without major incident

*After (narrative slide):*
> **The queue was designed for one writer — we now have four**
> [Chart: writer process count over time, with incident marker]

The "after" slide states the complication. The chart shows it. The speaker explains the rest. The audience understands the problem before the speaker finishes the first sentence.

---

## 9. The failure story

Postmortems and incident reports are the most powerful technical narratives you will ever write — if you write them well.

Done poorly, a postmortem is a timeline of events that explains what happened but not why, assigns no meaning to the failure, and is forgotten by the team within two weeks.

Done well, a postmortem is a failure story. It is honest. It is specific. It explains what the team believed, what was actually true, and what the gap between those two things cost. It makes the failure real enough that the next person who reads it will remember it.

**Structure of a failure story:**

**What we believed:** The assumption that turned out to be wrong. Not "we had a bug" — that's a description of the symptom. What did the team think was true about the system, the process, or the environment? This is the hardest part to write honestly.

> We believed that SQLite's file locking would prevent concurrent writes from interfering with each other. We had tested this — but only with a single writer process. We had never tested two simultaneous writers on the same file.

**What actually happened:** The specific chain of events, told with concrete details. Exact timestamps, exact error messages, exact metrics.

> At 3:42am, the second writer process started during a deployment. Both processes targeted the same queue file. SQLite serialized the writes — but the second process was silently discarding its own write errors rather than surfacing them. For 5 hours and 18 minutes, roughly 40% of writes were dropped.

**What we learned:** Not just what we fixed — what we now understand that we didn't before. The lesson is often about an assumption, a gap in testing, or a failure mode that wasn't in the mental model.

> We learned that our error handling masked write failures instead of surfacing them. We also learned that our queue-depth monitoring was measuring the rate of writes to the queue, not the rate of successful writes — two metrics that are identical under normal conditions and diverge dramatically under this failure mode.

**The villain is never a person.** It is always a system, an assumption, a gap in observability, a process that didn't account for a new condition. Naming a person as the cause of a failure produces postmortems that people write defensively and read suspiciously. Naming the structural cause produces postmortems that people write honestly and learn from.

For the full blameless postmortem framework, see **[`blameless-postmortems`](../blameless-postmortems/SKILL.md)**.

---

## 10. Anti-patterns

| Anti-pattern | What it looks like | What to do instead |
|---|---|---|
| **The info dump** | All facts, no narrative arc. Sections titled "Background," "Details," "Appendix" with no through-line. | Find the conflict. Ask: what problem does this document exist to address? Put that in sentence two. |
| **The chronological trap** | "At 9am we noticed X. At 9:15am we checked Y. At 9:30am we escalated to Z." Just events in order, no causal or narrative connective tissue. | Connect events with "but" and "therefore." Explain why each event caused the next. |
| **Burying the lede** | Starting with two paragraphs of background before the reader knows why they should care. | Hook first. Context second. The reader has already decided whether to keep reading by the end of sentence one. |
| **The passive voice shield** | "Errors were encountered." "Requests were dropped." "Issues were identified." Passive voice hides who did what and distances the writer from the events. | Active voice: "The queue dropped 40% of writes." "We identified the misconfiguration at 3:50am." Passive voice in postmortems especially signals defensiveness. |
| **Too many subplots** | Including every detail that exists, not just the ones that serve the story. The reader gets lost between what matters and what's background noise. | One main arc. Relevant context only. Ask of each detail: does the story break if I remove this? If not, remove it. |
| **The false resolution** | Ending with "we will monitor the situation" or "we are investigating further." This is not a resolution — it's a description of having no resolution. | If there is no resolution yet, say so explicitly: "We have mitigated the immediate risk but have not addressed the root cause. This document will be updated when the root-cause fix is deployed." |
| **Stakes-free urgency** | "This is a critical issue that needs immediate attention." Asserted urgency without named stakes. | Name the stakes: "If this recurs before the fix is deployed, we have no alerting — the next incident will also be detected by a customer." |
| **The abstract summary** | Opening or closing with vague statements: "We experienced some challenges with the system." | Open and close with your most specific, concrete, surprising fact. Save the vague summary for documents where no one will read past the title. |

---

## Related

- Instructional writing (README, how-to, runbook): **[`docs-clear-writing`](../docs-clear-writing/SKILL.md)**
- Stakeholder one-pagers and executive communication: **[`executive-reports`](../executive-reports/SKILL.md)**
- Failure narratives and blameless postmortems: **[`blameless-postmortems`](../blameless-postmortems/SKILL.md)**
- Design proposals and RFCs: **[`technical-rfcs`](../technical-rfcs/SKILL.md)**
- Persuasive writing and moving stakeholders to act: use **[`executive-reports`](../executive-reports/SKILL.md)** paired with this skill
- Visual communication: charts and diagrams that carry your narrative: **[`visual-communication`](../visual-communication/SKILL.md)**
- Persuasion structure (BLUF, objections, so-what): **[`persuasive-writing`](../persuasive-writing/SKILL.md)**

## Source

Authored for **ai-skills**. The "but / therefore" rule originates from Trey Parker and Matt Stone's writing process for South Park; the application to technical prose is this skill's adaptation. The situation-complication-resolution framework is common in executive communication training. All examples are synthetic.
