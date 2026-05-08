---
name: incident-response
description: >-
  Incident response during an active outage or security event: severity triage (sev1/sev2/sev3),
  incident commander assignment, war room setup, escalation, mitigation (rollback, feature flag,
  revoke credential), hotfix process, paste-ready Slack templates for declaration/update/resolution/
  executive summary. Covers the DURING phase — from first alert to resolution declared. For the
  AFTER phase (RCA, learning, action items), use blameless-postmortems. Triggers: incident, outage,
  sev1, sev2, sev3, production down, war room, on-call, triage, escalation, hotfix, incident
  commander, mitigation, rollback, page, pager.
---

# incident-response

## What this is

This skill covers the **DURING** phase of an incident — from the moment something looks wrong
to the moment you declare resolution. It is not a postmortem template.

**Boundary:**
- **This skill:** Detect → Triage → Communicate → Mitigate → Resolve
- **`blameless-postmortems`:** RCA, timeline write-up, action items, learning review — starts
  after resolution is declared

Do not conflate the two. During an active incident, your job is to stop the bleeding and
communicate clearly. Root cause analysis comes later, with a calm mind and complete data.

**Related skills:**
- `blameless-postmortems` — the after (RCA, action items)
- `docs-clear-writing` — communication tone and runbook format
- `executive-reports` — stakeholder / leadership summaries
- `python-scripts-and-services` — hotfix code review, deploy checklist

---

## Severity levels

Pick the highest severity that applies. When in doubt, go higher — it's easier to downgrade
than to explain why you under-responded.

| Severity | Definition | Response SLA | Update cadence |
|----------|-----------|-------------|----------------|
| **Sev1** | Production down for all or most users; data loss risk; active security breach; revenue impact | IC assigned within **5 min**; first comms within **10 min** | Every **30 min** until resolved |
| **Sev2** | Significant degradation; meaningful subset of users affected; workaround is painful or unavailable | IC assigned within **15 min**; first comms within **20 min** | Every **1 hr** until resolved |
| **Sev3** | Minor issue; most users unaffected; workaround exists and is easy to apply | No IC required; tracked in Jira; engineer handles async | Daily update until resolved |

**Sev1 examples:** API returning 5xx for all requests; authentication service down; database
unreachable; credentials confirmed leaked in a public repo; customer data exposed.

**Sev2 examples:** Elevated error rate (>5%) on a critical path; one region degraded; a feature
broken for a defined user segment; slow responses causing timeout cascades.

**Sev3 examples:** Cosmetic UI bug; non-critical job failing; one customer reporting an issue
not reproducible broadly; documentation link broken.

---

## The five phases

```
Detect → Triage → Communicate → Mitigate → Resolve
```

Each phase has a clear exit criterion before you move to the next. Do not skip phases under
pressure — skipping Triage leads to wrong mitigations; skipping Communicate leaves stakeholders
blind.

---

## Phase 1: Detect

**Sources:** monitoring alerts (PagerDuty, Datadog, CloudWatch), user reports (Slack, support
tickets), anomaly detection output, CI/CD pipeline failures, on-call rotation page.

**First thing: confirm it is real.**

A false alarm costs 10 minutes. Declaring an incident on a false alarm costs 10 minutes plus
credibility. Spend 2–3 minutes to verify before declaring.

Verification checklist:
- [ ] Check the primary dashboard — is the metric still firing, or did it resolve?
- [ ] Check logs for the relevant service in the last 10 minutes
- [ ] Check recent deploys — anything pushed in the last 2 hours?
- [ ] Ask one other engineer to confirm independently before declaring Sev1

If you cannot confirm it is a false alarm within 3 minutes, treat it as real and declare.

**Declare by opening the war room channel** (see Phase 3). The act of declaration starts the
clock on all SLAs above.

---

## Phase 2: Triage

**Goal:** Assign severity, assign IC, establish what is broken and how fast it is getting worse.

**For Sev1 and Sev2, assign an Incident Commander immediately.** The IC is one person. They
own communication and coordination. They do not fix the problem themselves — they direct others
and keep the timeline. If you are the only person awake, you are the IC until you can hand off.

**Triage questions (answer these fast, in order):**

