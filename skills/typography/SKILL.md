---
name: typography
description: >-
  Typography for designers and artists: type anatomy, font categories (serif,
  sans-serif, display, monospace), type pairing, hierarchy and scale, leading
  and tracking, text as a design element, choosing type for digital vs. print,
  free font sources, type in titles and series names, common mistakes. Triggers:
  typography, font, typeface, type pairing, serif, sans-serif, hierarchy, leading,
  tracking, kerning, font choice, display type, type design.
---

# typography

Typography is the art of arranging type — choosing typefaces, setting sizes and spacing, and organizing text so it works both practically (legible, readable) and aesthetically (appropriate, expressive). For visual artists, typography often appears in titles, series names, website text, and promotional materials.

---

## Type anatomy

Understanding the parts of letterforms helps you evaluate and choose type.

```
          ascender
              |
cap height    |
    |      ___↓___
    |     |       |
    |     |       |
baseline  |_______|
    |
descender (below baseline — y, g, p, q)
```

Key terms:
- **Baseline** — the line letters sit on
- **Cap height** — height of capital letters
- **X-height** — height of lowercase letters (like "x"); larger x-height = more readable at small sizes
- **Ascender** — stroke rising above the x-height (h, b, d, l)
- **Descender** — stroke falling below the baseline (g, y, p, q)
- **Serif** — small foot strokes at the end of letter strokes
- **Counter** — the enclosed or partially enclosed space inside letters (the hole in "o", "e", "a")
- **Kerning** — the space between two specific letter pairs
- **Tracking** — the overall spacing between letters across a word or block
- **Leading** — the vertical space between lines (line-height in CSS)

---

## Type categories

### Serif

Serifs have small strokes at the ends of letterforms. They read as traditional, authoritative, literary.

Subtypes:
- **Old Style** (Garamond, Caslon): bracketed serifs, moderate contrast, diagonal stress; classical, warm
- **Transitional** (Baskerville, Times New Roman): more contrast, more vertical stress; versatile
- **Modern** (Didot, Bodoni): high contrast, thin hairline serifs, vertical stress; elegant but fragile at small sizes
- **Slab serif** (Rockwell, Clarendon, Courier): thick block serifs; sturdy, industrial, or retro

### Sans-serif

No serifs. Read as modern, clean, functional.

Subtypes:
- **Humanist** (Gill Sans, Frutiger, Myriad): letterforms derived from handwriting; warmest of the sans-serifs
- **Geometric** (Futura, Avenir, Circular): based on geometric shapes; clean, minimal, contemporary
- **Grotesque / Neo-grotesque** (Helvetica, Neue Haas Grotesk, Arial): neutral, versatile; the "default" of sans-serifs

### Display

Type designed to be used large — headlines, titles, posters. Often expressive, decorative, or distinctive. Not meant for body text.

### Script

Based on handwriting or calligraphy. Use sparingly and at appropriate sizes; hard to read in large blocks.

### Monospace

Every character occupies the same width. Originally designed for typewriters; now used for code and technical text (Courier, Inconsolata, JetBrains Mono).

---

## Type pairing

Using two typefaces together creates visual contrast and hierarchy. The goal is complementary contrast — different enough to distinguish, related enough to cohere.

### Classic pairings

- **Serif headline + sans-serif body**: traditional and very readable (Playfair Display + Source Sans, Merriweather + Open Sans)
- **Sans-serif headline + serif body**: more contemporary; the reverse of the above
- **Two sans-serifs**: usually works if they're from different categories (geometric + humanist)

### Rules for pairing

- **Don't pair similar typefaces** — two different geometric sans-serifs fight each other without creating useful contrast
- **Contrast weight, not just style** — a light sans and a heavy serif pair better than two mid-weight faces
- **Limit to two** — three typefaces in one design is usually one too many; if you do use three, one should be clearly subordinate
- **Use the type family** — many typefaces have multiple weights and styles within the family; pairing a regular and bold from the same family is always safe

---

## Hierarchy and scale

Hierarchy is the visual ordering that tells readers what to read first, second, and third.

