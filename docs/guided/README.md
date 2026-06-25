# Guided Prayer State Machine — Architecture & Rebuild Instructions

**Purpose:** the single entry point for understanding how the guided prayer
sequences are specified and how they are rebuilt into Swift from scratch. If you
read only one file before touching the state machine, read this one.

Calibration is a **separate** state machine (see `../calibration/`) and is out of
scope here.

---

## 0. The Prayer State Machine Taxonomy

- The MD files in `docs/guided/` + `docs/prayers/prayers.md` are the **spec**
  (master source of truth — edit these first).
- They are hand-translated into one Swift file:
  `SalahMotion/Core/PrayerStateMachine/PrayerSequence.swift`
  (`enum GuidedSequenceGenerator`). The MD is **not parsed at runtime** — it is the
  blueprint a human/Claude uses to author the generator.
- Any deviation between this spec and the implementation is a defect, and Claude must flag it immediately. No exceptions.
- Prayer **text** is the exception: it lives in `docs/prayers/prayers.md` (spec)
  and is shipped as `SalahMotion/Resources/prayers.json` (runtime), loaded by
  `Core/Language/PrayerLibrary.swift`. The two must stay in sync; the MD is master.
- **Instructions** — every English-only spoken line that isn't canonical prayer text:
  the `entry` / `reprompt` movement guidance plus the opening **stand-upright / niyet** cues.
  Spec in `docs/guided/instructions.md`, shipped as
  `SalahMotion/Resources/instructions.json` (runtime), loaded by
  `Core/Language/InstructionLibrary.swift`, keyed `I-1 … I-25`. English-only by design.
  `I-25` is templated (`{prayer}` substituted at runtime).

```
SPEC (markdown)                         CODE (Swift)
─────────────────────────────────       ──────────────────────────────────────
docs/guided/rakats.md            ─┐
docs/guided/master-...machine.md ─┼──►  Core/PrayerStateMachine/PrayerSequence.swift
docs/guided/prayer-sets/*.md     ─┘      (GuidedSequenceGenerator)

docs/prayers/prayers.md          ──►    Resources/prayers.json       (loaded by PrayerLibrary.swift)
docs/guided/instructions.md      ──►    Resources/instructions.json  (loaded by InstructionLibrary.swift)
```

---

## 1. The spec layers

| Layer | File(s) | Owns |
|---|---|---|
| 1a. **Text library** | `../prayers/prayers.md` | Every prayer's Arabic / Turkish / English, keyed `P-0 … P-23`. Shipped as `Resources/prayers.json`. |
| 1b. **Instruction library** | `instructions.md` | Every English-only spoken line that isn't prayer text — movement guidance (`entry` / `reprompt`) + opening stand-upright / niyet cues, keyed `I-1 … I-25` (`I-25` templated). Shipped as `Resources/instructions.json`. |
| 2. **Blocks** | `rakats.md` | Reusable position blocks — order, motion trigger, mode, reprompt. **No utterances.** |
| 3. **Structure** | `master-prayer-state-machine.md` | Which blocks compose each prayer variant, rakat numbers, phase counts, yaw-baseline marks. |
| 4. **Content** | `prayer-sets/{prayer}.md` | Per-prayer rows per position: `P-ids` (prayer text), `I-ids` (movement instructions), and guidance levels F / F+P. |

Composition flows 4 → 3 → 2 → 1: a prayer-set fills the positions that the
structure composes from blocks; each `P-id` resolves through the text library and
each `I-id` through the instruction library.

The five blocks (2) are: `RAKAT_FULL`, `RAKAT_FATIHA_ONLY`, `SHORT_TASHAHHUD`,
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
| Instruction lookup | `Core/Language/InstructionLibrary.swift` → `InstructionLibrary.text(_:)`, `enum InstructionID` |
| Per-prayer content | `Tx` (resolved P-id strings) + `Content` (niyet, hasOpeningCue, surahs) |

The runtime engine (`PrayerStateMachine.swift`) consumes the `[PrayerState]` array;
empty utterances/speech are skipped.

---

## 4. Per-prayer composition (verified against code)

`generate(salat:language:unitIds:)` builds an **observance**: it walks
`SalatType.units` in order, keeps those in `unitIds` (default
`UserPreferences.selectedUnitIds`), and `flatMap`s each through
`generateUnit(_:content:isFirst:isLast:)`. One unit's block sequence is fully
determined by its `rakats` count (Qunut derived from `kind == .witr`):

| rakats | Block sequence |
|---|---|
| 2 | `rakat1Full → rakat2Full(yaw) → fullTashahhud(2) → tasleem(2)` |
| 3 | `rakat1Full → rakat2Full → shortTashahhud → rakat3FatihaOnly(yaw) → fullTashahhud(3) → tasleem(3)` |
| 4 | `rakat1Full → rakat2Full → shortTashahhud → rakat3FatihaOnly → rakat4FatihaOnly(yaw) → fullTashahhud(4) → tasleem(4)` |
| Witr (3) | as 3-rakat, but `rakat3FatihaOnly` carries the **Qunut** dua (`P-18…P-22`) |

`(yaw)` marks the block whose `qiyam-after-ruku` sets `capturesYawBaseline: true`
— always the **last** `qiyam-after-ruku` before that unit's Tasleem.

Unit-boundary behaviour (first vs subsequent unit openers, `P-23` placement) is in
`observances.md`.

