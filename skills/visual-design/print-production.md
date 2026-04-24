# Print production

**Hub:** [SKILL.md](SKILL.md)

---

## 1. Resolution

**300 DPI** is the standard for print. The math: print size in inches = pixel dimension ÷ DPI.

| Pixels | DPI | Print size |
|--------|-----|------------|
| 2700 × 3600 | 300 | 9" × 12" |
| 3600 × 4800 | 300 | 12" × 16" |
| 1500 × 2000 | 150 | 10" × 13.3" |

- **300 DPI**: standard for fine art prints, photo prints, anything viewed close.
- **150 DPI minimum**: large-format work (posters, banners) viewed from a distance.
- **72 DPI**: screen only. Never send 72 DPI to a print vendor.

**Upscaling doesn't add real detail.** A 72 DPI file resampled to 300 DPI will print soft. Start at the right resolution.

Check your file: in Photoshop, Image → Image Size (uncheck Resample) to see the true print size at 300 DPI.

---

## 2. Color mode

| Mode | Use for |
|------|---------|
| **RGB** | Screen display, digital delivery, inkjet printers (most accept RGB and convert internally) |
| **CMYK** | Offset commercial printing (magazines, posters at a print shop) |
| **Greyscale** | Single-color print jobs |

**Default to RGB unless the vendor specifies CMYK.** Fine art inkjet printers (Epson, Canon) work in RGB. Commercial offset presses need CMYK — ask the vendor.

**RGB → CMYK gamut shift:** CMYK can't reproduce all RGB colors. Blues and purples clip most. Neon/saturated greens also shift. Always soft-proof before sending to press (Photoshop: View → Proof Setup → Working CMYK, then View → Proof Colors).

**Rich black vs. pure black:**
- Large black areas: use rich black (e.g. C60 M40 Y40 K100) for a deeper, neutral black on press.
- Small text: K100 only. Misregistration on press makes rich black text look blurry.

---

## 3. Color profiles

Embed a profile in every file. Ask your vendor which they want if unsure.

| Profile | Use |
|---------|-----|
| **sRGB IEC61966-2.1** | Web, most digital delivery, wide compatibility |
| **Adobe RGB (1998)** | Broader gamut; good for wide-gamut inkjet printers (Epson P-series) |
| **ProPhoto RGB** | Maximum gamut; only useful if your entire workflow supports it |
| **US Web Coated (SWOP) v2** | CMYK offset, North America |
| **Fogra39** | CMYK offset, Europe |

When in doubt for fine art inkjet: **Adobe RGB**. For web: **sRGB**.

---

## 4. Bleed, trim, and safe zone

These matter whenever your design has color or content that goes to the edge of the page.

```
┌─────────────────────────────┐  ← bleed edge (add 0.125" on each side)
│   ┌─────────────────────┐   │  ← trim line (final cut size)
│   │   ┌─────────────┐   │   │  ← safe zone (0.125"–0.25" inside trim)
│   │   │             │   │   │
│   │   │  keep text  │   │   │
│   │   │  and logos  │   │   │
│   │   │  in here    │   │   │
│   │   └─────────────┘   │   │
│   └─────────────────────┘   │
└─────────────────────────────┘
```

- **Bleed**: extend background color/imagery 0.125" (3mm) beyond the trim on every side. Covers slight cutting variation.
- **Trim**: the final finished size. This is what the customer receives.
- **Safe zone**: keep all important content (text, logos, faces) at least 0.125"–0.25" inside the trim. Anything outside the safe zone risks being cut off.

If your design has a white border or no edge bleed, you don't need a bleed — just deliver at exact trim size.

---

## 5. File formats

| Format | Use | Notes |
|--------|-----|-------|
| **TIFF** | Print master, archival | Lossless; large file; accepts layers or flatten before delivery |
| **PDF/X-1a or PDF/X-4** | Press-ready delivery | Ask vendor which version; embed fonts and profiles |
| **PSD / PSB** | Working file | Keep layered; flatten for delivery |
| **PNG** | Web, digital, lossless | Not for print unless vendor accepts it |
| **JPG** | Web, some print vendors | Lossy; use Quality 10–12 (maximum) for print; 60–80 for web |
| **EPS / AI** | Vector artwork | Scalable; good for logos and line art going to press |

**For fine art print vendors (e.g. Bay Photo, WHCC, Mpix):** high-quality JPG (maximum quality, sRGB or Adobe RGB) is usually accepted. Check their specs page — they vary.

**For offset press:** PDF/X is the professional standard. Embed all fonts and color profiles.

---

## 6. Preparing a file for a vendor

1. **Check resolution** at final print size (300 DPI minimum, uncheck Resample).
2. **Confirm color mode** — RGB or CMYK per vendor spec.
3. **Embed the correct ICC profile** (don't leave it untagged).
4. **Add bleed** if the design goes edge-to-edge.
5. **Flatten layers** unless the vendor accepts layered files.
6. **Export at maximum quality** — no unnecessary compression.
7. **Name the file clearly** — include size and DPI: `owl-print-9x12-300dpi.tif`.
8. **Soft-proof** if going to CMYK press — check for gamut clipping in blues and purples.

---

## 7. Common mistakes

| Mistake | Fix |
|---------|-----|
| Low-resolution file upsampled to 300 DPI | Reshoot or recreate at native resolution |
| RGB file sent to offset press | Convert to CMYK, soft-proof first |
| No bleed on edge-to-edge design | Extend canvas by 0.125" on each side |
| Important text outside safe zone | Move inside trim − 0.25" margin |
| Untagged file (no profile embedded) | Assign and embed sRGB or Adobe RGB |
| Rich black text | Use K100 for any text under ~24pt |
| JPG saved repeatedly | Each save adds compression artifacts — work in TIFF or PSD, export JPG once |

---

## 8. Checklist

- [ ] Resolution is 300 DPI at final print dimensions
- [ ] Color mode matches vendor requirement (RGB or CMYK)
- [ ] ICC profile embedded
- [ ] Bleed added if design goes to edge
- [ ] Critical content inside safe zone
- [ ] File exported at maximum quality, layers flattened
- [ ] Filename includes size and DPI
- [ ] Soft-proofed if going to CMYK press