1. What is broken? (service, feature, data, auth)
2. Who is affected? (all users, a region, a tenant, a percentage)
3. Is it getting worse, stable, or improving?
4. What changed recently? (deploy, config change, dependency update, traffic spike)
5. Is there a security dimension? (data exposure, credential leak, unauthorized access)

If the answer to question 5 is yes or maybe, immediately loop in the security on-call contact
in addition to engineering. Do not wait until you have confirmed it.

**IC responsibilities:**
- Owns the Slack war room channel
- Posts all status updates on cadence
- Assigns investigation owners ("Alice, own logs; Bob, own DB")
- Calls escalations (page additional engineers, notify leadership)
- Declares resolution
- Hands off to postmortem owner within 48 hours

**Non-IC responsibilities:**
- Investigate assigned area
- Report findings to IC in the channel, not in DMs
- Propose mitigations; IC approves before execution
- Log every action taken with a timestamp

---

## Phase 3: Communicate

**Open the war room channel within 5 minutes of declaring a Sev1, 15 minutes for Sev2.**

Channel naming convention:

```
#incident-YYYY-MM-DD-short-description
```

Examples:
```
#incident-2026-05-04-auth-service-down
#incident-2026-05-04-db-connection-pool-exhausted
#incident-2026-05-04-credential-leak-gh-token
```

Pin the initial message. All updates go in this channel. No parallel DM investigations —
if you found something, post it in the channel so the IC and the full team can see it.

**Who to loop in:**
- Engineering: team owning the affected service + on-call rotation
- Security: if there is any security dimension, or if you are unsure
- Leadership: IC decides when to escalate to VP/director based on scope and duration

Keep the channel focused on investigation and decisions. Move off-topic conversation to a thread.

---

## Phase 4: Mitigate

**Goal: stop the bleeding before finding root cause.**

Mitigation is not the same as a fix. A mitigation reduces harm right now. The actual fix may
come later. Common mitigations:

| Situation | Mitigation option |
|-----------|-------------------|
| Bad deploy causing errors | Roll back the deploy |
| Feature causing cascading failures | Disable the feature flag |
| Runaway job consuming all DB connections | Kill the job; set connection limit |
| Leaked credential | Revoke immediately; rotate; audit access logs |
| Traffic spike | Redirect to static page; scale up; rate limit |
| Broken dependency | Pin to last known good version; bypass the dependency |
| Data corruption in progress | Stop writes; take snapshot; assess scope |

**Document every action taken with a timestamp.** Use this format in the channel:

```
[14:32 UTC] @alice: Rolled back deploy abc1234 to abc1233. Monitoring error rate.
[14:35 UTC] @alice: Error rate dropping. Was 47%, now 12%, still falling.
[14:38 UTC] @alice: Error rate at 1.2%, within normal range. Holding for 5 min to confirm.
```

Do not take mitigation actions without posting them to the channel first. The IC needs to
know what is happening before you do it, not after.

If a mitigation makes things worse, roll it back immediately and report to IC. This is not
a failure — catching it fast is the right outcome.

---

## Phase 5: Resolve

**Resolution criteria:**
- The symptom that triggered the incident is no longer present
- Metrics are within normal range and holding (not just a momentary dip)
- No new anomalies are appearing
- Affected users can confirm functionality is restored (for Sev1/2)

**Resolution is not:**
- Root cause identified (that is for the postmortem)
- Fix deployed (mitigation is sufficient to declare resolution)
- A guarantee it will not happen again

**Declare resolution in the channel** with the resolution message template (see below).

After declaring:
1. Update any status page entries
2. Notify stakeholders via the resolution template
3. Schedule the postmortem within 48 hours — capture the timeline while it is fresh
4. Hand off to the postmortem owner with a link to the incident channel

---

## Hotfix process

Sev1 incidents sometimes require a code change rather than a pure rollback or config toggle.

**Do not skip peer review.** Even under pressure, two sets of eyes on a production hotfix
reduces the risk of making the incident worse. The normal review cycle is expedited, not removed.

**Expedited hotfix process:**

1. IC confirms a code change is needed and approved
2. Author creates a branch and writes the minimal fix — no refactoring, no unrelated changes
3. Author opens a PR tagged `[HOTFIX]` in the title
4. IC nominates one reviewer (most senior available engineer, or the person who knows the code)
5. 15-minute review target — reviewer focuses on: does this fix the specific issue, does it
   introduce new risk, is it reversible
