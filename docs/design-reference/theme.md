# SalahMotion — "Colours Throughout the Day" Theme System

The app re-skins itself to the **light of each prayer's hour**. This document is
the authoritative colour + theme spec across ALL screens so Claude Code can
reproduce it identically.

There are two layers:
1. **Atmospheric themes** — full-bleed per-prayer gradients used on all
   prayer-facing screens (welcome/entry, dashboard, in-prayer motion, and
   **Guided Prayer Setup**). The setup screen uses whichever prayer is
   currently selected — switching prayer immediately re-skins the screen.
   At app launch, the gradient matches the current time-of-day prayer.
2. **Chrome theme** — a constant calm dark-indigo shell used on true utility
   screens only (Today list, Qibla, Path, Settings), which only borrows each
   prayer's **accent** colour.

---

## 0. Global neutrals & chrome

### Chrome (utility screens) background
`linear-gradient(180deg, #1a1730 0%, #131120 60%, #100e1b 100%)`

> **Note:** Guided Prayer Setup is NOT a chrome screen. It uses the full
> atmospheric per-prayer gradient, updating in real time as the user
> selects a prayer. Text tokens also switch (Dhuhr uses dark ink on its
> light sky gradient). Only Today list, Qibla, Path, and Settings use chrome.

### Chrome text ramp (on the dark shell)
| Token | Value | Use |
|---|---|---|
| ink | `#f4f1fa` | primary text |
| muted | `#b8b2c8` | secondary |
| faint | `#847e98` | labels, tertiary |
| dark-on-accent | `#16142a` | text/icons on accent fills |
| card bg | `rgba(255,255,255,0.035)` | resting card |
| card border | `rgba(255,255,255,0.07)` | resting card border |

### Gallery / artboard background (the showcase page only, not in-app)
`#e7e5df`; section captions `#8a8499`, ls 2.5px uppercase.

---

## 1. Per-prayer theme tokens (CANONICAL — full ramp)

These are the complete token sets (from the In-Prayer motion screen, the richest
source). **Recommend treating this table as the single source of truth** and
generating every prayer-tinted surface from it.

### Fajr — الفجر (dark)
| Token | Value |
|---|---|
| background | `linear-gradient(180deg, #0d1430 0%, #1c2147 36%, #46324f 64%, #8a5560 84%, #d18d6c 100%)` |
| ink | `#f7eef0` |
| muted | `#d8a9b4` |
| faint | `#b78996` |
| faintest | `#7e5f6b` |
| accent | `#eaa9b2` |
| glow | `rgba(234,169,178,0.85)` |
| orb light→dark | `#fce8ec` → `#eaa9b2` |
| orb ink | `rgba(58,30,40,0.55)` |
| light theme? | no |

### Dhuhr — الظهر (LIGHT)
| Token | Value |
|---|---|
| background | `linear-gradient(180deg, #8fb8df 0%, #bcd6ec 42%, #e6eef4 78%, #f4efe6 100%)` |
| ink | `#22323f` |
| muted | `#4f6473` |
| faint | `#6f8593` |
| faintest | `#9aaeba` |
| accent | `#d99a2a` |
| glow | `rgba(217,154,42,0.7)` |
| orb light→dark | `#fff6df` → `#f0c24e` |
| orb ink | `rgba(70,48,8,0.5)` |
| light theme? | **YES** (dark text on light bg) |

### Asr — العصر (dark)
| Token | Value |
|---|---|
| background | `linear-gradient(180deg, #2c3f63 0%, #5b5570 42%, #9c7158 74%, #d59a5c 100%)` |
| ink | `#f7ede1` |
| muted | `#d9b48f` |
| faint | `#b3906f` |
| faintest | `#806750` |
| accent | `#e8b87e` |
| glow | `rgba(232,184,126,0.85)` |
| orb light→dark | `#fbeeda` → `#e8b87e` |
| orb ink | `rgba(60,40,22,0.5)` |
| light theme? | no |

