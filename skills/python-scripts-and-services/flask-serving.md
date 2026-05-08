# Flask: serving an internal read-mostly web UI

<!-- Typical layout: `app/`, `templates/`, `static/`, `run_app.py`. For HTTP *clients* (Jira, etc.) see [security.md](security.md). This file is the **browser-facing** side: Flask + Jinja, auth, headers, layout. -->

Internal tools often need a **small, server-rendered** UI: browse data, run exports, and trigger work without building a SPA. The patterns below are **generic**—**adapt** names and routes to your project.

**Browser** side (templates + `static/`): read **[web-frontend-basics](../web-frontend-basics/SKILL.md) → [web-layout-css](../web-layout-css/SKILL.md) → [web-accessibility](../web-accessibility/SKILL.md)** — chart: [`SKILLS.md`](../../SKILLS.md#web-ui-default-reading-order).

---

## 1. Project layout (keep the split)

- **`app/`** — Flask **factory**, **route registration**, **Werkzeug/Flask** only. It should **import business logic** from **`src/`**, not embed scoring rules in route functions.
- **`src/`** — Scoring, DB, Jira, config — **no** Flask imports in core modules when you can avoid it (keeps `pytest` and reuse easy).
- **`templates/`** — Jinja2; use a single **`base.html`** with `{% block title %}`, `{% block content %}`, `{% block head %}`.
- **`static/css`**, **`static/js`**, images — versioned with the app; use **`url_for('static', ...)`** in templates.

`run_app.py` (or `wsgi.py`) is the **thin entry** that calls `create_app()` and, in dev, `app.run()`.

---

## 2. App factory and config

- **`Flask(__name__, template_folder="...", static_folder="...")`** with paths **relative to the app package** (a common choice is `../templates` from the `app` package when templates sit beside `app/`).
- Pass **`config_overrides`** in tests; avoid a single global for secrets — load from the same `config.yaml` / env pattern as the rest of the tool [security.md](security.md).
- **Production:** run with **gunicorn** (or similar) and **`FLASK_DEBUG=0`**. Bind address and `PORT` via env. Put **TLS** and rate limits at a **reverse proxy** when the UI is on a network, not in debug mode.

---

## 3. Authentication (internal, optional Basic)

For **low-risk internal** UIs, **HTTP Basic** over TLS is a common choice:

- Read password from **config** (not hardcoded) — see **security** guide.
- Compare the presented password in **constant time** (e.g. **HMAC-compare of digests** of UTF-8 bytes) so a naive string compare can’t **leak** timing. Example: `hmac.compare_digest(sha256(a), sha256(b))` in `app/__init__.py`.
- **Exempt** health checks from auth so load balancers can probe: e.g. **`request.path == "/health"`** → return `None` in `before_request` (or dedicated exempt list).
- Document that Basic sends credentials **on every** request; treat the network as **controlled**; prefer **SSO** or **mTLS** if policy requires it for your org.

---

## 4. Security headers

Set **default** headers on every response in **`@app.after_request`**, at minimum:

- **`X-Content-Type-Options: nosniff`**
- **`X-Frame-Options: SAMEORIGIN`** (or a stricter frame policy that matches your app)
- **`Referrer-Policy: strict-origin-when-cross-origin`**
- **`Permissions-Policy`** with sensitive features **disabled** unless you use them (e.g. `geolocation=(), microphone=(), ...`)

Tighten further with a **CSP** when you add inline script or untrusted content — not shown in the minimal exemplar, but add before embedding third-party JS.

---

## 5. Jinja2 and pages

- **`{% extends "base.html" %}`** on every page; put shared **nav** and **footer scripts** in `base.html` (e.g. nav, health check, search form, table helpers).
- Use **`url_for('route_name', ...)`** for links and forms so renames don’t break paths.
- **User-controlled text** in HTML must be **auto-escaped** (Jinja default for `{{ }}`. Use `| e` or Markup only when you *intend* raw HTML, and only after sanitize/trust).
- For **search/query** args, **normalize and allowlist** in Python in your route layer — don’t pass raw `request.args` into SQL or file paths.
- **CSV/exports:** build with **`io.StringIO`** or **`io.BytesIO`**, return **`Response(mimetype="text/csv", ...)`** with a sensible `Content-Disposition` filename. Keep export logic in **`src/`** or a small helper testable without Flask.

---

## 6. Database and request scope

- Use **Flask `g`** and **`teardown_appcontext`** to open/close one DB **connection per request** (or use a **pool** with the same lifetime rules). **Don’t** rely on a global open connection in multi-worker production.
- **`@app.context_processor`** for data needed on many pages (e.g. nav badges); **swallow** rare failures in nav so a bad **health** query does not **500** every page — return a **safe** default and log (common pattern: try/except around global health in a context processor with a fallback dict).

---

## 7. Subprocesses from the web layer

If routes shell out to the **CLI** (e.g. “run a batch job”):

- **`subprocess` with a list of args, `shell=False`**; never build a shell string from `request` values [security.md](security.md).
- **Prefer** a **queue** or **cron** for long work so HTTP doesn’t time out; return **202 + job id** or redirect to a **status** page if you add that pattern.

---

## 8. What this doc is *not*

- **Not** a product **design system** — for **HTML/CSS/JS** and **a11y** habit layers, use **[`web-frontend-basics/`](../web-frontend-basics/SKILL.md)**, **[`web-layout-css/`](../web-layout-css/SKILL.md)**, and **[`web-accessibility/`](../web-accessibility/SKILL.md)**; add org-specific design tokens on top.
- **Not** a full **CSRF** treatise — for **GET-only, read-only** UIs, risk is low; for **state-changing** `POST` forms, add **CSRF tokens** (Flask-WTF or hand-rolled) and `SameSite` cookies as your policy requires.
- **Not** a replacement for your org’s **formal** **security** or design review; this file is about **serving the tool** only.

---

## File map (illustrative—rename to your package)

| Area | Example path in your repo |
|------|----------------------------|
| App factory, auth, headers | `app/__init__.py` |
| Routes, DB, CSV | `app/routes.py` |
| Base template | `templates/base.html` |
| Run / WSGI entry | `run_app.py` or `wsgi.py` |
| Hardening notes | root `README.md` or `docs/web.md` |

If your internal UI grows **large**, consider a **dedicated** frontend later; for many Jinja pages, this stack stays **maintainable** when you keep **logic in `src/`** and **routes thin**.