### Content per prayer (`makeContent`)

| Prayer | hasOpeningCue | niyet | rakat-1 surah | rakat-2 surah |
|---|---|---|---|---|
| Fajr | yes | "Give your niyet for Fajr" | P-11 | P-12 |
| Dhuhr | yes | …Dhuhr | P-11 | P-14 |
| Asr | yes | …Asr | P-15 | P-11 |
| Maghrib | yes | …Maghrib | P-11 | P-13 |
| Isha | yes | …Isha | P-11 | P-12 |
| Witr | no | …Witr | P-16 | P-17 |

---

## 5. Invariants (must hold after any rebuild)

1. **The first unit's opening Qiyam is `timed`.** Entry speech is `I-1`. The opening
   prayer rows are `[I-24 (when hasOpeningCue) →] niyet → P-0 → P-7 (Fatiha) → surah → P-0`
   with `.fixed` durations (I-24 5s, niyet 5s, P-0 3s, Fatiha 2s, surah 2s, P-0 2s). Every
   later position in the unit is `motion` with `.pace`. (Entry speech carries no duration;
   the `—` on `I-1` entry rows in the prayer-sets reflects that.)
   - A **subsequent** unit's opening Qiyam is `motion` (`upright`): entry `I-24`, reprompt
     `I-14`, renewed niyet `I-25`, then `P-7 → surah → P-0` at `.pace` — **no** `I-1`. See
     `observances.md`.
2. **Yaw baseline** is captured at the last `qiyam-after-ruku` before `TASLEEM`, in the
   same unit (yaw is unit-relative).
3. **Reprompt interval = 5s** for all guided motion positions (the `PrayerState`
   default of 8 is overridden everywhere in guided).
4. **Closing dua** "Oh Allah, you are peace and peace comes from you" (`P-23`) is the
   `exitSpeech` of `tasleemLeft` — **once per observance**, on the final unit only
   (`isLast`). Non-final units' `tasleemLeft` carries no closing dua.
5. **Motion triggers:** Ruku→`ruku`, every standing/sitting→`upright`, Sujood→`sujood`,
   Tasleem→`headTurnRight` then `headTurnLeft`.

> Observance composition + unit-boundary semantics are specified in `observances.md`.

---

## 6. Rebuild recipe (MD → Swift, from scratch)

To regenerate `GuidedSequenceGenerator`:

1. **Libraries** — ensure every `P-id` in `prayers.md` exists in `Resources/prayers.json`
   (same ids, all three languages) with a `PrayerID` case, and every `I-id` in
   `instructions.md` exists in `Resources/instructions.json` with an `InstructionID` case.
2. **Block helpers** — author one function per block from `rakats.md`, emitting `PrayerState`s
   with the block's positions, modes, motion triggers, and 5s reprompts:
   `rakat1Full`, `rakat2Full`, `rakat3FatihaOnly`, `rakat4FatihaOnly`, `shortTashahhud`,
   `fullTashahhud`, `tasleem`, plus shared single-state helpers (`ruku`, `qiyamAfterRuku`,
   `sujoodFirst`, `julusBetween`, `sujoodSecond`).
3. **Utterances** — fill each position from the matching `prayer-sets/{prayer}.md` rows:
   `prayer` rows → `prayers`, substituting `P-id` → `tx.P{n}` (resolved text);
   `entry` / `reprompt` rows → `entrySpeech` / `repromptAudio`, substituting
   `I-id` → `InstructionLibrary.text(.i{n})`. The opening **stand-upright / niyet** cues are also
   `I-ids` (the niyet via `InstructionLibrary.text(.i25, prayer:)`), and the closing-dua
   `exit` row is `P-23`. Durations: `.fixed` only in the timed opening, `.pace` elsewhere.
4. **Content** — encode `makeContent` from the per-prayer niyet + surah table (§4).
5. **Compose** — `generateUnit(_:content:isFirst:isLast:)` wires the block order by
   `rakats` (§4), setting `capturesYaw` on the last `qiyam-after-ruku`; apply the unit
   opener / `P-23` boundary rules from `observances.md`. `generate(salat:…)` chains the
   selected `SalatType.units`.
6. **Verify** — phase counts per variant must match `master-prayer-state-machine.md`
   (Fajr 15, Maghrib 22, 4-rakat 28, Witr 22), and the §5 invariants must hold.

---

## 7. Known gaps (none open)

**Every spoken line now resolves through a library** — no prayer-content literals remain in
`PrayerSequence.swift`. Prayer text → `P-ids` (`prayers.json`); movement guidance plus the
opening **stand-upright / niyet** cues → `I-ids` (`instructions.json`). The niyet is the single
templated id **`I-25`** ("Give your niyet for {prayer}"); the closing dua is **`P-23`**. The
only literals left in the guided generator are position **display labels** ("Qiyam", "Ruku", …).

The standing-into-a-rakat cues run a clean ordinal: rakat 2 = `I-2` ("second"),
rakat 3 = `I-10` ("third"), rakat 4 = `I-9` ("fourth") — rakat 1 is the opening takbir
(`I-1`, no number). Dhuhr / Asr / Isha prayer-sets list rakat 3 and rakat 4 as **separate**
`qiyam-fatiha` blocks so spec ↔ code agree; Maghrib / Witr (rakat 3 only) use `I-10` in both.
