# Jira-integrated internal tools

<!-- Split from the developer guide. Canonical: [`../../.claude/CLAUDE.md`](../../.claude/CLAUDE.md). For general HTTP, credentials, SQL, subprocess, and the full “new API” checklist, see [security.md](security.md). LLM + ticket text: [llm-integrations-safety](../llm-integrations-safety/SKILL.md). -->

Jira is a common system of record for **Security** and **Architecture** tooling. This file focuses on **Jira shape** (PAT, REST, allowlists) and **CLI** habits (**JQL**, **bulk**, **`--preview`**). General Python (layout, venv, tests) lives in [reference.md](reference.md); shared secure patterns in [security.md](security.md).

**Shell / exported files:** for **bash**, **awk**, or **cut** on **saved** CSV/TSV or other **text** (not the REST client in this package), use **[`shell-csv-pipelines`](../shell-csv-pipelines/SKILL.md)** in **ai-skills**. Routing note: [`SKILLS.md`](../../SKILLS.md#jiracsv-split).

## Example: top-level `main.py` + package (illustrative)

*Substitute your package name; ticket keys in examples are fictional.*

This shape uses a **top-level `main.py`** plus a package (not `src/` + `scripts/`):

```
main.py                # CLI: argparse, logging, invokes triage_issue()
jira_triage/          # e.g. config.py, jira_client.py, triage.py
config/               # config.example.yaml, jira_actions.yaml
tests/
docs/
WORK.md
README.md
```

**Behaviour notes**

- **No LLM, no local database today** — Jira is the system of record. Tests mock `JiraClient` / HTTP. If you add an LLM or local persistence later, see §6 / §9 in the canonical guide and the **llm-integrations-safety** skill.
- **HTTP method allowlist** — `config/jira_actions.yaml` lists permitted verbs; `JiraClient` raises `PermissionError` if a disabled method is used.
- **Jira write path allowlist** — After verbs pass, `POST`/`PUT` under `rest/api/` must match compiled patterns and bodies in `jira_client.py`. Extend the allowlist when adding new Jira writes.
- **Link access check (optional)** — `link_access_check` in config; restricted `add_comment` with project-role visibility; see `README.md`.
- **URL policy** — `url_allowlist` gates all remote links; optional `url_allowlist_threat_model` adds domains only for Proforma answers titled Threat Model (see `README.md`).
- **Writes to Jira only** — remote links, issue links, watchers, label, assignee, transitions. Scope PATs and automation accordingly; see `WORK.md` for backlog and decisions.
- **CLI flags:** `--bulk` (cron, `all_open_jql` in config), `--scout` / `--assign` (up to five keys), **`--preview`** = dry run (this project does not use `--dry-run` or `--all-open` alone). See `README.md`.

## Jira in `config.example.yaml` and at startup

`config.example.yaml` is committed; real `config.yaml` is gitignored. Typical **Jira** block:

```yaml
jira:
  base_url: "https://your-domain.atlassian.net"
  token: "your-api-token-here"   # Account Settings → Security → API tokens
  # username: "you@example.com"  # Data Center / Basic only
```

Load config **once** in the entry point and pass `config: dict` into library code. **Validate** Jira fields before any I/O:

```python
def get_jira_config(config: dict) -> dict:
    jira = config.get("jira") or {}
    if not jira.get("base_url"):
        raise ValueError("config.yaml: jira.base_url is required")
    if not jira.get("token"):
        raise ValueError("config.yaml: jira.token is required")
    return jira
```

**Session-style client (sketch):** one `requests.Session` per `JiraClient`, default headers, timeout, then `rest/api/...` calls. The guide’s full `JiraClient` example, **JQL** validation, retries, and **checklist** for new APIs are in [security.md](security.md) — use that for implementation detail so this file does not drift.

## CLI: dry run, JQL, bulk, output

### Dry run / read-only path

Any tool that **writes to Jira** (or a DB) should have a read-only path: **`--dry-run`**, **`--preview`**, or similar — same discovery, no writes, documented in `README.md`.

**Illustrative CLI examples** (project and keys are made up)

**Service A** — uses `--dry-run` on a key or “all open”:

```bash
python main.py --dry-run PROJ-1234
python main.py --all-open --dry-run
```

**Service B** — uses `--preview` *with* other flags (not a lone `--dry-run`):

```bash
python main.py --watch --preview PROJ-1234
python main.py --bulk --preview
```

### Confirm before wide bulk (interactive)

When a human runs over many issues, list keys and require confirmation:

```python
print(f"\nFound {len(keys)} ticket(s):\n")
print(", ".join(keys))
print()
answer = input(f"Run on all {len(keys)} tickets? [y/N] ").strip().lower()
if answer != "y":
    print("Aborted.")
    return 0
```

Handle `EOFError` and `KeyboardInterrupt` as “no.”

**Unattended bulk:** for a **cron**-style `python main.py --bulk`, **do not** prompt; exclude already-labeled work via JQL. Run with **`--preview`** before scheduling. Keep JQL in config **tight**.

### Put JQL in config, not in code

```yaml
all_open_jql: 'project = "Security" AND status = Open AND assignee = sec.arch.eng.dl'
```

### One summary per item

For multi-ticket runs, print after each item (not only at the end):

```
=== Triage summary: PROJ-6834 ===
External links found (4): ...
```

### Exit codes

```python
def main() -> int:
    ...
    return 1 if has_errors else 0

if __name__ == "__main__":
    sys.exit(main())
```

`0` = success, non-zero = failure — so CI and shell pipelines can rely on the exit code.