Create it with:
- **Size** — larger = more important
- **Weight** — bolder = more prominent
- **Color** — high contrast = primary; lower contrast = secondary
- **Spacing** — more space around something makes it more important
- **Position** — top and left read first in Western languages

A clear hierarchy has 3–4 levels: headline, subhead, body, caption. If everything is the same size and weight, nothing has priority.

Scale relationships that feel right: there's no single rule, but large jumps (a headline 3–4× the body size) read as intentionally hierarchical. Small jumps (1.1–1.5×) can feel accidental.

---

## Spacing

### Leading (line spacing)

Tight leading (line spacing close to or less than the type size): dramatic for headlines; hard to read for body text.

Comfortable body text leading: 1.4–1.6× the type size. A 16pt font with 24pt leading reads comfortably.

More leading = more air = more formal/open feeling. Less leading = more compressed = more intense.

### Tracking (letter spacing)

Adding tracking to all-caps text improves readability — capitals were designed for use with lowercase; they benefit from extra space when set alone.

Adding tracking to body text usually makes it harder to read. Reserve tracking adjustments for display text.

Negative tracking (letters closer than default) can feel stylistically contemporary but sacrifices legibility at text sizes.

### Kerning

Certain letter pairs have awkward gaps that need optical adjustment: AV, VA, WA, To, Ta, AT. Professional typefaces have kerning tables built in; adjust manually in display type when gaps are obvious.

---

## Text as a design element

Typography in graphic work — titles, prints, posters — goes beyond "legible text." The letters themselves are visual form.

Considerations:
- **Letterform as shape**: how does the outline of the letters interact with the surrounding visual space?
- **Texture**: a block of text has a visual texture (dense or open, regular or irregular)
- **Weight contrast**: how the type weight relates to the weight of lines and shapes in the composition
- **Negative space**: the space inside and around letters is as active as the letters themselves

Type set very large reads as image first, word second. Small type reads as pattern. Medium type reads as word.

---

## Choosing type for digital vs. print

| Consideration | Digital | Print |
|---------------|---------|-------|
| Resolution | Screen resolution limits fine details | High-res; hairlines and fine detail render well |
| Size | Minimum ~14px for body text on screen | Minimum 8–9pt for body text |
| High-contrast serifs (Didot-style) | Hairlines break down at small sizes | Work well at print sizes |
| Web font licensing | Use web-licensed fonts (Google Fonts, Adobe Fonts) | Standard desktop licensing |
| Anti-aliasing | Affects how letterforms render | Not a factor |

For screen: humanist sans-serifs and transitional serifs tend to work well at small sizes because they have generous x-heights and moderate contrast.

---

## Free type resources

- **Google Fonts** (fonts.google.com) — free, open-source, web-licensed; wide selection; not all are good
- **Adobe Fonts** — included with Creative Cloud; large library; not free standalone
- **Font Squirrel** — free, desktop-licensed fonts; vetted for quality
- **The League of Moveable Type** — open-source, high-quality text faces
- **DaFont** — mostly display and decorative; free but check licenses for commercial use

For serious design work, investing in a few good typefaces from type foundries (Klim, Commercial Type, Hoefler&Co, etc.) pays off — the quality difference from free fonts is real.

---

## Common mistakes

| Mistake | Fix |
|---------|-----|
| Too many typefaces | Maximum two; use weight variation within a family |
| Body text too small | 14–16px on screen, 9–11pt in print |
| No leading on body text | Set line-height to 1.4–1.6 |
| Centered body text | Use left alignment for body; centered for short display text only |
| Stretched or squashed type | Never scale type non-proportionally |
| Fake bold/italic | Use the actual bold or italic font, not the synthetic version |
| All caps body text | Capitals slow reading; reserve for short display text |

---

## Related

- Visual design and print production: [`visual-design`](../visual-design/SKILL.md)
- Visual communication and layout: [`visual-communication`](../visual-communication/SKILL.md)
- CSS for web typography: [`web-layout-css`](../web-layout-css/SKILL.md)
- Color theory (type color and contrast): [`color-theory`](../color-theory/SKILL.md)
