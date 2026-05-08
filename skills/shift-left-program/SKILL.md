---
name: shift-left-program
description: |
  High-level ideas for building an internal shift-left / secure-development program:
  threat modeling, security champions, dev-friendly guardrails, training, and
  when to hand off to a central security team. Use for org process questions,
  not for company-specific policy text.
---

# Shift-left and your security program (thin)

This is **not** a replacement for your organization’s official security, compliance, or GRC process. It lists **considerations** if you want to **move security earlier** in the lifecycle and make it **sustainable** for engineering.

## Why shift-left

- **Defects cost more** the later you find them; security is the same.
- **Developers** ship code daily; **central review** does not scale as the only gate.
- A good program **trains and equips** teams, then **measures** outcomes (findings, MTTR, repeat issues).

## Building blocks to consider

| Area | What to think about |
|------|----------------------|
| **Clarity of ownership** | Who owns the service boundary, data classification, and incident comms? Document it next to the repo. |
| **Threat modeling (lightweight)** | For non-trivial changes, ask: assets, trust boundaries, attacker goals, and failure modes. Reuse a short template; deep dives only when risk warrants. |
| **Security champions / liaisons** | A named contact per team who can route questions, not do all review alone. |
| **Standards as defaults** | Approved crypto, auth, logging, and config patterns; **convention over configuration** beats one-off “best effort.” |
| **Automation** | SAST, dependency and secret scanning, pre-commit or CI; tune noise so people trust the signal. |
| **Safe logging and PII** | Classify data; default to minimal logs in production; align with your privacy and retention policy. (See `data-handling-pii` and `secrets-management` in this bundle.) |
| **Training that sticks** | Short, recurring sessions (e.g. OWASP Top 10, SSRF, supply chain) plus **this codebase** examples. |
| **Handoff** | When design is security-sensitive, new external integration, or regulatory scope, **escalate early** to your org’s **official** security or architecture review process—this skill does not define that process. |
| **Metrics (carefully)** | Track trends (classes of bug, time to remediate) without turning metrics into per-developer scorecards. |

## Relationship to the rest of this pack

- **Code-level habits:** `python-scripts-and-services` (security & API sections), `llm-integrations-safety` for in-app LLM use, `web-accessibility` for UIs.
- **Secrets and sensitive data:** `secrets-management`, `data-handling-pii`.

## Optional reading (external, general)

- [OWASP](https://owasp.org) — top risks, ASVS, cheat sheets.  
- [NIST SSDF](https://csrc.nist.gov/Projects/ssdf) — secure software development practices (framework, not a checklist to paste).

Keep links and procedures **in your** internal systems of record; this file stays **vendor- and employer-neutral**.
