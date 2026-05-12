---
name: git-workflow
description: >-
  Git workflow habits for Python internal tools teams: branch naming, commit
  messages (Conventional Commits), PR hygiene, rebase vs merge, tags and
  releases, merge strategies, and safety rules. Triggers: git, branch, commit,
  PR, pull request, merge, rebase, tag, release, squash, gitignore, force push,
  conventional commits, branch naming, commit message, git workflow, cherry-pick,
  git stash, undo commit, reset staged.
---

# git-workflow

## What this is

A **shared playbook** for **branch naming**, **commit messages**, **PR hygiene**, and **merge strategy** in Python internal tool repos. Follows conventions that keep history **readable**, reviews **focused**, and `main` **always deployable**.

---

## 1. Branch naming

### Prefixes

| Prefix | When to use |
|--------|-------------|
| `feature/` | New capability or user-visible behaviour |
| `bugfix/` | Fixing a defect in a non-production branch |
| `hotfix/` | Emergency fix directly targeting a production release |
| `release/` | Release preparation (version bump, changelog, final QA) |
| `chore/` | Dependency bumps, config, CI tweaks — no production behaviour change |
| `docs/` | Documentation-only changes |

### Format rules

- **Kebab-case** — all lowercase, words separated by hyphens: `feature/add-auth-middleware`
- **Include the ticket key** when there is one: `feature/PROJ-123-add-auth-middleware`
- **Max ~60 characters** total (branch name only, not counting remote prefix)
- **Never** commit directly to `main` or `master`
- **Never** commit directly to a shared `release/` or `hotfix/` branch without coordination

### Examples

```
feature/PROJ-456-jira-bulk-triage
bugfix/PROJ-789-retry-on-timeout
hotfix/PROJ-101-fix-token-expiry
release/v1.3.0
chore/bump-requests-2.32.3
docs/add-sdel-runbook
```

---

## 2. Commit messages

Follow **Conventional Commits** (`type(scope): short summary`).

### Types

| Type | When |
|------|------|
| `feat` | A new feature or user-visible behaviour |
| `fix` | A bug fix |
| `refactor` | Code restructure with no behaviour change |
| `docs` | Documentation only |
| `test` | Adding or fixing tests |
| `chore` | Build, deps, CI — no production code change |
| `perf` | Performance improvement |
| `ci` | CI/CD config changes |

### Rules

- **Subject line ≤ 50 characters** — if you cannot fit it, the commit is probably too large
- **No period** at the end of the subject line
- **Imperative mood** — "add retry logic", not "added retry logic" or "adds retry logic"
- **Blank line** between subject and body
- **Body explains WHY**, not what — the diff shows what; the message explains the reasoning
- **Include ticket reference** in the body (not the subject) if your team uses Jira links

### Template

```
type(scope): short summary under 50 chars

Why this change was needed and what the key decision was.
Reference docs or constraints that shaped the approach.

Refs: PROJ-123
```

### Examples

```
feat(jira): add bulk triage mode for open tickets

Cron-friendly path processes all tickets matching all_open_jql from
config without prompting. Existing --scout/--assign flow is unchanged.
Added confirmation prompt for interactive runs with >10 tickets.

Refs: PROJ-456
```

```
fix(http): retry on 429 and 503 with Retry-After backoff

Upstream Jira throttles at ~50 req/min per token. Without backoff,
bulk runs were failing silently after the first burst. Max 3 retries
with exponential fallback; 4xx errors (our bug) are not retried.

Refs: PROJ-789
```

```
chore: pin requests to 2.32.3

requests 2.32.x fixes CVE-2024-35195 (proxy trust bypass). Pinning
now so future pip freeze does not drift back to the older version.
```

```
test(db): add idempotency test for init_db

Proved that calling init_db twice on the same file does not drop
existing rows. Catches accidental DROP TABLE regressions in migrations.
```

---

## 3. PR hygiene

### Keep PRs small

- **Target < 400 lines changed** (excluding generated files, lockfiles, migrations)
- A PR that adds a feature, refactors an unrelated module, and bumps three dependencies is three PRs
- If a PR must be large, explain why in the description and break it into logical commits

