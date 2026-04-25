# Reference: accessibility (a11y) for web UIs

**Default target:** **WCAG 2.1 Level AA** ideas (informal mapping below — not a formal audit). **Internal** tools: still **avoid** locking out **keyboard** users and **low vision** colleagues.

## 1. Perceivable

### 1.1 Text alternatives

- **Meaningful** images: `alt` text that **replaces** the image for screen reader users. **Decorative** images: `alt=""` and `role="presentation"` if needed so SR **ignores** them.
- **Icons** that convey **state** (error, success) need **text** or **`aria-label`** on the **control**, not only the icon color.

### 1.2 Time-based media

- **Internal** UIs: rare. If you add **video**, provide **captions** and **controls**; not expanded here.

### 1.3 Adaptable

- **Correct** **heading** order (see [web-frontend-basics](../web-frontend-basics/SKILL.md)); **landmarks** `main`, `nav` **once** per page where appropriate.
- **Form** `input` + **`label`** association; **table** `th` **scope** for simple tables; more complex: **headers** + **id** or see **WAI-ARIA table** patterns.

### 1.4 Distinguishable

- **Contrast** — **4.5:1** for normal text, **3:1** for **large** text (18pt+ or 14pt+ bold) and **UI** components and **graphical** parts that convey information (rough **AA**). **Don’t** use **color alone** for “required”, “error”, or “pass/fail” — add **text**, **icon** with `aria-label`, or **pattern**.

---

## 2. Operable

### 2.1 Keyboard accessible

- **Everything** that is **clickable** must be **focusable** and **activatable** with **keyboard** (usually **Tab** / **Shift+Tab**, **Enter** / **Space** on **buttons** / **links**).
- **No** **positive** `tabindex` for **reordering** the tab ring without a **very** good reason (it confuses **everyone**). **`tabindex="-1"`** for **programmatic** focus only.
- **Skip link** to **`main`**: a **first** focusable **“Skip to main content”** **link** (visible on **focus**) helps **keyboard** users on **long** nav.

### 2.2 Enough time

- **Session** timeouts: **warn** before expire and offer **extend** if policy allows. **Autoplay** carousels: **pause** control and **no** only-motion **auto-advance** for **critical** content.

### 2.3 Seizures and physical reactions

- **No** flashing **more than three** times per second over **large** area. **Animation** for **decoration** only: respect **`prefers-reduced-motion`** (see **§7**).

### 2.4 Navigable

- **Page** **title** in `<title>` and **`h1`** that **match** the task.
- **Focus** **visible** — don’t `outline: none` without a **strong** **replacement** (custom `:focus-visible` style).
- **Multipage** flows: **consistent** **nav** and **where** you are ( **breadcrumb** or **step** indicator with **text**, not only **color** ).

---

## 3. Keyboard & pointer (quick matrix)

| Check | Pass |
|-------|------|
| All **interactive** controls **Tab**-reachable in **logical** order | Yes |
| **Focus** visible on **every** control | Yes |
| **Target** size **~44×44 CSS px** minimum (AA **for essential** controls in 2.5.5; good default for all) | Prefer yes |
| **Modal** open: **focus** **traps** inside; **close** on **Esc**; **return** focus to **trigger** on close | Yes |
| **No** **keyboard** trap in **widgets** (custom selects: use **combobox** APG or native `<select>`) | Yes |

