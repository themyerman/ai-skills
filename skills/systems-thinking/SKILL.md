---
name: systems-thinking
description: >-
  Systems thinking for engineers and technical leads: stocks and flows, feedback
  loops (reinforcing and balancing), second-order effects, unintended
  consequences, causal loop diagrams, and five recurring archetypes. Practical
  tools for architecture decisions, design reviews, and diagnosing recurring
  problems — not academic theory. Triggers: systems thinking, feedback loop,
  second-order effects, unintended consequences, reinforcing loop, balancing
  loop, stock and flow, causal loop, systems archetype, tragedy of the commons,
  escalation, fixes that fail, shifting the burden, complex system, ripple
  effect, why does this keep happening, recurring problem, architecture
  tradeoffs.
---

# systems-thinking

## What this is

A practical toolkit for engineers and technical leads who need to reason about systems where cause and effect are separated in time or space — where a "fix" keeps breaking something else, or the same problem keeps coming back regardless of how many times it's addressed.

**Use this skill when:**
- A fix you shipped created a new problem you didn't expect.
- The same incident type keeps recurring despite repeated solutions.
- A proposed change has ripple effects you need to map before committing.
- You're designing something that will interact with other services, teams, or incentive structures over time.

**Don't use this for** simple linear cause-and-effect. If a service throws a null pointer exception because of a missing nil check, fix the nil check — you don't need a causal loop diagram. Systems thinking is for situations where the cause is structural, not incidental.