### Maghrib — المغرب (dark)
| Token | Value |
|---|---|
| background | `linear-gradient(180deg, #241640 0%, #6a2c54 36%, #b34440 60%, #db6e3a 80%, #f2a85a 100%)` |
| ink | `#fbeede` |
| muted | `#e6b095` |
| faint | `#bd8771` |
| faintest | `#8a6253` |
| accent | `#f4a86a` |
| glow | `rgba(244,168,106,0.9)` |
| orb light→dark | `#ffe9d4` → `#f4a86a` |
| orb ink | `rgba(64,28,30,0.5)` |
| light theme? | no |

### Isha — العشاء (dark)
| Token | Value |
|---|---|
| background | `radial-gradient(115% 60% at 50% 42%, #201b3a 0%, #141224 50%, #0b0a14 100%)` |
| ink | `#f4f1fa` |
| muted | `#a39db6` |
| faint | `#7d7790` |
| faintest | `#4f4a63` |
| accent | `#9a86c7` |
| glow | `rgba(154,134,199,0.9)` |
| orb light→dark | `#d6c9ee` → `#9a86c7` |
| orb ink | `rgba(22,20,42,0.6)` |
| light theme? | no |

**Neutral helpers per theme** (derive from `light` flag):
- neutralFill: light → `rgba(36,50,63,0.12)`, dark → `rgba(255,255,255,0.16)`
- neutralBorder: light → `rgba(36,50,63,0.30)`, dark → `rgba(255,255,255,0.28)`
- haloColor: light → `rgba(120,90,30,0.18)`, dark → `rgba(255,255,255,0.16)`

---

## 2. Background gradients by context

Some immersive screens use a slightly different background than the canonical
in-prayer one. Match per context:

### Welcome / Entry & Isha-night (deep indigo radial)
`radial-gradient(125% 75% at 50% 6-8%, #251f40 0%, #16142a 46%, #0d0c18 100%)`

### Per-prayer ENTRY screens (standalone "Enter prayer")
- Fajr: `linear-gradient(180deg, #0d1430 0%, #1c2147 36%, #46324f 64%, #8a5560 84%, #d18d6c 100%)`
- Dhuhr: `linear-gradient(180deg, #8fb8df 0%, #bcd6ec 42%, #e6eef4 78%, #f4efe6 100%)`
- Asr: `linear-gradient(180deg, #2c3f63 0%, #5b5570 42%, #9c7158 74%, #d59a5c 100%)`
- Maghrib: `linear-gradient(180deg, #241640 0%, #6a2c54 36%, #b34440 60%, #db6e3a 80%, #f2a85a 100%)`
- Isha: `radial-gradient(125% 75% at 50% 8%, #251f40 0%, #16142a 46%, #0d0c18 100%)`

(These match §1 except Isha entry uses the indigo radial.)

### In-prayer motion screen
Uses §1 canonical backgrounds (Isha = `radial-gradient(115% 60% at 50% 42%, …)`).

---

## 3. Accent variants — IMPORTANT (existing inconsistency)

The current build uses **three slightly different accent hues per prayer**
depending on the screen. To "make it identical," match the column for the screen
you're building; to unify, pick ONE column (recommend **A — In-Prayer canonical**).

| Prayer | A · In-Prayer (canonical) | B · Guided Setup | C · Today/Tab button |
|---|---|---|---|
| Fajr | `#eaa9b2` (rose) | `#e8a07e` (peach) | `#e8a07e` |
| Dhuhr | `#d99a2a` | `#d6a13a` | `#c08326` (tab) / `#e7b23e` (btn) |
| Asr | `#e8b87e` | `#e6a85a` | `#ecb877` (tab) / `#e6a85a` (btn) |
| Maghrib | `#f4a86a` | `#f0a05a` | `#f6b079` (tab) / `#f0a05a` (btn) |
| Isha | `#9a86c7` | `#9a86c7` | `#9a86c7` |

