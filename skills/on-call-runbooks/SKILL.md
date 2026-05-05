---
name: on-call-runbooks
description: >-
  Writing and maintaining operational runbooks — the documents you open at 2am when something
  breaks. Covers what makes a runbook useful vs useless, runbook vs incident-response, required
  sections, exact-command discipline, a complete example runbook for a Python internal tool
  failure, common failure modes in bad runbooks, keeping runbooks current after incidents,
  and a paste-ready template. Triggers: runbook, on-call, operational runbook, incident
  runbook, how to fix, restart service, alert runbook, on-call guide, operational guide,
  2am, escalation, mitigation steps, exact commands, runbook template.
---

# on-call-runbooks

## What this is

This skill covers **writing and maintaining operational runbooks** — the specific how-to
documents you open at 2am when a known failure mode fires. It is not the incident response
lifecycle, which is covered by [`incident-response`](../incident-response/SKILL.md).

**The boundary:**
- **`incident-response`:** What to do during an incident in general — severity triage,
  IC assignment, war room, communication cadence, hotfix process.
- **This skill (runbooks):** How to fix a **specific known failure** — exact commands, expected
  output, verification steps, escalation path for that one alert.

Incident response tells you **what** to do. A runbook tells you **how** to fix **a specific thing**.

---

## What makes a runbook actually useful

**A runbook is useful if:** someone who did not write the system can follow it under stress.

**A runbook fails when:**
- It assumes context the reader does not have ("just restart the worker")
- It uses jargon without explaining what it means
- It skips steps that were "obvious" to the author
- It is out of date and no longer matches the running system
- It describes what *could* cause the problem but not what to *do about* each cause

**The 2am test:** Would a tired on-call engineer who has not touched this system in 6 months
be able to follow this runbook from first alert to confirmed resolution, without asking anyone
for help?

If the answer is no, the runbook is not done.

---

## Runbook vs incident-response

| | Runbook | Incident response |
|---|---|---|
| **Scope** | One specific alert / failure mode | Any incident, any service |
| **Input** | An alert fires with a known name | Something is wrong |
| **Output** | System restored; alert resolved | Incident declared resolved |
| **Who uses it** | The on-call engineer | IC + all responders |
| **When to use** | First thing after alert fires | Running alongside the runbook |
| **Skill** | This one | [`incident-response`](../incident-response/SKILL.md) |

For a Sev1 where the runbook does not resolve the issue, switch to
[`incident-response`](../incident-response/SKILL.md) and escalate.

---

## Runbook structure

Every runbook should have these sections, in this order:

**1. Alert name**
The exact name as it appears in your alerting system (PagerDuty, Datadog, CloudWatch,
Prometheus, etc.). Copy it verbatim. Engineers search for this string when paged.

**2. Severity**
Sev1, Sev2, or Sev3 — and one sentence on why. "Sev2 because this affects all scheduled
Jira triage runs but does not impact any user-facing system."

**3. Symptoms**
What the user or system experiences — not what the metric shows. "Jira tickets are not being
labeled. Scheduled triage runs produce no output and no error emails." NOT "the
`triage_runs_completed` counter is zero."

**4. Likely causes**
Ordered by probability, based on past incidents. The most common cause goes first. Include
how to identify each one. If you know frequencies ("this cause accounts for ~70% of firings"),
say so.

**5. Immediate mitigation**
Steps to stop the bleeding, in order. Numbered. Each step has the exact command and the
expected output. The goal is to reduce user impact before root cause is found.

**6. Verification**
How to confirm the fix worked. The exact check, the expected result, and how long to wait
before declaring it resolved. "Run X; if you see Y, the issue is resolved."

**7. Escalation**
Who to page if this runbook does not resolve it, and when. Name the role, not just the
person. "If not resolved after 30 minutes, page the Jira integration team lead via
PagerDuty schedule `jira-integration-oncall`."

