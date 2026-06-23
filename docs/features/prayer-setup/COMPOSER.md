# Guided Prayer Setup — Rakʿah Composer Sheet

The bottom sheet opened by tapping the hero card or its **"Change"** pill on the
Guided Prayer Setup screen. Lets the user pick the prayer and toggle which rakʿah
units are included. Reflects the current build (Done-only, no confirm button, no
totals row).

Pairs with `SPEC.md` (full screen), `THEME.md` (day colours), `SETUP-THEMED.md`
(themed background + sheet tint).

---

## 1. Structure (top → bottom)

1. **Backdrop** — dims + blurs the screen behind. Tap to close.
2. **Grab handle** — 40×4 pill, centered.
3. **Header row** — left: eyebrow "Prayer set" + title "Compose the session"; right: **Done** (closes the sheet). *This is the only dismiss control.*
4. **Prayer chips** — horizontal, selectable: Fajr · Dhuhr · Asr · Maghrib · Isha. Selecting re-themes the whole screen and swaps the unit list.
5. **Unit rows** — one per rakʿah unit for the selected prayer (farḍ / sunnah / witr). Toggle to include.

> Removed: the "Confirm set" button and the bottom totals row (breakdown + rakʿah count). The hero card on the screen still shows the live rakʿah summary.

---

## 2. Tokens

`accent` = current prayer accent · `rgba(accent,α)` = accent at alpha α.

| Token | Value |
|---|---|
| ink | `#f4f1fa` |
| muted | `#b8b2c8` |
| faint | `#847e98` |
| dark-on-accent | `#16142a` |
| label eyebrow | `11px / ls 2.5px / uppercase / 600 / faint` |

---

## 3. Element specs (at 402×874)

### Backdrop
`position:absolute; inset:0; background:rgba(8,7,16,0.62); backdrop-filter:blur(3px); z-index:20`. Tap → close.

### Sheet container
`position:absolute; left/right/bottom:0; z-index:21; border-radius:28px 28px 0 0; border-top:1px solid rgba(255,255,255,0.09); box-shadow:0 -22px 54px rgba(0,0,0,0.55); padding:12px 22px 24px; display:flex; flex-direction:column; gap:15px; max-height:86%`.
- **Background — neutral:** `linear-gradient(180deg, #221d3a, #16142a)`
- **Background — themed (Option B):** `linear-gradient(180deg, rgba(accent,0.16), #1b1730 42%, #16142a)`

### Grab handle
`width:40px; height:4px; border-radius:2px; background:rgba(255,255,255,0.18); align-self:center`.

### Header row
`display:flex; align-items:baseline; justify-content:space-between`.
- Left: eyebrow **"Prayer set"** (label style) + title **"Compose the session"** — Cormorant 23px / 500 / ink, `margin-top:2px`.
- Right: **"Done"** — 14px / 600 / color `accent`, `cursor:pointer`. Closes the sheet.

### Prayer chips
Row `gap:8px; overflow-x:auto`. Each pill `padding:8px 15px; border-radius:100px; font-size:13px; weight:600`.
- Selected: `background:accent; color:#16142a`.
- Unselected: `background:rgba(255,255,255,0.05); color:muted; border:1px solid rgba(255,255,255,0.08)`.

### Unit rows
Column `gap:8px`. Each row `display:flex; align-items:center; gap:13px; padding:11px 13px; border-radius:14px`.
- Checked: `border:1px solid rgba(accent,0.32); background:rgba(accent,0.10)`.
- Unchecked: `border:1px solid rgba(255,255,255,0.06); background:rgba(255,255,255,0.035)`.
- **Count badge** (left): 34×34, `border-radius:10px`, Cormorant 18px/600 ink; bg `rgba(accent,0.16)` if checked else `rgba(255,255,255,0.06)`; text `×{count}`.
- **Middle** (`flex:1`): label 15px/600 ink (`Farḍ` / `Sunnah` / `Witr`) + Arabic Amiri 14px (فرض / سنة / وتر, accent if checked else faint); tag line 11px / ls 0.3px / faint.
- **Toggle** (right): 24px circle. Checked → filled `accent` + `box-shadow:0 0 10px rgba(accent,0.6)` with a `#16142a` check (SVG, stroke-width 1.9); farḍ rows additionally `opacity:0.8`. Unchecked → `1.5px` ring `rgba(255,255,255,0.2)`.

---

## 4. Behaviour

- **Open:** tap hero card or its "Change" pill → `sheetOpen = true`.
- **Close:** **Done** button, or tap backdrop. (No confirm step — selections apply live.)
- **Prayer chip:** sets `prayer` → re-themes screen + swaps unit list.
- **Farḍ rows:** always counted, **not toggleable** (cursor default; toggle drawn checked at 0.8 opacity; tag "Obligatory").
- **Sunnah / Witr rows:** default **off**; tap toggles inclusion (`units[id]`).
- **Live summary:** the hero card's rakʿah line updates from the selection — `{total} rakʿahs · {n farḍ + n sunnah + n witr}`, or `{farḍ} rakʿahs · farḍ` when nothing optional is selected.

### Tag text
- Farḍ → `Obligatory`
- Witr → `After ʿIshāʾ · witr`
- Sunnah → `{Before farḍ | After farḍ} · {emphasised | optional}`

---

## 5. Units per prayer (id · kind · count · default)

| Prayer | Units |
|---|---|
| **Fajr** | `fajr_sb` sunnah ×2 (emph, before, off) · `fajr_f` farḍ ×2 (on, locked) |
| **Dhuhr** | `dhuhr_sb` sunnah ×4 (emph, before, off) · `dhuhr_f` farḍ ×4 (locked) · `dhuhr_sa` sunnah ×2 (emph, after, off) |
| **Asr** | `asr_sb` sunnah ×4 (optional, before, off) · `asr_f` farḍ ×4 (locked) |
| **Maghrib** | `maghrib_f` farḍ ×3 (locked) · `maghrib_sa` sunnah ×2 (emph, after, off) |
| **Isha** | `isha_f` farḍ ×4 (locked) · `isha_sa` sunnah ×2 (emph, after, off) · `isha_witr` witr ×3 (off) |

`units` state holds only the toggled-on optional ids (e.g. `{ maghrib_sa: true }`); farḍ is always counted regardless.
