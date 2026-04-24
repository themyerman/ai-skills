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
- **File** uploads: `enctype="multipart/form-data"`, `accept` as a hint, **server** must validate type and size [python-internal-tools security](../python-internal-tools/security.md).

## 3. Progressive enhancement

- **Core** task works with **HTML + server round-trip**; **JS** adds convenience (sort tables client-side, auto-submit search) but **degrades** if script fails.
- **No** critical path that only works with client-side `fetch` unless the audience is **known** to have modern browsers and **JS** on (internal is often OK — still test **no-JS** for important actions or document the limitation).
- **Links** for navigation; **`button`** for in-page actions — don’t use `<a href="#">` as a fake button (keyboard and SR users suffer).

## 4. JavaScript: stay small

- **One** entry per feature area (e.g. `sortable-tables.js`); **avoid** global `var` sprawl. Prefer **`<script type="module">`** or a **single IIFE** with a clear **namespace** object if you must support legacy.
- **Events:** `addEventListener` — not `onclick` attributes in HTML (keeps **CSP** and separation cleaner).
- **`fetch`:** always **`await` or `.then`**, check **`response.ok`**, parse **JSON** in `try/catch` — [python-internal-tools http-clients-reliability](../python-internal-tools/http-clients-reliability.md) patterns mirror **server**; on the **client** you also handle **4xx/5xx** and show a **user-visible** message.
- **Don’t** put **secrets** in front-end code; **API** keys in env at **build** time for public SPAs is a product decision — internal tools usually **proxy** through Flask.
- **User / ticket** text: if it ever goes to an **LLM** or is **injected** into the DOM, follow **llm-integrations-safety** and **escape** (Jinja `{{ }}` is escaped by default).

## 5. XSSI, JSON, and cookies

- **JSON** responses: prefer **POST** with **Content-Type: application/json** and **CSRF** token in header or body for **state-changing** actions; **GET** JSON **can** leak cross-origin if misconfigured—don’t put **sensitive** lists behind GET.
- **Cookies:** `SameSite=Lax` or `Strict` for **session**; `Secure` in prod; know **CSRF** rules for **custom** `fetch` from same site (same-origin form POST is often simpler for internal UIs).
- If you add **CSP** (Flask or proxy), **avoid** `'unsafe-inline'` for **script** long-term; use **nonce** or small **external** files.

## 6. Jinja and static assets

- **`url_for('static', filename='js/…')`** for script `src` so deploy paths stay correct.
- **Pass JSON** to JS with `tojson` filter in a **`<script type="application/json">` id="…"** block, then `JSON.parse` in your module — **not** by pasting unescaped into a JS string (XSS if data ever has `</script>`).
- Re-read **user-controlled** output rules in [flask-serving](../python-internal-tools/flask-serving.md) §5.

## 7. Checklist (new page or widget)

- [ ] **Semantic** structure and **one** `h1`
- [ ] **Labels** on all inputs; **error** text linked with `aria-describedby` when you add client validation
- [ ] **POST** for mutations; **CSRF** if session cookie auth
- [ ] **`fetch`** handles **non-ok** and **parse** errors
- [ ] **No** secrets in JS; **no** raw user HTML without trust path
- [ ] **a11y** pass: [web-accessibility](../web-accessibility/SKILL.md) quick checks

## 8. When to read more

- **Layout and responsive:** [web-layout-css reference](../web-layout-css/reference.md)  
- **Flask, auth, headers, CSRF app-wide:** [flask-serving](../python-internal-tools/flask-serving.md)  
- **Code review of a PR** touching UI: [code-review](../python-internal-tools/code-review.md)
