---
name: secrets-management
description: >-
  Engineering secrets hygiene: no plaintext in Slack, email, wikis, or chat;
  app code and repos (config, .env, CI, Docker, tests, gitleaks); approved stores
  and env injection; CI/K8s/local dev; redaction in logs; leak response. Broad
  eng. Triggers: hardcoded key, .env, os.getenv, pre-commit, token in URL,
  gitleaks, secret scan, API key, PAT, vault, wiki, Slack, K8s Secret, OIDC
  vs long-lived cloud key, accidentally committed, org policy, approved store.
---

# secrets-management

## What this is

A **broad-eng** pattern for **handling credentials** in **day-to-day coding and repos** (config, tests, **CI**, containers) **and** in **collaboration** tools (**Slack**, **email**, **wiki**, **tickets**, **AI chats**). Covers **storing, injecting, rotating, and responding** to leaks in line with **least privilege** and your org’s **approved** tooling.

**Canonical deep content:** [reference.md](reference.md) — including **[application code and repos](reference.md#3-application-code-repos-and-developer-workflow)** and collaboration channels.

## Your organization: read current policy (your portal wins)

Use your employer’s **authoritative** policy index for **password and secret** management, **Application Security** (e.g. secrets in **CI**/**CD**), **Acceptable Use** (credentials in **chat** and **messaging**), and **encryption** or **key** management. This skill does not paste those policies. The [reference: **your** **org** “where do I get a key?”](reference.md#your-organization-where-to-get-a-key) block is a placeholder for your **named** **stores** and runbooks. If this file and your **internal** **policy** disagree, **the policy wins**.

## When to use

- **Someone pasted or almost pasted** a key, cert, or password in **Slack / email / wiki / a ticket** or asked you to “just put the token here.”
- **Designing or reviewing** how a service, **pipeline**, or **cluster** gets **PATs**, API keys, **TLS** material, or **db** passwords.
- **Writing or reviewing** code: **config** loading, **env** only at startup, **tests** that do not hit **prod** creds, **Docker/CI** without **baking** keys, **pre-commit** or **gitleaks**-class checks.
- **Local dev** and **.env** discipline; **preventing** commits and **log** leaks.
- **After a suspected leak** or **exposure in a log**—**rotate** and **contain** first; the skill does **not** tell you a one-size path without your org’s runbook.
- **Pairing** with [python-internal-tools / security.md](../python-internal-tools/security.md) (code-level) and [shift-left-program](../shift-left-program/SKILL.md) (org **handoff** context) for **tickets** / design review **redact** in text.

## Not in scope (route elsewhere)

| Need | See |
|------|-----|
| **Python**-specific: `config.yaml`, `requests`, validation | [python-internal-tools / security.md](../python-internal-tools/security.md), [jira.md](../python-internal-tools/jira.md) |
| **Threat model / formal** org **review** | [shift-left-program](../shift-left-program/SKILL.md) + your internal runbooks |
| **LLM** API keys, mocks, audit in app | [llm-integrations-safety](../llm-integrations-safety/SKILL.md) |
| **Writing** clear runbooks (tone, structure) | [docs-clear-writing](../docs-clear-writing/SKILL.md) |

## Agent guardrails (must follow)

- **Never** output, repeat, or “fix” a **user-provided** secret by writing it back in full. If the user pasted a live credential, tell them to **revoke/rotate** it and **treat the channel as compromised**—per [reference.md §7](reference.md#7-if-a-secret-may-be-exposed).
- **Do not** put real **tokens, passwords, or private keys** in **example** **Jira** **comments,** **wiki** **drafts,** or **Slack** copy-paste. Use **`REDACTED`**, `***`, or a **last**-**four** **only** when illustrating.
- **Prefer** linking to the org’s **approved** secret **store** and access process; do not invent a vendor name if your org **standardizes** on something else—use [Your organization: read current policy](#your-organization-read-current-policy-your-portal-wins) and your **internal** policy **index** when in doubt.

## Quick “say this instead”

| Do not | Do instead |
|--------|------------|
| Post the key in #general | **Approved** secret store + grant to identity; or **1:1** / **internal break-glass** per runbook; **minimize** who sees a value |
| “Document the API key in the **wiki**” for operators | **Where to fetch** the secret (name/path), **how to get access**—**not** the value |
| Commit `.env` to help a teammate | **`.env.example`** with **dummy** values; share **access** to the store, not a file of secrets |
| Log `Authorization: Bearer ...` in debug | **Redact** at the logging boundary; never log full headers for auth |
| Put a **prod** key in a **default** in `config` “for now” | **No** real defaults; **fail fast** on missing **required** **env**; **separate** **dev** credentials or mocks |

**Full tables, coding workflow, and checklists:** [reference.md](reference.md) ([§3 Application code](reference.md#3-application-code-repos-and-developer-workflow), [checklists](reference.md#8-checklists)).

## Source

**Authored** for the **ai-skills** bundle. Reconcile with your org’s **incident** playbooks; for **formal** policy text, use **your** **internal** **index** and [reference: your org](reference.md#your-organization-where-to-get-a-key) **.**
