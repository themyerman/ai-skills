---
name: threat-modeling
description: >-
  Full threat modeling process: data flow diagrams, trust boundaries, STRIDE
  methodology, attack trees, threat model document format, when to do it and
  how deep to go. Practical for developers, not just security specialists.
  Triggers: threat model, STRIDE, data flow diagram, DFD, trust boundary,
  attack tree, threat analysis, what could go wrong, security design review.
---

# threat-modeling

Threat modeling is structured thinking about what could go wrong. You don't need to be a security specialist — you need to know your system and be willing to think like someone who wants to break it.

The output is a documented list of threats and what you're doing about each one. The process of producing it is as valuable as the document.

---

## When to do it

- Before building a new service or significant feature
- When adding a new external integration or data store
- When changing authentication, authorization, or session handling
- When the data your system handles changes in sensitivity
- Annually for production services that haven't been reviewed recently

Brief threat model (30–60 min): any change that touches auth, data, or external surfaces.
Full threat model (half day): new service, new integration, significant architectural change.

---

## Step 1 — Draw the data flow diagram

A data flow diagram (DFD) shows how data moves through your system. You need:

- **External entities** — users, other systems, third parties (drawn as rectangles)
- **Processes** — things that transform data (circles or rounded rectangles)
- **Data stores** — where data rests (parallel horizontal lines)
- **Data flows** — arrows between the above
- **Trust boundaries** — dashed lines where control or trust changes

```
[Browser] --> [API Gateway] --> [Auth Service] --> [User DB]
                    |
                    v
              [Order Service] --> [Orders DB]
                    |
                    v
              [Payment API (external)]
```

You don't need formal DFD software. A whiteboard photo, a Mermaid diagram, or a quick ASCII sketch works. The act of drawing it is what matters — it forces you to enumerate every component and every place data crosses a boundary.

---

## Step 2 — Identify trust boundaries

A trust boundary is anywhere control or trust changes:

- Internet → your service (unauthenticated traffic becomes authenticated)
- Your service → a third-party API (you're trusting their security)
- One microservice → another (is the internal call authenticated?)
- User input → your database (untrusted strings become stored data)
- Your service → customer data (privileged access to sensitive information)

Mark every trust boundary on your diagram. Threats cluster at boundaries.

---

## Step 3 — Apply STRIDE

STRIDE is a checklist of threat categories. For each component and trust boundary in your diagram, work through each category:

| Letter | Category | Question to ask |
|--------|----------|----------------|
| **S** | Spoofing | Can an attacker pretend to be a legitimate user or service? |
| **T** | Tampering | Can data be modified in transit or at rest without detection? |
| **R** | Repudiation | Can someone deny having performed an action, and can you prove they did? |
| **I** | Information disclosure | Can data be read by someone who shouldn't have access? |
| **D** | Denial of service | Can the service be made unavailable? |
| **E** | Elevation of privilege | Can someone gain permissions they shouldn't have? |

For each threat you identify, capture:
- What is the threat (one sentence)
- Where in the system it applies (component or boundary)
- Current mitigation (what's already in place)
- Residual risk (High / Medium / Low after mitigations)
- Action (accept, mitigate further, or transfer)

---

## STRIDE applied — example

System: a REST API that accepts file uploads and stores them in S3.

| STRIDE | Threat | Where | Mitigation | Residual |
|--------|--------|-------|------------|---------|
| S | Attacker impersonates another user by forging a JWT | API → Auth boundary | JWT signature verification, short expiry | Low |
| T | Attacker modifies a file in S3 after upload | S3 data store | S3 versioning + object integrity check on read | Medium |
| R | User denies uploading a file that caused a policy violation | Upload handler | CloudTrail logs API calls with user identity | Low |
| I | Signed S3 URL shared beyond intended recipient | S3 → User | Short-lived signed URLs (15 min expiry) | Medium |
| D | Attacker uploads a 10GB file, exhausting storage | Upload handler | File size limit enforced before writing to S3 | Low |
| E | Uploader accesses another user's files via predictable S3 keys | S3 data store | Random UUID keys; access requires signed URL issued per-user | Low |

---

## Attack trees (for deeper analysis)

An attack tree starts with a goal an attacker wants to achieve and works backward through the ways they could achieve it.

```
Goal: Access another user's private documents

OR
├── Exploit BOLA in document API (guess/enumerate IDs)
│   AND
│   ├── Documents have sequential/guessable IDs
│   └── API doesn't check ownership
│
├── Steal a valid session token
│   OR
│   ├── XSS in the app → extract token from storage
│   ├── Network intercept (requires HTTP or weak TLS)
│   └── Social engineering (phishing)
│
└── Compromise the document storage directly
    AND
    ├── S3 bucket is public or has overly broad policy
    └── Attacker knows bucket name
```

Attack trees help you see whether mitigating one branch actually closes the threat or just forces attackers to use a different path.

---

## Threat model document format

Keep it in the repo alongside the service it covers.

```markdown
# Threat Model: [Service Name]

**Date:** YYYY-MM-DD
**Author:** [name]
**Status:** Draft / Review / Approved
**Next review:** YYYY-MM-DD

## Scope
[One paragraph: what this covers, what it doesn't]

## Architecture overview
[DFD or diagram link]

## Trust boundaries
- [List each boundary and what crosses it]

## Data in scope
| Data type | Sensitivity | Where stored | Who can access |
|-----------|------------|--------------|----------------|

## Threats

| ID | Category | Description | Component | Mitigation | Residual risk | Status |
|----|----------|-------------|-----------|------------|---------------|--------|
| T1 | Spoofing | ... | | | High | Open |
| T2 | Tampering | ... | | | Low | Mitigated |

## Open actions
- [ ] [Action] — [owner] — [due date]

## Out of scope
[Threats explicitly excluded and why]
```

---

## How deep to go

| Change type | Depth |
|-------------|-------|
| Bug fix, UI tweak | Skip |
| New field, small feature | 15-minute STRIDE check on the changed components |
| New endpoint, new data type | 1-hour focused threat model on the new surface |
| New service, new integration | Half-day full threat model with DFD |
| New product / major launch | Full threat model + external review |

The goal is proportionate effort, not exhaustive coverage of every theoretical threat. A threat model that takes a week produces diminishing returns compared to one that takes two hours and is actually done.

---

## Related

- Stub for a PR-level security review: [`security-review-advisor`](../security-review-advisor/SKILL.md)
- Full security review before a release: [`deploy-readiness`](../deploy-readiness/SKILL.md)
- Identity and authorization design: [`identity-authz`](../identity-authz/SKILL.md)
