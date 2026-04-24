---
name: shell-csv-pipelines
description: >-
  Bash, awk, cut, grep for CSV/TSV and Jira *file* exports (not the REST
  client): 1-based columns, delimiters, awk/cut, pipes, set -euo pipefail,
  quoting, safe loops, xargs -0, parallel, shellcheck, when to switch to Python.
  Triggers: .sh, shell script, wrangle export, one-liner, bulk text transform,
  awk one-liner, CSV pipeline. For Jira API/PAT/CLI: python-internal-tools jira.
---

# shell-csv-pipelines

## What this is

A single place for **safe, boring shell** on **text and CSV** (exports, Jira field dumps, awk, list normalizers, thin `find`/`ps` wrappers). For **Jira API clients, PATs, and Python** business logic, use **python-internal-tools** and **jira.md** there.

## When to use

- New or refactored **`.sh`**: argument parsing, pipes, `awk`/`cut`, `grep` on exports
- **One-off** extracts from Jira CSVs (champions, threat model lines, reporters, links)
- **Reviewing** a pipeline for quoting mistakes, word-splitting, or missing `set -e`

## When to stop and use Python

- **Writing to Jira** or any authenticated API → Python with tests and config
- **Non-ASCII / messy CSV** (embedded newlines, Excel weirdness) → `csv` module
- **Anything** you will run in production on a schedule without a human watching → prefer Python or add **real** error handling and logging in shell (still harder to test)

## Reference

- **[reference.md](reference.md)** — habits, patterns, and checks to follow every time.

## Related

- **python-internal-tools** (incl. **jira.md**, **security.md**)
- **llm-integrations-safety** (not for shell; for LLM + untrusted text in code)

## Source

Authored for **ai-skills**; if your org keeps a **shared** `unix-shell` or `scripts/` pack, use it as a **concrete** peer set of examples—this skill stays **portable** without a fixed path. Not a slice of **`.claude/CLAUDE.md`**.
