---
name: llm-integrations-safety
description: >-
  LLM in Python: mock client first, provider factory (no scattered if/elif),
  SECURITY NOTICE in system message, token/size limits, prompt-injection and
  Jira-aware flows, input+output screening (e.g. anomaly module), pass/fail/
  uncertain, audit in DB, never silent mock in production, HTTP retries. See
  reference.md. Triggers: Anthropic, OpenAI, Ollama, Bedrock, add LLM, RAG on
  tickets, screen untrusted text, audit trail, false negative/positive, §9
  from CLAUDE. Org: acceptable use, unsanctioned GenAI, follow internal policy.
---

# llm-integrations-safety

## What this is

**Section 9** of the shared developer guide in **`.claude/CLAUDE.md`**, extracted so agents can load **LLM integration** patterns without the rest of the Python guide. Examples use a central **`anomaly` (or similar) module**; in your repo, keep the same **ideas** and **one** clear screening surface, not a copy of any particular path.

## When to use

- Wiring **Anthropic**, **OpenAI**, or a **shim** that mimics their APIs
- **Jira (or any ticket text) as LLM input**—treat as untrusted
- **Output** that might contain instructions or PII back to the user
- **CI**: mock client, **no** production credentials; **no** “forgot to swap mock” in prod

## Pair with

**`python-scripts-and-services`** for project layout, config, tests, and CLI design. **`data-handling-pii`** when ticket or output may include **PII** or other **sensitive** data, or when **acceptable-use** policy governs use of **AI** with **work** content.

## Your organization (read current policy; this skill is not a legal copy)

Use your employer’s published **Application Security**, **Acceptable Use**, **privacy and data handling**, and any **Generative AI** or **non‑human / agentic use** policy for the current rules on LLMs, **tickets** as model input, and model output—not this file. Follow internal governance contacts and escalation paths. If this skill and your policy disagree, **the policy wins**.

## Reference

- **[reference.md](reference.md)** — full “LLM Integration Patterns” text from the source guide.

## Source

Sliced from §9 of the canonical developer guide at **[`../../.claude/CLAUDE.md`](../../.claude/CLAUDE.md)** (**`ai-skills/.claude/CLAUDE.md`**; a **`<REPOS>/.claude/CLAUDE.md`** symlink can point at the same file).
