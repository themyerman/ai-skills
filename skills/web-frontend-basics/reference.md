# Reference: HTML & small JS for internal UIs

## 1. Semantic HTML (default)

- Use **one** `h1` per page; **heading levels** don’t skip (`h2` then `h4` is wrong).
- Prefer **native elements** over `div` soup: `main`, `nav`, `header`, `footer`, `section` with a **heading**, `article` when it stands alone, `ul`/`ol` for lists, `button` for actions, `a` for navigation.
- **`table`** for **tabular** data only; use **headers** `th` with `scope` where it helps (see [web-accessibility](../web-accessibility/SKILL.md) for complex tables).
- **Don’t** pick elements for **default styling** (e.g. `h3` because it “looks right”); use **class** + CSS in [web-layout-css](../web-layout-css/SKILL.md).

## 2. Forms

- Every **visible** input has a **`<label>`** (wrapped or `for` + `id`). **Placeholders** are not labels.
- **Required** fields: `required` **and** a **text** or `aria` indicator in the label (not color-only) — a11y skill has detail.
- **Errors:** associate with the field using **`aria-describedby`** pointing to an `id` on the error text; don’t rely on color alone.
- **Submit** with `<button type="submit">` (default type is **submit** in many browsers for `button` inside form — be explicit). Avoid `type="button"` for primary save unless you handle submit in JS.
- **GET** for safe, idempotent **search**; **POST** for state changes. Match **server** method and **CSRF** if you use cookies for session (see **§6**).
- **File** uploads: `enctype="multipart/form-data"`, `accept` as a hint, **server** must validate type and size [python-scripts-and-services security](../python-scripts-and-services/security.md).

## 3. Progressive enhancement

- **Core** task works with **HTML + server round-trip**; **JS** adds convenience (sort tables client-side, auto-submit search) but **degrades** if script fails.
- **No** critical path that only works with client-side `fetch` unless the audience is **known** to have modern browsers and **JS** on (internal is often OK — still test **no-JS** for important actions or document the limitation).
- **Links** for navigation; **`button`** for in-page actions — don’t use `<a href="#">` as a fake button (keyboard and SR users suffer).

## 4. JavaScript: stay small

- **One** entry per feature area (e.g. `sortable-tables.js`); **avoid** global `var` sprawl. Prefer **`<script type="module">`** or a **single IIFE** with a clear **namespace** object if you must support legacy.
- **Events:** `addEventListener` — not `onclick` attributes in HTML (keeps **CSP** and separation cleaner).
- **`fetch`:** always **`await` or `.then`**, check **`response.ok`**, parse **JSON** in `try/catch` — [python-scripts-and-services http-clients-reliability](../python-scripts-and-services/http-clients-reliability.md) patterns mirror **server**; on the **client** you also handle **4xx/5xx** and show a **user-visible** message.
- **Don’t** put **secrets** in front-end code; **API** keys in env at **build** time for public SPAs is a product decision — internal tools usually **proxy** through Flask.
- **User / ticket** text: if it ever goes to an **LLM** or is **injected** into the DOM, follow **llm-integrations-safety** and **escape** (Jinja `{{ }}` is escaped by default).

**`data-*` attributes as JS hooks** — use CSS classes for styling only; use `data-*` for JS state and data. Renaming a visual class then breaks JS if you mixed the two:

```html
<!-- fragile: visual class doubles as JS selector -->
<button class="btn btn-primary add-to-cart">Add</button>

<!-- resilient: styling and behavior are decoupled -->
<button class="btn btn-primary" data-action="add-to-cart" data-sku="OWL-001">Add</button>
```

```js
document.addEventListener(‘click’, e => {
  const btn = e.target.closest(‘[data-action="add-to-cart"]’);
  if (!btn) return;
  addToCart(btn.dataset.sku);
});
```

**IIFE module pattern** — encapsulate a feature without a bundler. No globals, no build step, works in a plain `<script>` tag:

```js
(function () {
  ‘use strict’;
  const STORAGE_KEY = ‘my-cart’;

  function getCart() {
    return JSON.parse(localStorage.getItem(STORAGE_KEY) || ‘[]’);
  }

  function init() { /* wire events */ }

  document.addEventListener(‘DOMContentLoaded’, init);
}());
```

**Client-side JSON search** — for catalogs under ~2 000 items a pre-built static index beats adding a search service. Generate `search.json` at deploy time (array of `{ slug, title, tags[], story }`). Filter on input:

```js
const results = index.filter(item =>
  terms.every(t =>
    item.title.toLowerCase().includes(t) ||
    item.tags.some(tag => tag.includes(t))
  )
);
```

