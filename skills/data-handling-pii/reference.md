# Reference: data handling, PII, and sensitive data

**Hub:** [SKILL.md](SKILL.md)

Not legal, employment, or jurisdiction-specific advice. This file is not a copy of any employer’s policy text. Use the current published policy from your org as the source of truth for obligations.

For binding rules, work with your org’s Privacy, Legal, and Security teams. This document is a practical engineering and collaboration layer.

---

## 0. Your organization’s data policy (alignment)

This section distills **themes** many teams care about: classification, **minimization**, support- and case-style handling, vendors, and indirect access (e.g. screen share). It does **not** replace authoritative text from your Legal, Privacy, or Security teams.

Read your current data handling, personal/customer data definitions, acceptable use (including Generative AI if applicable), and any “handling in support” or DLP documents in your system of record.

### Definitions (verify against *your* current text)

- **Customer** or **end-user** content: your org will define it.
- **Personal** or **sensitive** data: your org will define categories and examples.

### Themes (engineering and support)

| Theme | Implication (non-exhaustive) |
|-------|--------------------------------|
| **Environments** | Production-like real data in dev/QA is often restricted without an exception and approved path. **Synthetic** or **anonymized** fixtures are the default. |
| **Support, cases, tickets, chat** | Your org's acceptable use and support-handling policies govern what not to put in Jira/Slack/email; read the live text. [§4](#4-collaboration-slack-email-wikis-and-tickets) below is a generic habit layer only. |
| **Indirect access** | Screen share and co-viewing can still be access; policies often require need-to-know and care with recordings and remote control. |
| **Vendors, subprocessors, new SaaS/LLM** | New tools that process work data may need Privacy / Legal / Security or DPA work before broad rollout. [§0.1](#01-illustrative-genai-and-third-party-tools) is illustration only. |
| **Incidents** | Use your org’s **incident** and **breach** playbooks. |

### 0.1 Illustrative: GenAI and third-party tools

**Illustration only, not your policy:** A new browser add-on, SaaS, or GenAI product may move work content into retention or subprocessor scope that differs from your approved default stack. Compliance-style review typically looks at (a) unintended storage or training and (b) DPA/subprocessor fit before pasting work into a new surface. This does not replace your org's acceptable use or data-handling policies.

---

## 1. A practical classification (engineering view)

| Tier | Examples (illustrative) | Default engineering posture |
|------|---------------------------|----------------------------|
| **Credentials** | API keys, passwords, session tokens | [security.md](../python-scripts-and-services/security.md): do not log; do not paste in tickets. |
| **Identifier / contact** (often PII) | Email, name, phone, person-linked IDs | Minimize; avoid in default log lines; prefer opaque internal IDs. |
| **System / internal** | Hosts, Jira keys | Often lower risk; still be careful in public or competitive settings. |
| **User-generated content** | Ticket bodies, pasted email | **Untrusted**; use [llm-integrations-safety](../llm-integrations-safety/SKILL.md) when sending to models. |

Map to your org’s **named** tiers (Confidential, PII, and so on) when you need a policy sign-off.

---

## 2. Data minimization (default)

- Collect the smallest set of fields that still make the tool work; prefer aggregates or sampling when you can.
- For non-prod, prefer **synthetic** or **anonymized** data, not a copy of production, unless an approved process allows it.
- If you store **sensitive** data, know **retention** and **deletion** expectations. Avoid unbounded on-disk logs of full ticket or email bodies.

---

## 3. Logging and observability

- Your org’s logging and observability policies define what must not appear in application and system logs. If those documents and the bullets below disagree, policy wins.
- By default, avoid full emails, phone numbers, and legal names in `INFO`/`ERROR` lines unless you have an allowlist. Prefer opaque or internal numeric IDs. Traces and error trackers: avoid unbounded ticket bodies or free text as **tags** that get indexed widely.
- Error bodies from **external** APIs can contain PII: truncate, redact, or avoid persisting without a clear need.

*Python field patterns:* [logging-structured.md](../python-scripts-and-services/logging-structured.md).

---

## 4. Collaboration: Slack, email, wikis, and tickets

- **Slack and email:** Durable, wide reach—do not paste user lists or full ticket exports for convenience. Use an approved file share or dashboard.
- **Wikis (Confluence, Notion, and so on):** Long-lived and indexed. Prefer “how to get access in system Y” over public lists in an overly open space.
- **Jira** and similar: encourage **redacted** repros; if you need a full **payload**, narrow who can read it. If a **“customer data in support”** path applies, follow **that** policy, not this file alone.

---

## 5. Exports, CSV, and pipelines

- Extracts often include reporter, assignee, and names—treat the file as **sensitive** end to end. See [shell-csv-pipelines](../shell-csv-pipelines/SKILL.md) for **safe** parsing. Avoid re-publishing columns in logs.
- Before publishing a chart, dataset, or **artifact** (even in a private repo), re-check columns and your **DLP** / org rules.

---

## 6. Databases, lakes, and backups

- Test DBs: **pseudonymized** or **synthetic** data; avoid full prod to a laptop as the default. Backups and replicas complicate **erasure**; platform and Privacy own that story for your org.

---

## 7. LLMs and automated processing

- [llm-integrations-safety](../llm-integrations-safety/SKILL.md) for I/O, audit fields, and allowed models. “Summarize this for a **blog**” still needs **redaction** and approval; one model run is not a compliance sign-off.

---

## 8. If sensitive data is over-shared

Follow your org’s playbooks. A typical order: **(1) contain** the spread, **(2) notify** per process (Security / Privacy, and so on), **(3) assess** any notification or HR/legal steps, **(4) fix** technically (rotate exposed credentials, tighten access, fix the source of the leak).

---

## 9. Checklists

### 9.1 New feature (author)

- [ ] **Data** classes and user-generated or pasted **content** identified.
- [ ] Smallest storage and shortest **retention** you can justify; steward for non-trivial cases.
- [ ] Log design: no raw PII on default paths.
- [ ] Test data synthetic or from an **approved** fixture.
- [ ] If **LLM** [llm-integrations-safety](../llm-integrations-safety/SKILL.md) and org vendor/DLP checks as required.

### 9.2 PR / review (reviewer)

- [ ] No new broad logging of names, emails, or full response bodies in logs or “print on failure” dumps.
- [ ] No unbounded storage of ticket or email **bodies** without a clear need (often a threat model or sponsor).
- [ ] If using a prod **copy** or a new **export**, Privacy/DBA/Security are in the design before launch.
- [ ] Exports, CSV, CI: no PII in artifact **names** or job logs when avoidable.

### 9.3 Incident in a chat tool

- [ ] Do not add more full rows of affected people to a wide thread.
- [ ] Follow the internal runbook: [§8](#8-if-sensitive-data-is-over-shared) and your org’s steps.

---

## 10. Calibrate to your org

Maintain a link in your internal docs to the authoritative policy index your org uses. Obligations and versions change there, not in a static fork of this repository.

*Public-edition reference: a habit and teaching layer, not a regulatory copy of a specific employer’s policy set.*
