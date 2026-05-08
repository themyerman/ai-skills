---
name: blameless-postmortems
description: >-
  Blameless incident postmortems: timeline, contributing factors (not individual
  blame), customer impact, what went well, concrete action items with owners and
  dates, follow-up on lessons. Triggers: postmortem, incident review, outage
  writeup, RCA, retrospective, sev1, sev2, blameless, five whys without naming
  people, action items from incident.
---

# blameless-postmortems

## What this is

A **thin** pattern for **learning** from **incidents** and **near-misses** **without** **blaming** **individuals**. Focus on **systems**, **signals**, **runbooks**, and **follow-up** work that **reduces** **recurrence** and **mean time to detect/restore**.

## Principles (non-negotiable)

- **Blameless** — **no** “**who** messed up” in the **record**; **do** name **what** **failed** (config, **alert** gap, **missing** test, **unclear** **on-call** **runbook**).  
- **Facts first** — **timeline** with **UTC**, **tooling** **links** (logs, **dashboards**, **deploy** **events**), **customer** **impact** **quantified** where possible.  
- **Psychological safety** — the **goal** is **fix** the **system**, **not** **score** **points**.  
- **Action items** are **assigned**, **dated**, and **trackable** (ticket or **backlog**), **not** vague “**be** **more** **careful**.”

## Recommended document shape

1. **Summary** — **what** **happened**, **duration**, **impact** (users, **SLA**, **data**).  
2. **Timeline** — **detection** → **mitigation** → **recovery** → **post-fix** (UTC).  
3. **Root causes** — **contributing** **factors** (**plural**); **five** **whys** on **systems**, **not** **people**.  
4. **What went well** — **paging**, **rollback**, **comms**, **pairing**.  
5. **What went poorly** — **missing** **alerts**, **slow** **runbook**, **flaky** **deploy**, **unclear** **ownership**.  
6. **Action items** — **owner**, **due** **date**, **link** **to** **ticket**; **one** **item** **per** **system** **lever** **where** **possible**.

## When to stop and escalate

- **HR** / **conduct** concerns, **legal** hold, or **regulated** **breach** **notification** — **not** **only** a **postmortem** **doc**; **route** per **Legal** / **InfoSec** / **People** **process**.  
- **Customer** **communications** **sign-off** — use **official** **comms** **templates** and **exec** **review** when required.

## Related

- **Stakeholder-facing** **incident** **summary** or **exec** **update** (BLUF, **limitations**): **[`executive-reports`](../executive-reports/SKILL.md)**  
- **Runbook** and **how-to** **updates** after the incident: **[`docs-clear-writing`](../docs-clear-writing/SKILL.md)**  
- **Python** **tooling** **and** **logging** **gaps**: **[`python-scripts-and-services`](../python-scripts-and-services/SKILL.md)** (**logging**, **testing**, **security**)  
- **Next** **merge** **quality** **gate**: **[`major-change-readiness`](../major-change-readiness/SKILL.md)**  
- **Routing:** [`../../SKILLS.md`](../../SKILLS.md)

## Source

Authored for **ai-skills**. **Align** with your org’s **incident** **management** **process** (severity definitions, **mandatory** **sections**, **approval** **to** **publish**).
