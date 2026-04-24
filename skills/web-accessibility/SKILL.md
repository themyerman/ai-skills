---
name: web-accessibility
description: >-
  **Third** in the web read order: **web-frontend-basics** → **web-layout-css** →
  **this**. WCAG-2.1-style habits, keyboard+focus, forms+errors, ARIA, contrast,
  live regions, reduced motion. Triggers: a11y, accessibility, screen reader, WCAG,
  keyboard only, focus trap, ARIA, color contrast, skip link, pre-merge a11y
  review. Not legal/VPAT advice. Read HTML/CSS skills first.
---

# web-accessibility

## What this is

**Accessibility** is **usability** under constraints: **keyboard** only, **screen reader**, **low vision**, **motor** limitations, **reduced motion**, **cognitive** load. This skill gives **practical** checks that match **WCAG 2.1** **Level AA** as a **default target** for internal tools (verify **org** policy for **public** or **regulated** surfaces).

**Default read order** (this repo): [web-frontend-basics](../web-frontend-basics/SKILL.md) → [web-layout-css](../web-layout-css/SKILL.md) → **web-accessibility (here)** — chart: [`SKILLS.md`](../../SKILLS.md#web-ui-default-reading-order).

**Structure and HTML:** [web-frontend-basics](../web-frontend-basics/SKILL.md). **CSS** layout and **print:** [web-layout-css](../web-layout-css/SKILL.md). **Flask, Jinja, security headers:** [python-internal-tools / `flask-serving.md`](../python-internal-tools/flask-serving.md).

## When to use

- New **form**, **table**, **modal**, or **nav** pattern
- “**Is this OK** for a11y?” before merge
- **Bug** from a user who **can’t use a mouse** or **uses zoom**

## When to escalate

- **VPAT**, **Section 508** formal deliverable, or **legal** sign-off → **accessibility** team or **vendor** process; this skill is **engineering** hygiene, not a **certification**.

## Reference

- **[reference.md](reference.md)** — per-topic checklists, WCAG mapping (informal), testing tips.

## Source

Authored for this repo. **Not** a slice of **`.claude/CLAUDE.md`**. For **authoritative** specs, use **W3C** [WCAG 2.1](https://www.w3.org/TR/WCAG21/) and [WAI-ARIA](https://www.w3.org/WAI/ARIA/apg/); this doc is a **curated** subset for **internal** delivery speed.
