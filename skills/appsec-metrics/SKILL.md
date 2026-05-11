---
name: appsec-metrics
description: >-
  Security measurement: coverage floors vs defensible numbers, leading and
  lagging indicators, MTTR/MTTD, vulnerability aging, exec communication
  template. Answers "how secure are we?" with data rather than vibes.
  Triggers: security metrics, coverage, vulnerability aging, MTTR, security
  dashboard, how do I show progress, exec update, security KPIs.
---

# appsec-metrics

How to measure security in a way that's honest, useful, and communicable — to engineers, to leads, and to stakeholders who ask "how secure are we?"

## The core problem: coverage vs. defensibility

**Coverage metrics** tell you how much of a thing you scanned, checked, or tested. They're easy to game: 100% scanner coverage says nothing about finding rate, fix rate, or actual risk reduction.

**Defensible metrics** answer a harder question: if something goes wrong, can you show you were doing reasonable things at reasonable speed? That's what actually matters in a post-incident conversation.

Aim for both — coverage floors (proof you're looking) plus outcome rates (proof it's working).

---

## Leading vs. lagging indicators

| Type | Measures | Examples |
|------|----------|---------|
| **Lagging** | What already happened | Vulnerabilities found, incidents, MTTR |
| **Leading** | What predicts future outcomes | % repos with scanner enabled, % findings reviewed within SLA, dependency freshness |

Leading indicators let you catch a deteriorating posture before it becomes an incident. Track at least two of each.

---

## Core metrics to track

### Coverage floors (are we looking?)

- % of repos with SAST/dependency scanning enabled
- % of images in container registry scanned in the last 30 days
- % of services with a known owner (for routing findings)
- % of critical/high findings acknowledged within SLA

These are minimums. If any floor drops below a threshold you've defined, that's a signal to investigate.

### Outcome rates (is it working?)

- **MTTR by severity** — Mean Time to Remediate. Track separately for Critical, High, Medium.
- **MTTD** — Mean Time to Detect. Time from vulnerability introduced to finding reported.
- **Aging report** — findings open longer than SLA, bucketed by age (30d, 60d, 90d+). A growing 90d+ bucket is the loudest signal.
- **Recurrence rate** — same class of finding appearing in the same service again within 90 days. High recurrence = no root cause fix.
- **Exception rate** — % of findings granted an exception instead of fixed. Rising exception rate often means SLAs are unrealistic or teams are under-resourced.

### Trend, not snapshot

A single number means little. What matters is direction over time. Always show 4–6 data points (monthly or per-sprint) alongside the current value.

---

## SLA tiers (starting point — adjust to your context)

| Severity | Remediate within |
|----------|-----------------|
| Critical | 7 days |
| High | 30 days |
| Medium | 90 days |
| Low | 180 days or next planned upgrade |

SLAs only work if they're enforced and exceptions are tracked. An SLA nobody follows is noise.

---

## The aging report

Run this to identify findings that are past SLA and growing stale:

```
Findings by age bucket (Critical + High only):
  < 7 days:   N
  7–30 days:  N
  30–60 days: N
  60–90 days: N
  > 90 days:  N  ← this bucket is the one to watch
```

Review the 90d+ bucket with owners monthly. Each finding should have a documented status: in-flight, blocked (why), or exception-approved.

---

## Exec communication template

Short, scannable, no jargon. Answer three questions: where are we, what's moving, what do we need?

```
Security posture update — [Month YYYY]

WHERE WE ARE
  Critical open findings: N (was N last month)
  High open findings: N (was N last month)
  MTTR (critical): N days (target: 7)
  Scanner coverage: N% of repos (target: 100%)

WHAT'S MOVING
  - [One sentence on biggest improvement]
  - [One sentence on biggest risk or blocker]

WHAT WE NEED
  - [Specific ask, if any — headcount, tooling, prioritization call]
```

Keep it to half a page. If they want detail, link to the full report.

---

## Common mistakes

- **Reporting findings count as a health metric.** Finding more means your scanner is working, not that you're less secure. Remediation rate and MTTR are health metrics.
- **Treating 0 critical findings as the goal.** The goal is fast detection and fast fix. Zero findings often means incomplete coverage.
- **Mixing severity levels in a single number.** "We have 47 open vulnerabilities" is meaningless. Break it down by severity.
- **No denominator.** "We fixed 20 findings this month" — out of how many? Fix rate needs a denominator.

---

## Related

- Finding triage and CVSS context: [`cve-lifecycle`](../cve-lifecycle/SKILL.md)
- Dependency scanning setup: [`dependency-security`](../dependency-security/SKILL.md)
- Executive one-pager format: [`executive-reports`](../executive-reports/SKILL.md)
