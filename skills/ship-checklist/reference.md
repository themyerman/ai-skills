# Major change readiness — full checklist

Use before **merging** a **large** or **security-relevant** change. **Check** every box that applies; **N/A** with **one**-line reason is fine.

---

## Automation

- [ ] **`pytest`** (or project test entrypoint) — **all** tests **green** locally  
- [ ] Same **job** (or documented **subset**) you expect **CI** to run — **no** drift vs `.github/` / Jenkins / etc.  
- [ ] **`ruff`** / **`flake8`** / **`mypy`** — **green** if the repo enforces them  
- [ ] **No** new **`xfail`** without **ticket** and **owner**  
- [ ] **Secrets scan** in CI or locally per **[`secrets-scanning-ci.md`](../python-internal-tools/secrets-scanning-ci.md)** (if not already in pipeline)

---

## Documentation

- [ ] **`README.md`** — install, **flags**, **config** example, **copy-paste** command still accurate  
- [ ] **`WORK.md`** — updated if **decisions** / **backlog** / **ops** context changed (if file exists)  
- [ ] **`docs/`** — runbooks, **ADRs**, or **API** notes updated for **new** **failure** or **operator** paths  
- [ ] **`config.example.yaml`** (or env template) matches **new** **keys** / **defaults**

---

## Security & threat modeling

- [ ] **Threat model** (or equivalent in **`docs/`**) **updated** if **trust boundaries**, **data**, or **sensitive** flows changed — or a **security ticket linked** with an explicit "TM **follow-up**" plan; follow your org's formal security review intake when required  
- [ ] **No secrets** in diff; **PII** / **classification** in **logs** and **exports** reviewed per **[`data-handling-pii`](../data-handling-pii/SKILL.md)** where relevant  
- [ ] **Optional** but recommended: quick pass **[`security-code-audit.md`](../python-internal-tools/security-code-audit.md)** for **SAST** / **deps** / **manual** hotspots

---

## API & performance (when applicable)

- [ ] **Public HTTP** surface — **[`api-http-service-design.md`](../python-internal-tools/api-http-service-design.md)** (errors, **idempotency**, **versioning**) reviewed if routes or contracts changed  
- [ ] **Performance** — **critical** paths: new **N+1**, **unbounded** queries, or **hot** loops have a **plan** (test, **benchmark**, or **ticket**)

---

## Human / process

- [ ] **Reviewers** named; **blockers** from **[`code-review.md`](../python-internal-tools/code-review.md)** addressed or **documented**  
- [ ] Formal org **security / privacy / RAI intake** considered when your policy requires it (not every PR)

---

*Part of **[`SKILL.md`](SKILL.md)** in **major-change-readiness**.*
