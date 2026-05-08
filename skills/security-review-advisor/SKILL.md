---
name: security-review-advisor
description: >-
  Pre-PR and pre-release security advisor. Detects when a change warrants a
  formal security review, drafts a threat model stub with risks and mitigations
  already evident from the code, and produces a punchlist of fixes the developer
  can land before the review. Three tiers: small change (targeted observation
  only), PR-level scan (pattern detection + TM stub + punchlist), milestone/release
  (full TM prep). Triggers: security review needed, should I file a ticket,
  pre-PR security, threat model prep, what do I need to fix before review.
source: ai-skills original.
---

# Security Review Advisor

Runs **alongside the development workflow** — not as a replacement for your linter or CI, but at a higher altitude. Linters catch line-level issues. This skill looks at what the change *does as a whole* and answers three questions:

1. Does this change need a formal security review?
2. If yes, how do you prepare for it?
3. What can you fix right now, before anyone else looks at this?

**Assume your linter and CI are already running.** Do not re-report findings that `ruff`, `bandit`, `semgrep`, or your existing CI pipeline would catch. Focus on patterns and combinations that tooling misses.

**Related skills:**
- Pre-PR quality gates (build, types, lint, tests) → [`../pre-pr-checklist/SKILL.md`](../pre-pr-checklist/SKILL.md)
- PII / sensitive data handling → [`../data-handling-pii/SKILL.md`](../data-handling-pii/SKILL.md)
- Secrets hygiene → [`../secrets-management/SKILL.md`](../secrets-management/SKILL.md)

---

## Tier selection

Choose the tier based on the size and nature of the change.

| Situation | Tier |
|-----------|------|
| A few lines; no high-signal triggers present | Skip entirely |
| A few lines; one or more high-signal triggers hit | **Tier 1** — targeted observation |
| A PR-sized diff (tens to hundreds of lines); feature or behaviour change | **Tier 2** — PR scan |
| A significant feature, new service, new integration, or pre-release cut | **Tier 3** — milestone prep |

When in doubt between Tier 2 and Tier 3, prefer Tier 2 and note what would push it to Tier 3.

---

## High-signal triggers

These patterns in a diff — regardless of size — always warrant at least Tier 1:

**Authentication & authorisation**
- New or modified login, session, token, or OAuth flow
- Permission check added, removed, or restructured
- New role, scope, or privilege level introduced

**Data handling**
- New field or model containing `password`, `token`, `secret`, `ssn`, `dob`, `credit`, `card`, `health`, `salary`, or similar PII/sensitive terms
- New database table or column storing user-identifiable data
- Export, download, or bulk-read endpoint

**External surface**
- New HTTP endpoint (REST, GraphQL, webhook receiver)
- New outbound HTTP client call to an external or third-party service
- New file upload or multipart form handler
- New message queue consumer or producer touching external systems

**Infrastructure / config**
- New environment variable, secret reference, or credentials file
- New Dockerfile, compose file, or Kubernetes manifest
- Changes to CORS, CSP, or security headers
- Changes to IAM roles, service accounts, or network policy

**Cryptography**
- Any direct use of a crypto primitive (`AES`, `RSA`, `HMAC`, `MD5`, `SHA1`)
- Custom token generation or signing logic

---

## Tier 1 — Targeted observation (small change, trigger present)

Do not produce a full scan. Identify the one or two things most likely to cause a problem and state them plainly.

**Format:**

```
SECURITY NOTE
─────────────
Trigger: [what pattern was detected]
Observation: [one sentence — what could go wrong]
Suggested fix: [one sentence — what to do about it]
Needs formal review: [yes / no / maybe — with one-line reason]
```

If `Needs formal review: yes` or `maybe`, move to Tier 2 output before the developer opens a PR.

---

## Tier 2 — PR scan (the default tier)

Run this before a PR is opened on any meaningful feature or behaviour change.

### Step 1 — Read the diff

```bash
git diff main...HEAD --stat
git diff main...HEAD
```

If the diff is too large to read fully, focus on: new files, new routes/endpoints, auth-related files, model/schema changes, config changes.

### Step 2 — Pattern detection

Look for *combinations*, not just individual lines. Examples of combinations that matter:

- New endpoint + no auth check on the route = likely missing authorisation
- PII field added to model + no mention of encryption or masking = unprotected sensitive data
- New outbound HTTP call + user-controlled input in the URL or body = SSRF risk
- File upload handler + no file type or size validation = unrestricted upload
- New JWT or token generation + custom signing logic = crypto misuse risk
- New admin or privileged action + no audit log = unlogged privileged operation

### Step 3 — Needs-review determination

**A formal security review is warranted if any of the following are true:**

- A new external-facing endpoint is introduced
- Authentication, authorisation, or session logic is added or materially changed
- PII or sensitive data is newly stored, transmitted, or processed
- A new third-party integration or outbound service call is added
- Cryptographic operations are introduced or changed
- The change introduces a new service, component, or deployment unit

If none of these apply, state "No formal review required for this change" and stop at the punchlist.

### Step 4 — Threat model stub

Only produce this section if a formal review is warranted.

Draft from what is *observable in the code* — do not speculate. Map each risk to a STRIDE category.

```
THREAT MODEL STUB
─────────────────
Component: [name of the feature/service/endpoint being changed]
Change summary: [one sentence]

Risks identified:
  [STRIDE category] [Risk title]
    What: [one sentence describing the threat]
    Where: [file:line or component name]
    Current mitigation: [what is already in the code, or "none observed"]
    Residual risk: [High / Medium / Low]

  [repeat for each risk]

Data in scope:
  [list data types touched — user IDs, emails, tokens, etc.]

Trust boundaries crossed:
  [list — e.g. "unauthenticated internet → API", "API → database"]
```

### Step 5 — Punchlist

Low-hanging fruit the developer can fix *before* the review. Findings here should be:
- Observable directly in the code (not speculative)
- Fixable by the developer without outside involvement
- Not already caught by the existing linter / CI

```
PRE-REVIEW PUNCHLIST
────────────────────
Fix before the review:

  [ ] [Short title] — [file:line] — [one sentence: what to do]
  [ ] ...

Consider before the review (lower priority):

  [ ] [Short title] — [one sentence]
  [ ] ...
```

---

## Tier 3 — Milestone / pre-release prep

Use this when a significant feature is complete, a new service is being introduced, or a release branch is about to be cut.

### Step 1 — Run Tier 2 in full

Complete all five Tier 2 steps first.

### Step 2 — Escalate the threat model

Expand the Tier 2 stub into a full OWASP / STRIDE / CVSS pass. For each risk:
- Assign a CVSS base score (use the CVSS 3.1 calculator mentally or cite a reference score)
- Identify a concrete mitigation and an owner
- Note whether the risk is accepted, mitigated, or transferred

Produce a final threat model document or hand it to your team's security review process.

---

## Full output template (Tier 2 / Tier 3)

```
SECURITY REVIEW ADVISOR
═══════════════════════
Tier: [2 / 3]
Change: [branch or PR name]
Date: [YYYY-MM-DD]

NEEDS FORMAL REVIEW: [YES / NO]
Reason: [one sentence]

─── THREAT MODEL STUB ──────────────────────────────── (if review needed)
[stub content]

─── PRE-REVIEW PUNCHLIST ───────────────────────────────────────────────
[punchlist content]
```

---

## What this skill does not do

- Does not replace `pre-pr-checklist` quality gates (run those first)
- Does not replace a formal security review
- Does not re-report linter or CI findings
- Does not speculate about vulnerabilities without observable evidence in the code
- Does not provide legal or compliance sign-off
