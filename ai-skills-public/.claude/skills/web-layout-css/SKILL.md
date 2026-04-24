---
name: web-layout-css
description: >-
  **Second** in the web read order: **web-frontend-basics** → **this** →
  **web-accessibility**. CSS flex/grid, spacing, responsive, tables/cards, print;
  vanilla or design-system-agnostic. Triggers: stylesheet, static/css, layout,
  breakpoint, Jinja class soup, two-column, data table, print PDF. For HTML/JS
  first: web-frontend-basics; for a11y: web-accessibility. Flask: flask-serving.
---

# web-layout-css

## What this is

**CSS** patterns for **internal** tools: **readable** sources, **consistent** spacing, **responsive** without a heavy framework. You may still use **your org** design system; this doc gives **portable** defaults. **Not** a course in every CSS property—focus on what **fails in production**: overflow, z-index battles, **unusable** small tap targets, **print** for exports.

For **HTML structure** and **JS**, use **[web-frontend-basics](../web-frontend-basics/SKILL.md)**. For **contrast, focus, keyboard**, use **[web-accessibility](../web-accessibility/SKILL.md)**. For **Jinja, static, Flask**, use **[`flask-serving.md`](../python-internal-tools/flask-serving.md)** in **python-internal-tools**.

**Default read order** (this repo): [web-frontend-basics](../web-frontend-basics/SKILL.md) → **web-layout-css (here)** → [web-accessibility](../web-accessibility/SKILL.md) — also summarized in [`SKILLS.md`](../../SKILLS.md#web-ui-default-reading-order).

## When to use

- New **page** or **component** (nav, data table, filter bar, two-column layout)
- **Refactor** “every class is ad hoc” in `static/css/`
- **Print** or **export** to PDF of a page (margins, break-inside)

## When to stop

- **Pixel-identical** match to a **Figma** you don’t have access to → get **design** input, not this skill.
- **Animation-heavy** marketing site → out of scope (still read **a11y** for **reduced motion**).
- **Tailwind** / **Bootstrap** team standards → follow those; this is **fall-back** when there is no system.

## Reference

- **[reference.md](reference.md)** — flex/grid choices, tokens, tables, print.

## Source

Authored for this repo. **Not** a slice of **`.claude/CLAUDE.md`**.