6. If reviewer approves, IC authorizes deploy immediately
7. Post in the channel: reason for expedited review, who reviewed, PR link, deploy time

**Document in the PR why the normal review process was expedited.** Example PR description:

```
HOTFIX: Sev1 incident #incident-2026-05-04-auth-service-down

Problem: Auth token validation rejecting all requests due to null check on missing field.
Fix: Add null guard before validation; return 401 on missing token rather than 500.

Normal review expedited because: production auth down, all users affected.
Reviewed by: @bob (15-min expedited review, 2026-05-04 14:42 UTC)
IC approval: @carol
```

---

## Communication templates

Copy, fill in the brackets, and post. Do not draft from scratch during an incident.

### Initial declaration (post within 5–10 min of detecting Sev1)

```
:rotating_light: *INCIDENT DECLARED — [SEV1/SEV2]*

*What:* We are investigating [brief symptom description, e.g. "elevated 5xx errors on the auth service"].
*Who's affected:* [scope, e.g. "all users / users in US-EAST / ~15% of requests"]
*Started:* [time UTC, e.g. "14:18 UTC"]
*IC:* @[name]
*Next update:* [time, e.g. "14:48 UTC (30 min)"]

Investigation is underway. Updates in this channel on cadence.
```

### Status update (every 30 min for Sev1, 1 hr for Sev2)

```
:wave: *UPDATE — [time UTC]*

*Status:* Still investigating / Mitigation in progress / Monitoring after mitigation
*Current situation:* [what you know now, what changed since last update]
*What's being worked on:* [current focus, who owns it]
*Next update:* [time UTC]
```

### Resolution announcement

```
:white_check_mark: *RESOLVED — [time UTC]*

*Incident:* [channel name or short description]
*Duration:* [start time] → [end time] ([X hours Y min])
*What happened:* [1–2 sentences on the symptom — not root cause]
*How resolved:* [mitigation or fix applied]
*Current state:* [metrics normal / service fully operational]

Root cause analysis will follow via the postmortem process within 48 hours.
Thank you to everyone who responded: [list names].
```

### Stakeholder / executive summary (for Sev1, send after resolution)

```
*Incident Summary — [date]*

*Service affected:* [name]
*Impact:* [plain English: what users could not do, for how long]
*Duration:* [X hours Y minutes], [start time UTC] to [end time UTC]
*Customers affected:* [estimate or scope if known]

*What happened (brief):* [2–3 sentences, no jargon. What broke, what made it worse, what fixed it.]

*Immediate actions taken:* [bullet list of mitigations]

*Next steps:* Blameless postmortem scheduled for [date/time]. Action items and preventive
measures will be communicated after that review.

Questions: contact [IC name] or [team Slack channel].
```

---

## After the incident

Immediately after declaring resolution:

1. **Archive the timeline** — export or copy the incident channel history before people forget
   or the context is lost. The postmortem owner needs the full sequence of events.

2. **Schedule the postmortem within 48 hours** — while memory is fresh. For Sev1, this is not
   optional. For Sev2, strongly recommended. For Sev3, a brief Jira comment summary is usually
   sufficient.

3. **Open a Jira ticket** for the incident (if one does not already exist) and link the channel,
   the postmortem doc, and any hotfix PRs.

4. **Hand off to `blameless-postmortems`** — that skill covers the RCA facilitation, 5-whys,
   action items, and learning distribution. The incident channel and this skill's outputs are
   your inputs to that process.

Do not let the postmortem slip. The incident is over; the learning is not.

---

## Related

- **Runbooks to consult during an incident:** [`on-call-runbooks`](../on-call-runbooks/SKILL.md)
- **After the incident — RCA, action items, learning:** [`blameless-postmortems`](../blameless-postmortems/SKILL.md)
- **Observability: metrics, alerts, SLOs that fired:** [`observability`](../observability/SKILL.md)
- **Git hotfix workflow:** [`git-workflow`](../git-workflow/SKILL.md)
- **Routing:** [`../../SKILLS.md`](../../SKILLS.md)
