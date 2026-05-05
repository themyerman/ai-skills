---
name: ci-cd-pipelines
description: >-
  CI/CD pipelines: GitHub Actions workflow structure, job anatomy, pip caching,
  matrix builds across Python versions, secrets in CI, reusable workflows,
  complete Python CI yml, deploy on merge to main, common mistakes, GitLab CI
  equivalents. Triggers: CI, CD, GitHub Actions, pipeline, workflow,
  .github/workflows, GitLab CI, .gitlab-ci.yml, matrix build, cache pip,
  secrets in CI, deploy on merge, reusable workflow, workflow_call, lint gate,
  pytest in CI, continuous integration, continuous deployment, ruff in CI,
  mypy in CI, coverage artifact, concurrency group, cancel stale runs.
---

# ci-cd-pipelines

## What this is

Practical patterns for **GitHub Actions** (primary) and **GitLab CI** (secondary) for **Python internal tools**: workflow layout, caching, matrix builds, secrets hygiene, reusable workflows, and deploy-on-merge. The goal is a pipeline that is **fast**, **correct**, and **safe to copy into a new repo without modification**.

For secrets storage and rotation policy: [`secrets-management`](../secrets-management/SKILL.md). For pre-PR quality gates you run locally first: [`verification-loop`](../verification-loop/SKILL.md). For Docker-based deploy targets: [`docker-containerization`](../docker-containerization/SKILL.md).

---

## 1. Workflow structure

### Directory layout

```
.github/
  workflows/
    ci.yml          # lint + type check + test (runs on every PR and push)
    cd.yml          # deploy (runs only on merge to main)
    reusable-test.yml  # shared logic called by ci.yml in other repos
```

**One file per concern.** A single 400-line `main.yml` is hard to read and re-trigger independently. Split when:

- Deploy has different secrets or permissions than test
- You want to retrigger deploy without rerunning tests
- Other repos need to call the same pipeline logic (use `workflow_call`)

### Trigger blocks (`on:`)

```yaml
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  workflow_dispatch:    # manual trigger from GitHub UI or API
  schedule:
    - cron: "0 6 * * 1"  # Monday 06:00 UTC — dependency audit, nightly build, etc.
```

**Path filters** — avoid running expensive jobs when only docs changed:

```yaml
on:
  push:
    paths:
      - "src/**"
      - "tests/**"
      - "requirements*.txt"
      - ".github/workflows/**"
```

### Concurrency groups — cancel stale runs

Without this, every `git push` queues a new run behind the previous one. Cancel the in-progress run when a newer push arrives on the same branch:

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

Put this at the **workflow level** (not inside a job). On `main`, where you never want a deploy cancelled mid-flight, set `cancel-in-progress: false` in the CD workflow.

---

## 2. Job anatomy

A complete annotated job:

```yaml
jobs:
  test:
    name: Test (Python ${{ matrix.python-version }})
    runs-on: ubuntu-latest          # or self-hosted runner label
    timeout-minutes: 15             # hard cap — prevents hung jobs burning minutes

    strategy:
      fail-fast: false              # see §4 for matrix
      matrix:
        python-version: ["3.10", "3.11", "3.12"]

    needs: []                       # list job IDs this one waits for; empty = run in parallel

    if: github.event_name != 'schedule' || github.ref == 'refs/heads/main'
    # ^ example conditional: skip schedule trigger on non-main branches

    steps:
      - name: Checkout
        uses: actions/checkout@v4   # pin to a tag; see §9 for SHA pinning

      - name: Set up Python ${{ matrix.python-version }}
        uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python-version }}

      - name: Cache pip
        uses: actions/cache@v4
        with:
          path: ~/.cache/pip
          key: ${{ runner.os }}-pip-${{ matrix.python-version }}-${{ hashFiles('requirements*.txt') }}
          restore-keys: |
            ${{ runner.os }}-pip-${{ matrix.python-version }}-
            ${{ runner.os }}-pip-

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt -r requirements-dev.txt

      - name: Lint (ruff)
        run: ruff check .

      - name: Type check (mypy)
        run: mypy src/ --ignore-missing-imports

      - name: Test (pytest)
        run: pytest -q --cov=src --cov-report=xml

      - name: Upload coverage
        uses: actions/upload-artifact@v4
        with:
          name: coverage-${{ matrix.python-version }}
          path: coverage.xml
          retention-days: 7
```

Key options:

