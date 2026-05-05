---
name: dependency-security
description: >-
  Audit Python dependencies for CVEs and supply chain risk: pip-audit, pinning strategy,
  pip-compile, Dependabot, Renovate, CVE triage workflow, private package indexes, index
  confusion attacks, supply chain hygiene, SBOM, license compliance with pip-licenses.
  Triggers: CVE, dependency, pip-audit, supply chain, vulnerable package, dependabot,
  renovate, pip-compile, license compliance, SBOM, security vulnerability,
  requirements.txt audit, package security.
---

# dependency-security

## What this is

A practical guide to keeping Python internal tool dependencies secure. Covers auditing for
known CVEs, pinning strategy, automating update PRs, triaging vulnerability reports, private
index configuration, supply chain hygiene habits, SBOM generation, and license checks.

**Scope:** Python internal tools and services. Not a substitute for your org's formal security review program — if a CVE in a dependency affects a production service, follow your org's formal vulnerability response path.

**Related skills:**
- `python-internal-tools` — pinning in `requirements.txt`, project structure
- `secrets-management` — broader security hygiene including CI scanning
- `python-internal-tools/secrets-scanning-ci.md` — CI secrets and SAST scanning

---

## 1. Why dependency security matters

A Python project with 10 direct dependencies typically pulls in 30–60 transitive ones. Any
single package in that graph can carry a CVE or, in the worst case, be actively compromised.

Real-world examples of the category:
- **SolarWinds (2020):** a build-time dependency was backdoored; the malicious code shipped
  in signed releases.
- **Log4Shell (2021):** a single transitive dependency (log4j) was exploitable in thousands
  of products, most of which had no idea they were using it.
- **PyPI typosquatting:** packages named `requets`, `colourama`, or `python-dateutil2` have
  appeared and run malicious code on install.

For internal tools the blast radius is usually smaller than production services, but the
risk is not zero — internal tools often hold Jira PATs, GHE tokens, or database credentials.
A compromised dependency that exfiltrates environment variables or `config.yaml` is a
serious incident.

The good news: auditing Python deps takes minutes. The tools are free and the workflow is
straightforward.

---

## 2. pip-audit — the primary tool

`pip-audit` queries the OSV database (which aggregates NVD, GitHub Advisory, and others)
for known CVEs against your installed or listed packages.

### Install

```bash
# Into your project venv
source .venv/bin/activate
pip install pip-audit
```

Add to `requirements-dev.txt`:

```
pip-audit==2.7.3
```

### Basic usage

Audit against a requirements file (does not require the packages to be installed):

```bash
pip-audit -r requirements.txt
```

Audit what is currently installed in the active venv:

```bash
pip-audit
```

### JSON output for scripting or CI

```bash
pip-audit -r requirements.txt --format json > audit.json
```

The JSON output includes `name`, `version`, `vulns` (list of `id`, `fix_versions`,
`description`). Useful for parsing in CI to fail the build on high-severity findings.

### Interpreting output

```
Name        Version  ID                  Fix Versions
----------- -------- ------------------- ------------
cryptography 39.0.0  GHSA-jfh8-c2jp-5v3q 39.0.1
requests     2.28.0  CVE-2023-32681      2.31.0
```

Each row is one vulnerability. `Fix Versions` tells you the minimum safe version. If the
column is empty, no upstream fix exists yet.

### Fixing a flagged package

If a fix version exists:

```bash
pip install "cryptography>=39.0.1"
pip freeze | grep cryptography >> requirements.txt  # then manually set exact pin
```

Or update the pin in `requirements.txt` directly and re-install:

```
cryptography==39.0.1
```

Then re-run `pip-audit -r requirements.txt` to confirm the finding is cleared.

If no fix exists: see the CVE triage workflow in section 5.

---

## 3. Pinning strategy revisited

### Exact pins are correct for internal tools

```
# requirements.txt — exact pins
requests==2.31.0
PyYAML==6.0.2
cryptography==41.0.7
```

