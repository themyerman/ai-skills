---
name: supply-chain-integrity
description: >-
  Software supply chain integrity: SLSA levels, Sigstore/cosign artifact
  signing, SBOM generation, dependency integrity verification, incident
  response when supply chain is compromised. Goes beyond scanner tooling
  into provenance and signing. Triggers: SLSA, Sigstore, cosign, SBOM,
  supply chain, artifact signing, provenance, dependency tampering,
  build integrity, software attestation.
---

# supply-chain-integrity

Supply chain attacks target the build and delivery pipeline rather than the running application. The goal: ensure that what you ship is exactly what you built, and that what you built came from what you think it did.

This skill covers provenance, signing, and verification — the layer above "which packages have known CVEs."

---

## SLSA levels

SLSA (Supply chain Levels for Software Artifacts) is a framework for describing build integrity. Four levels:

| Level | What it guarantees |
|-------|--------------------|
| **SLSA 1** | Build is scripted (not manual). Provenance exists but isn't verified. |
| **SLSA 2** | Build uses a hosted, version-controlled build service. Provenance is signed by the builder. |
| **SLSA 3** | Build runs in an isolated environment. Source and build steps are auditable. Provenance is non-forgeable. |
| **SLSA 4** | Two-person review of all changes. Hermetic, reproducible builds. Highest assurance. |

Most teams should aim for SLSA 2 as a baseline. SLSA 3 is achievable with GitHub Actions or similar hosted CI if you use their SLSA generator actions.

### Generating SLSA provenance in GitHub Actions

```yaml
jobs:
  build:
    uses: slsa-framework/slsa-github-generator/.github/workflows/generator_generic_slsa3.yml@v1.9.0
    with:
      base64-subjects: ${{ needs.build.outputs.hashes }}
    permissions:
      actions: read
      id-token: write
      contents: write
```

The generator produces a signed provenance attestation alongside your artifact.

---

## Artifact signing with Sigstore / cosign

Sigstore provides keyless signing using short-lived certificates tied to OIDC identity (your GitHub Actions workflow, your Google account, etc.). No long-lived signing keys to manage.

### Sign an image after building it

```bash
# Install cosign
brew install cosign

# Sign a container image (keyless, using OIDC identity from CI)
cosign sign \
  --yes \
  ghcr.io/your-org/your-image@sha256:abc123...

# Attach an SBOM to the image
cosign attach sbom \
  --sbom sbom.spdx.json \
  ghcr.io/your-org/your-image@sha256:abc123...
```

### Verify a signed image before deploying

```bash
cosign verify \
  --certificate-identity-regexp "https://github.com/your-org/your-repo" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  ghcr.io/your-org/your-image@sha256:abc123...
```

This confirms the image was signed by your CI pipeline, not by an attacker who pushed a malicious image.

### Sign arbitrary files (not just images)

```bash
cosign sign-blob \
  --yes \
  --output-certificate cert.pem \
  --output-signature sig.bundle \
  dist/my-binary

# Verify later
cosign verify-blob \
  --certificate cert.pem \
  --signature sig.bundle \
  --certificate-identity-regexp "https://github.com/your-org" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  dist/my-binary
```

---

## SBOM generation

An SBOM (Software Bill of Materials) lists every component in your artifact — libraries, tools, base images.

### Why

- Know what you're shipping before someone else tells you.
- When a new CVE drops, you can immediately answer "are we affected?"
- Increasingly required for regulated industries and enterprise customers.

### Generate with syft

```bash
# Install syft
brew install syft

# SBOM for a Python project
syft . -o spdx-json > sbom.spdx.json

# SBOM for a container image
syft ghcr.io/your-org/your-image:latest -o spdx-json > sbom.spdx.json

# SBOM for a directory with multiple package managers
syft dir:. -o cyclonedx-json > sbom.cyclonedx.json
```

### Scan SBOM for vulnerabilities with grype

```bash
brew install grype

# Scan directly from SBOM
grype sbom:sbom.spdx.json

# Or scan the image directly
grype ghcr.io/your-org/your-image:latest
```

---

## Dependency integrity verification

Before running or deploying, verify that dependencies haven't been tampered with between the lock file and what's actually installed.

### Python — hash pinning

```bash
# Generate requirements with hashes
pip-compile --generate-hashes requirements.in > requirements.txt

# Install — pip verifies hashes automatically
pip install --require-hashes -r requirements.txt
```

Example output:
```
Django==4.2.7 \
    --hash=sha256:abc123... \
    --hash=sha256:def456...  # multiple hashes cover different wheel variants
```

### Node — lockfile integrity

npm and yarn both embed integrity hashes in their lockfiles. Never skip the lockfile in CI:

```bash
# Install exactly what the lockfile says — error if anything differs
npm ci   # not npm install
```

### Detect dependency confusion attacks

Dependency confusion: an attacker publishes a malicious package to PyPI/npm with the same name as an internal package, hoping your installer picks it up.

Mitigations:
- Use a private registry for internal packages with a `--index-url` or `.npmrc` that sets the registry explicitly.
- For Python: set `--extra-index-url` to check PyPI as a fallback only, not primary.
- Enable Trusted Publishing on PyPI for your own packages (ties release to a specific GitHub Actions workflow).

---

## Incident response: suspected supply chain compromise

If you suspect a dependency or build artifact has been tampered with:

1. **Freeze.** Stop deploying. Put up a maintenance page if needed.
2. **Identify the blast radius.** When was the compromised version first used? What deployments are running it?
3. **Pull the affected artifact.** Remove from registry, revoke from CDN, block the version in your package manager config.
4. **Forensics.** Compare running artifact against the expected hash. Diff the compromised dependency against the known-good version.
5. **Rotate.** Any credentials, tokens, or secrets that ran in the affected environment should be considered compromised. Rotate them.
6. **Rebuild from clean state.** Build fresh from a known-good source commit in a clean CI environment.
7. **Post-incident.** Document what happened, what was exposed, and what controls would have caught it earlier.

---

## Related

- Known CVEs in dependencies (scanner tooling): [`dependency-security`](../dependency-security/SKILL.md)
- Full vulnerability lifecycle after discovery: [`cve-lifecycle`](../cve-lifecycle/SKILL.md)
- CI/CD pipeline integrity: [`ci-cd-pipelines`](../ci-cd-pipelines/SKILL.md)
