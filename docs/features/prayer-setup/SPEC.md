# Guided Prayer Setup — Component Spec

Source of truth for the **Guided Prayer Setup** screen. Use this to diff what
has been built and make it identical in all ways.

## 0. Frame & global

- **Device frame:** iOS, dark mode. Screen artboard **402 × 874 px**. All values below are at that scale.
- **Screen background:** Per-prayer atmospheric gradient (see `theme.md §1`),
  matching whichever prayer is currently selected. Switches immediately when
  the user taps a prayer chip. At launch defaults to current time-of-day prayer.
  Dhuhr is a light theme — text tokens flip to dark ink.
- **Root container:** `height:100%`, `display:flex; flex-direction:column`, `padding: 54px 0 26px`, `position:relative`, `overflow:hidden`, `box-sizing:border-box`, `font-family: Manrope, system-ui, sans-serif`.
- **Vertical structure:** fixed **Header** → scrollable **Body** (`flex:1; overflow-y:auto`) → fixed **Start** footer. A **Composer bottom-sheet** overlays everything when open.

### Color tokens
| Token | Value |
|---|---|
| ink (primary text) | `#f4f1fa` |
| muted (secondary) | `#b8b2c8` |
| faint (tertiary/labels) | `#847e98` |
| card bg | `rgba(255,255,255,0.035)` |
| card border | `rgba(255,255,255,0.07)` |
| dark-on-accent text | `#16142a` |
| **accent** | per-prayer (see below) |

`rgba(accent, α)` below means the accent color at alpha α.

### Per-prayer theme (accent + hero data)
| Prayer | Arabic | accent | farḍ rakʿahs | eyebrow | time |
|---|---|---|---|---|---|
| Fajr | الفجر | `#e8a07e` | 2 | Before sunrise | 4:52 AM |
| Dhuhr | الظهر | `#d6a13a` | 4 | Midday | 12:21 PM |
| Asr | العصر | `#e6a85a` | 4 | Afternoon | 3:47 PM |
| Maghrib | المغرب | `#f0a05a` | 3 | Sunset | 6:58 PM |
| Isha | العشاء | `#9a86c7` | 4 | Night | 8:24 PM |

Default prayer = **maghrib**. The accent drives every selected state, the hero tint, avatars, Start button, and chips. Background stays constant.

### Fonts (roles)
- **Cormorant Garamond** (500/600) — "Guided Prayer", prayer Latin names, voice/muezzin names, numerals, sheet titles.
- **Manrope** (400/500/600/700) — all UI/body/labels/buttons.
- **Amiri** (400) — all Arabic, always `direction: rtl`.

Google Fonts import:
```html
<link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:wght@400;500;600&family=Manrope:wght@400;500;600;700&family=Amiri:wght@400;700&display=swap" rel="stylesheet">
```

### Section label style (reused everywhere)
`font-size:11px; letter-spacing:2.5px; text-transform:uppercase; color:#847e98; font-weight:600`

---

## 1. Header (fixed)
Row: `display:flex; align-items:center; gap:14px; padding:0 22px`.
- **Back button:** 36×36 circle, `background:rgba(255,255,255,0.06)`, `border:1px solid rgba(255,255,255,0.1)`, centered chevron-left SVG (16px, stroke `#a39db6`, width 1.8).
- **Title block** (`flex:1`): eyebrow `New session` (label style **but** color = accent, size 10.5px) → title **"Guided Prayer"** Cormorant 26px / weight 500 / `line-height:1.05` / color ink, `margin-top:1px`.
- **Right:** prayer time (e.g. "6:58 PM"), 12.5px, color faint, `white-space:nowrap`.

---

## 2. Body (scroll, `gap:20px`, `padding:0 22px 4px`, `margin-top:20px`)

### 2a. Hero — Prayer set card  *(tap → opens Composer sheet)*
Container: `padding:18px 20px; border-radius:22px; border:1px solid rgba(accent,0.28); background: linear-gradient(155deg, rgba(accent,0.16), rgba(accent,0.03)); cursor:pointer`.
Inner row `space-between`, `align-items:flex-start`:
- Left column:
  - Eyebrow: `{EYEBROW} · UP NEXT` (uppercase, 10.5px, ls 2.5px, weight 600, **accent**).
  - Name row (`gap:11px; align-items:baseline; margin-top:10px`): Arabic name **Amiri 38px ink** (rtl) + Latin name **Cormorant 28px / 500 / muted**.
  - Rakʿah line (`margin-top:8px`, 12.5px, muted): see **rakʿah text rule** in §4.
