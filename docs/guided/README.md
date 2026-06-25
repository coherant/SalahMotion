# Guided Prayer State Machine — Architecture & Rebuild Guide

**Purpose:** the single entry point for understanding how the guided prayer
sequences are specified and how they are rebuilt into Swift from scratch. If you
read only one file before touching the state machine, read this one.

Calibration is a **separate** state machine (see `../calibration/`) and is out of
scope here.

---

## 0. TL;DR

- The MD files in `docs/guided/` + `docs/prayers/prayers.md` are the **spec**
  (master source of truth — edit these first).
- They are hand-translated into one Swift file:
  `SalahMotion/Core/PrayerStateMachine/PrayerSequence.swift`
  (`enum GuidedSequenceGenerator`). The MD is **not parsed at runtime** — it is the
  blueprint a human/Claude uses to author the generator.
- Prayer **text** is the exception: it lives in `docs/prayers/prayers.md` (spec)
  and is shipped as `SalahMotion/Resources/prayers.json` (runtime), loaded by
  `Core/Language/PrayerLibrary.swift`. The two must stay in sync; the MD is master.

```
SPEC (markdown)                         CODE (Swift)
─────────────────────────────────       ──────────────────────────────────────
docs/guided/rakats.md            ─┐
docs/guided/master-...machine.md ─┼──►  Core/PrayerStateMachine/PrayerSequence.swift
docs/guided/prayer-sets/*.md     ─┘      (GuidedSequenceGenerator)

docs/prayers/prayers.md          ──►    Resources/prayers.json  (loaded by PrayerLibrary.swift)
```

---

## 1. The four spec layers

| Layer | File(s) | Owns |
|---|---|---|
| ① **Text library** | `../prayers/prayers.md` | Every prayer's Arabic / Turkish / English, keyed `P-0 … P-22`. Shipped as `Resources/prayers.json`. |
| ② **Blocks** | `rakats.md` | Reusable position blocks — order, motion trigger, mode, reprompt. **No utterances.** |
| ③ **Structure** | `master-prayer-state-machine.md` | Which blocks compose each prayer variant, rakat numbers, phase counts, yaw-baseline marks. |
| ④ **Content** | `prayer-sets/{prayer}.md` | Per-prayer utterances per position (P-ids + guidance levels F / F+P). |

Composition flows ④ → ③ → ② → ①: a prayer-set fills the positions that the
structure composes from blocks, and each utterance resolves through the text library.

The five blocks (②) are: `RAKAT_FULL`, `RAKAT_FATIHA_ONLY`, `SHORT_TASHAHHUD`,
`FULL_TASHAHHUD`, `TASLEEM`.

---

## 2. What is NOT a source

- `docs/guided/prayers-for-each-state-in-state-machine.md` — **deleted** (commit
  `79ff61d`). It was a stale, divergent duplicate of `prayer-sets/`. No code referenced it.
- Anything under `docs/calibration/` — that is the calibration state machine
  (`CalibrationSequenceGenerator`), a different sequence with its own thresholds.

---

## 3. Runtime model (Swift surfaces)

All in `Core/PrayerStateMachine/PrayerSequence.swift` unless noted:

| Concept | Swift symbol |
|---|---|
| One position | `struct PrayerState` |
| Position identity | `enum PrayerStateID` — naming `r{N}…` / `julus…` / `tasleem…` (MD convention `rakat{N}_{position}`) |
| Phase behaviour | `enum PhaseMode` — `auto` / `timed` / `motion` / `timedMotion` |
| Sensor gate | `enum MotionTrigger` — `ruku` / `sujood` / `upright` / `headTurnRight` / `headTurnLeft` |
| Pause length | `enum PrayerDuration` — `.pace` (user setting) / `.fixed(seconds)` |
| Generator | `enum GuidedSequenceGenerator` — `generate(salat:language:)` |
| Text lookup | `Core/Language/PrayerLibrary.swift` → `PrayerLibrary.text(_:_:)`, `enum PrayerID` |
| Per-prayer content | `Tx` (resolved P-id strings) + `Content` (niyet, hasEzan, surahs) |

The runtime engine (`PrayerStateMachine.swift`) consumes the `[PrayerState]` array;
empty utterances/speech are skipped.

---

## 4. Per-prayer composition (verified against code)

`generate(salat:)` dispatches:

| Prayer | Builder | Block sequence |
|---|---|---|
| Fajr | `fajrSequence` | `rakat1Full → rakat2Full(yaw) → fullTashahhud(2) → tasleem(2)` |
| Maghrib | `maghribSequence` | `rakat1Full → rakat2Full → shortTashahhud → rakat3FatihaOnly(yaw) → fullTashahhud(3) → tasleem(3)` |
| Dhuhr / Asr / Isha | `fourRakatSequence` | `rakat1Full → rakat2Full → shortTashahhud → rakat3FatihaOnly → rakat4FatihaOnly(yaw) → fullTashahhud(4) → tasleem(4)` |
| Witr | `witrSequence` | as Maghrib, but `rakat3FatihaOnly` carries the **Qunut** dua (`P-18…P-22`) as extra prayers |

`(yaw)` marks the block whose `qiyam-after-ruku` sets `capturesYawBaseline: true`
— always the **last** `qiyam-after-ruku` before Tasleem.

### Content per prayer (`makeContent`)

| Prayer | hasEzan | niyet | rakat-1 surah | rakat-2 surah |
|---|---|---|---|---|
| Fajr | yes | "Give your niyet for Fajr" | P-11 | P-12 |
| Dhuhr | yes | …Dhuhr | P-11 | P-14 |
| Asr | yes | …Asr | P-15 | P-11 |
| Maghrib | yes | …Maghrib | P-11 | P-13 |
| Isha | yes | …Isha | P-11 | P-12 |
| Witr | no | …Witr | P-16 | P-17 |

---

## 5. Invariants (must hold after any rebuild)

1. **First Qiyam of a session is `timed`** with `.fixed` durations (Ezan 5s, niyet 5s,
   P-0 3s, Fatiha 2s, surah 2s, P-0 2s). Every later position is `motion` with `.pace`.
2. **Opening order:** `[Listen to the Ezan?] → niyet → P-0 → P-7 (Fatiha) → surah → P-0`.
   Ezan row is present only when `hasEzan` (absent for Witr).
3. **Yaw baseline** is captured at the last `qiyam-after-ruku` before `TASLEEM`, in the
   same session (yaw is session-relative).
4. **Reprompt interval = 5s** for all guided motion positions (the `PrayerState`
   default of 8 is overridden everywhere in guided).
5. **Closing dua** "Oh Allah, you are peace and peace comes from you" is the `exitSpeech`
   of `tasleemLeft`.
6. **Motion triggers:** Ruku→`ruku`, every standing/sitting→`upright`, Sujood→`sujood`,
   Tasleem→`headTurnRight` then `headTurnLeft`.

---

## 6. Rebuild recipe (MD → Swift, from scratch)

To regenerate `GuidedSequenceGenerator`:

1. **Text library** — ensure every `P-id` in `prayers.md` exists in `Resources/prayers.json`
   (same ids, all three languages). Add a `PrayerID` case per id.
2. **Block helpers** — author one function per block from `rakats.md`, emitting `PrayerState`s
   with the block's positions, modes, motion triggers, and 5s reprompts:
   `rakat1Full`, `rakat2Full`, `rakat3FatihaOnly`, `rakat4FatihaOnly`, `shortTashahhud`,
   `fullTashahhud`, `tasleem`, plus shared single-state helpers (`ruku`, `qiyamAfterRuku`,
   `sujoodFirst`, `julusBetween`, `sujoodSecond`).
3. **Utterances** — fill each position's `prayers` from the matching `prayer-sets/{prayer}.md`
   row, substituting `P-id` → `tx.P{n}` (resolved text) and keeping inline instruction
   strings verbatim. Durations: `.fixed` only in the timed opening, `.pace` elsewhere.
4. **Content** — encode `makeContent` from the per-prayer niyet + surah table (§4).
5. **Compose** — wire each `…Sequence` builder to the block order in
   `master-prayer-state-machine.md` (§4), setting `capturesYaw` on the correct block.
6. **Verify** — phase counts per variant must match `master-prayer-state-machine.md`
   (Fajr 15, Maghrib 22, 4-rakat 28, Witr 22), and the §5 invariants must hold.

---

## 7. Known gap (tracked, not yet resolved)

Instructional speech — `entrySpeech`, `repromptAudio`, `exitSpeech`, plus the
opening **Ezan / niyet** rows and the **closing dua** — are **inline English literals**
in `PrayerSequence.swift`, not `P-ids`. They are English-only and bypass the
`prayers.json` library. Converting the *prayer-content* literals (Ezan, niyet,
closing dua) to P-ids is the scoped refactor; movement instructions are intentionally
left as literals. See the `prayer-state-machine-tuning` branch work.