Exact pins (`==`) give you:
- Reproducible installs across environments
- No surprise breakage when upstream releases a new version
- A clear diff when you intentionally update

The cost: you must update proactively (monthly cadence or on CVE alert). This is the right
trade-off for internal tools.

Ranges (`>=`, `~=`) let packages auto-update, which sounds helpful but means your CI can
pass today and break tomorrow when upstream releases an incompatible version. Avoid ranges
in `requirements.txt` for deployed tools.

### pip-compile for managed pinning

`pip-compile` (from `pip-tools`) takes a high-level `requirements.in` listing only your
direct dependencies and generates a fully-resolved, annotated `requirements.txt` with all
transitive pins.

```bash
pip install pip-tools
```

Create `requirements.in`:

```
requests
PyYAML
anthropic
```

Generate the full pinned `requirements.txt`:

```bash
pip-compile requirements.in
```

The generated file includes comments showing which direct dependency pulled in each
transitive one, making it easy to trace why a package is present.

To upgrade all packages to latest compatible versions:

```bash
pip-compile --upgrade requirements.in
```

To upgrade a single package:

```bash
pip-compile --upgrade-package requests requirements.in
```

Commit both `requirements.in` and `requirements.txt`. Only `requirements.txt` is used for
`pip install`.

Dev dependencies follow the same pattern: `requirements-dev.in` → `requirements-dev.txt`.

---

## 4. Dependabot and Renovate for automated update PRs

Running `pip-audit` manually works, but you will miss CVEs between runs. Dependabot and
Renovate watch your repository continuously and open PRs when dependencies have updates or
known vulnerabilities.

### Dependabot (GitHub / GHE)

Create `.github/dependabot.yml` in your repo:

```yaml
version: 2
updates:
  - package-ecosystem: pip
    directory: "/"           # location of requirements.txt
    schedule:
      interval: weekly       # or daily
    open-pull-requests-limit: 10
    labels:
      - dependencies
    # If you use pip-compile, target the .in file:
    # pip-compile is detected automatically when requirements.in exists
```

If your project uses multiple requirements files:

```yaml
version: 2
updates:
  - package-ecosystem: pip
    directory: "/"
    schedule:
      interval: weekly
    # Dependabot will pick up requirements.txt and requirements-dev.txt automatically
```

Dependabot opens one PR per outdated or vulnerable package. The PR includes:
- The old and new version
- The changelog or release notes (when available)
- Links to any associated CVEs

**Your workflow:** review the PR, check that CI passes, merge. For security-flagged updates,
prioritize and merge within the SLA your team sets (e.g. critical CVE within 48 hours, high
within 7 days).

Do not let these PRs pile up. A backlog of 30 dependency PRs usually means none of them get
reviewed and the tool becomes noise. Keep the queue short by merging routinely.

### Renovate (alternative)

Renovate is more configurable than Dependabot and supports grouping related updates into a
single PR (useful for reducing noise). Basic `renovate.json` at the repo root:

```json
{
  "extends": ["config:base"],
  "packageRules": [
    {
      "matchPackagePatterns": ["*"],
      "matchUpdateTypes": ["patch"],
      "automerge": true
    }
  ],
  "schedule": ["every weekend"]
}
```

The `automerge: true` on patch updates means Renovate merges patch bumps automatically if
CI passes — reduces manual load while still requiring review for minor and major updates.

---

## 5. CVE triage workflow

When `pip-audit` (or Dependabot) reports a CVE, follow this five-step workflow. Do not
close the finding without completing at least steps 1–3.

### Step 1: Read the CVE description

Go to `https://osv.dev/vulnerability/<ID>` or `https://nvd.nist.gov/vuln/detail/<CVE-ID>`.

Understand:
- What is the vulnerable component (the package itself, or a specific sub-module)?
- What type of vulnerability (RCE, SSRF, path traversal, DoS, information disclosure)?
- What conditions trigger it (specific function call, specific input, network-accessible
  endpoint)?

