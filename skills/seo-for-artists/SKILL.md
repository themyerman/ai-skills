---
name: seo-for-artists
description: >-
  SEO for visual artists and creatives: image SEO, keyword research for art
  buyers, metadata (title, alt text, description), Google Search Console,
  structured data for artworks, local SEO, blog strategy, backlinks. Practical
  for independent artists with a portfolio site. Triggers: SEO, image SEO,
  alt text, artist website, keyword, Google, search, portfolio site, metadata,
  art SEO, discoverability.
---

# seo-for-artists

Search engine optimization for artists is mostly about being found by people who are looking for what you make. It's less technical than enterprise SEO and more about describing your work clearly and consistently across your site and the web.

---

## How people find art online

People search for art in a few ways:
- **By subject** — "wolf digital art print", "abstract landscape painting"
- **By style** — "Indigenous digital art", "geometric art print"
- **By use** — "art print for living room", "office wall art"
- **By your name** — after discovering you somewhere else

Your SEO job is to show up for the subject and style searches. The name searches take care of themselves once your name is out there.

---

## Keyword research

Start with what you make, then find the words buyers actually use.

Tools:
- **Google autocomplete** — type your subject into Google and see what it suggests
- **Google Search Console** — once set up, shows you what searches already bring people to your site
- **Ahrefs / Semrush** (paid) — full keyword research if you want to go deeper
- **Etsy search** — if your buyers also shop Etsy, Etsy's autocomplete reflects real demand

Building a keyword list:
```
Core subject:  wolf, forest, night sky
Style terms:   digital art, Indigenous art, geometric, abstract
Format terms:  print, wall art, canvas, poster
Modifier:      original, limited edition, signed, large format

Combinations:
- "Indigenous digital art print"
- "wolf digital art print"
- "geometric wolf art"
- "large format nature print"
```

Focus on 2–4 word phrases, not single words. "Art" is too broad. "Wolf digital art print" is specific enough to rank for.

---

## Page titles and meta descriptions

Every page on your site has a title (shown in browser tabs and search results) and a meta description (the text under your link in search results).

Title format that works for artists:
```
[Subject] — [Style/Medium] by [Your Name]
Wolf at Midnight — Indigenous Digital Art Print | Tom Myer
```

Rules:
- Keep titles under 60 characters
- Include the most important keyword near the front
- Every page should have a unique title

Meta descriptions:
- 150–160 characters
- Describe what's on the page; include 1–2 keywords naturally
- Write it to make someone want to click, not just to stuff keywords

```html
<title>Wolf at Midnight — Indigenous Digital Art Print | Tom Myer</title>
<meta name="description" content="Limited edition digital print — a wolf in a midnight forest, drawn from Haudenosaunee storytelling traditions. Signed, numbered, available in 3 sizes.">
```

---

## Image SEO

Search engines can't see images directly. They read the filename, alt text, and surrounding text to understand what an image depicts.

### Filename

Before uploading: rename your files descriptively.

```
# Bad
DSC_4821.jpg
image001.jpg

# Good
wolf-at-midnight-indigenous-digital-art.jpg
canyon-lands-geometric-print-tom-myer.jpg
```

Use hyphens between words (not underscores). Lowercase.

### Alt text

Alt text describes the image for screen readers and search engines. Write it as a description, not a keyword dump.

```html
<!-- Bad: empty -->
<img src="wolf-print.jpg" alt="">

<!-- Bad: keyword stuffing -->
<img src="wolf-print.jpg" alt="wolf art wolf print wolf painting wolf digital art buy wolf art">

<!-- Good: descriptive -->
<img src="wolf-midnight-print.jpg" alt="A wolf standing in a moonlit forest, rendered in geometric digital art style with deep blues and grays">
```

### Image file size

Large images slow down your site. Google uses page speed as a ranking factor.

- Resize images before uploading — a 300px thumbnail doesn't need to be a 4000px source file
- Use modern formats: WebP instead of JPEG/PNG where supported
- Compress with ImageOptim (Mac), Squoosh (web), or similar

---

## Structured data for artworks

Structured data is markup that tells Google specifically what kind of thing a page describes. For art sales, the `Product` and `VisualArtwork` schema types are useful.

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "VisualArtwork",
  "name": "Wolf at Midnight",
  "creator": {
    "@type": "Person",
    "name": "Tom Myer"
  },
  "description": "Limited edition digital print depicting a wolf in a moonlit forest.",
  "artMedium": "Digital",
  "artworkSurface": "Hahnemühle Photo Rag",
  "width": "18 in",
  "height": "24 in",
  "numberOfPages": null,
  "offers": {
    "@type": "Offer",
    "price": "175.00",
    "priceCurrency": "USD",
    "availability": "https://schema.org/InStock"
  }
}
</script>
```

This can help your listings appear in Google's rich results and shopping surfaces.

---

## Google Search Console

Search Console is free and shows you:
- What searches bring people to your site
- How often your pages appear in search results (impressions)
- What your click-through rate is
- Which pages Google has indexed
- Any crawl errors

Set it up:
1. Go to [search.google.com/search-console](https://search.google.com/search-console)
2. Add your property (your site's URL)
3. Verify ownership (usually via a DNS record or HTML file)
4. Submit your sitemap under Settings → Sitemaps

Check Search Console monthly. The "Queries" report shows what people are actually searching for when they find you — use that to tune your page copy and titles.

---

## Blog and content strategy

A simple blog or process post strategy helps SEO because:
- More pages = more chances to rank for different searches
- Long-form text gives search engines more to index
- Content attracts links from other sites

Content ideas that work for artists:
- "How I made [series name]" — process + story
- "[Subject] in Indigenous art traditions" — educational, builds authority
- "Behind the print: materials and process" — targets buyers who care about craft
- "[Your medium] printing explained" — informational, attracts print buyers

You don't need to post frequently — 1 post per month is enough if it's substantive. Posts of 500–1,000 words perform better than short captions-length text.

---

## Backlinks

A backlink is when another website links to yours. Google treats backlinks as votes of credibility.

Ways artists build backlinks:
- Gallery or exhibition websites that list you
- Press coverage (interviews, features, reviews)
- Art directories and Indigenous art organization listings
- Social profiles (Instagram bio, Patreon, Etsy "website" field — link to your site)
- Guest posts or features on other art blogs
- Nonprofit partnerships (if you work with art-focused nonprofits, ask them to link your site)

You don't need hundreds of backlinks. A few from credible, relevant sites matters more than many from unrelated ones.

---

## Local SEO (if relevant)

If you sell locally, do workshops, or show in your area:

- Claim and fill out your [Google Business Profile](https://business.google.com) — it's free
- List your city and region on your website's About page and contact page
- Use local terms in some titles: "Indigenous artist [city]", "[city] art prints"

Local SEO helps when people search for "artist near me" or "[city] art gallery".

---

## Common mistakes

| Mistake | Fix |
|---------|-----|
| Every page has the same title | Write a unique title per page |
| Images named DSC_001.jpg | Rename before upload |
| No alt text anywhere | Add alt text to every image |
| Site loads slowly | Compress images; check PageSpeed Insights |
| Not linked from anywhere | Add site link to all social profiles and directories |
| Never checking Search Console | Set a monthly reminder |

---

## Related

- Writing clear descriptions and artist statements: [`docs-clear-writing`](../docs-clear-writing/SKILL.md)
- Art business, pricing, and licensing: [`art-business`](../art-business/SKILL.md)
- Static site deployment on GitHub Pages: [`static-site-github-pages`](../static-site-github-pages/SKILL.md)
