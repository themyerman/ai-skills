# Installation and environment guides

**Hub:** [SKILL.md](SKILL.md) · **Principles:** [reference.md](reference.md) · **Root README** surface: [readmes.md](readmes.md)

**Installation** documents get a machine from “nothing” to “can run the software.” They are not marketing copy.

## 1. Structure (recommended order)

1. **Prerequisites** — OS, language **runtime** versions (pin if the project is sensitive to them), accounts (VPN, artifact registry, cloud CLI) if needed before `pip` works.
2. **Get the code** — clone, submodules, default branch, optional shallow clone.
3. **Dependencies** — **one** blessed path: `uv` *or* `pip` *or* `poetry`—if you support more than one, state **when** to use which.
4. **Configuration** — copy `config.example.yaml` → `config.yaml` (or env pattern); table of **keys** with **required** / default; no real **secrets** in the doc.
5. **Verify** — a **command** with **expected** output (even one line) so the reader can confirm success.
6. **If install fails** — top 2–3 **symptoms** and **fixes** (missing compiler, SSL/CA, wrong Python on `PATH`).
7. **Optional: clean uninstall** — remove venv/caches without deleting user data dirs.

## 2. Version truth

- **Last verified on** … with **OS** and **runtime** version.
- If you support **multiple** tracks (e.g. LTS vs current), use **separate** subsections; do not jumble in one paragraph.

## 3. Air-gapped, production, and enterprise

- If **air-gapped** install is a real use case, document it or name the **owning** team. If you do not know that path, say **out of scope** and who to ask (IT, platform).
- **Production** deploys (systemd, Kubernetes, reverse proxy) belong in a **dedicated** section; link from the README in **one** line. Keep **dev** quick path short.

## 4. Containers

- `Dockerfile` and image tags in the **doc** should **match** CI. Document **volumes** for **config** vs **data** separately.

## 5. Checklist

- [ ] No **secret** literals; examples only
- [ ] Every **hard** prereq has a “how to check” (`python --version`, `docker version`, …)
- [ ] **Verify** step at end of main path
- [ ] **Failure** section or link to a troubleshooting page
- [ ] **Upgrades** — table of breaking changes (from version → to version) or link to `CHANGELOG`

## 6. After install

- Point to **[user-instructions-howto.md](user-instructions-howto.md)** for *doing the job*. Install stops when the app or service is **healthy**.