### Step 2: Check reachability from your code

Search your codebase for the specific API or feature mentioned in the CVE:

```bash
# Example: CVE is in requests' Proxy-Authorization header handling
grep -r "proxies=" src/ scripts/ app/
grep -r "HTTPS_PROXY\|HTTP_PROXY" src/ scripts/ app/
```

Ask: does your code exercise the vulnerable code path? If you never call the affected
function, or if the vulnerability requires an attacker-controlled input that your code never
accepts, the risk is lower — but not zero (a future code change could introduce it).

### Step 3a: If reachable — upgrade immediately

```bash
# Update the pin in requirements.txt
# Then:
pip install -r requirements.txt
pip-audit -r requirements.txt   # confirm finding is cleared
pytest                           # confirm nothing broke
```

Open a PR. Reference the CVE ID in the commit message:

```
fix: upgrade requests to 2.31.0 (CVE-2023-32681)
```

### Step 3b: If not reachable — document accepted risk

Create or update `docs/security-notes.md`:

```markdown
## CVE-2023-32681 — requests proxy credential leak

**Package:** requests 2.28.0
**Fix available in:** 2.31.0
**Date reviewed:** 2026-05-04
**Reviewed by:** name@example.com

**Assessment:** This vulnerability leaks Proxy-Authorization headers when following
redirects across hosts. Our tool does not configure proxies and does not follow
cross-host redirects. The vulnerable code path is not reachable.

**Action:** Upgrade to 2.31.0 at next scheduled dependency update (by 2026-06-01).

**Review date:** 2026-08-01 (reassess if code changes touch HTTP proxy configuration)
```

Set a calendar reminder for the review date. "Not currently reachable" is not permanent
acceptance — it needs to be re-evaluated when the code changes.

### Step 4: If no fix is available

Same documentation as step 3b, plus open a tracking ticket:

```markdown
**Action:** No upstream fix available as of 2026-05-04. Ticket PROJ-1234 tracks this.
Monitor OSV for fix availability. Consider replacing the package if no fix appears
within 30 days.
```

Check the upstream issue tracker for a fix timeline. If the maintainer is unresponsive,
evaluate replacing the package with an alternative.

### Step 5: Record the outcome

Add a one-line entry to a `CHANGELOG.md` or `WORK.md` section tracking security updates:

```markdown
## Security
- 2026-05-04: Upgraded cryptography 39.0.0 → 41.0.7 (GHSA-jfh8-c2jp-5v3q)
- 2026-05-04: Accepted CVE-2023-32681 (requests); not reachable; tracking in PROJ-1234
```

---

## 6. Private package indexes

If your org runs an internal PyPI mirror or private package index (common for proprietary
packages or to avoid pulling from the public internet in CI), configure `pip` to use it.

### pip.conf

```ini
[global]
index-url = https://your-internal-pypi.example.com/simple/
```

Place this in the project's `.pip.conf` or set the environment variable:

```bash
export PIP_INDEX_URL=https://your-internal-pypi.example.com/simple/
```

For CI, set `PIP_INDEX_URL` as a CI environment variable, not hardcoded in scripts.

### --extra-index-url caution (index confusion)

If you need packages from both an internal index and PyPI, the naive approach is:

```bash
pip install --extra-index-url https://internal.example.com/simple/ mypackage
```

**This is dangerous.** `pip` will search both indexes and install whichever version is
higher. An attacker who publishes `mypackage` on public PyPI with a higher version number
than your internal one wins — and pip installs the public (potentially malicious) package.
This is an **index confusion attack** (also called dependency confusion).

Safer alternatives:
- **Use only the internal index** (`index-url`, not `extra-index-url`) if the internal
  mirror proxies PyPI.
- **Pin exact hashes** using `pip install --require-hashes -r requirements.txt`. Generate
  hashes with `pip-compile --generate-hashes`.
