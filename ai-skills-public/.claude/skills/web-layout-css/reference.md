# Reference: CSS for internal UIs

## 1. Conventions that pay off

- **One** main stylesheet (e.g. `app.css`) imported from **`base.html`**, plus **page-specific** small files only if **CSS** is huge. Avoid **dozens** of link tags.
- **Variables** for **spacing** and **color** at `:root` (or a **`.theme`** class) so you don’t grep for `12px` vs `0.75rem` forever:

```css
:root {
  --space-1: 0.25rem;
  --space-2: 0.5rem;
  --space-3: 1rem;
  --color-border: #ccc;
  --radius: 4px;
}
```

- **Box-sizing:** `*, *::before, *::after { box-sizing: border-box; }` once globally.
- **min-width: 0** on **flex** children that must **shrink** (stops overflow weirdness in sidebars and tables-in-flex).

## 2. Layout: choose flex or grid

| Use case | Prefer |
|----------|--------|
| **Toolbar** (logo, nav, user) | **Flex** row; `align-items: center`; `gap` for spacing; [touch targets ~44px](../web-accessibility/reference.md#3-keyboard--pointer-quick-matrix) |
| **Main + sidebar** | **Grid** `grid-template-columns: 1fr 280px` or `auto 1fr`; or flex with **sidebar** `flex: 0 0 240px` |
| **Form** fields in a row (filters) | **Flex** with `flex-wrap: wrap` + `gap` |
| **Dashboard** of **cards** | **Grid** `repeat(auto-fill, minmax(280px, 1fr))` |
| **True** 2D alignment (gaps both ways) | **Grid** |

- **Don’t** absolutely position **entire** layout regions unless you’re building a true overlay (modals) — it **breaks** reflow and zoom. See [a11y](../web-accessibility/SKILL.md) for **focus** on open modals.

## 3. Responsive

- **Mobile-first** optional for **internal** tools if everyone uses **desktop**—but **still** set **max-width** and **overflow** on tables (horizontal scroll with **sticky** first column is a common pattern) or **stack** filters vertically below a width.
- **`rem`** / **`em`** for type and spacing where it matters; **at least** one **breakpoint** where the **nav** doesn’t require horizontal page scroll.
- **Avoid** fixed **width: 100vw** (scrollbar width causes **horizontal** scroll on some systems).

## 4. Data tables (HTML `table` + CSS)

- **`border-collapse: collapse`**, **zebra** with `:nth-child(even)` for readability (not **only** way to tell rows apart — [a11y](../web-accessibility/reference.md) **contrast**).
- **Sticky** `th` for long lists: `position: sticky; top: 0; background: ...; z-index: 1`.
- If the table is **wider** than the viewport, wrap in **`overflow-x: auto`** and give the wrapper a **role**/label if you use a **caption** (a11y skill for **screen reader** table navigation).

## 5. Common components (minimal)

- **Card:** `border`, `border-radius: var(--radius)`, `padding: var(--space-3)`, optional `box-shadow: 0 1px 2px rgba(0,0,0,0.06)`.
- **Pill / badge:** `display: inline-block; padding: 0.2em 0.6em; border-radius: 999px; font-size: 0.875em;`
- **Alert** banners: **don’t** rely on **red border only** — add **icon** or **“Error:”** text ([a11y](../web-accessibility/SKILL.md)).

## 6. z-index

- **Small** integers: **content** 1, **dropdowns** 10, **modals** 100, **toast** 200 — document in a **comment** at the top of the CSS. **No** `z-index: 9999` without a plan.

## 7. Print

- **`@media print`**: hide **nav**, **buttons** that only make sense on screen; `color-adjust: exact;` for backgrounds if policy allows; `break-inside: avoid` on **cards** you don’t want split across pages.

## 8. What we skip here

- **Sass/PostCSS** — fine; keep **output** debuggable.
- **Tailwind** — if you use it, this skill is **rare**; use **a11y** and **flask** docs from **python-internal-tools** for structure.

## 9. Checklist

- [ ] **Layout** is **grid** or **flex**, not **float** hacks
- [ ] **Overflow** and **min-width: 0** on flex children that clip
- [ ] **Table** or **code** wide content has **scroll** or **stack** on small viewports
- [ ] **Touch** targets and **contrast** checked with [web-accessibility](../web-accessibility/SKILL.md)
- [ ] **Print** path doesn’t show **useless** chrome (optional but nice for reports)

## 10. Related

- [web-frontend-basics](../web-frontend-basics/SKILL.md) — HTML/JS
- [web-accessibility](../web-accessibility/SKILL.md) — focus, color, reduced motion
- [flask-serving](../python-internal-tools/flask-serving.md) — Jinja, static