| Option | Purpose |
|--------|---------|
| `timeout-minutes` | Kill hung jobs; default is 6 hours (very expensive) |
| `needs: [job-id]` | Sequential dependency; omit for parallel |
| `if:` | Conditional execution; evaluated before the job starts |
| `continue-on-error: true` | Mark job allowed-to-fail (useful for optional checks or canary Python versions) |
| `uses: org/action@tag` | Calls a pre-built action from the marketplace or your org |
| `run: |` | Shell script; runs in a fresh shell per step |

---

## 3. Caching

Without caching, `pip install` on a cold runner takes 60–120 seconds. With a warm cache it drops to 5–10 seconds.

### Cache pip (recommended approach)

```yaml
- name: Cache pip
  uses: actions/cache@v4
  with:
    path: ~/.cache/pip
    key: ${{ runner.os }}-pip-${{ matrix.python-version }}-${{ hashFiles('requirements.txt', 'requirements-dev.txt') }}
    restore-keys: |
      ${{ runner.os }}-pip-${{ matrix.python-version }}-
      ${{ runner.os }}-pip-
```

**Cache key strategy:**

- Primary key: exact match on OS + Python version + requirements hash. A requirements change busts the cache correctly.
- Restore keys (fallback, ordered): broader prefixes allow partial cache hits so you only re-download changed packages instead of all packages.

### Cache a venv (alternative)

If you need the venv itself cached (e.g. for reproducible activation in subsequent steps):

```yaml
- name: Cache venv
  uses: actions/cache@v4
  with:
    path: .venv
    key: ${{ runner.os }}-venv-${{ matrix.python-version }}-${{ hashFiles('requirements*.txt') }}

- name: Create / restore venv
  run: |
    python -m venv .venv
    source .venv/bin/activate
    pip install -r requirements.txt -r requirements-dev.txt
  env:
    VIRTUAL_ENV: .venv
```

### Do not cache `node_modules` across major version changes

If your repo has a small JS build step alongside Python, cache with the lockfile hash:

```yaml
key: ${{ runner.os }}-node-${{ hashFiles('package-lock.json') }}
```

---

## 4. Matrix builds

Test across multiple Python versions in parallel:

```yaml
strategy:
  fail-fast: false        # one version failing does NOT cancel the others
  matrix:
    python-version: ["3.10", "3.11", "3.12"]
```

**When to use matrix:**

- Public libraries or packages that advertise multi-version support
- Services where the deployment Python version is still being decided
- Catching compatibility regressions before they reach production

**When matrix is overkill for internal tools:**

- The tool is deployed to a single, pinned Python version (e.g. Python 3.11 on a specific server)
- You control the runtime and can upgrade it — just test on the version you deploy
- Build time is already tight and you want fast feedback

If you run a matrix but only care about one "official" version for coverage uploads or artifacts, use a conditional:

```yaml
- name: Upload coverage
  if: matrix.python-version == '3.11'
  uses: actions/upload-artifact@v4
  ...
```

**`fail-fast: false` is almost always the right choice.** When `fail-fast: true` (the default), a failure on Python 3.10 immediately cancels 3.11 and 3.12, so you never learn whether those pass. The only reason to keep `fail-fast: true` is when all matrix jobs share a resource that should be freed immediately on failure.

---

## 5. Secrets in CI

### The right way to pass a secret

```yaml
- name: Deploy
  env:
    DEPLOY_TOKEN: ${{ secrets.DEPLOY_TOKEN }}   # exposed to this step's env only
  run: ./scripts/deploy.sh
```

Secrets are available as `${{ secrets.NAME }}` in `env:` blocks and in `with:` inputs to actions. GitHub automatically redacts the secret value from logs — but only if it knows the value. Derived values (base64-encoded, URL-encoded) are **not** auto-redacted.

### Rules

- **Never `echo` a secret** — even a partial echo can leak enough bits.
- **Never put secrets in workflow file variables** at the top level — they appear in `env:` for every job including ones that do not need them.
- **Never put secrets in job `outputs:`** — outputs are visible in the workflow summary.
- **Use `github.token` for repo access** (checking out, creating releases, commenting on PRs). It is automatically available and scoped to the current repo with least privilege. Request additional permissions only when needed:

```yaml
permissions:
  contents: read
  pull-requests: write    # only if the job comments on PRs
```

- **Scope permissions at the workflow level, not the job level,** unless different jobs genuinely need different scopes.
- **Do not store secrets in `env:` at the workflow level** if only one job needs them.

For secrets storage, rotation, TTLs, and leak response: [`secrets-management`](../secrets-management/SKILL.md) and its `reference.md`.

---

## 6. Reusable workflows

When multiple repos share the same test/lint pipeline, extract it into a `workflow_call` workflow so you change it once and all callers update:

**Callee** (`.github/workflows/reusable-test.yml` in a shared repo):

```yaml
on:
  workflow_call:
    inputs:
      python-version:
        required: false
        type: string
        default: "3.11"
    secrets:
      INTERNAL_PYPI_TOKEN:
        required: false

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: ${{ inputs.python-version }}
      - name: Install
        run: pip install -r requirements.txt -r requirements-dev.txt
      - name: Test
        run: pytest -q
        env:
          INTERNAL_PYPI_TOKEN: ${{ secrets.INTERNAL_PYPI_TOKEN }}
```

**Caller** (any repo's `.github/workflows/ci.yml`):

```yaml
jobs:
  call-shared-test:
    uses: my-org/shared-workflows/.github/workflows/reusable-test.yml@main
    with:
      python-version: "3.11"
    secrets:
      INTERNAL_PYPI_TOKEN: ${{ secrets.INTERNAL_PYPI_TOKEN }}
```

**Rules:**

- The callee workflow must be in a repo accessible to the caller (same org, or public).
- Secrets are passed explicitly — they are never inherited automatically.
- Use `@main` or a pinned SHA, not a floating branch, for stability.
- Reusable workflows cannot call other reusable workflows more than one level deep.

---

## 7. Complete Python CI workflow

Copy this into `.github/workflows/ci.yml`. It covers checkout, setup, caching, lint, type check, test with coverage, and artifact upload. Production-ready for a Python internal tool.

```yaml
# .github/workflows/ci.yml
# Runs on every PR and push to main.
# Requirements: requirements.txt and requirements-dev.txt at repo root.
# Expects: src/ for source code, tests/ for tests.

name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  workflow_dispatch:

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read

jobs:
  lint:
    name: Lint and type check
    runs-on: ubuntu-latest
    timeout-minutes: 10

    steps:
      - name: Checkout
        uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2

      - name: Set up Python
        uses: actions/setup-python@0b93645e9fea7318ecaed2b359559ac225c90a2b  # v5.3.0
        with:
          python-version: "3.11"

      - name: Cache pip
        uses: actions/cache@1bd1e32a3bdc45362d1e726936510720a7c6158d  # v4.2.0
        with:
          path: ~/.cache/pip
          key: ${{ runner.os }}-pip-3.11-${{ hashFiles('requirements*.txt') }}
          restore-keys: |
            ${{ runner.os }}-pip-3.11-
            ${{ runner.os }}-pip-

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt -r requirements-dev.txt

      - name: Lint (ruff check)
        run: ruff check .

      - name: Format check (ruff format --check)
        run: ruff format --check .

      - name: Type check (mypy)
        run: mypy src/ --ignore-missing-imports

  test:
    name: Test (Python ${{ matrix.python-version }})
    runs-on: ubuntu-latest
    timeout-minutes: 15
    needs: lint           # only run tests when lint passes

    strategy:
      fail-fast: false
      matrix:
        python-version: ["3.10", "3.11", "3.12"]

    steps:
      - name: Checkout
        uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2

      - name: Set up Python ${{ matrix.python-version }}
        uses: actions/setup-python@0b93645e9fea7318ecaed2b359559ac225c90a2b  # v5.3.0
        with:
          python-version: ${{ matrix.python-version }}

      - name: Cache pip
        uses: actions/cache@1bd1e32a3bdc45362d1e726936510720a7c6158d  # v4.2.0
        with:
          path: ~/.cache/pip
          key: ${{ runner.os }}-pip-${{ matrix.python-version }}-${{ hashFiles('requirements*.txt') }}
          restore-keys: |
            ${{ runner.os }}-pip-${{ matrix.python-version }}-
            ${{ runner.os }}-pip-

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt -r requirements-dev.txt

      - name: Run tests
        run: pytest -q --cov=src --cov-report=xml --cov-report=term-missing

      - name: Upload coverage report
        if: matrix.python-version == '3.11'   # upload once, not per version
        uses: actions/upload-artifact@65c4c4a1ddee5b72f698fdd19549f0f0fb45cf08  # v4.6.0
        with:
          name: coverage-report
          path: coverage.xml
          retention-days: 14
```

**Notes on this file:**

- Actions are pinned to **SHAs** (see §9 — why tags are not enough).
- `lint` runs first; `test` has `needs: lint` so you don't burn matrix minutes on broken code.
- `ruff format --check` fails the build if code is not formatted — it does **not** auto-format. Run `ruff format .` locally before pushing.
- Coverage is uploaded only for Python 3.11 to avoid duplicate artifacts.
- `permissions: contents: read` at the workflow level — least privilege.

---

## 8. CD: deploy on merge

A separate workflow that runs after CI passes on `main`. Keep deploy credentials out of the CI workflow entirely.

```yaml
# .github/workflows/cd.yml
name: CD

on:
  push:
    branches: [main]

# No cancel-in-progress — never cancel a deploy mid-flight.
concurrency:
  group: deploy-main
  cancel-in-progress: false

permissions:
  contents: read

jobs:
  deploy:
    name: Deploy to production
    runs-on: ubuntu-latest
    timeout-minutes: 20
    # Require CI to pass first. Replace with the actual workflow filename.
    # For cross-workflow dependency, use environments + required status checks
    # in branch protection rules — that is more reliable than needs: across files.
    environment: production    # triggers required reviewers / wait gates if configured

    steps:
      - name: Checkout
        uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2

      - name: Set up Python
        uses: actions/setup-python@0b93645e9fea7318ecaed2b359559ac225c90a2b  # v5.3.0
        with:
          python-version: "3.11"

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt

      # Pattern A: rsync to a server
      - name: Deploy via rsync
        env:
          DEPLOY_SSH_KEY: ${{ secrets.DEPLOY_SSH_KEY }}
          DEPLOY_HOST: ${{ secrets.DEPLOY_HOST }}
          DEPLOY_USER: ${{ secrets.DEPLOY_USER }}
        run: |
          echo "$DEPLOY_SSH_KEY" > /tmp/deploy_key
          chmod 600 /tmp/deploy_key
          rsync -az --delete \
            -e "ssh -i /tmp/deploy_key -o StrictHostKeyChecking=no" \
            src/ scripts/ requirements.txt \
            "$DEPLOY_USER@$DEPLOY_HOST:/opt/myapp/"
          rm -f /tmp/deploy_key

      # Pattern B: Docker build + push to registry, then pull on server
      # - name: Build and push Docker image
      #   env:
      #     REGISTRY_TOKEN: ${{ secrets.REGISTRY_TOKEN }}
      #   run: |
      #     echo "$REGISTRY_TOKEN" | docker login ghcr.io -u ${{ github.actor }} --password-stdin
      #     docker build -t ghcr.io/my-org/myapp:${{ github.sha }} .
      #     docker push ghcr.io/my-org/myapp:${{ github.sha }}
```

**Cross-workflow dependency (the reliable way):** Use **branch protection rules** in GitHub → require the `CI / Test` status check to pass before merging. This prevents a deploy from triggering even if someone pushes directly. The `environment: production` block adds an optional manual approval gate.

---

## 9. Common mistakes

| Mistake | Better approach |
|---------|----------------|
| Running expensive jobs on every PR with no path filter | Add `paths:` filter to `on.push` and `on.pull_request` so jobs only run when relevant files change |
| Pinning actions to a tag (`@v4`) | Pin to the **commit SHA** for the tag — tags are mutable and can be hijacked; SHA is immutable |
| Using `ruff format .` as a CI step | Use `ruff format --check .` — the `--check` flag fails the build without modifying files |
| Putting secrets in workflow-level `env:` | Scope secrets to the specific step `env:` block that needs them |
| Storing secrets in `workflow` outputs or `echo` | Never echo secrets; outputs are visible in the summary |
| One giant workflow file for everything | Split CI and CD; use `workflow_call` for shared logic |
| `fail-fast: true` (the default) in a matrix | Set `fail-fast: false` so all versions report results |
| No `timeout-minutes` on jobs | The default is 6 hours; a hung test will burn your minutes quota |
| No `concurrency:` group | Old runs pile up and run redundantly; cancel stale runs |
| Skipping the `permissions:` block | Default is read+write on all scopes; specify `contents: read` minimum |
| `needs:` across workflow files | Use branch protection required status checks instead — cross-file `needs:` does not work |
| Caching with a key that never changes | Always include a file hash (`hashFiles(...)`) so the cache busts when dependencies change |
| Running deploy on every push branch | Gate deploy on `github.ref == 'refs/heads/main'` or use `on.push.branches: [main]` |

### SHA pinning for actions

Tags like `actions/checkout@v4` can be repointed to a different commit at any time (a compromised maintainer or a tag force-push). Pin to the full SHA:

```yaml
# Insecure — tag can be moved
uses: actions/checkout@v4

# Secure — SHA is immutable; keep the tag as a comment for readability
uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2
```

Use [Dependabot for GitHub Actions](https://docs.github.com/en/code-security/dependabot/working-with-dependabot/keeping-your-actions-up-to-date-with-dependabot) or a tool like `pin-github-action` to keep SHAs current.

---

## 10. GitLab CI equivalent

For teams on GitLab or GitHub Enterprise running GitLab CI (`.gitlab-ci.yml`):

### Key concept mapping

| GitHub Actions | GitLab CI |
|----------------|-----------|
| `on:` | `workflow:rules:` or `only:`/`except:` (use `rules:`) |
| `jobs:` | top-level job names |
| `needs:` | `needs:` (same concept, same keyword) |
| `strategy.matrix` | `parallel: matrix:` |
| `env:` | `variables:` |
| `secrets.NAME` | CI/CD Variables (masked, protected) |
| `actions/cache` | `cache:` block with `key:` |
| `workflow_call` | `include:` with a remote template |
| `runs-on:` | `tags:` (to select a runner) |
| `environment:` | `environment:` (same concept) |

### Complete `.gitlab-ci.yml` for Python (equivalent to §7)

```yaml
# .gitlab-ci.yml
# Stages run in order; jobs within a stage run in parallel.

stages:
  - lint
  - test
  - deploy

variables:
  PIP_CACHE_DIR: "$CI_PROJECT_DIR/.cache/pip"
  PYTHON_VERSION: "3.11"

# Cache pip downloads across jobs and pipelines.
.pip-cache: &pip-cache
  cache:
    key:
      files:
        - requirements.txt
        - requirements-dev.txt
      prefix: pip-$PYTHON_VERSION
    paths:
      - .cache/pip
    policy: pull-push

lint:
  stage: lint
  image: python:$PYTHON_VERSION-slim
  <<: *pip-cache
  script:
    - pip install -r requirements-dev.txt
    - ruff check .
    - ruff format --check .
    - mypy src/ --ignore-missing-imports
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

test:
  stage: test
  needs: [lint]
  image: python:${PYTHON_VERSION}-slim
  parallel:
    matrix:
      - PYTHON_VERSION: ["3.10", "3.11", "3.12"]
  <<: *pip-cache
  script:
    - pip install -r requirements.txt -r requirements-dev.txt
    - pytest -q --cov=src --cov-report=xml --cov-report=term-missing
  artifacts:
    when: always
    paths:
      - coverage.xml
    expire_in: 14 days
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

deploy:
  stage: deploy
  image: python:$PYTHON_VERSION-slim
  needs: [test]
  environment:
    name: production
  script:
    - pip install -r requirements.txt
    - ./scripts/deploy.sh
  rules:
    # Only deploy on push to default branch, not on MRs
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      when: on_success
```

**GitLab-specific notes:**

- **`rules:`** over `only:`/`except:` — `rules:` is evaluated top-to-bottom and is more predictable.
- **Masked variables** — in GitLab CI/CD settings, mark secrets as **Masked** (redacted from logs) and **Protected** (only available on protected branches). Never pass secrets as plain `variables:` in the YAML file.
- **`cache: policy: pull-push`** — the default; a job that does not install deps should use `policy: pull` to avoid writing a stale cache.
- **`needs:`** works the same as in GitHub Actions for cross-stage dependencies.
- **`parallel: matrix:`** is the GitLab equivalent of `strategy.matrix`; `fail-fast` equivalent does not exist — use `allow_failure: true` on specific matrix entries if needed.

---

## Related

- **Before pushing — run quality gates locally:** [`verification-loop`](../verification-loop/SKILL.md)
- **Merge readiness (README, WORK, TM gates):** [`major-change-readiness`](../major-change-readiness/SKILL.md)
- **Secrets hygiene, leak response, policy:** [`secrets-management`](../secrets-management/SKILL.md)
- **Docker build and push in CD:** [`docker-containerization`](../docker-containerization/SKILL.md)
- **Dependency auditing (pip-audit, Dependabot, CVE triage):** [`dependency-security`](../dependency-security/SKILL.md)
- **Python service structure, venv, pytest, Flask:** [`python-internal-tools`](../python-internal-tools/SKILL.md)
- **Git branch naming, commit messages, PR hygiene:** [`git-workflow`](../git-workflow/SKILL.md)
- **Routing:** [`../../SKILLS.md`](../../SKILLS.md)

## Source

Authored for **`ai-skills`**. GitHub Actions syntax follows the [GitHub Actions documentation](https://docs.github.com/en/actions). GitLab CI syntax follows the [GitLab CI/CD reference](https://docs.gitlab.com/ee/ci/yaml/). SHA pins in §7 are illustrative — **verify current SHAs** from the action's release page before use in production. Align with your org's runner configuration, approved registries, and deployment runbooks.
