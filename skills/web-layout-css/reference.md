# Reference: CSS for internal UIs

## 1. Conventions that pay off

- **One** main stylesheet (e.g. `app.css`) imported from **`base.html`**, plus **page-specific** small files only if **CSS** is huge. Avoid **dozens** of link tags.
- **Variables** for **spacing**, **color**, and **layout constants** at `:root` — name tokens by **role**, not value, so you can change the value without hunting down every use:

```css
:root {
  /* Colors — role names, not hex descriptions */
  --bg: #0c0c0c;
  --surface: #161616;        /* card, panel */
  --surface-hi: #1f1f1f;     /* input, elevated surface */
  --border: #2a2a2a;
  --text: #ede9e1;
  --text-muted: #7a7570;
  --accent: #c9a96e;

  /* Spacing — t-shirt scale */
  --space-1: 0.25rem;
  --space-2: 0.5rem;
  --space-3: 1rem;
  --space-4: 1.5rem;
  --space-5: 2.5rem;

  /* Layout constants */
  --max-w: 1140px;
  --nav-h: 64px;                          /* used for sticky offset calc */
  --gutter: clamp(1.25rem, 5vw, 2.5rem);  /* responsive container padding */
  --radius: 3px;
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

## 4. Fluid scaling with `clamp()`

Scale type and spacing continuously across viewport widths without breakpoints for these values. Pattern: `clamp(min, preferred, max)` where the middle term is viewport-relative.

```css
/* Typography */
h1 { font-size: clamp(2rem, 5vw, 3.5rem); }
h2 { font-size: clamp(1.4rem, 3.5vw, 2.1rem); }
h3 { font-size: clamp(1rem, 2.5vw, 1.25rem); }

/* Section breathing room */
.section { padding-block: clamp(3.5rem, 8vw, 6rem); }

/* Container gutter (also useful as a token) */
.container {
  max-width: var(--max-w);
  margin-inline: auto;
  padding-inline: var(--gutter); /* --gutter: clamp(1.25rem, 5vw, 2.5rem) */
}
```

- Use for headings, section padding, and container gutters — things that should breathe at larger viewports.
- Don't use for line-height or small component padding; prefer fixed `rem` there.
- `max-width: 68ch` on prose keeps lines readable without a breakpoint.
- Combine with `position: sticky; top: calc(var(--nav-h) + 1.5rem)` for sidebar images that clear the nav.

## 5. Data tables (HTML `table` + CSS)

- **`border-collapse: collapse`**, **zebra** with `:nth-child(even)` for readability (not **only** way to tell rows apart — [a11y](../web-accessibility/reference.md) **contrast**).
- **Sticky** `th` for long lists: `position: sticky; top: 0; background: ...; z-index: 1`.
- If the table is **wider** than the viewport, wrap in **`overflow-x: auto`** and give the wrapper a **role**/label if you use a **caption** (a11y skill for **screen reader** table navigation).

## 6. Common components (minimal)

- **Card:** `border`, `border-radius: var(--radius)`, `padding: var(--space-3)`, optional `box-shadow: 0 1px 2px rgba(0,0,0,0.06)`.
- **Pill / badge:** `display: inline-block; padding: 0.2em 0.6em; border-radius: 999px; font-size: 0.875em;`
- **Alert** banners: **don’t** rely on **red border only** — add **icon** or **“Error:”** text ([a11y](../web-accessibility/SKILL.md)).

## 7. z-index

- **Small** integers: **content** 1, **dropdowns** 10, **modals** 100, **toast** 200 — document in a **comment** at the top of the CSS. **No** `z-index: 9999` without a plan.

## 8. Print

- **`@media print`**: hide **nav**, **buttons** that only make sense on screen; `color-adjust: exact;` for backgrounds if policy allows; `break-inside: avoid` on **cards** you don’t want split across pages.

## 9. Images in layout

### Banner images (full-width, object-fit: cover)

```css
.img-banner {
  width: 100%;
  max-height: 540px;
  object-fit: cover;
  object-position: center;
  display: block;
}
```

- **Portrait photos used as landscape banners** crop to the middle by default — faces get cut. Use `object-position: 50% 20%` to anchor near the top, or increase `max-height` so more of the photo is visible.
- Tune `object-position` with percentage pairs: `50% 0%` = top, `50% 100%` = bottom. For a photo where you need to show face AND shirt text, bump `max-height` first, then adjust the Y position.
- **Float images in prose:** clear floats on the next block element with `clear: right` to prevent pull-quotes or headings from sitting beside an image unexpectedly.

### Avoiding dead space on the right

A common trap: set a generous `--max` container (e.g. 1000px) then constrain children with `max-width: 55ch` everywhere. Result: content fills 60% of the page, 40% is blank on the right.

**Prefer:** narrow the container itself to the widest comfortable reading width (typically 780–860px for prose, 1000–1200px for dashboards), then remove child max-width constraints. One constraint beats many.

```css
/* Instead of this — scattered child constraints */
.wrap { max-width: 1000px; }
.page-header p { max-width: 55ch; }   /* dead space */
.about-body { max-width: 65ch; }      /* dead space */

/* Do this — one tighter container */
.wrap { max-width: 820px; }           /* no child constraints needed */
```

Exception: if you need a wide layout for grids/tables AND narrow prose on the same page, use a narrower inner wrapper (`.prose`) rather than constraining every element individually.

### Image optimization (macOS `sips`)

macOS ships `sips` — no install needed. Use it to convert iPhone PNGs to web-ready JPEGs before committing:

```bash
# Resize to max 1400px wide + convert to JPEG at 85% quality
sips -s format jpeg -s formatOptions 85 --resampleWidth 1400 INPUT.png --out OUTPUT.jpg

# Resize illustration/icon to specific width, keep PNG
sips --resampleWidth 400 INPUT.png --out OUTPUT_sm.png

# Batch convert a folder
for f in img/*.png; do
  sips -s format jpeg -s formatOptions 85 --resampleWidth 1400 "$f" --out "${f%.png}.jpg"
done
```

Typical gains from iPhone photos: 15–28 MB PNG → 700 KB–1.1 MB JPEG (94–97% reduction). Use `loading="lazy"` on below-fold images.

## 10. What we skip here

- **Sass/PostCSS** — fine; keep **output** debuggable.
- **Tailwind** — if you use it, this skill is **rare**; use **a11y** and **flask** docs from **python-scripts-and-services** for structure.

## 11. Checklist

- [ ] **Layout** is **grid** or **flex**, not **float** hacks
- [ ] **Overflow** and **min-width: 0** on flex children that clip
- [ ] **Design tokens** at `:root`; no raw hex or px values scattered through rules
- [ ] **Fluid type and spacing** use `clamp()` for headings and section padding
- [ ] **Table** or **code** wide content has **scroll** or **stack** on small viewports
- [ ] **Touch** targets and **contrast** checked with [web-accessibility](../web-accessibility/SKILL.md)
- [ ] **Print** path doesn’t show **useless** chrome (optional but nice for reports)

## 12. Related

- [web-frontend-basics](../web-frontend-basics/SKILL.md) — HTML/JS
- [web-accessibility](../web-accessibility/SKILL.md) — focus, color, reduced motion
- [flask-serving](../python-scripts-and-services/flask-serving.md) — Jinja, static