- Right: **"Change" pill** — `padding:7px 12px; border-radius:100px; border:1px solid rgba(255,255,255,0.14); background:rgba(255,255,255,0.04); color:muted`, "Change" 11px/600 + chevron-down SVG 11px (`stroke:currentColor`, width 2).

### 2b. Language — segmented (3)
Label "Language". Track: `display:flex; gap:5px; padding:5px; background:rgba(255,255,255,0.05); border-radius:18px; margin-top:10px`.
Each **segment** (`segBase`): `flex:1; display:flex; flex-direction:column; align-items:center; gap:3px; padding:9px 4px; border-radius:14px; cursor:pointer; border:1px solid transparent; transition:background .2s`.
- **Selected:** add `background:rgba(accent,0.18); border-color:rgba(accent,0.4)`.
- Top label: `العربية` (Amiri 18px) / `English` / `Türkçe` (Manrope 15px/600). Color ink if selected else muted.
- Sub label below: `Arabic` / `Latin` / `Turkish` — 10px, ls 0.4px, color accent if selected else faint.
- Default selected: **English (`en`)**.

### 2c. Voice — two cards
Label "Voice". Row `display:flex; gap:10px; margin-top:10px`. Two cards, each `flex:1`:
Card: `display:flex; flex-direction:column; gap:6px; padding:13px 14px; border-radius:16px; cursor:pointer; transition:all .2s`.
- **Selected:** `border:1px solid rgba(accent,0.45); background:rgba(accent,0.12)`. **Unselected:** `border:1px solid rgba(255,255,255,0.07); background:rgba(255,255,255,0.035)`.
- Top row `space-between`: name group = Latin name **Cormorant 20px/600 ink** + Arabic **Amiri 14px** (color accent if selected else faint); plus a **dot** (16px circle): selected = filled accent w/ `box-shadow:0 0 10px rgba(accent,0.7)`; unselected = `1.5px` ring `rgba(255,255,255,0.18)`.
- **Tag pill** (self-start): 9.5px, ls 1px, uppercase, weight 600, `padding:2px 8px; border-radius:100px`. Selected → color accent / `background:rgba(accent,0.16)`; else faint / `rgba(255,255,255,0.05)`.
- Desc: 11.5px, faint, `line-height:1.4`.

Data: **Hātif** (هاتف · tag "Voice" · "Guiding voice · natural speech") and **Reciter** (قارئ · tag "Settings" · "Choose a qārī in Settings"). Default selected: **hatif**.

### 2d. Guidance level — 3 stacked rows
Label "Guidance level". Column `gap:7px; margin-top:10px`.
Row: `display:flex; align-items:center; gap:12px; padding:11px 14px; border-radius:14px; cursor:pointer`.
- **Selected:** `border:1px solid rgba(accent,0.35); background:rgba(accent,0.12)`. Else card border/bg.
- **Number badge** (left): 26px circle. Selected → `background:accent; color:#16142a`. Else → `1px` border `rgba(255,255,255,0.16)`, color faint. Text 12px/700.
- Middle (`flex:1`): title 14.5px/600 (ink if selected else muted) + desc 11.5px faint (`margin-top:1px`).
- **Radio** (right): 18px circle. Selected → `border:5px solid accent`. Else → `1.5px` ring `rgba(255,255,255,0.18)`.

Data: `1 Full guidance / Instructions + prayers` · `2 Prayer only / Recitation, no cues` · `3 Silent guiding / Gentle motion only`. Default: **full**.

### 2e. Pace — segmented (3)
Identical structure to Language (`segBase`, same track). Labels Manrope 15px/600. Sub labels 10px.
Data: `Slow / Unhurried` · `Medium / Balanced` · `Fast / Brisk`. Default: **medium**.

