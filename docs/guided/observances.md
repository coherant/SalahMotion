# Observances

An **observance** is the ordered chain of prayer **units** performed at a given
prayer-time. (Vocabulary: phase → unit → observance → prayer-time.) A `unit` is one
niyet→TASLEEM prayer; see the *Unit identity* section of
`master-prayer-state-machine.md`.

The guided generator emits an observance as the concatenation of each unit's
`[PrayerState]`, applying the boundary rules below.

---

## 1. Composition (canonical — `SalatType.units`)

The composition is **not authored here**. It is `SalatType.units` in
`SalatType.swift` (built for prayer-setup), consumed verbatim by the generator. In
execution order:

| Prayer-time | Units (in order) |
|---|---|
| Fajr | SunnahBefore-2 → Fard-2 |
| Dhuhr | SunnahBefore-4 → Fard-4 → SunnahAfter-2 |
| Asr | SunnahBefore-4 (ghair mu'akkadah) → Fard-4 |
| Maghrib | Fard-3 → SunnahAfter-2 |
| Isha | SunnahBefore-4 (ghair mu'akkadah) → Fard-4 → SunnahAfter-2 → Witr-3 |

Hanafi-flavoured (3-rakat Witr; Asr sunnah ghair mu'akkadah) — **locked**; the unit
model is not madhab-parameterised.

## 2. Inclusion (user-selected)

Which units actually run is the worshipper's choice, persisted as
`UserPreferences.selectedUnitIds` (set in prayer-setup's Composer sheet). The
generator walks `SalatType.units` in order and keeps only those whose `id` is in
`selectedUnitIds`; the order of the kept units is unchanged. An unselected unit is
simply omitted.

`isFirst` / `isLast` below refer to position **within the filtered chain**, not
within the full composition.

## 3. Transition semantics (unit boundaries)

**First unit (`isFirst`)** — opens exactly as a standalone unit does: its first
Qiyam is `timed`, plays the `I-1` instructional intro, then `I-24` (when
`hasOpeningCue`) + niyet `I-25` + `P-0` + Al-Fatiha + surah + `P-0`.

**Subsequent units (`isFirst == false`):**
- The `I-1` intro fires **once per observance** — never replayed.
- The opening Qiyam becomes `motion` (trigger `upright`): the worshipper has just
  finished the previous unit seated, so they stand to begin. Entry cue is `I-24`
  ("Stand upright…"); reprompt `I-14` ("Please stand").
- The niyet `I-25` **renews** — each unit declares its own intention.
- Opening prayer rows become `.pace` (motion), not the `.fixed` timed durations.

**Closing dua (`P-23`)** — sounds **once, at the observance's final TASLEEM**
(`isLast`). A non-final unit's `tasleem-left` carries no closing dua.

Everything else is unit-local and unchanged: each unit is its own niyet→TASLEEM, the
pie-timer opening restarts per unit, and the yaw baseline is captured at *that
unit's* last `qiyam-after-ruku` before its TASLEEM.

---

## 4. Runtime & UI (Stage 4)

The engine (`PrayerStateMachine`) runs the whole observance in one pass — it is
array-driven, so the chained `[PrayerState]` needs no special iteration. The yaw
baseline re-captures per unit (each unit's last `qiyam-after-ruku` sets it before
that unit's TASLEEM); `status` becomes `.complete` only after the final TASLEEM; one
session CSV covers the whole observance.

Each `PrayerState` carries its **unit identity** (`unitIndex`, `unitLabel`), stamped
by `generate`. From it the machine exposes `currentUnitIndex`, `unitCount`,
`currentUnitLabel`, and a **per-unit** `totalRakat`.

- **Header.** When `unitCount > 1` the header shows the unit name + its own rak'ah
  count + "unit *i* of *N*" (e.g. "Sunnah · Rak'ah 1/2 · unit 1 of 2"). A single-unit
  observance keeps the plain "Rak'ah X/Y" with no unit chrome.
- **Boundary card.** Crossing from one unit to the next, the machine publishes
  `unitTransition {from,to}` and holds ~2s (silent) while the UI shows a
  "*from* complete — Begin *to*" card; then the next unit's `I-24` motion opener
  runs. Rakat numbering resets at the boundary.

---

## 5. Per-unit content (niyet identity + surahs) — Stage 5

A unit's recitation content (niyet + the two opening-rakat surahs) is resolved
per **unit**, not per prayer-time, by `content(for:unit:)`. This is the authoritative
source for the surah assignment; the prayer-set shape files defer to this table.

### Niyet identity

`I-25` ("Give your niyet for {prayer}") substitutes the unit's identity, so each unit
in a chained observance declares its own intention:

| Unit kind | `{prayer}` substitution | Spoken niyet |
|---|---|---|
| Farḍ | "the Farḍ of *{Prayer}*" | "Give your niyet for the Farḍ of Fajr" |
| Sunnah (before/after) | "the Sunnah of *{Prayer}*" | "Give your niyet for the Sunnah of Fajr" |
| Witr | "Witr" | "Give your niyet for Witr" |

### Surahs (rakat 1 / rakat 2 of each unit)

Drawn from the seven short surahs `P-11…P-17`. Curation rules: **every Farḍ unit opens
(rakat 1) with Al-Ikhlas** — the declaration of tawhid at the start of every obligatory
prayer; no surah repeats inside a unit; no surah repeats across a unit boundary; Witr
keeps its traditional Al-Aʿlā / Al-Kāfirūn.

| Prayer | Unit (`id`) | Rakat 1 | Rakat 2 |
|---|---|---|---|
| Fajr | Sunnah (`fajr_sb`) | Al-Aʿlā `P-16` | Al-Kāfirūn `P-17` |
| | **Farḍ** (`fajr_f`) | **Al-Ikhlas `P-11`** | Al-Falaq `P-13` |
| Dhuhr | Sunnah before (`dhuhr_sb`) | Al-Kawthar `P-14` | Al-Nas `P-12` |
| | **Farḍ** (`dhuhr_f`) | **Al-Ikhlas `P-11`** | Al-ʿAsr `P-15` |
| | Sunnah after (`dhuhr_sa`) | Al-Falaq `P-13` | Al-Aʿlā `P-16` |
| Asr | Sunnah before (`asr_sb`) | Al-Kāfirūn `P-17` | Al-Nas `P-12` |
| | **Farḍ** (`asr_f`) | **Al-Ikhlas `P-11`** | Al-Kawthar `P-14` |
| Maghrib | **Farḍ** (`maghrib_f`) | **Al-Ikhlas `P-11`** | Al-Falaq `P-13` |
| | Sunnah after (`maghrib_sa`) | Al-Kāfirūn `P-17` | Al-Aʿlā `P-16` |
| Isha | Sunnah before (`isha_sb`) | Al-ʿAsr `P-15` | Al-Kāfirūn `P-17` |
| | **Farḍ** (`isha_f`) | **Al-Ikhlas `P-11`** | Al-Nas `P-12` |
| | Sunnah after (`isha_sa`) | Al-Falaq `P-13` | Al-Kawthar `P-14` |
| | Witr (`isha_witr`) | Al-Aʿlā `P-16` | Al-Kāfirūn `P-17` |

Standalone Witr (`witrSequence`) uses the same `isha_witr` content.

---

## Resolved in Stage 5

- ~~Niyet identity~~ → §5. Each unit declares its own niyet ("the Farḍ of Fajr" vs
  "the Sunnah of Fajr"; Witr stands alone).
- ~~Per-unit surahs~~ → §5. Each unit recites its own surahs; Farḍ always opens Al-Ikhlas.

## Micro-enhancement (deferred)

- **`I-1` 5s hold.** `entrySpeech` has no duration slot, so `I-1` is spoken without a
  hold. To make it hold ~5s, add an entry-hold to `PrayerState` / `PrayerStateMachine`
  (small, snapshot-visible change).
