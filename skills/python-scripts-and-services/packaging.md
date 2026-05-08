# Packaging and distribution (internal tools)

<!-- Use when a script grows into something **`pip install`’d** or you publish a **console script** to an internal index. `pyproject` vs requirements: [reference.md](reference.md) §3. -->

Most repos start as **clone + venv + `pip install -r requirements.txt`**. This note is for the **next step**: installable **package** layout, **entry points**, and **publishing** without over-engineering a library.

---

## 1. When to package

- **Multiple** `scripts/*.py` that **import** the same `src/` modules in **ad hoc** `PYTHONPATH` — time for **`pip install -e .`** in dev.  
- **Console commands** for operators: e.g. `triage-issues` → `mypackage.cli:main`.  
- **Version pinning** in **one** place (`pyproject` **or** `requirements` — see [reference](reference.md) *pyproject.toml vs requirements.txt*).

**Don’t** package a **one-file** 40-line tool unless a **second** user already asked for it.

---

## 2. Minimal `pyproject.toml` (Hatch / setuptools)

- **Project** metadata: `name`, `version` (or **`dynamic` from** `setuptools_scm` if you standardize on tags), `requires-python >= 3.11` (or your org floor), **`dependencies = [...]`** direct deps.  
- **`[project.scripts]`** for CLIs: `mytool = "mypkg.cli:main"`. **Avoid** a **huge** entry surface — **one** main, **subcommands** via `argparse` or **Typer** if you like.  
- **`[tool.hatch.build.targets.wheel] packages = ["src/mypkg"]`** (or `src` layout) — keep **`src=`** the **importable** tree; `scripts/` can stay for **ad hoc** or move into **`mypkg.cli`**.

---

## 3. Layout: **`src` layout** for the package

- If you use **`src/mypackage/`** as the **import root**, you **can’t** accidentally `import` from a **stale** checkout path as easily as with **flat** layout. The [reference](reference.md) **§1. Project structure** already says **`src/`** for product logic.  
- **Tests** `tests/` importing **`mypackage`** with **`pip install -e .` in CI** — **mirrors** production.

---

## 4. Dev vs production deps

- **`[project.optional-dependencies] dev`**: `pytest`, `ruff`, `mypy` — `pip install -e ".[dev]"`.  
- **Prod** `Dockerfile` / venv: **`pip install .`** (no `dev`).

---

## 5. Internal index (Artifactory, etc.)

- **Build** wheel: `python -m build` → `dist/*.whl`. **Upload** with your org’s **token**; **do not** commit **`.pypirc`** with secrets.  
- **Name** the package with a **clear prefix** (e.g. `wd-triage-helper`) to avoid **PyPI** collisions; internal indexes often use **`--extra-index-url`**.

---

## 6. Versioning

- **Calendar** or **semver** — pick one per repo and **stick**; `README` the **version** in `main.py -h` is nice for “what ran in cron.”

---

## 7. What stays out of packaging

- **Internal** tools: **data/** and **config.example** stay in the **repo**; `pip` ships **code**, not **50MB** CSV. Use **`importlib.resources`** when you need **one** default **data** file in the **wheel** (rare for internal tools).

---

## 8. Checklist

- [ ] **`src/`** (or clear **single** import root)  
- [ ] **`[project.scripts]`** for **intended** operator CLIs  
- [ ] **Dev** extras for **ruff/pytest**  
- [ ] **CI** `pip install -e ".[dev]"` then **pytest**  
- [ ] **No** secrets in **any** `toml` committed