### 2f. Muezzin
Header row `space-between; align-items:baseline`: label "Muezzin" + right hint "Choreographs the session" (11px faint).
**Featured card** (`margin-top:10px`): `display:flex; align-items:center; gap:15px; padding:15px 16px; border-radius:18px; border:1px solid rgba(accent,0.3); background:linear-gradient(155deg, rgba(accent,0.14), rgba(accent,0.03))`.
- **Avatar** 56px circle: `background: radial-gradient(circle at 40% 32%, rgba(accent,0.38), rgba(255,255,255,0.04) 82%)`, `border:2px solid accent`, `box-shadow:0 0 20px rgba(accent,0.5)`. Contains Arabic initial Amiri 25px ink.
- Text (`flex:1`): name Cormorant 21px/600 ink + Arabic Amiri 15px accent (baseline, gap 8); style line 12px muted (`margin-top:2px`); **waveform** below (`margin-top:9px`, `height:14px`, `align-items:flex-end; gap:3px`): 9 bars, each `width:3px`, heights `[6,11,8,14,9,13,7,11,6]`, `border-radius:2px`, `background:rgba(accent, 0.45 + h/30)`, animated `wavePulse` (scaleY .5↔1) duration `1.4 + (i%3)*0.4`s, delay `i*0.12`s.

**Picker row** (`margin-top:14px; gap:14px; overflow-x:auto`): each item `width:58px`, column, `gap:7px`, `cursor:pointer`. Avatar 48px circle, same radial bg at `rgba(accent,0.3)…`; **selected** → `border:2px solid accent` + `box-shadow:0 0 16px rgba(accent,0.55)`; else `border:1px solid rgba(255,255,255,0.12)`. Initial Amiri 19px ink. Name below 11px, color accent if selected else faint.

Data: **Bilāl** بلال (ب · "Madinah cadence · unhurried") · **Idrīs** إدريس (إ · "Flowing · melodic") · **Ṣādiq** صادق (ص · "Spacious · minimal") · **Yūnus** يونس (ي · "Bright · resonant"). Default: **bilal**.

---

## 3. Start footer (fixed)
`padding:14px 22px 0`.
- **Summary line** (centered, 11.5px, faint, ls 0.3px, `margin-bottom:11px`): `{Prayer} · {Guidance title} · {Pace} pace · {Muezzin name}` — e.g. "Maghrib · Full guidance · Medium pace · Bilāl".
- **Start button:** `height:56px; border-radius:18px; background:accent; color:#16142a; font-size:16px; weight:700; ls:0.3px; display:flex; align-items:center; justify-content:center; gap:9px; box-shadow:0 12px 34px rgba(accent,0.34)`. Text **"Begin {Prayer}"** + arrow-right SVG 17px (`stroke:#16142a`, width 2).

---