### PR description

Write three short sections:

```
## What
One sentence on what changed.

## Why
One sentence on why it was needed (link Jira ticket here).

## How to test
Steps a reviewer can follow to verify the change locally or in CI.
```

### Before requesting review

- [ ] `git diff main...HEAD` — read every line you changed; catch debug prints, leftover TODOs, and stray whitespace
- [ ] All tests pass locally (`pytest`, `ruff check .`, `mypy src/` if the repo uses mypy)
- [ ] No secrets or config files with real values in the diff
- [ ] Jira ticket linked in the description
- [ ] Branch is up to date with `main` (rebase, do not merge main into feature)

### Do not

- Push directly to a shared branch without telling the team
- Request review before CI is green
- Merge your own PR without a second set of eyes (unless your team explicitly allows it for chores/docs)
- Accumulate fixup commits after review — squash or amend locally before merging

---

## 4. Rebase vs merge

### The rule

| Situation | Command |
|-----------|---------|
| Update feature branch with latest `main` | `git rebase main` (keeps history linear) |
| Integrate a feature branch into `main` | Merge (usually squash merge via PR) |
| Daily pull from remote on your own feature branch | `git pull --rebase` |
| **Never** | Rebase a branch another person has checked out |

### Why rebase for updates

`git merge main` into a feature branch adds a merge commit that pollutes `git log` with "Merge branch 'main' into feature/..." noise. Rebase replays your commits on top of the latest `main`, keeping the log clean and bisect-friendly.

### Safe rebase workflow

```bash
# On your feature branch:
git fetch origin
git rebase origin/main

# If conflicts:
# Fix the conflict in each file, then:
git add <file>
git rebase --continue

# To bail out entirely:
git rebase --abort
```

### When to use merge (not rebase)

- Integrating a **completed feature** into `main` via a merge commit (preserves the merge event in history for releases)
- A **hotfix** branch that must be merged into both `main` and a release branch — cherry-pick or merge both explicitly; do not rebase

### Never rebase a published branch

If you have already pushed a branch and someone else has pulled it, rebasing rewrites history and forces them to do a hard reset. Coordinate before rebasing any shared branch.

---

## 5. Tags and releases

### Semantic versioning

Use `vMAJOR.MINOR.PATCH`:

| Bump | When |
|------|------|
| `PATCH` (v1.2.**3**) | Bug fix, no API or behaviour change |
| `MINOR` (v1.**3**.0) | New backwards-compatible feature |
| `MAJOR` (**2**.0.0) | Breaking change to CLI flags, config schema, or public API |

### Creating a tag

Always use **annotated** tags (they store the tagger, date, and message — lightweight tags lose this):

```bash
git checkout main
git pull --rebase
git tag -a v1.3.0 -m "$(cat <<'EOF'
Release v1.3.0

## What's new
- feat(jira): bulk triage mode (PROJ-456)
- feat(db): scorer_version column on runs (PROJ-512)

## Bug fixes
- fix(http): retry on 429 with Retry-After backoff (PROJ-789)

## Breaking changes
None.
EOF
)"
git push origin v1.3.0
```

### Tag on `main` after merge

Never tag a feature or release branch. Merge first, verify CI passes on `main`, then tag.

### Keep a CHANGELOG

