---
name: jira-integration
description: >-
  Jira from the agent: REST/curl patterns, JQL, fetch tickets, comments,
  transitions, PR links. For Python PAT tools see python-scripts-and-services/jira.md.
---

# Jira Integration

Retrieve, analyze, and update Jira tickets from an AI coding workflow.

## This repo: Python + PAT / Data Center

For **internal Python tools** (Bearer PAT, URL allowlists, fail-closed writes), use **[`python-scripts-and-services/jira.md`](../python-scripts-and-services/jira.md)**. This skill complements that file with **curl** patterns.

## When to activate

- Fetch a ticket to understand requirements
- Extract testable acceptance criteria
- Add comments or transition status
- Search with JQL
- Link PRs or branches

## Prerequisites

**curl fallback** — set (typical **Jira Cloud** pattern):

| Variable | Description |
|----------|-------------|
| `JIRA_URL` | Instance base URL |
| `JIRA_EMAIL` | Atlassian account email |
| `JIRA_API_TOKEN` | Token from Atlassian |

Never commit credentials; use env or a secrets manager. **Data Center** often uses **PAT + Bearer** instead — see **`jira.md`** above.

## REST examples (Cloud-style curl)

Use **`rest/api/3`** only if your server is Jira Cloud or compatible; **Data Center** may use **`/rest/api/2`** — confirm your instance.

### Fetch a ticket

```bash
curl -s -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  -H "Content-Type: application/json" \
  "$JIRA_URL/rest/api/3/issue/PROJ-1234" | jq '{
    key: .key,
    summary: .fields.summary,
    status: .fields.status.name
  }'
```

### Search with JQL

```bash
curl -s -G -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  --data-urlencode "jql=project = PROJ AND status = 'In Progress'" \
  "$JIRA_URL/rest/api/3/search"
```

### Transitions

```bash
curl -s -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  "$JIRA_URL/rest/api/3/issue/PROJ-1234/transitions" | jq '.transitions[] | {id, name: .name}'
```

## Analyzing a ticket

Extract **testable requirements**, **acceptance criteria**, **test types**, **edge cases**, and **dependencies**. Use a structured summary (ticket key, status, scenarios, data needs).

## Updating tickets

Comment when starting work, when tests land, when PR is open, when done — keep comments concise; link out to PRs and dashboards. Pair with **[`data-handling-pii`](../data-handling-pii/SKILL.md)** if ticket text is sensitive.

## Security

- No API tokens in source or pasted into tickets
- Least-privilege tokens; rotate if exposed
- Fail fast if credentials missing

## Related

- **[`secrets-management`](../secrets-management/SKILL.md)** — credential hygiene
- **[`python-scripts-and-services/jira.md`](../python-scripts-and-services/jira.md)** — Python PAT patterns