## 4. Composer bottom-sheet (overlay; "prayer set")
Opened by tapping the hero or its "Change" pill; closed by backdrop tap, "Done", or "Confirm set".
- **Backdrop:** `position:absolute; inset:0; background:rgba(8,7,16,0.62); backdrop-filter:blur(3px); z-index:20`. Tap closes.
- **Sheet:** `position:absolute; left/right/bottom:0; z-index:21; background:linear-gradient(180deg,#221d3a,#16142a); border-radius:28px 28px 0 0; border-top:1px solid rgba(255,255,255,0.09); box-shadow:0 -22px 54px rgba(0,0,0,0.55); padding:12px 22px 24px; display:flex; flex-direction:column; gap:15px; max-height:86%`.
  - **Grabber:** 40×4 pill, `rgba(255,255,255,0.18)`, centered.
  - **Header row:** left = label "Prayer set" + "Compose the session" (Cormorant 23px/500 ink); right = **"Done"** 14px/600 accent.
  - **Prayer chips** (`gap:8px; overflow-x:auto`): pill `padding:8px 15px; border-radius:100px; font-size:13px; weight:600`. Selected → `background:accent; color:#16142a`; else `background:rgba(255,255,255,0.05); color:muted; border:1px solid rgba(255,255,255,0.08)`. Selecting a chip re-themes the whole screen and swaps the unit list.
  - **Unit rows** (`gap:8px`): per row `display:flex; align-items:center; gap:13px; padding:11px 13px; border-radius:14px`. Checked → `border:1px solid rgba(accent,0.32); background:rgba(accent,0.1)`; unchecked → `rgba(255,255,255,0.06)` border / `rgba(255,255,255,0.035)` bg.
    - **Count badge** 34×34, `border-radius:10px`, Cormorant 18px/600 ink, bg `rgba(accent,0.16)` if checked else `rgba(255,255,255,0.06)`; text `×{count}`.
    - Middle (`flex:1`): label 15px/600 ink (`Farḍ`/`Sunnah`/`Witr`) + Arabic Amiri 14px (فرض/سنة/وتر, accent if checked else faint); tag line 11px, ls 0.3px, faint.
    - **Toggle** 24px circle: checked → filled accent w/ `box-shadow:0 0 10px rgba(accent,0.6)` containing a check SVG (`stroke:#16142a`, width 1.9); farḍ rows additionally `opacity:0.8`. Unchecked → `1.5px` ring `rgba(255,255,255,0.2)`.
  - **Totals row** (`padding-top:12px; border-top:1px solid rgba(255,255,255,0.08)`): left breakdown 13px muted (e.g. "3 farḍ · 2 sunnah"); right total Cormorant 22px/600 ink (e.g. "5 rakʿahs").
  - **Confirm button:** `height:50px; border-radius:15px; background:accent; color:#16142a; font-size:15px; weight:700; box-shadow:0 10px 28px rgba(accent,0.3)`, text "Confirm set".

### Rakʿah units data (per prayer)
- **Fajr:** Sunnah before ×2 (emphasised), Farḍ ×2.
- **Dhuhr:** Sunnah before ×4 (emph), Farḍ ×4, Sunnah after ×2 (emph).
- **Asr:** Sunnah before ×4 (optional), Farḍ ×4.
- **Maghrib:** Farḍ ×3, Sunnah after ×2 (emph).
- **Isha:** Farḍ ×4, Sunnah after ×2 (emph), Witr ×3.

**Rules / behavior:**
- **Farḍ is always counted and not toggleable** (cursor default; toggle shown checked at 0.8 opacity; tag "Obligatory").
- Sunnah/Witr default **off**; tapping toggles inclusion.
- Tag text: farḍ → "Obligatory"; witr → "After ʿIshāʾ · witr"; sunnah → `{Before farḍ|After farḍ} · {emphasised|optional}`.
- **Totals:** sum farḍ + toggled sunnah + toggled witr.
- **Rakʿah text rule** (hero §2a): if any sunnah/witr selected → `{total} rakʿahs · {n farḍ + n sunnah + n witr}` (joined with " + "); else → `{farḍ} rakʿahs · farḍ`.

---

## 5. State model
```
{ prayer:'maghrib', language:'en', voice:'hatif',
  guidance:'full', pace:'medium', muezzin:'bilal',
  sheetOpen:bool, units:{ [unitId]:true } }   // units = toggled sunnah/witr only
```
All selections are local screen state; changing `prayer` (chip) recomputes accent/theme everywhere and swaps the composer's unit list. `units` keys are prayer-scoped ids (e.g. `maghrib_sa`).

### Unit ids (prayer-scoped)
- fajr: `fajr_sb` (sunnah before ×2, emph), `fajr_f` (farḍ ×2)
- dhuhr: `dhuhr_sb` (×4 emph), `dhuhr_f` (×4), `dhuhr_sa` (×2 emph)
- asr: `asr_sb` (×4 optional), `asr_f` (×4)
- maghrib: `maghrib_f` (×3), `maghrib_sa` (×2 emph)
- isha: `isha_f` (×4), `isha_sa` (×2 emph), `isha_witr` (×3)

---

## 6. Naming reference (exact spellings)
- Prayers: Fajr الفجر · Dhuhr الظهر · Asr العصر · Maghrib المغرب · Isha العشاء
- Units: Farḍ فرض · Sunnah سنة · Witr وتر
- Voice: Hātif هاتف (TTS guiding voice) · Reciter قارئ
- Muezzins: Bilāl بلال · Idrīs إدريس · Ṣādiq صادق · Yūnus يونس