- **Namespace internal packages** under an org-specific prefix that is not on PyPI
  (e.g. `myorg-mypackage` instead of `mypackage`).

### Verify the index before trusting packages

Before adding a package from an internal index that you have not used before:
- Confirm the index URL with your platform/infra team
- Check that TLS is enforced (never `http://` for a package index)
- Confirm that the internal mirror signs or proxies from a verified source

---

## 7. Supply chain hygiene habits

Before adding any new dependency to `requirements.txt`, spend two minutes on these checks.
Most bad packages fail at least one.

### Checklist for a new package

- [ ] **Download count:** search `https://pypistats.org/packages/<name>`. Packages with
  fewer than 10,000 monthly downloads warrant extra scrutiny.
- [ ] **Last publish date:** check PyPI. A package last published 4+ years ago may be
  unmaintained. For security-sensitive code (crypto, HTTP, auth), prefer actively maintained
  packages.
- [ ] **GitHub stars and maintainer activity:** look at the linked repository. One maintainer
  with no recent commits and no responses to issues is a risk — if a vulnerability is found,
  no one will fix it.
- [ ] **Package name:** confirm the PyPI name matches the GitHub repo name and that there are
  no obvious typosquats (e.g. `requets` vs `requests`). Check that you are installing exactly
  what you searched for.
- [ ] **Signed releases:** for critical dependencies (crypto, auth, HTTP clients), check
  whether the package uses `pyproject.toml` and publishes release provenance via SLSA or
  Sigstore. This is not universal yet, but is a positive signal.
- [ ] **Transitive dependency count:** `pip install --dry-run <package>` shows what it pulls
  in. A package that brings in 20 transitive dependencies for a minor utility is not worth it.
  Prefer packages with a small dependency footprint for non-critical functionality.

### When to prefer stdlib over a package

For simple tasks, the standard library is the most secure dependency: it ships with Python,
is widely audited, and has no supply chain exposure. Before adding a package, check whether
the stdlib covers the need:

- HTTP: `urllib.request` for simple GET; `requests` or `httpx` for anything more complex
- JSON: `json` (stdlib)
- YAML: `PyYAML` (necessary; no stdlib equivalent)
- Date parsing: `datetime` (stdlib) for most cases; `python-dateutil` only if you need
  complex parsing

---

## 8. SBOM basics

A Software Bill of Materials (SBOM) is a machine-readable list of all software components
in your project. Its primary value is incident response: when Log4Shell was announced, teams
with an SBOM answered "do we use log4j?" in minutes. Teams without one spent days.

### Quick SBOM with pip

```bash
pip list --format=json > sbom.json
```

Output:

```json
[
  {"name": "requests", "version": "2.31.0"},
  {"name": "certifi", "version": "2024.2.2"},
  ...
]
```

This covers all packages installed in the active venv. Regenerate after any dependency
change and commit it alongside `requirements.txt` (or generate it in CI as an artifact).

### SBOM with pip-audit

`pip-audit` can emit CycloneDX format, which is the emerging standard for SBOMs:

```bash
pip-audit -r requirements.txt --format cyclonedx-json > sbom-cyclonedx.json
```

CycloneDX SBOMs are understood by vulnerability scanners and compliance tooling. If your
org has a software asset or compliance system that ingests SBOMs, use this format.

### Using the SBOM during an incident

When a new CVE is announced:

```bash
# Check if you have the affected package
python -c "
import json, sys
sbom = json.load(open('sbom.json'))
affected = [p for p in sbom if p['name'].lower() == 'log4j']
print(affected or 'not found')
"
```

Or search the requirements file directly:

```bash
grep -i "log4j\|requests\|cryptography" requirements.txt requirements-dev.txt
```

---

## 9. License compliance

Dependency licenses matter for internal tools. Some licenses impose conditions that affect
how you can distribute or modify your software. For purely internal tools that are never
distributed outside the org, GPL and AGPL are lower risk than for distributed software —
but they are still worth knowing about.