Update `CHANGELOG.md` (or `WORK.md` if that is your team's convention) before tagging. Use the tag message as the release entry. See **[`docs-clear-writing / changelog-release-notes.md`](../docs-clear-writing/SKILL.md)** for format guidance.

---

## 6. Merge strategies

### Squash merge for feature branches (default)

Squash all commits on a feature branch into one clean commit on `main`. This keeps `git log main` readable — one line per feature or fix, not a stream of "WIP", "fix typo", "actually fix typo" commits.

```bash
# Via GitHub/GHE PR: select "Squash and merge"
# Locally (avoid; prefer the PR UI):
git checkout main
git merge --squash feature/PROJ-456-bulk-triage
git commit -m "feat(jira): add bulk triage mode (PROJ-456)"
```

The squash commit message should follow Conventional Commits (see §2).

### Merge commit for releases

When merging a `release/` branch into `main`, use a regular merge commit (no squash) so the release boundary is visible in the graph:

```bash
git checkout main
git merge --no-ff release/v1.3.0
git tag -a v1.3.0 -m "..."
```

### Protect `main`

Configure branch protection:
- Require at least **1 approving review**
- Require **status checks to pass** before merging (CI, lint, tests)
- **Restrict who can push** to `main` directly
- **Do not allow force pushes** to `main`

### Never force-push to `main`

If `main` is in a bad state, revert the offending commit with `git revert`. Do not rewrite shared history.

---

## 7. Common safety rules

### Before every commit

```bash
git status          # know what is staged and what is not
git diff --staged   # read every line you are about to commit
```

If `git status` shows files you did not intend to include, unstage them:

```bash
git restore --staged <file>
```

### Never commit

- `config.yaml` or any file with real credentials (add to `.gitignore`)
- `.venv/`, `__pycache__/`, `*.pyc`, `dist/`, `build/` (add to `.gitignore`)
- `logs/` or `*.log` files (add to `.gitignore`)
- Large binary files or test fixtures over a few hundred KB (consider Git LFS or external storage)

### Minimum `.gitignore` for Python repos

```gitignore
# Secrets and config with real values
config.yaml
.env

# Python artifacts
__pycache__/
*.py[cod]
*.egg-info/
dist/
build/

# Virtual environment
.venv/
venv/

# Runtime output
logs/
*.log

# Editor
.DS_Store
.idea/
.vscode/
```

### Use `git stash` instead of committing WIP

If you need to switch branches mid-task without committing broken code:

```bash
git stash push -m "wip: half-done retry logic"
# ... switch, do other work, come back ...
git stash pop
```

### Never use `--force` on shared branches

If you must force-push your own feature branch (after a rebase), use `--force-with-lease` instead — it aborts if someone else pushed since your last fetch:

```bash
git push --force-with-lease origin feature/PROJ-456-bulk-triage
```

---

## 8. Quick reference

| Task | Safe command |
|------|-------------|
| Undo last commit, keep changes staged | `git reset --soft HEAD~1` |
| Undo last commit, keep changes unstaged | `git reset HEAD~1` |
| Undo last commit, discard changes entirely | `git reset --hard HEAD~1` *(only on local, unshared commits)* |
| Unstage a file (keep edits) | `git restore --staged <file>` |
| Discard edits to a tracked file | `git restore <file>` |
| See what is staged | `git diff --staged` |
| See unpushed commits | `git log origin/main..HEAD` |
| Update feature branch from main | `git fetch origin && git rebase origin/main` |
| Stash all local changes | `git stash push -m "description"` |
| Restore stash | `git stash pop` |
| List stashes | `git stash list` |
| Create annotated tag | `git tag -a v1.2.3 -m "message"` |
| Push a tag | `git push origin v1.2.3` |
| Delete a local branch | `git branch -d feature/done` |
| Delete a remote branch | `git push origin --delete feature/done` |
| Find which commit introduced a bug | `git bisect start && git bisect bad && git bisect good <sha>` |
| Cherry-pick one commit to another branch | `git cherry-pick <sha>` |

---

## Related

- **Pre-merge quality gate** (tests, README, TM alignment): **[`ship-checklist`](../ship-checklist/SKILL.md)**
- **Lint, type-check, test before push**: **[`pre-pr-checklist`](../pre-pr-checklist/SKILL.md)**
- **CHANGELOG and release notes format**: **[`docs-clear-writing / changelog-release-notes.md`](../docs-clear-writing/SKILL.md)**
- **`.gitignore` for secrets, CI scanning, gitleaks**: **[`secrets-management`](../secrets-management/SKILL.md)**
- **Routing**: [`../../SKILLS.md`](../../SKILLS.md)

## Source

Authored for **ai-skills**. Override with your team's **branch protection policy**, **required CI checks**, and **release process** where they are stricter.