> Recommendation: standardise on **Column A** everywhere and delete B/C. Only
> Isha (`#9a86c7`) is already consistent across all three.

### How accent is applied
- **Selected states** (segmented controls, cards, rows): bg `rgba(accent,0.10–0.18)`, border `rgba(accent,0.32–0.45)`.
- **Filled controls** (Start button, number badge, toggles, chips-selected): solid `accent` with `#16142a` text/icon.
- **Glows**: `box-shadow: 0 0 Npx rgba(accent, 0.5–0.9)`.
- **Eyebrows / active labels**: text colour = accent.

---

## 4. Prayer metadata

| Prayer | Arabic | Time (London) | Farḍ rakʿahs | Eyebrow / phase |
|---|---|---|---|---|
| Fajr | الفجر | 4:52 AM | 2 | Before sunrise / The first light |
| Dhuhr | الظهر | 12:21 PM | 4 | Midday / Sun at its zenith |
| Asr | العصر | 3:47 PM | 4 | Afternoon / Lengthening light |
| Maghrib | المغرب | 6:58 PM | 3 | Sunset / The day closes |
| Isha | العشاء | 8:24 PM | 4 | Night / Stillness |

Shared context strings: location **London**; Hijri **5 Muḥarram 1448**;
Gregorian **Thursday, 21 June**.

### Full rakʿah composition (farḍ + sunnah/witr)
- Fajr: 2 sunnah (emph) + 2 farḍ
- Dhuhr: 4 sunnah (emph) + 4 farḍ + 2 sunnah (emph)
- Asr: 4 sunnah (optional) + 4 farḍ
- Maghrib: 3 farḍ + 2 sunnah (emph)
- Isha: 4 farḍ + 2 sunnah (emph) + Witr (3)

---

## 5. Light vs dark handling

- **Dhuhr is the only LIGHT theme** — text becomes dark (`#22323f` ramp), card
  fills/borders flip to dark-alpha (`rgba(36,50,63,…)`), tab bar uses a white
  glass pill. Every other prayer is dark (white-alpha neutrals, light text).
- Drive this off a single `light` boolean per theme.

---

## 6. Fonts (theme-wide)
- **Cormorant Garamond** (500/600) — display, prayer Latin names, numerals.
- **Manrope** (400–700) — all UI/body/labels.
- **Amiri** (400/700) — all Arabic, `direction: rtl`.
```
https://fonts.googleapis.com/css2?family=Cormorant+Garamond:wght@400;500;600&family=Manrope:wght@400;500;600;700&family=Amiri:wght@400;700&display=swap
```

---

## 7. Signature animations (keyframes)
| Name | Effect | Typical use |
|---|---|---|
| `breathe` | scale 0.93↔1.06, opacity 0.82↔1, ~7s | orbs, glows |
| `drift` | translateY 0↔-4px | floating sun/moon |
| `twinkle` | opacity 0.2↔0.85 | stars (Fajr/Isha) |
| `pulseRing` | scale 0.85→1.5, opacity 0.55→0 | active markers |
| `glowSoft` | box-shadow soft↔strong | welcome moon |
| `haloSpin` | rotate 360°, 60s linear | prayer orb halo |
| `ringDraw` | stroke-dashoffset 207→40 | streak ring |
| `moonPhase` | translateX shift | crescent terminator |
| `wavePulse` | scaleY 0.5↔1 | muezzin waveform |

---

## 8. Suggested token shape (for code)
```ts
type PrayerTheme = {
  key: 'fajr'|'dhuhr'|'asr'|'maghrib'|'isha';
  name: string; ar: string; time: string; rakah: number; eyebrow: string;
  bg: string;            // full-bleed gradient
  ink: string; muted: string; faint: string; faintest: string;
  accent: string; glow: string;
  orbA: string; orbB: string; orbInk: string;
  light: boolean;
};
```
Generate selected/hover/glow surfaces from `accent` via an alpha helper
`rgba(accent, α)` rather than hardcoding tints.