**8. Root cause investigation**
Where to look after the fire is out. Logs, dashboards, queries. This section is for the
postmortem, not the 2am mitigation.

**9. Last updated**
Date and who updated it. Include a `last_verified` date (the last time someone actually
ran through the steps and confirmed they work). A runbook not verified in 6+ months should
carry a warning.

---

## Writing good steps

Each step: **one action, one check**. If a step has "and" in it, split it into two steps.

**Bad step:**
```
3. Restart the triage worker and verify it picks up new jobs.
```

**Good step:**
```
3. Restart the triage worker process:

   sudo systemctl restart jira-triage-worker

   Expected output:
   (no output on success; the command exits 0)

4. Confirm the worker is running:

   sudo systemctl status jira-triage-worker

   Expected output:
   ● jira-triage-worker.service - Jira Triage Worker
      Active: active (running) since ...
   
   If the status shows "failed" instead of "running", go to step 8 (escalation).
```

The reader should never have to guess whether a step worked. Show the expected output.
If the output differs, say where to go next.

---

## Exact commands matter

The difference between a useful runbook and a useless one is often whether the commands
are copy-paste-ready.

Do not write:
- "Check the logs" — say `tail -f /var/log/app/app.log | grep ERROR`
- "Look at the database" — say the exact SQL query
- "Restart the service" — say `sudo systemctl restart jira-triage-worker` (or `docker restart
  jira-triage`, or `kubectl rollout restart deployment/jira-triage -n prod`)
- "SSH to the server" — include the exact SSH command, bastion if needed

**Show realistic values, not placeholders.** A command with `<your-value>` forces the reader
to figure out what that value is under pressure. Use the real value or, if it varies, show a
concrete example and explain how to find the real one.

```bash
# Show this:
ssh -J bastion.internal.example.com ec2-user@10.0.1.45

# Not this:
ssh -J <bastion-host> <user>@<server-ip>
```

If the IP changes per environment, explain how to find it:

```bash
# Get the current worker host IP:
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=jira-triage-worker" \
  --query 'Reservations[*].Instances[*].PrivateIpAddress' \
  --output text
```

---

## Complete example runbook: Jira triage tool run failed

```markdown
# Runbook: Jira Triage Tool — No Output in 30 Minutes

**Alert name:** `jira_triage_no_completed_runs_30m`
**Severity:** Sev2 — scheduled triage runs are stalled; no user-facing system is affected,
but security tickets are not being labeled and may age past SLA.
**Last updated:** YYYY-MM-DD by name@example.com
**Last verified:** 2026-05-04

---

## Symptoms

- No new Jira labels applied to open security tickets in the last 30+ minutes.
- `jira_triage_runs_completed` counter has not incremented in the monitoring dashboard.
- No recent entries in `/var/log/jira-triage/triage.log` (last entry is older than 30 min).
- No email summary from the scheduled run.

---

## Likely causes (in order of frequency)

1. **Process not running** (~60% of firings) — the cron job or systemd service died silently.
2. **Jira API credential expired** (~20%) — the PAT was rotated or expired; all Jira calls
   return 401.
3. **Database locked or corrupted** (~10%) — SQLite lock held by a crashed process.
4. **Jira API rate limited or down** (~5%) — all requests returning 429 or 5xx.
5. **Disk full on the worker host** (~5%) — logs and DB writes failing silently.

---

## Immediate mitigation

### Step 1: Check whether the process is running

SSH to the triage worker host:

```bash
ssh -J bastion.internal.example.com ec2-user@10.0.1.45
```

Check the process:

```bash
sudo systemctl status jira-triage-worker
```

**If active (running):** The process is alive but not completing runs. Go to Step 3.

**If failed or inactive:** The process has stopped. Continue to Step 2.

---

### Step 2: Restart the triage worker

```bash
sudo systemctl restart jira-triage-worker
```

Wait 60 seconds, then confirm it is running:

```bash
sudo systemctl status jira-triage-worker
```

Expected output:
```
● jira-triage-worker.service - Jira Triage Worker
   Active: active (running) since 2026-05-04 02:14:32 UTC; 1min 3s ago