**Complex widgets** (combobox, tabs): follow **[ARIA Authoring Practices](https://www.w3.org/WAI/ARIA/apg/patterns/)** (APG) or use **native** **HTML** first.

---

## 4. Understandable

- **Error** **messages** in **plain language**; **field-level** next to the **input** + **`aria-describedby`**; **form-level** **summary** at top for many errors (with **list** of **links** to fields if helpful).
- **Required** `*` in **label** with **explanation** of meaning for SR (`aria-required` if you can’t use native `required` consistently).
- **Consistent** **navigation** and **labels** across the app for the **same** action.

---

## 5. Robust

- **Valid** **HTML** (nesting, unique **ids**). **ARIA** only when **HTML** is insufficient; **no** `role="button"` on **`div`** without **keyboard** handlers matching **button**.
- **Parse** as **intended** — Jinja that **breaks** **tags** is **a11y** and **security** risk (see [flask-serving](../python-internal-tools/flask-serving.md) escaping).

---

## 6. Tables

- **`<caption>`** or **aria**-label the **table** if **purpose** isn’t obvious from **heading** above.
- **`<th` `scope="col|row">`** for **most** **internal** tables. **Complex** **gird** tables: `headers` / `id` **association** or **simplify** the design.
- **Sortable** columns: **button** in **th** (not `div` **onclick**) with **sort** state in **`aria-sort`**.

---

## 7. Motion

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

- **Respect** **user** system preference; don’t **disable** **for branding**.

---

## 8. Live regions

- **Toasts** / **inline** **status** after **save:** **`role="status"`** + **polite** `aria-live` (or **`role="status"`** implies **live** region) so SR **announces** without **stealing** **focus** from a **form** mid-type.
- **Urgent** **errors** that need **immediate** notice: `role="alert"` (assertive) — use **sparingly**.
- **Any region that updates dynamically** — search results, cart count, filter output — needs `aria-live="polite"` so screen readers announce changes without a focus move:

```html
<!-- search results container -->
<p aria-live="polite" id="search-meta">Found 12 prints matching "raven"</p>

<!-- cart badge — update textContent in JS, SR announces the new count -->
<span class="cart-count" aria-live="polite" aria-atomic="true">3</span>
```

Use `aria-atomic="true"` when the whole value should be read as a unit (a count), not word by word.

**`aria-expanded`** on toggle controls (nav hamburger, accordion, disclosure):
- Put `aria-expanded` on the **button**, not the panel it controls.
- Update it in JS whenever state changes: `btn.setAttribute('aria-expanded', isOpen)`.
- Pair with `aria-label` if the button has no visible text (e.g. icon-only hamburger).
- The controlled panel doesn't need `aria-hidden` if it's removed from layout with `display: none` — that already hides it from the accessibility tree.

```html
<button class="nav-toggle" aria-label="Open menu" aria-expanded="false">...</button>
```
```js
const open = panel.classList.toggle('open');
btn.setAttribute('aria-expanded', open);
```

**`aria-current="page"`** on the active nav link — screen readers announce "(current)" without extra text:

```html
<nav aria-label="Site">
  <a href="/prints/" aria-current="page">Prints</a>
  <a href="/about/">About</a>
</nav>
```

Set it in server-rendered templates or JS on page load; remove it from all other links in the same nav.

---

## 9. Pre-merge checklist (5 minutes)

- [ ] **Tab** through **entire** page: **order** and **visible** **focus**  
- [ ] **Required** and **error** not **color-only**  
- [ ] **Headings** and **one** **`main`**  
- [ ] **Active nav link** has `aria-current="page"`  
- [ ] **Dynamic regions** (search results, cart count, status messages) have `aria-live="polite"`  
- [ ] **Modal** (if any): **trap** + **Esc** + **return** **focus**  
- [ ] **Zoom** 200%: no **content** **lost** without **scroll** **path** (or **intentional** **horizontal** **scroll** for **table**)  
- [ ] **`prefers-reduced-motion`** doesn’t **break** **layout** (transitions to **0.01ms** ok)

**Automated** tools (**axe**, **Lighthouse** accessibility) **catch** ~**30%**; **keyboard** and **content** need **human** check.

## 10. Related

- [web-frontend-basics](../web-frontend-basics/SKILL.md) — **forms**, **semantics**  
- [web-layout-css](../web-layout-css/SKILL.md) — **contrast** with **design** tokens  
- [code-review.md](../python-internal-tools/code-review.md) — **PR** for **UI** **changes**  

## 11. Informal WCAG 2.1 mapping (this doc)

| Topic | Rough WCAG refs |
|-------|------------------|
| Contrast, not color alone | 1.4.3, 1.4.1 |
| Keyboard, focus, pointer target | 2.1.1, 2.1.2, 2.4.7, 2.5.5 |
| Labels, errors, consistent nav | 3.3.2, 3.3.1, 3.2.3 |
| Name, role, value | 4.1.2 |
| Motion | 2.3.1 + **prefers-reduced-motion** best practice |

*Official **conformance** requires a **formal** **audit** scope; this list helps **dev** self-check.*
