# READMEs and project front doors

**Hub:** [SKILL.md](SKILL.md) · **Principles:** [reference.md](reference.md) · **Python layout:** [python-scripts-and-services / documentation.md](../python-scripts-and-services/documentation.md)

A **root `README.md`** is the first thing a **human** and many **tools** read. It should make the **next step** obvious.

## 1. What belongs in a root README

| Section | Include |
|---------|---------|
| **What** | One **paragraph**: what the project **does** and **who** it is for (not internal history). |
| **Why** (optional) | If non-obvious, **one** sentence on **when** to use this vs **alternatives**. |
| **Quickstart** | **Copy-paste** commands: clone, venv, install, **one** command that proves it works. |
| **Config** | Point to **`config.example.yaml`** or **env** vars with a **table** of **name / required / default**. |
| **Docs** | Links to `docs/`, **operator** runbooks, or **deeper** install if quickstart is “happy path” only. |
| **Contribute** | How to **run tests** and open a PR, if external or multi-team. |

**Avoid:** **Paste-only** Confluence in place of a README—duplicate **truth** in-repo or state **one** **canonical** link. **Avoid** a **novel** before the first code block unless the project is **research** with no runnable artifact.

## 2. First screen rule

- **Reader** in **2 minutes** can answer: **What is this?** **How do I run the main path?** **Where is config?**  
- If **strangers** (new hire, other team) are **in scope**, the **top** of the **README** must work **without** a **private** wiki.

## 3. Tone

- **Friendly** and **confident**; no **apology** for “rough” if you ship: say **“Known limitations”** in **one** place instead.  
- **Same** **must/should** discipline as [reference](reference.md). For **plain**, **layman-friendly** **wording** without being **cute** or **wordy**, see [plain-english](plain-english.md).

## 4. `WORK.md` and README

- **`WORK.md`**: **running** **decisions**, **backlog**, “what we shipped this week” — not a second README. [documentation.md](../python-scripts-and-services/documentation.md) describes the **split** for **Python** repos.  
- **No** full **duplicate** of the quickstart: **link** the README from **WORK** for **onboarding**.

## 5. Checklist (new or overhauled README)

- [ ] **Title** and **one-line** description **match** the **repo** name and **reality**  
- [ ] **Prereqs** (language version, **OS** if you only tested one) **above** the first **install** command  
- [ ] **Commands** work from a **clean** **clone** (not only from your **laptop**)  
- [ ] **Config** and **secrets** : **no** **real** tokens; **link** to **example** and **env** table  
- [ ] **Troubleshooting** for the **one** most common **failure** (path, auth, version) or **link** to **`docs/troubleshooting.md`**

## 6. When to add more files

- **Long** **install** or **enterprise**-specific paths → [installation-guides](installation-guides.md) in **`docs/`**; README **teases** and **links**.  
- **SOPs** for **operators** → [user-instructions-howto](user-instructions-howto.md).

## 7. Executive-facing summary

- If the **README** is a **teaser** for a **narrative** for **leads**, the **narrative** may belong in [executive-reports](../executive-reports/SKILL.md); keep the **repo** **README** **factual** and **runbook**-leaning.