```

If still failed, check the journal for the exit reason:

```bash
sudo journalctl -u jira-triage-worker -n 50 --no-pager
```

Look for the last error before the crash. Common patterns:
- `Error: config.yaml: jira.token is required` → credential issue, go to Step 4.
- `database is locked` → DB lock issue, go to Step 5.
- `No space left on device` → disk full, go to Step 6.

---

### Step 3: Check the application log for errors

```bash
tail -n 100 /var/log/jira-triage/triage.log | grep -E 'ERROR|WARNING|Exception'
```

Common findings:
- `HTTP 401` on Jira calls → credential expired, go to Step 4.
- `HTTP 429` on Jira calls → rate limited; wait 5 minutes and re-check.
- `OperationalError: database is locked` → go to Step 5.
- No errors but also no recent activity → check cron schedule in Step 3b.

**Step 3b: Verify the cron schedule is still configured:**

```bash
crontab -l -u jira-triage
```

Expected output includes a line like:
```
*/15 * * * * /opt/jira-triage/.venv/bin/python /opt/jira-triage/main.py --bulk >> /var/log/jira-triage/triage.log 2>&1
```

If the crontab is empty or missing this line, the scheduled run was accidentally removed.
Re-add from the runbook source in `docs/runbooks/crontab.txt` in the repo, then continue
to Verification.

---

### Step 4: Check Jira credential validity

Run the credential test directly:

```bash
cd /opt/jira-triage
source .venv/bin/activate
python -c "
import yaml, requests
cfg = yaml.safe_load(open('config.yaml'))
r = requests.get(
    cfg['jira']['base_url'] + '/rest/api/2/myself',
    headers={'Authorization': 'Bearer ' + cfg['jira']['token']},
    timeout=10
)
print(r.status_code, r.text[:200])
"
```

**If `200`:** Credentials are valid. The problem is elsewhere — go back to Step 3.

**If `401`:** The PAT has expired or was revoked. Do not generate a new PAT yourself —
the PAT must be created under the service account `svc-jira-triage@example.com`.
Page the Jira integration team lead to rotate the credential:
PagerDuty schedule `jira-integration-oncall`.

---

### Step 5: Check for a stale SQLite lock

A crashed process may leave a lock file:

```bash
ls -la /opt/jira-triage/data/triage.db-shm /opt/jira-triage/data/triage.db-wal 2>/dev/null
```

If these files exist and are non-empty while the process is not running, they are leftover
from a crash. Check that no process holds the DB open:

```bash
lsof /opt/jira-triage/data/triage.db
```

If `lsof` returns no output (no process has the file open), the lock files are stale. Remove them:

```bash
rm -f /opt/jira-triage/data/triage.db-shm /opt/jira-triage/data/triage.db-wal
```

Then restart the worker (Step 2) and continue to Verification.

If `lsof` shows a process holding the file, note the PID and check what it is before killing it.

---

### Step 6: Check disk space

```bash
df -h /opt/jira-triage /var/log/jira-triage
```

If either filesystem is above 90% used:

```bash
# Find the largest files under the triage directory:
du -sh /opt/jira-triage/* | sort -rh | head -20
du -sh /var/log/jira-triage/* | sort -rh | head -10
```

Common culprits:
- `/var/log/jira-triage/triage.log` grown very large → rotate it: `sudo logrotate -f /etc/logrotate.d/jira-triage`
- `/opt/jira-triage/logs/` contains LLM debug logs that were not rotated → delete logs older than 30 days:

```bash
find /opt/jira-triage/logs/ -name "ask_llm_*.log" -mtime +30 -delete
```

After freeing space, restart the worker (Step 2) and continue to Verification.

---

## Verification

After applying a fix, confirm the tool is running successfully:

```bash
# Watch the log for a completed run (may take up to 15 minutes for the next cron firing):
tail -f /var/log/jira-triage/triage.log

# A successful run looks like:
# 2026-05-04 02:15:01 INFO  Starting bulk triage run
# 2026-05-04 02:15:04 INFO  Fetched 8 open tickets
# 2026-05-04 02:15:22 INFO  Triage complete: 8 issues processed, 6 labeled
```

Check the monitoring dashboard — the `jira_triage_runs_completed` counter should increment
within 15 minutes of the cron schedule.

The alert should auto-resolve once two consecutive successful runs are recorded.

---

## Escalation

**If not resolved within 30 minutes of starting this runbook:**
Page the Jira integration team lead via PagerDuty schedule `jira-integration-oncall`.

Include in your page:
- Which steps you completed
- Output of the most recent log check
- Current status of the process (`systemctl status jira-triage-worker`)

**If this is a credential problem (Step 4 returned 401):**
Do not wait 30 minutes — page immediately, as you cannot rotate the service account PAT
yourself.

---

## Root cause investigation (after fire is out)

1. Check the full log around the time the runs stopped: `grep -A5 -B5 'ERROR' /var/log/jira-triage/triage.log`
2. Check deploy history — was anything pushed in the 2 hours before the alert fired?
3. Check Jira API status page for any reported incidents.
4. Review the DB for any anomalous state: `sqlite3 /opt/jira-triage/data/triage.db "SELECT * FROM runs ORDER BY id DESC LIMIT 10;"`
5. File a postmortem if the outage lasted more than 60 minutes or if tickets missed SLA as a result.
   See [`blameless-postmortems`](../blameless-postmortems/SKILL.md).
```

---

## Common runbook failure modes

These patterns make runbooks useless under pressure. Watch for them in review.

**"Check the dashboard"**
Which dashboard? Which panel? Which time range? A link and a description of what you are
looking for ("check the `Jira Triage Overview` dashboard, top-left `Runs Completed` panel;
it should show at least one bar in the last 15 minutes") is usable. "Check the dashboard"
is not.

**"Restart the service"**
How? `systemctl restart X`? `docker restart X`? `kubectl rollout restart deployment/X -n prod`?
The service name matters. The correct command matters. "Restart the service" is not a step.

**Assumes SSH access is already set up**
Include the full SSH command, including bastion host if required. Do not assume the engineer
has the right SSH key configured or knows the hostname.

**References a Slack channel that no longer exists**
"Ask in #jira-infra-oncall" is broken if that channel was renamed or archived. Keep escalation
paths as PagerDuty schedule names, not Slack channel names — schedule names are stable.

**Steps that only work on the author's laptop**
Commands that rely on a locally configured alias, a local `.env` file, or a local tool
version that differs from the server will fail for everyone else. Test commands on the actual
server, not your development machine.

**Causes listed without remediation**
"This could be caused by a Jira API outage" is not actionable. Pair every cause with the
exact step to identify it and the step to mitigate it.

---

## Keeping runbooks current

Stale runbooks are dangerous. An engineer who follows a runbook with confidence, only to find
the commands no longer work or the service was renamed, has lost critical time and trust.

**After every incident:**
- Update the runbook with what actually worked (not just what the theory said would work).
- Add any new cause you discovered that is not in the "likely causes" list.
- Update the `last_updated` and `last_verified` dates.
- Add a runbook update as a required action item in the postmortem when the incident revealed
  a gap in the runbook.

**Add runbook review to your postmortem template.** The standard question: "Did the runbook
help? What was missing? What was wrong?" captures drift systematically.

**Set a review cadence.** If a runbook has not been verified in 6 months, add a warning
at the top:

```markdown
> **WARNING: This runbook has not been verified since 2025-11-01. Steps may be outdated.
> Verify each command before relying on it. Update this notice when you verify.**
```

A runbook with an honest staleness warning is safer than one that silently lies.

**Do not delete runbooks for retired alerts.** Archive them with a note: "Alert removed
2026-03-15 when service was decomissioned. Kept for reference." Deleted runbooks cause
confusion when the alert is re-added or when a similar problem appears in a successor service.

---

## Runbook discovery

An engineer cannot use a runbook they cannot find in under 60 seconds during an incident.

**Best option: link from the alert description.** Every alert in your alerting system
(PagerDuty, Datadog, CloudWatch) should include a direct URL to the runbook in the alert
description or annotation. The engineer clicks the link in the page and is reading the
runbook within 10 seconds.

**Second option: `docs/runbooks/` in the repo**, named after the alert:

```
docs/runbooks/
  jira_triage_no_completed_runs_30m.md
  db_connection_pool_exhausted.md
  auth_service_5xx_rate_high.md
```

The filename matches the alert name exactly. Engineers can find it without knowing the repo
structure.

**Third option: a Confluence space** with a consistent naming convention and a single index
page. This works if the space is kept current and the URL is stable. Link to the index page
from alert descriptions.

**Anti-pattern: runbooks buried inside a general wiki**, reachable only by navigating
through unrelated pages. Engineers will not find them in time. They will not update them
either, because they cannot find them when the incident is over.

---

## Minimal runbook template

Copy this into `docs/runbooks/<alert-name>.md` and fill it in. Resist the urge to leave
sections blank — a blank section during an incident means wasted time.

```markdown
# Runbook: [Alert Name — copy exactly from alerting system]

**Alert name:** `exact_alert_name_here`
**Severity:** Sev[1/2/3] — [one sentence on why this severity]
**Last updated:** YYYY-MM-DD by name@example.com
**Last verified:** YYYY-MM-DD

---

## Symptoms

What the user or system experiences when this alert fires. Not the metric value — the
observable behavior. Use bullet points.

- [User-visible symptom]
- [System-visible symptom, e.g. log output, missing data]

---

## Likely causes (in order of frequency)

1. **[Most common cause]** (~X% of firings) — [how to identify it]
2. **[Second cause]** (~Y% of firings) — [how to identify it]
3. **[Third cause]** — [how to identify it]

---

## Immediate mitigation

### Step 1: [First action]

[Command or action]

```bash
exact command here
```

Expected output:
```
what you should see if this worked
```

If you see something different: [what to do instead].

### Step 2: [Second action]

...

---

## Verification

[Exact check to confirm the fix worked. Include the command and expected output.]

```bash
command to verify
```

Expected: [what success looks like]. Wait [X minutes] before declaring resolved.

The alert should auto-resolve when [condition].

---

## Escalation

If not resolved within [X minutes] of starting this runbook:
- Page [role, not person] via [PagerDuty schedule name].
- Include: [what information to include in the page].

---

## Root cause investigation (after fire is out)

- [Where to look in logs]
- [Dashboard or query for historical context]
- [Any DB queries useful for diagnosis]
- Link to postmortem process: [`blameless-postmortems`](../blameless-postmortems/SKILL.md)
```

---

## Related

- **Active incident lifecycle** (triage, IC, war room, comms): [`incident-response`](../incident-response/SKILL.md)
- **After the incident** (RCA, action items, learning): [`blameless-postmortems`](../blameless-postmortems/SKILL.md)
- **Metrics, alerting, SLOs, log fields**: [`observability`](../observability/SKILL.md)
- **Runbook prose quality** (plain English, clarity): [`docs-clear-writing`](../docs-clear-writing/SKILL.md)
- **Routing:** [`../../SKILLS.md`](../../SKILLS.md)

## Source

Authored for **ai-skills**. Adapt alert names, service names, escalation schedules, and
paths to match your team's actual infrastructure. The patterns (exact commands, expected
output, ordered causes, verification step) are portable.