### Install pip-licenses

```bash
pip install pip-licenses
```

Add to `requirements-dev.txt`:

```
pip-licenses==4.4.0
```

### Run the audit

```bash
pip-licenses --format=markdown
```

Output:

```
| Name          | Version | License                 |
|---------------|---------|-------------------------|
| anthropic     | 0.40.0  | MIT                     |
| certifi       | 2024.2.2| MPL-2.0                 |
| requests      | 2.31.0  | Apache Software License |
| PyYAML        | 6.0.2   | MIT                     |
```

### License risk tiers

| License | Risk for internal tools | Action |
|---------|------------------------|--------|
| MIT, BSD-2, BSD-3, Apache-2.0 | Low | Generally fine; keep attribution |
| ISC | Low | Fine; similar to MIT |
| MPL-2.0 | Low-medium | File-level copyleft; modifications to MPL files must be shared, but you can combine with proprietary code |
| LGPL | Medium | Dynamic linking is generally safe; check with your legal/IP team if in doubt |
| GPL-2.0, GPL-3.0 | High | Strong copyleft; consult legal before using in any tool that is distributed or deployed as a service |
| AGPL | High | Network use triggers copyleft; avoid for internal services without legal review |
| Unknown / UNKNOWN | Review | `pip-licenses` could not detect the license; inspect the package manually on PyPI |
| Commercial / proprietary | Review | Requires a license agreement; confirm you have one |

### Documenting non-standard licenses

If a package has a license outside the Low tier, document it in `docs/security-notes.md`
(or a separate `docs/licenses.md`):

```markdown
## Non-standard licenses

### certifi (MPL-2.0)
- We use certifi for CA bundles only; we do not modify its source.
- MPL-2.0 file-level copyleft does not affect our proprietary code.
- Reviewed: 2026-05-04
```

Run `pip-licenses` as part of your monthly maintenance check and when adding new
dependencies.

---

## 10. Checklists

### Before adding a new dependency

- [ ] Is the package necessary, or does stdlib or an existing dep cover it?
- [ ] Check PyPI download count (pypistats.org) — low count warrants scrutiny
- [ ] Check last publish date and maintainer activity on GitHub
- [ ] Check the package name matches what you searched for (typosquat check)
- [ ] Run `pip install --dry-run <package>` to see transitive deps
- [ ] Check the license with `pip-licenses` after installing
- [ ] Pin the exact version in `requirements.txt` (or `requirements.in` if using pip-compile)
- [ ] Run `pip-audit -r requirements.txt` after adding

### Before each release

- [ ] Run `pip-audit -r requirements.txt` — fix or document any findings
- [ ] Run `pip-licenses --format=markdown` — flag any new non-standard licenses
- [ ] Regenerate `sbom.json` (`pip list --format=json > sbom.json`)
- [ ] Confirm all pins in `requirements.txt` are exact (`==`) with no ranges
- [ ] Confirm `requirements.txt` is committed and `config.yaml` is gitignored

### Monthly maintenance

- [ ] Run `pip-audit -r requirements.txt` — address new CVEs since last run
- [ ] Review open Dependabot / Renovate PRs — merge or document why not
- [ ] Run `pip-compile --upgrade requirements.in` to get latest compatible versions
  (review the diff, run tests, then commit)
- [ ] Review `docs/security-notes.md` — are any "no fix available" entries now fixed
  upstream?
- [ ] Check review dates in accepted-risk entries and reassess if due

### When a CVE is announced publicly (incident response)

- [ ] Search `requirements.txt` and `sbom.json` for the affected package
- [ ] If present: follow the CVE triage workflow (section 5) immediately
- [ ] If not present: record a one-line note in `WORK.md` confirming you checked
  (makes future audits faster)
- [ ] If the CVE affects a production service: follow your org's formal security review / vulnerability response path alongside this technical triage
