# Guided Prayer Setup — Themed to the Hour (Option B)

The chosen treatment for the Guided Prayer **Setup** screen: the background and
the composer sheet carry a **subtle tinted wash of the current prayer's accent**,
over the dark config ground. This is NOT the full immersive per-prayer sky (that
stays reserved for the in-prayer screen), and Dhuhr keeps the **dark** chrome for
legibility rather than flipping to its daytime light theme.

Pairs with `SPEC.md` (full screen anatomy) and `THEME.md` (day-colour system).
This file only documents what changes between the neutral shell and the themed
treatment, per prayer.

---

## 1. The rule (theme-agnostic formulas)

`accent` = the prayer's Setup accent (table §3). `rgba(accent, α)` = that hex at alpha α.

**Screen background**
```
radial-gradient(125% 78% at 50% 0%, rgba(accent,0.20), transparent 56%),
linear-gradient(180deg, #181426 0%, #131120 58%, #0f0d18 100%)
```
A glow of the hour at the top, fading into the neutral dark ground by ~58%.

**Composer sheet background** (the "Change" bottom sheet)
```
linear-gradient(180deg, rgba(accent,0.16), #1b1730 42%, #16142a)
```
Same tint at the sheet's top edge, settling into the dark sheet body.

**Everything else is unchanged from `SPEC.md`** — text ramp (ink `#f4f1fa`,
muted `#b8b2c8`, faint `#847e98`), all selected-state tints/borders/glows already
derive from `accent`, the Start button, segmented controls, cards, etc.

> Neutral shell (Option A) for reference — screen `linear-gradient(180deg,#1a1730,#131120 60%,#100e1b)`, sheet `linear-gradient(180deg,#221d3a,#16142a)`.

---

## 2. Implementation note

Single boolean drives it (`themed`); the rest of the component is identical:
```js
const themed = !!props.themed;
const bg = themed
  ? 'radial-gradient(125% 78% at 50% 0%, ' + rgba(0.20) + ', transparent 56%), linear-gradient(180deg, #181426 0%, #131120 58%, #0f0d18 100%)'
  : 'linear-gradient(180deg, #1a1730 0%, #131120 60%, #100e1b 100%)';
const sheetBg = themed
  ? 'linear-gradient(180deg, ' + rgba(0.16) + ', #1b1730 42%, #16142a)'
  : 'linear-gradient(180deg, #221d3a, #16142a)';
// rgba(a) = hexToRgba(accent, a)
```
Recommendation: ship `themed` ON by default for the Setup screen.

---

## 3. Per-prayer values (resolved)

| Prayer | Arabic | Time | Accent | Screen top-glow `rgba(accent,0.20)` | Sheet top-tint `rgba(accent,0.16)` |
|---|---|---|---|---|---|
| **Fajr** | الفجر | 4:52 AM | `#e8a07e` | `rgba(232,160,126,0.20)` | `rgba(232,160,126,0.16)` |
| **Dhuhr** | الظهر | 12:21 PM | `#d6a13a` | `rgba(214,161,58,0.20)` | `rgba(214,161,58,0.16)` |
| **Asr** | العصر | 3:47 PM | `#e6a85a` | `rgba(230,168,90,0.20)` | `rgba(230,168,90,0.16)` |
| **Maghrib** | المغرب | 6:58 PM | `#f0a05a` | `rgba(240,160,90,0.20)` | `rgba(240,160,90,0.16)` |
| **Isha** | العشاء | 8:24 PM | `#9a86c7` | `rgba(154,134,199,0.20)` | `rgba(154,134,199,0.16)` |

Constant dark stops used in both gradients (all prayers):
`#181426`, `#131120`, `#0f0d18` (screen) · `#1b1730`, `#16142a` (sheet).

---

## 4. Resolved full backgrounds (copy-paste per prayer)

### Fajr
- Screen: `radial-gradient(125% 78% at 50% 0%, rgba(232,160,126,0.20), transparent 56%), linear-gradient(180deg, #181426 0%, #131120 58%, #0f0d18 100%)`
- Sheet: `linear-gradient(180deg, rgba(232,160,126,0.16), #1b1730 42%, #16142a)`

### Dhuhr
- Screen: `radial-gradient(125% 78% at 50% 0%, rgba(214,161,58,0.20), transparent 56%), linear-gradient(180deg, #181426 0%, #131120 58%, #0f0d18 100%)`
- Sheet: `linear-gradient(180deg, rgba(214,161,58,0.16), #1b1730 42%, #16142a)`

### Asr
- Screen: `radial-gradient(125% 78% at 50% 0%, rgba(230,168,90,0.20), transparent 56%), linear-gradient(180deg, #181426 0%, #131120 58%, #0f0d18 100%)`
- Sheet: `linear-gradient(180deg, rgba(230,168,90,0.16), #1b1730 42%, #16142a)`

### Maghrib
- Screen: `radial-gradient(125% 78% at 50% 0%, rgba(240,160,90,0.20), transparent 56%), linear-gradient(180deg, #181426 0%, #131120 58%, #0f0d18 100%)`
- Sheet: `linear-gradient(180deg, rgba(240,160,90,0.16), #1b1730 42%, #16142a)`

### Isha
- Screen: `radial-gradient(125% 78% at 50% 0%, rgba(154,134,199,0.20), transparent 56%), linear-gradient(180deg, #181426 0%, #131120 58%, #0f0d18 100%)`
- Sheet: `linear-gradient(180deg, rgba(154,134,199,0.16), #1b1730 42%, #16142a)`

---

## 5. Rationale (why this and not the full sky)

1. **Identity at the entry point** — the app is "colours throughout the day"; the first screen of the core flow should preview the hour rather than read neutral.
2. **Reveal preserved** — using a restrained wash (not the full immersive gradient) keeps the emotional peak for the in-prayer screen.
3. **Legibility on a dense control screen** — the dark ground keeps contrast predictable across all five times; Dhuhr stays dark rather than flipping to its light theme, so the config chrome is consistent end to end.
