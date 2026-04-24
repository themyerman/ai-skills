---
name: web-frontend-basics
description: >-
  **Read first** in the web trio: **web-frontend-basics** → **web-layout-css** →
  **web-accessibility** (see Related). Semantic HTML, forms, small JS, fetch+JSON
  boundary, Jinja+Flask pointer. Triggers: template, Jinja, static JS, form,
  progressive enhancement, fetch, CSRF, internal UI (not a large SPA). Server:
  python-internal-tools flask-serving; visuals: web-layout-css; a11y:
  web-accessibility.
---

# web-frontend-basics

## What this is

**Browser-side** building blocks for **server-rendered** or **light-JS** internal tools: **HTML** that means something, **forms** that fail accessibly, and **JavaScript** that stays small and testable. For **Flask routes, Jinja, auth, headers,** and **`static/`** layout, use **[`python-internal-tools` / `flask-serving.md`](../python-internal-tools/flask-serving.md)**. For **layout and CSS**, see **[web-layout-css](../web-layout-css/SKILL.md)**. For **WCAG and keyboard**, see **[web-accessibility](../web-accessibility/SKILL.md)**.

## When to use

- New or refactored **templates** + **static** JS/CSS for an internal tool
- **Forms** (search, filters, admin actions) with or without a **JSON** API
- **Reviewing** a page for “valid HTML but wrong semantics” or **inline** script sprawl

## When to stop and use something else

- **Full** React/Vue/Svelte app with bundler, router, and state store → follow your org’s **frontend platform**; this skill only helps at the **edges** (a11y, forms, fetch).
- **Design system** tokens and **Figma** handoff → document org standards; [web-layout-css](../web-layout-css/SKILL.md) has generic **CSS** patterns.
- **Python** HTTP clients, Jira, secrets → **python-internal-tools** / **security.md**.

## Reference

- **[reference.md](reference.md)** — patterns, checklists, and “don’t do this” for HTML/JS in internal UIs.

## Default reading order (web trio)

1. **This skill** — structure and behavior (HTML, forms, small JS).  
2. [**web-layout-css**](../web-layout-css/SKILL.md) — layout and CSS.  
3. [**web-accessibility**](../web-accessibility/SKILL.md) — WCAG-style pass (keyboard, contrast, ARIA).

**Server-side** (routes, `static/`, auth, headers): [**flask-serving**](../python-internal-tools/flask-serving.md) in **python-internal-tools**. Repo-level chart: [`SKILLS.md`](../../SKILLS.md#web-ui-default-reading-order) in **ai-skills**.

## Related

- **web-layout-css** — flex/grid, responsive, component-ish patterns (step 2)  
- **web-accessibility** — keyboard, ARIA, focus, contrast (step 3)  
- **python-internal-tools** — **flask-serving.md**, **security.md**

## Source

Authored for **ai-skills**; **not** a slice of **`.claude/CLAUDE.md`**. **Pair** with [flask-serving](../python-internal-tools/flask-serving.md) and your project’s `templates/`, `static/`.
