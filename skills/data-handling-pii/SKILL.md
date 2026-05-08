---
name: data-handling-pii
description: |
  Data classification, PII and sensitive data, minimization, safe logging,
  Jira/CSV/exports, wiki/Slack, LLM+ticket text. Not legal advice—align to your
  org’s privacy and data policies. Pairs with secrets-management and
  llm-integrations-safety.
---

# data-handling-pii

**What this is:** practical engineering habits for **PII**, **credentials**, and **sensitive** fields in **internal tools**—tickets, exports, logs, and small UIs. **Not** a substitute for your org’s **privacy** office, **Legal**, or **published** data policies.

**Deep reference:** [reference.md](reference.md).

**Authoritative** obligations live in your employer’s policy set and handbooks. If policy and this skill disagree, **policy wins**. Escalation paths (DLP, Privacy, Security, and so on) are internal to your org—this file is not a directory of contacts.

## Align with your organization (authoritative source)

This skill **aligns** engineering and collaboration habits to common themes: **minimization**, **least privilege**, **safe logs**, and care with **exports** and **third-party tools** (including **LLMs**). It does not paste or version your employer’s customer data, PII, or acceptable-use text—read the current internal or published documents.

**You must** use current policy text from your system of record (wiki, policy portal, or PDFs your org issues), not a stale export and not a summary in a chat.

A distilled set of **themes** and **checklists** is in [reference.md](reference.md#0-your-organizations-data-policy-alignment). [§0.1](reference.md#01-illustrative-genai-and-third-party-tools) illustrates why **pasting** sensitive work into a **new** SaaS or LLM surface is often high risk from a **governance** perspective—that is one design narrative, not a substitute for **legal** or **compliance** review.

## Triggers: open this skill when…

- A **Jira/CSV/warehouse** path might contain **reporter/assignee** names, **emails**, or free text you could **re-publish** in **Slack** or a **log**.
- You are **choosing** what to **write** in **default** `INFO`/`ERROR` **log** lines, **Sentry** tags, or a **triage** **export**.
- A **PII** field is “convenient to keep forever” in a local **SQLite** or a **file** in `~/`.
- A **user** (or you) is about to **paste** ticket or **email** **content** into an **unapproved** **LLM** or a **new** **vendor** **app**.

## Pairs (same bundle)

- **Pipelines and exports** (**Jira** CSV, **SQL** extract, **S3** **bucket**): **scope**, **redaction**, **access** before you **ship** a path.
- **In-product LLM** or **prompt**-based tools: [llm-integrations-safety](../llm-integrations-safety/SKILL.md).
- **Code-level** **secrets** and **injection** boundaries: [python-scripts-and-services / security.md](../python-scripts-and-services/security.md).
- **Leaks in chat, tickets, wikis:** [secrets-management](../secrets-management/SKILL.md).

| Topic (program level) | See |
|------------------------|-----|
| **Shift-left / AppSec** context | [shift-left-program](../shift-left-program/SKILL.md) |
| **Formal** threat model, **DLP** / **incident** **process** | **Your** org’s **internal** runbooks; **this** file does **not** name **them**. |

**Authored** for **teaching and habits**. Point readers at **the** **stable** **URL** for **your** data-handling and privacy policies in [reference.md](reference.md#10-calibrate-to-your-org) when you maintain a fork.