Regenerate the index when content changes. Use `aria-live="polite"` on the results region so screen readers announce the count — see [web-accessibility §8](../web-accessibility/reference.md#8-live-regions).

## 5. Images

**Always include `width` and `height`** — the browser reserves layout space before the image loads, preventing layout shift (CLS). The values should match the image's intrinsic dimensions (CSS can scale it from there):

```html
<!-- grid card — lazy load, dimensions prevent layout shift -->
<img src="/prints/owl-thumb.jpg" alt="Superb Owl print"
     width="480" height="480" loading="lazy">

<!-- hero — above the fold, load immediately -->
<img src="/prints/owl-display.jpg" alt="Superb Owl"
     width="900" height="1200" loading="eager">
```

**`loading` attribute:**
- `loading="lazy"` — defer off-screen images (grids, cards, below-fold content).
- `loading="eager"` — force immediate load for hero images and anything above the fold. Be explicit; don't rely on browser default.

**Three-variant pattern** for image-heavy sites:

| Variant | Use | Notes |
|---------|-----|-------|
| Thumb | Grids, cards, cart thumbnails | Square crop, e.g. 480×480 |
| Display | Product/detail page hero | Full resolution |
| OG | `<meta property="og:image">` only | ~1200×630, lives in `/images/` not alongside content |

Name files by slug + suffix: `superb-owl-thumb.jpg`, `superb-owl-display.jpg`. Keeps filenames predictable and scriptable.

**Decorative images:** `alt=""` (empty string, not omitted) so screen readers skip them.

**Aspect ratio on the container** when image dimensions aren't known at author time, so the slot exists before the image loads:

```css
.card-image { aspect-ratio: 1 / 1; overflow: hidden; }
.card-image img { width: 100%; height: 100%; object-fit: cover; }
```

## 6. Mobile nav hamburger pattern

Minimal accessible toggle — no library needed:

```html
<nav>
  <a class="nav-brand" href="/">Site Name</a>
  <button class="nav-toggle" aria-label="Open menu" aria-expanded="false">
    <span></span><span></span><span></span>
  </button>
  <ul class="nav-links">...</ul>
</nav>
```

```css
.nav-toggle { display: none; flex-direction: column; gap: 5px;
              background: none; border: none; cursor: pointer; padding: 4px; }
.nav-toggle span { display: block; width: 22px; height: 2px; background: currentColor;
                   transition: transform .2s, opacity .2s; }

@media (max-width: 720px) {
  .nav-toggle { display: flex; }
  .nav-links { display: none; }
  .nav-links.open { display: flex; flex-direction: column; }

  /* Animate to X when open */
  .nav-toggle[aria-expanded="true"] span:nth-child(1) { transform: translateY(7px) rotate(45deg); }
  .nav-toggle[aria-expanded="true"] span:nth-child(2) { opacity: 0; }
  .nav-toggle[aria-expanded="true"] span:nth-child(3) { transform: translateY(-7px) rotate(-45deg); }
}
```

```js
// js/nav.js
const toggle = document.querySelector('.nav-toggle');
const links  = document.querySelector('.nav-links');
toggle.addEventListener('click', () => {
  const open = links.classList.toggle('open');
  toggle.setAttribute('aria-expanded', open);
});
```

Key points: `aria-expanded` on the button (not the list), `aria-label` on the button (the spans are decorative), Y offset for X animation = span height + gap (2px + 5px = 7px).

## 6a. Embedding a Google Form

Get the form embed URL by opening the form in Google Forms → Send → Embed → copy the iframe src. The URL ends with `?embedded=true`:

```html
<iframe
  src="https://docs.google.com/forms/d/e/FORM_ID/viewform?embedded=true"
  width="100%" height="1400" frameborder="0">
  Loading form…
</iframe>
```

If you only have a short link (`forms.gle/…`), resolve it to the full URL:
```bash
curl -sI https://forms.gle/SHORTCODE | grep -i location
```

Height is trial-and-error — set it high initially (1400px), then trim. The form doesn't resize itself.

## 6b. `sed` replacement string gotcha

`&` in a `sed` replacement string means "the matched text" — not a literal ampersand. This breaks HTML entities:

```bash
# WRONG — &nbsp; becomes matchedtext + nbsp;
sed -i '' 's/foo/bar \&nbsp;/' file.html

# RIGHT — escape the & or use a different tool
sed -i '' 's/foo/bar \&amp;/' file.html   # use \& for literal &
```

For multi-file HTML edits prefer the Edit tool (exact string replacement, no regex gotchas). Use `sed` only for simple token swaps where the replacement contains no special characters.

## 7. XSSI, JSON, and cookies

- **JSON** responses: prefer **POST** with **Content-Type: application/json** and **CSRF** token in header or body for **state-changing** actions; **GET** JSON **can** leak cross-origin if misconfigured—don’t put **sensitive** lists behind GET.
- **Cookies:** `SameSite=Lax` or `Strict` for **session**; `Secure` in prod; know **CSRF** rules for **custom** `fetch` from same site (same-origin form POST is often simpler for internal UIs).
- If you add **CSP** (Flask or proxy), **avoid** `'unsafe-inline'` for **script** long-term; use **nonce** or small **external** files.

## 8. Jinja and static assets

- **`url_for('static', filename='js/…')`** for script `src` so deploy paths stay correct.
- **Pass JSON** to JS with `tojson` filter in a **`<script type="application/json">` id="…"** block, then `JSON.parse` in your module — **not** by pasting unescaped into a JS string (XSS if data ever has `</script>`).
- Re-read **user-controlled** output rules in [flask-serving](../python-scripts-and-services/flask-serving.md) §5.

## 9. Checklist (new page or widget)

- [ ] **Semantic** structure and **one** `h1`
- [ ] **Labels** on all inputs; **error** text linked with `aria-describedby` when you add client validation
- [ ] **POST** for mutations; **CSRF** if session cookie auth
- [ ] **`fetch`** handles **non-ok** and **parse** errors
- [ ] **No** secrets in JS; **no** raw user HTML without trust path
- [ ] **Images** have `width`, `height`, and correct `loading` attribute
- [ ] **JS hooks** use `data-*` attributes, not styling class names
- [ ] **a11y** pass: [web-accessibility](../web-accessibility/SKILL.md) quick checks

## 10. When to read more

- **Layout and responsive:** [web-layout-css reference](../web-layout-css/reference.md)  
- **Flask, auth, headers, CSRF app-wide:** [flask-serving](../python-scripts-and-services/flask-serving.md)  
- **Code review of a PR** touching UI: [code-review](../python-scripts-and-services/code-review.md)
