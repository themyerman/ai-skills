---
name: deploy-readiness
description: >-
  Pre-deployment gate. Evaluates whether a service or change is safe to ship:
  observability instrumented, alerts defined, runbook exists, rollback plan
  documented, dependencies confirmed, secrets in the right stores, capacity
  accounted for. Produces READY / NOT READY with a gap list.
  Triggers: safe to deploy, pre-release checklist, deployment gate, is this
  ready to ship, launch readiness, operational readiness, pre-deploy review.
source: ai-skills original.
---

# deploy-readiness

Answers one question: **is this safe to deploy to production?**

Run it before a new service launch, a significant feature release, or any change that meaningfully alters the production blast radius. This is not a code review — it is a deployment gate that checks the operational envelope around the code.

**Related skills:**
- Pre-PR quality gates (build, types, lint, tests) → [`../pre-pr-checklist/SKILL.md`](../pre-pr-checklist/SKILL.md)
- Does this change need a security review? → [`../security-review-advisor/SKILL.md`](../security-review-advisor/SKILL.md)
- Health checks, metrics (RED), SLOs, alerting → [`../observability/SKILL.md`](../observability/SKILL.md)
- Writing runbooks → [`../on-call-runbooks/SKILL.md`](../on-call-runbooks/SKILL.md)
- Incident response during an outage → [`../incident-response/SKILL.md`](../incident-response/SKILL.md)
- Secrets in the right stores → [`../secrets-management/SKILL.md`](../secrets-management/SKILL.md)

---

## When to run

| Situation | Scope |
|-----------|-------|
| New service going to production for the first time | Full review — all sections |
| Significant feature (new endpoint, new data store, new integration) | Full review |
| Routine release of an existing service | Abbreviated — sections 2, 3, 5, 7 |
| Hotfix or patch | Sections 3 (rollback) and 5 (alerts) only |

When in doubt, run the full review. The cost of a gap list is low; the cost of a missed gap in production is not.

---

## Section 1 — Service definition

Confirm the basics are documented before evaluating anything else.

- [ ] Service name and owner team are recorded in the service catalog (Backstage or equivalent)
- [ ] Dependencies (upstream and downstream) are listed
- [ ] Data classification is stated: what data does this service touch, and at what sensitivity level?
- [ ] SLA / SLO targets are defined (availability, latency, error rate)

If any of these are missing, stop. The review cannot be completed without them.

---

## Section 2 — Observability

A service that cannot be observed cannot be operated.

- [ ] Structured logs are emitted with consistent fields (request ID, service name, level, timestamp)
- [ ] RED metrics are instrumented: **R**ate (requests/sec), **E**rrors (error rate), **D**uration (latency p50/p95/p99)
- [ ] A health check endpoint exists and is reachable by the load balancer / orchestrator
- [ ] Distributed tracing is wired up if the service makes downstream calls
- [ ] Dashboard exists (or is linked) showing the RED metrics in production

**Gap format:** "Missing: p95 latency metric on `/api/submit` — add before deploy"

---

## Section 3 — Rollback plan

Every deployment must have a documented path back.

- [ ] Previous stable version is identified and tagged
- [ ] Rollback procedure is documented: who does it, what command, how long it takes
- [ ] Database migrations (if any) are reversible — or a compensating migration exists
- [ ] Feature flags are in place if the change needs to be disabled without a redeploy
- [ ] Rollback has been tested in a non-production environment (or the procedure is unambiguous)

---

## Section 4 — Runbook

- [ ] An on-call runbook exists for this service
- [ ] The runbook covers the top 3–5 failure modes introduced by this change specifically
- [ ] Runbook is linked from the alert definitions and the service catalog entry
- [ ] On-call rotation knows this service is deploying and what to watch for

See [`../on-call-runbooks/SKILL.md`](../on-call-runbooks/SKILL.md) for runbook writing guidance.

---

## Section 5 — Alerts

- [ ] At least one alert fires if the service is down or returning errors above threshold
- [ ] Alert thresholds are calibrated to the SLO targets (not arbitrary round numbers)
- [ ] Alerts route to the correct on-call rotation
- [ ] Alert fatigue check: no alerts that fire in normal operation; all existing alerts have a runbook entry
- [ ] New failure modes introduced by this change have corresponding alerts

---

## Section 6 — Capacity and dependencies

- [ ] Load estimate for the new traffic pattern is documented
- [ ] Resource limits (CPU, memory, connections) are set and match the load estimate
- [ ] All upstream dependencies have been confirmed healthy and notified if traffic will increase
- [ ] Downstream dependencies have sufficient capacity to absorb the new load
- [ ] Graceful degradation is defined: what happens when a dependency is unavailable?

---

## Section 7 — Security posture

This section does not replace a formal security review — it checks that security basics are in place at deploy time.

- [ ] Secrets are stored in the approved secrets store (not env vars, not source control)
- [ ] Service runs as a non-root user with least-privilege permissions
- [ ] Network exposure is explicitly defined: what ports/protocols are open, to whom
- [ ] Authentication is required on all external-facing endpoints
- [ ] Dependency versions are pinned and have no known critical CVEs
- [ ] If a formal security review is required, it is complete or a documented exception is in place

For the security review gate, see [`../security-review-advisor/SKILL.md`](../security-review-advisor/SKILL.md).

---

## Section 8 — Deployment mechanics

- [ ] Deployment is automated (no manual steps that could be skipped or mis-ordered)
- [ ] A canary or staged rollout strategy is defined for high-risk changes
- [ ] Smoke tests run automatically post-deploy and block promotion on failure
- [ ] Deployment window is communicated to stakeholders if there is any user-facing impact

---

## Output format

```
DEPLOY READINESS REVIEW
═══════════════════════
Service:    [name]
Change:     [PR / release / feature description]
Date:       [YYYY-MM-DD]
Reviewer:   [name or "self-assessed"]

VERDICT: [READY / NOT READY / READY WITH CONDITIONS]

──── GAPS ──────────────────────────────────────────
  [Section] [Gap description] — [owner] — [blocking / non-blocking]
  ...

──── CONDITIONS (if applicable) ────────────────────
  Deploy is approved if the following are resolved before or immediately after:
  [list]

──── SIGN-OFF ───────────────────────────────────────
  [ ] Engineer
  [ ] On-call lead
  [ ] Security review complete (if required)
```

A **READY WITH CONDITIONS** verdict means non-blocking gaps exist that must be closed within an agreed window post-deploy (typically 24–72 hours). Do not use it to defer blocking gaps.
