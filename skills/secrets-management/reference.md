# Reference: secrets management (broad eng)

**Hub:** [SKILL.md](SKILL.md) · **Python code practices:** [python-scripts-and-services / security.md](../python-scripts-and-services/security.md)

**Your org:** Your employer’s **published** policy **index** is the source of truth for **password/secret** management, **Application Security** (e.g. secrets in **CI**/**CD**), **Acceptable Use** (credentials in **Slack**/**email**), and **encryption** / key rules. [SKILL.md](SKILL.md) is a **router** only. If a detail in this file and that source disagree, **the source wins**.

---

## Your organization: “where do I get a key?” (placeholder for maintainers)

> Add **durable** **internal** links: approved **store** (Vault, cloud **KMS**, and so on), how to get access, on-call or **Security** for exposure, and your **K8s** or **PaaS** pattern for **injected** **secrets** **.**
> Keep in sync with [Your organization: read current policy in SKILL.md](SKILL.md#your-organization-read-current-policy-your-portal-wins).
> The rest of this file is **general** engineering practice; confirm **policy**-binding **detail** with **house** runbooks.

---

## 1. What counts as a secret (non-exhaustive)

- **API keys** and **PATs** (Git, Jira, cloud providers, LLM providers)
- **Database** passwords, **connection strings** with embedded creds
- **TLS** private keys, **signed URL** parameters that grant access, **webhook** signing secrets
- **Session** cookies, **OAuth** **refresh** tokens, **long-lived** bearer tokens
- **K8s** **ServiceAccount** tokens, **CI** **deploy** keys, **SaaS** integration secrets

**Treat as sensitive:** anything that **authenticates** a human or system, or **grants** **write** or **exfil** capability.

---

## 2. Collaboration channels: hard rules

These patterns cause **the most** real-world exposure (email, wikis, **Slack**, DMs, **Jira** descriptions).

| Channel | Why it fails | Do instead |
|---------|----------------|------------|
| **Slack** (incl. threads, huddles, snippets) | Searchable, exportable, retention varies; **bots** and **integrations** may see content | **Never** post raw secrets. Use **org-approved** grant flow; **1:1** with **ephemeral** delivery only if runbook says so; **revoke/rotate** if posted |
| **Email** | Forwarding, **indefinite** retention, wrong recipient | **Do not** email secrets. **Rotate** if sent. Use **store + access** or **tickets** that only reference **resource name**, not value |
| **Wiki** | Durable, indexed, **wide** readership, hard to **purge** from caches | Document **name** of secret in vault, **who approves access**, runbook link—not the **value**. **Never** “save for the team” as a code block of keys |
| **Jira** / **tickets** | **Long-lived** ticket history, **many** viewers | **Redact**; attach evidence as **“completed in system X”** not raw tokens. If a key was **ever** pasted, **rotate** and note exposure per process |
| **LLM / chat** (incl. coding assistants) | **Training, logging, and support** policies vary; treat as **untrusted for secrets** | **Do not** paste **production** creds. Use **mock** or **ephemeral** dev creds; **revoke** anything accidentally pasted |
| **Screenshots and screen share** | Keys in **env bars**, **Postman**, **browser** **storage** | **Redact** before share; use **separate** demo data |

**Heuristic:** if it would be awkward in an **all-hands** slide, it should not be in a **durable** collaboration system as plaintext.

---

## 3. Application code, repos, and developer workflow

This section is the **main coding** complement to collaboration and runtime injection: **where** secrets leave **fingers and editors** and **enter** **running** code and **pipelines**—**without** landing in **git**, **images**, or **test** output.

### 3.1 Configuration in source (language-agnostic)

- **Single load path** at process start: read **env** and/or your org’s **secret file mount** in **one** `config` / `settings` module (or your stack’s equivalent). **Avoid** scattered `getenv` calls deep in the call stack—**harder** to audit and to mock in tests.
- **No real secrets as defaults** in code: a **missing** required credential should **fail fast** on boot, not default to a string that “works on someone’s laptop.”
- **Never** put access tokens, passwords, or **HMAC** keys in **query strings** or user-visible **URLs**; **headers** or **body** (server-side) per API contract, and log **redacted** URLs.
- **Separate** **dev/stage/prod** **principals** and **key material** when the platform allows; **one** long-lived key for **every** environment is a **rotation** and **blast-radius** **problem**.

### 3.2 Local development

- **`.env`** (or your stack’s local override): **gitignored**; list **only** the **names** of required variables in **`.env.example` / `env.example` / `config.example.*`** with **placeholder** or **obviously fake** values. **Document** in README **how** to get **real** dev creds (usually **not** by copying a teammate’s `.env`).
- **`.pem`,** **`.key`,** **`*.p12`**, and similar: **default** to **gitignore**; **path** in config, **file** on disk, **file** from store in prod.
- **IDE / editor:** do **not** check in **API keys** inside **`.vscode/`**, **JetBrains** run configs, or **“share”** JSON that contains tokens.

### 3.3 Tests and test fixtures

- **Tests** use **fakes** or **short-lived** **test** credentials from a **dedicated** **test** identity, **or** **mocked** I/O (e.g. HTTP) at the **boundary**—**not** production **PATs** in `conftest` or `setup`.
- **Commit**able JSON fixtures: **redact**; use **synthetic** tokens. If a capture was **scanned** from a **real** system, **rotate** anything that was ever **live** in a dev environment that touched prod-adjacent systems.
- **Snapshot** tests: ensure **no** real keys in **vcr**-style cassettes (or use **redacting** re-record flows).

### 3.4 Docker, OCI, and “build time”

- **Do not** `COPY` **`.env`** or **key files** into the **image** unless the image is **only** for **local** use and **never** **pushed**; **default** is **runtime** **env** and **platform**-mounted **secrets**.
- **Build args** that end up in **layer** **history** can **leak**; treat **as bad** as plain text in repo. Prefer **runtime** injection in real deploy paths.
- **K8s:** `Secret` **references** in manifests are **ok**; **the actual value** in **git**-committed **plain** YAML is **not**. Use **sealed**/**external** **secrets** if your org requires.

### 3.5 Continuous integration and deployment

- **CI** should pull credentials from the **CI platform’s** **secret** store, **not** from **ciphertext in repo** and **not** from **unencrypted** static vars in **public** YAML.
- Prefer **OIDC** / **federated** identity to the cloud (and short-lived **STS**-style creds) over **static** `AWS_ACCESS_KEY` in a **5-year** **PAT** on a service account—when the platform supports it; align with your **org’s** **standard**.
- **Fork PRs** from **untrusted** contributions: **do not** run workflows that **inject** **production** secrets; use **repositories** and **rules** that scope secrets to **protected** **branches** / **internal** PRs only, per your **platform** guidance.

### 3.6 Repository and dependency hygiene

- **Lockfiles** and **.npmrc**-style “auth to private registry” often tempt **auth in URL**; use **per-user** or **CI**-scoped **creds** that **are not** the **default** in every **clone**.
- **Pre-commit** and **server-side** **secret scanning** (e.g. `gitleaks`, `trufflehog`, `detect-secrets`, vendor **GitHub** **secret** **scanning**): **treat** findings as **block** until **rotated** if real.
- If a key **touched** **git** **history** (even reverted on `main`), **rotate** the credential; **“delete file”** commit is **not** enough for **a leaked** value.

### 3.7 Frontends, mobile, and public clients

- **Browsers and apps** you ship to users: **no** long-lived **API** **keys** to **core** **systems** **embedded** in the bundle. **Backend-for-frontend** or **device**-scoped tokens with **tight** **TTL** and **revocation**; **align** to **appsec** review for your org.
- **Public** **repos** and **gist**-style shares: same rules as “prod”—**nothing** that authenticates to your **org** or **partners** **'** **systems** **.**

### 3.8 Python (and when to go deeper)

For **Jira** clients, **Flask**, `requests.Session`, and **file**-based `config` patterns, **use** [python-scripts-and-services / security.md](../python-scripts-and-services/security.md) and [jira.md](../python-scripts-and-services/jira.md) as the **code-level** **canonical** add-on to **this** skill.

---

## 4. Storing and injecting (where values *should* live)

Align with your org’s **one** or **few** **approved** mechanisms. Typical layers (wording is generic; **replace** with your internal standard):

| Layer | Pattern |
|-------|--------|
| **Central store** | **Managed** vault / cloud secret manager / **internal** equivalent—**IAM**, **time-bound** access, **auditing** |
| **App runtime** | **Inject** at start (**env** from platform, **sidecar**, **CSI**), **file** from mounted secret—**not** in **image** layers or **git** |
| **CI (GitHub Actions, Jenkins, etc.)** | **Platform** **secrets**; **no** long-lived tokens in `yaml` in repo. **Scope** to job/repo; **rotate** on people leaving |
| **K8s** | **`Secret`** (and **sealed** or **ESO**-style if your org uses them), **not** `values.yaml` in git. **RBAC** who can `get secret` |
| **Local dev** | **`.env`** **gitignored**; `env.example` or `.env.example` with **fakes**; some teams use **dev-only** **short-lived** creds from the same **store** as prod patterns |

**Anti-patterns to flag in review:** “temporarily” **hardcode**; **Base64 in git** = still a secret; **“private”** repo = **not** access control for keys.

---

## 5. Logging, metrics, and support

- **Never** log **headers** with `Authorization`, `Cookie`, **API-Key** (full value).
- **Sanitize** **URLs** that might embed **query tokens** (`?access_key=...`).
- **Troubleshooting:** prefer **last 4** of a key, **id** in vault, **time range** of failure—not **replaying** a secret in **Splunk** / **Datadog** messages to colleagues.

---

## 6. Code and PR review gates

- **Block** new literals that **look** like **JWTs**, **long** hex blobs, or **`glpat-` / `sk-` / `xoxb-` style** **prefixes** unless clearly **test fixtures** in `tests/`.
- **`git` history:** if a secret was **committed**, **removing** it in a later commit is **insufficient**—**rotate the credential** and use org **history cleanup** or **BFG**-style process if required; ask **Security** for the standard.
- **Dependabot** / SCA: separate concern, but **leaked** keys in **open** repos are a **P0** rotation.
- **Rubric for reviewers:** (1) **any** new **string** that could be a **key**—verify **provenance**; (2) **any** new **outbound** **URL** in logs; (3) **any** new **file** in repo that’s **key-shaped**.

---

## 7. If a secret may be exposed

**Order of operations (adapt to your runbook; not legal/security advice as a process):**

1. **Stop** the bleeding: **no more** **copying** the same value into new places.
2. **Rotate** the credential in the **issuer** (PAT **revoke**, key **rollover**, **password** change) as soon as practical. **Scope** the **smallest** rotation if the platform allows (one PAT not all).
3. **Record** the incident in the **org’s** channel (often **internal** **security** **queue** or **P1**), **not** the **full** secret in the ticket.
4. **Assess** who could have seen it (**channel** membership, **forwarding**, **external** if email).
5. **Re-deploy** with **new** **material** where the old value was in **env** or **store**.

**Jira/Slack copy (example shape):** “PAT for service **X** was pasted in #channel; **revoked** and **replaced**; **deployed**; **this** message has **no** token body.”

---

## 8. Checklists

### 8.1 New service or integration

- [ ] **Name** the secret in the **store** (no **surprise** **shared** passwords across **unrelated** services).
- [ ] **Shortest** **TTL** the platform allows for **that** use case; **separate** **dev/stage/prod** **identities** where required.
- [ ] **No** **plaintext** in **wiki**/**Slack**/**email**; **onboarding** doc = **where** to **get** access.
- [ ] **Deploy path** does not **bake** into **image**; **injection** path is documented.

### 8.2 Before posting in Slack / **wiki**

- [ ] Is this a **value** (key, cert body, full connection string with password)? **→ Do not post.**
- [ ] Can I use a **name**, **ID**, or a pointer to the **event** (“rotated in system X”)? **→ Yes.**

### 8.3 PR: author and reviewer (coding)

- [ ] **No** new **secrets** in **code** or **tracked** **config** (except **obvious** test doubles in `tests/` or **redacted** fixtures).
- [ ] **Logging** and **error** **paths** do not **print** full **requests** or **query** strings with tokens.
- [ ] **.gitignore** covers **local** **secret** files; **`.env.example`** **lists** all **required** **vars** with **fakes** only.
- [ ] **Docker/CI** does **not** add **key** **material** to **layers** or **public** **workflow** context for **untrusted** PRs.
- [ ] **If** a **VCR**/fixture was **refreshed**, **re-scan** for real **substrings** that match **PATs** or **bearer** tokens.

---

## 9. Calibrate to your org

**Maintainers:** when you have **internal** sources, add **durable** links in [Your organization: “where do I get a key?”](#your-organization-where-do-i-get-a-key-placeholder-for-maintainers) and in the onboarding / runbook prose in **§2** and **§3** so readers have one obvious place to look.

*Authored for the **ai-skills** bundle; verify against internal **policy** and **platform** owners.*