**This skill complements** — it does not replace — **[`blameless-postmortems`](../blameless-postmortems/SKILL.md)** (single incident analysis) and **[`brainstorming-ideation`](../brainstorming-ideation/SKILL.md)** (option generation once you've mapped the problem).

---

## Stocks and flows

A **stock** is anything that accumulates or depletes over time:
- A job queue depth
- Rows in a database table
- On-call engineer fatigue
- Technical debt
- Trust between teams

A **flow** is a rate that changes a stock:
- New tickets arriving (inflow) vs. tickets resolved per hour (outflow)
- Incidents added to the backlog vs. incidents closed
- Confidence gained from shipped features vs. confidence lost from outages

**The key insight:** you cannot change a stock instantly. You can only change its inflows or outflows, and those changes take time to accumulate.

**Applied example — alert fatigue:** When on-call load becomes unsustainable, a common response is "add more engineers to the rotation." This reduces alert burden per person (changes the outflow of fatigue), but the stock of fatigue in the team doesn't drop immediately. Engineers who have been running hot for months still need recovery time. Policies that treat alert fatigue as something you can fix in a single sprint by adding headcount are misreading what kind of variable fatigue is. The inflow (alert volume) also continues unless addressed — which means the stock may start rebuilding as soon as the new engineers get up to speed.

When you're stuck on a persistent problem: identify what the relevant stocks are, map what's changing their inflows and outflows, and ask whether your proposed fix actually affects the right flow.

---

## Feedback loops

A **feedback loop** exists when a change in a stock causes a change in the flows that produced it. There are two types.

### Reinforcing loops (amplifying)

A change in one direction produces more change in the same direction — either a vicious cycle or a virtuous one.

**Software example (vicious):** A service becomes slow under load. Clients time out and retry. Retries increase load on the slow service. The service slows further. More retries. This is a reinforcing loop — the initial slowdown amplifies itself. Left unchecked it leads to a cascading failure.

**Software example (virtuous):** A team starts writing tests. Tests catch regressions. Fewer regressions mean less fire-fighting. More time for tests. Higher coverage. More confidence to ship. Shipping velocity increases, which generates positive feedback about the team, which attracts stronger engineers, who write more tests. This loop also reinforces — in the desired direction.

### Balancing loops (stabilizing)

A change in one direction triggers a response that pushes back toward a target or equilibrium.

**Software example:** An autoscaler monitors CPU utilization. When CPU crosses 80%, new instances are added. CPU drops. The autoscaler sees that utilization is now 40% and removes instances. CPU rises again. This loop is balancing — it resists deviation from the target. Most control systems (autoscalers, circuit breakers, rate limiters) are balancing loops by design.

**Balancing loops have limits.** In the autoscaler example, the balancing loop stops working when you hit your cost budget cap, your account quota, or your cloud region's capacity ceiling. When the limit is reached, the balancing loop disengages and the reinforcing pressure of load takes over. Knowing your balancing constraints in advance is part of capacity planning.

**Before acting on a problem, identify which type of loop you're in.** If you're in a reinforcing loop, you need to interrupt it — circuit breakers, backoff, load shedding. If you're in a balancing loop that isn't converging, you need to find what's preventing it from reaching its target.

---

## Second-order effects

The **first-order effect** of a decision is the intended, obvious outcome. The **second-order effect** is what happens because of the first-order effect — often unintended, often delayed, often the thing that creates the next problem.

**Example:**
- Decision: add a caching layer in front of the database.
- First-order effect: read latency drops. Customers notice improved response times.
- Second-order effects: cache invalidation bugs emerge when writes happen out of order. A stale-read incident occurs during a deployment that doesn't flush cache correctly. The team now has to monitor cache hit rate, eviction policy, and memory pressure — three new signals that didn't exist before. When the cache is unavailable, the database absorbs a thundering herd it was never sized for.

None of those second-order effects are reasons to never use a cache. They are reasons to plan for them before shipping, not after.

**Template — ask "and then what?" twice:**

For any proposed solution, run through this chain:
1. What is the direct effect of this change?
2. What happens as a result of that effect? (second order)
3. What happens as a result of that? (third order — stop here in most cases)

Do this once for the success case and once for the failure case. The failure-case second-order effects are usually where the unintended consequences live.

---

## Unintended consequences checklist

Before committing to a solution — in a design review, an RFC, or a 10-minute whiteboard sketch — run through these questions:

- **Who else uses this system?** Other teams, other services, downstream consumers. Does your change affect their behavior, their SLAs, their cost?
- **What happens at 10x load?** Not at your current scale — at the scale this system will operate at after it's successful, or during a traffic spike. Does the solution hold, or does it introduce a new bottleneck?
- **What's the failure mode if a dependency goes down?** Every dependency you add is a new failure mode. What happens to your service if that dependency is unavailable for 30 seconds? For 10 minutes?
- **Does this create a new single point of failure?** Centralizing something (a shared cache, a shared queue, a shared config store) often improves performance in the normal case and creates a single point of failure in the failure case.
- **Does this change incentives in a way that produces perverse behavior?** Systems involving humans are especially prone to this. If you make it easy to mark an alert as "acknowledged" without resolving it, engineers will start acknowledging alerts to stop the noise — and the underlying signal disappears.

You don't need to block a decision because one of these answers is uncomfortable. You need to know the answer before you ship, not after.

---

## Causal loop diagrams (lightweight)

You do not need formal notation or modeling software to draw a causal loop diagram. A text-based causal map is enough for a design discussion.

**Notation:**
- Arrow with `+` means: when the source increases, the target also increases (same direction).
- Arrow with `-` means: when the source increases, the target decreases (opposite direction).
- A loop that has an even number of `-` arrows (or zero) is reinforcing.
- A loop that has an odd number of `-` arrows is balancing.

**Example — why a "just fix it faster" policy creates more incidents over time:**

```
Incident volume
    |
    | + (more incidents → more pressure to fix fast)
    v
Time pressure on engineers
    |
    | + (more pressure → more shortcuts taken)
    v
Shortcuts / deferred fixes
    |
    | + (more deferred fixes → more fragile system)
    v
System fragility
    |
    | + (more fragility → more incidents)
    v
[back to Incident volume]
```

This is a reinforcing loop with all `+` arrows — a vicious cycle. The policy of "fix it faster" addresses the symptom (each individual incident) while strengthening the loop that produces incidents (system fragility). Adding incident response speed doesn't interrupt the loop; reducing shortcuts and deferred fixes does.

To draw your own: list the 4–6 variables that most influence your situation. Draw arrows between them. Label each `+` or `-`. Find any closed loops. Determine whether each loop is reinforcing or balancing. Then ask: which variable, if changed, would break the reinforcing loop or strengthen the balancing one?

---

## Archetypes — recurring system patterns

Five patterns appear so frequently in software organizations that naming them speeds up diagnosis.

### Fixes that fail

**Pattern:** A short-term fix is applied to relieve a symptom. The fix works initially, but has delayed side effects that restore the original problem — or make it worse.

**Software example:** Database query performance degrades. The team adds an index, performance improves, the incident closes. Six months later, the table has grown and write performance degrades because of the additional index. The team adds read replicas. Read replica lag introduces inconsistency bugs. Each "fix" creates the next problem. The root cause — an unscaled data model — is never addressed.

**Signal:** You're in this archetype when the same category of problem recurs despite repeated interventions, and each intervention buys less time than the last.

### Shifting the burden

**Pattern:** A symptomatic fix reduces the urgency to address the root cause. The symptomatic fix becomes habitual. The capability to address the root cause atrophies.

**Software example:** A service has flaky tests that fail in CI about 20% of the time. Rather than fixing the flakiness, the team adds a retry policy to the CI pipeline — tests re-run automatically on failure. The immediate pain goes away. Engineers stop treating test failures as signal. The underlying flakiness grows as more tests are added with the same patterns. Two years later, nobody on the team knows which tests are reliably meaningful because the retry habit has obscured the signal entirely.

**Signal:** You're in this archetype when a workaround is in place and the original problem is no longer visible — but also never resolved.

### Tragedy of the commons

**Pattern:** A shared resource is degraded by individually rational choices. Each user optimizes for their own benefit; the collective degrades the shared resource; everyone is eventually worse off.

**Software example:** A shared PostgreSQL instance serves twelve internal services. Each team optimizes their own queries without a global view of connection pool usage. Each team's choices are locally rational. Collectively, they saturate the connection pool during peak hours. Connection timeouts cascade across all services. No single team caused the outage; the structure of shared ownership did.

**Signal:** You're in this archetype when individuals or teams behave rationally but the shared resource degrades. The fix usually involves either partitioning the resource (each service gets its own DB) or governing access to it (connection limits per service, resource quotas).

### Limits to growth

**Pattern:** A reinforcing growth loop drives a system toward improvement, but runs into a constraint that slows and eventually stops growth. If the constraint isn't addressed, growth stalls or reverses.

**Software example:** A microservice architecture performs well and teams adopt it enthusiastically. Service count grows. Observability, deployment complexity, and cross-service coordination overhead also grow. At some point, the overhead of maintaining hundreds of services exceeds the productivity gains from decomposition. Growth slows not because the architecture is wrong, but because the supporting capability (observability, platform tooling, service mesh) didn't scale alongside it.

**Signal:** You're in this archetype when a previously successful approach stops working, and the reason is a constraint that wasn't relevant at smaller scale. The fix is to address the limiting constraint — not to push harder on the growth lever.

### Escalation

**Pattern:** Two parties each respond to the other's moves, with each response triggering a stronger counter-response, in a spiral that neither party intended and both find undesirable.

**Software example:** Service A and Service B share a downstream dependency. Service A experiences elevated error rates and responds by adding aggressive retries with short timeouts. The retries increase load on the dependency. Service B, also seeing elevated errors, adds its own aggressive retries. The dependency saturates. Both services increase their retry counts further. The dependency fails completely. Neither team intended to take down the dependency — each team was acting rationally in isolation.

**Signal:** You're in this archetype when two or more parties are each reacting to the other's behavior, and the situation is deteriorating despite each party acting in what they believe is their own interest. The fix usually requires coordination — circuit breakers, backoff standards, or communication between the teams.

---

## Applying it to architecture decisions

When you're evaluating a proposed architectural change — adding a service, changing a data model, introducing a new dependency — spend 10 minutes mapping:

1. **What are the key stocks?** Queue depths, table sizes, connection counts, team capacity, latency budgets.
2. **What flows does this change affect?** Which inflows increase or decrease? Which outflows?
3. **What feedback loops does this create or break?** Does the change introduce a new reinforcing loop? Does it remove a balancing constraint?
4. **What are the second-order effects?** Apply the "and then what?" template once for the success path and once for the failure path.
5. **Which archetype does this resemble?** If the proposal looks like "fixes that fail" or "tragedy of the commons," name it explicitly. Naming the pattern is often enough to shift the conversation.

This doesn't require a formal model. A 10-minute whiteboard sketch covering these five questions is usually enough to surface the non-obvious risks before a design gets implemented.

---

## Applying it to recurring incidents

When the same incident type keeps recurring — database overload, memory leaks, authentication failures under load, alert storms — the immediate cause of each individual incident is not the system cause of the pattern.

The immediate cause is what the postmortem captures: this query ran long, this memory wasn't freed, this token expired. The system cause is the structure that keeps regenerating the condition.

**Process:**
1. Collect 3–5 incidents of the same type. Don't look at each in isolation.
2. For each incident, note: what triggered it, what made the system vulnerable to it, what reduced (or failed to reduce) the condition before the incident.
3. Map the feedback loop that regenerates the vulnerable condition. Ask: what policy, incentive, or structure keeps recreating this state?
4. Look for archetypes. "Fixes that fail" and "shifting the burden" are the most common patterns behind recurring incidents.

**Example:** A team has recurring out-of-memory incidents on a worker service. Each postmortem finds a different large allocation as the immediate cause. The system cause is that there's no memory limit configured on the container, so each deployment that slightly increases memory usage eventually causes an OOM. The loop: OOM incident → postmortem finds proximate cause → specific allocation is fixed → next release adds different allocation → OOM incident. The fix is to set a memory limit and instrument allocation growth, not to chase individual allocations.

**This complements [`blameless-postmortems`](../blameless-postmortems/SKILL.md).** Use that skill for single-incident analysis — timeline, contributing factors, action items. Use systems thinking when you notice the same contributing factors appearing across multiple postmortems. The pattern across incidents is signal that the structure itself needs to change.

---

## Quick systems audit — paste-ready checklist for design reviews

Use this in any design review, RFC comment, or architecture discussion. You don't need to answer every question every time — pick the ones that are most relevant to the system being reviewed.

```
Systems audit questions:

Stocks and flows
[ ] What are the key stocks in this system (queues, tables, capacity, fatigue)?
[ ] What changes their inflows?
[ ] What changes their outflows?
[ ] Can any stock be changed faster than the flows allow?

Feedback loops
[ ] What feedback loops does this change create?
[ ] Are any of those loops reinforcing? What amplifies them?
[ ] Are any of those loops balancing? What limits them?
[ ] What happens when a balancing constraint is hit?

Second-order effects
[ ] What is the first-order effect of this change?
[ ] And then what? (second order — success path)
[ ] And then what? (second order — failure path)

Unintended consequences
[ ] Who else uses this system and how does this affect them?
[ ] What happens at 10x load?
[ ] What's the failure mode if a dependency goes down?
[ ] Does this create a new single point of failure?
[ ] Does this change incentives in a way that produces perverse behavior?

Archetypes
[ ] Does this resemble "fixes that fail" (delayed side effects restore the problem)?
[ ] Does this resemble "shifting the burden" (workaround reduces urgency to fix root cause)?
[ ] Does this resemble "tragedy of the commons" (shared resource, individually rational choices)?
[ ] Does this resemble "limits to growth" (reinforcing loop about to hit a constraint)?
[ ] Does this resemble "escalation" (two parties reacting to each other in a spiral)?
```

---

## Related

- Generating options before deciding: **[`brainstorming-ideation`](../brainstorming-ideation/SKILL.md)**
- Documenting complex decisions with alternatives and tradeoffs: **[`technical-rfcs`](../technical-rfcs/SKILL.md)**
- Single incident analysis: **[`blameless-postmortems`](../blameless-postmortems/SKILL.md)**
- Measuring stocks and flows in production (RED metrics, SLOs, health checks): **[`observability`](../observability/SKILL.md)**

## Source

Authored for **ai-skills**. Archetype names (fixes that fail, shifting the burden, tragedy of the commons, limits to growth, escalation) follow Senge's *The Fifth Discipline* and Meadows' *Thinking in Systems* — two foundational texts. The checklist and causal loop notation are simplified for engineering design discussion; adapt to your team's existing review formats.
