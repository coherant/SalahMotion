# Observance Sequencer — Refactor Plan

Working document for the staged refactor on branch `observance-sequencer`
(baseline `ab7ae2e`). Goal: make the guided prayer state machine an
**idempotent function of the spec**, then add the **observance layer** that
chains multiple units (e.g. Fajr = Sunnah → Fard) instead of running one unit
that stops at TASLEEM.

This doc is the shared source of truth for the arc. It outlives sessions; keep
it current.

---

## Principles

1. **MD-first.** Update spec docs, then hand-translate Swift to match. Never the reverse.
2. **Golden snapshot is the spine.** Freeze today's emitted `[PrayerState]` arrays
   in a checked-in fixture. Behavior-preserving stages must reproduce it byte-for-byte;
   behavior-changing stages must show a reviewed, intentional diff.
3. **Park the future, sharpen the present.** The *live* spec describes only what the
   code does today — self-consistent, no forward references. All forward-looking
   design lives in `observance-considerations.md` until the stage that implements it.
4. **Make the unit deterministic before composing units.** No observance layer on a
   unit whose spec→build isn't already a pure function.
5. **Small, reversible stages.** Each compiles, builds, passes the snapshot.

---

## The two buckets

| Park (→ `observance-considerations.md`, "not yet implemented") | Sharpen in the live spec (current-truth) |
|---|---|
| I-1 / I-24 *lifetime* (observance-level / once) | Entry-row `5s` durations have no data-model slot — make the live spec match code (code ignores them) |
| Unit selection / order / inclusion | FATIHA_ONLY inheritance — state that its motion sub-phases reuse RAKAT_FULL's utterances |
| Unit-boundary transition semantics | |
| Unit-scoped niyet identity (Sunnah vs Fard) | |
| P-23 closing-dua placement across units | |

The contradiction we currently carry (README invariant #2 says I-1/I-24 are
observance-level "once" + a ⚠ gap note, while the prayer-set tables list them
per-unit) gets resolved by **moving the aspiration out** and reverting the live
invariant to describe current behavior plainly. `observance-considerations.md`
is not throwaway — it is the **seed of the Stage 3 `observances.md` spec**.

---

## Stages

### Stage 0 — Lock the current truth (spec) + golden snapshot
*Collapses the old Stage 0 + Stage 1. Mostly spec; one new test; no behavior change.*
- Create `observance-considerations.md`; move the I-1/I-24 lifetime + all
  composition design into it, clearly marked *not yet implemented*.
- Revert the live invariant (README §5 #2) to describe current behavior: opening
  is I-1 (entry) + I-24 (per-unit, gated by `hasOpeningCue`) + niyet + P-0 +
  Fatiha + surah + P-0. Remove the ⚠ spec↔code gap note.
- Sharpen #2: make the live spec honest about entry-row `5s` (code ignores it —
  remove it from the tables or annotate as non-timed).
- Sharpen #3: add the FATIHA_ONLY inheritance rule to `rakats.md`.
- Build the **golden snapshot test**: emit every `SalatType` + Witr, assert the
  array (id, mode, utterances, durations, motionTrigger, rakatNumber)
  against a checked-in fixture.
- **Exit:** live spec self-consistent and faithful to code; snapshot green; a
  from-spec reader of one unit has zero legal forks.

### Stage 1 — (folded into Stage 0)

### Stage 2 — Introduce unit identity (model, no composition) ✅ DONE
- Spec: documented unit identity in `master-prayer-state-machine.md` (§ Unit identity).
- **Key finding:** the unit model already existed — `PrayerUnit` in `SalatType.swift`,
  and `SalatType.units` already lists each prayer-time's **full composition** (built
  for prayer-setup). We **reused the canonical model** instead of adding a parallel
  one. The guided generator now consumes it.
- Code: `generateUnit(_ unit: PrayerUnit, content:tx:)` composes the existing block
  generators by `unit.rakats` (+ Qunut derived from `kind == .witr`). `generate(salat:)`
  / `witrSequence()` are thin shims; the three per-shape sequence funcs were deleted.
- **Deviations from original plan (approved):** (a) skipped `isFirst:isLast:` — inert
  today and would pre-decide a parked opener question; add in Stage 3. (b) Skipped the
  `session` rename — that word is the *recording-session* concept, correctly named.
- **Exit:** snapshot byte-identical (green); nothing chains yet; fully reversible. ✅

### Stage 3 — The observance layer (new) ✅ DONE
- **The composition table already exists** as `SalatType.units` (see Stage 2 finding)
  — Stage 3 consumes it rather than re-authoring. Promoted `observance-considerations.md`
  → **`observances.md`** (live spec): composition = `SalatType.units`, inclusion =
  `UserPreferences.selectedUnitIds` (farḍ always included, never stored), the three
  resolved transition rules. Composition matches `SalatType.units`.
- Transition semantics authored: niyet replays per unit; I-1 fires once (first unit
  only); subsequent units open `motion` (I-24 stand cue + I-14 reprompt, no I-1);
  timed pie-opening restarts each unit; P-23 once at observance end (`isLast`).
- Code: `generate(salat:language:unitIds:)` filters `salat.units` by
  `isObligatory || unitIds.contains`, then `generateUnit($0, isFirst:, isLast:)` per
  unit. `rakat1Full(isFirst:)` branches timed/motion opener; `tasleem(closingDua:)`
  gates P-23. Witr content (own surahs/niyet) resolved via `content(for:unit:)`.
- **Snapshot:** intentional diff — full observances now emitted (fajr 15→30,
  dhuhr 28→71, asr 28→56, maghrib 22→37, isha 28→65; standalone witr 22 unchanged).
  Test passes explicit full `unitIds` for determinism. Green, reviewed.

### Stage 4 — Runtime + UI chaining (highest risk; device-tested) ✅ DONE (`0681db8`, worked first go on device)
- **Key finding:** the engine already iterated the chained array (array-driven loop);
  yaw re-captures per unit; `.complete` only after the final TASLEEM; one CSV per
  observance. So no engine surgery — only unit-awareness was missing.
- Done: `PrayerState.unitIndex`/`unitLabel` (stamped by `generate`); machine exposes
  `currentUnitIndex`/`unitCount`/`currentUnitLabel` + **per-unit** `totalRakat`;
  `unitTransition` published with a ~2s silent hold at each boundary.
- UI: header shows unit name + per-unit rak'ah + "unit i of N" when `unitCount > 1`
  (single-unit unchanged); `UnitTransitionCardView` overlay ("{from} complete — Begin
  {to}"); `GuidedPrayerView` passes explicit `unitIds`. Decisions: brief titled card
  (~2s auto-dismiss); unit-name header.
- Builds green; snapshot extended with `unit=i:"Label"` (byte-identical otherwise).
- **Still needs real-device iteration:** card timing/feel, header layout, multi-unit
  motion flow on AirPods, rakat-reset across the boundary. No automated net for these.

### Stage 5 — Content correctness ✅ DONE (`cdfabcd`)
- **Per-unit niyet identity:** `I-25` now substitutes the *unit's* intention via
  `niyetName(for:salat:)` — "the Farḍ of {Prayer}" / "the Sunnah of {Prayer}" / "Witr"
  (wording chosen by user). Each unit in a chained observance declares its own niyet.
- **Per-unit surahs:** new `surahs(for:unit:)` keyed by `unit.id` (authoritative table
  in `observances.md` §5). Curation: **every Farḍ unit opens rakat-1 with Al-Ikhlas**
  (user's rule — tawhid at the start of every obligatory prayer); varied spread of the
  seven short surahs `P-11…P-17`, no repeat within a unit or across a unit boundary;
  Witr keeps Al-Aʿlā/Al-Kāfirūn. Dead `makeContent(for:salat)` removed.
- Spec (MD-first): `observances.md` §5 (new) + "Resolved in Stage 5"; README §4 table →
  per-unit pointer; `instructions.md` I-25 note; 5 prayer-sets surah rows → `surah¹`/
  `surah²` placeholders deferring to §5 (witr.md left concrete — fixed surahs).
- **Snapshot:** intentional diff, reviewed — 1135↔1135 lines (no structural change), 40
  changed lines, *every one a recitation line* (niyet + surah text only); all other
  fields (ids, modes, durations, motion, yaw, rakat, `unit=`) byte-identical. Green.
- **Still outstanding:** P-23 Arabic/Turkish translation verification — *moved to the
  parked language refactor* (`LANGUAGE-REFACTOR.md`), where field-level translation work
  belongs (placement was settled in Stage 3). Optional device listen-through of the new
  niyets/surahs.

### Stage 6 — Validation & cleanup ✅ DONE
- **Phase-count checksums (pass):** observance totals = sum of unit checksums (2-rakat
  unit = 15, 3-rakat = 22, 4-rakat = 28) — Fajr 30, Dhuhr 71, Asr 56, Maghrib 37, Isha 65,
  standalone Witr 22. Snapshot section headers match actual `[index]` ranges exactly.
- **ID sync (pass):** `P-0…P-23` + `I-1…I-25` identical across `prayers.json` /
  `PrayerLibrary` / `prayers.md` and `instructions.json` / `InstructionLibrary` /
  `instructions.md`. `observances.md` §5 surah table ↔ `surahs(for:unit:)` — all 12 match.
- **README invariants 2–5 (pass):** yaw-at-last-qiyam, 5s reprompts, P-23 once on `isLast`,
  motion triggers — all verified against code. master-prayer-state-machine.md clean.
- **Two doc drifts fixed:** README §5 invariant 1 (subsequent-unit opener was missing the
  takbīr `P-0` after the niyet — code emits `niyet → P-0 → P-7 → surah → P-0`); README §6
  step 4 (referenced the deleted `makeContent`; now `content(for:unit:)` / §5).
- **`witrSequence()` kept (not redundant):** sole producer of standalone Witr
  (`generate()` always force-includes farḍ, so can't emit Witr in isolation) and the only
  coverage of the cue-less timed opener (`hasOpeningCue == false`). Comment relabelled.
- Snapshot test green; no regen needed (no behaviour change).

---

## Ambiguity → stage

| # | Ambiguity | Stage |
|---|---|---|
| 1 | Opener-lifetime (per-unit vs once) | parked Stage 0 → implemented Stage 3 |
| 2 | Entry-row durations unrepresentable | Stage 0 |
| 3 | FATIHA_ONLY implicit row inheritance | Stage 0 |
| 6 | Niyet has no unit identity | parked Stage 0 → Stage 2/3/5 |
| 4 | Unit selection / order / inclusion | parked Stage 0 → Stage 3 |
| 5 | Unit-boundary transitions | parked Stage 0 → Stage 3 |
| 7 | P-23 repetition across units | parked Stage 0 → Stage 3 |

---

## Decisions owed by the user before Stage 3

- **Sunnah inclusion:** always-on, or user-toggleable (Fard-only mode)?
- **I-24 home:** keep per-unit then hoist in Stage 3, or hoist immediately?
- **P-23 closing dua:** end of every unit, or once at observance end?
- **Madhab scope:** lock Hanafi-flavoured (3-rakat Witr, Asr sunnah ghair
  mu'akkadah), or design the unit model to be madhab-parameterised later?

---

## Status

- Baseline committed `ab7ae2e`; on branch `observance-sequencer`.
- **Stage 0 ✅ committed** (`1346d83`): live spec locked to current truth; golden
  snapshot (`SalahMotionTests/GuidedSnapshotTests.swift` + `__Snapshots__/guided-sequences.txt`,
  584 lines) green. State counts match master phase counts; one yaw-capture per sequence.
- **Stage 2 ✅ committed** (`1e73ade`): generator reuses canonical `PrayerUnit` /
  `SalatType.units`; single `generateUnit` composes by `rakats`; per-shape funcs
  deleted; spec § Unit identity added. Snapshot byte-identical. Key finding:
  composition table already exists in `SalatType.units` — de-risked Stage 3.
- **Stage 3 ✅ committed** (`31a6fb6`): observance layer. `generate(…unitIds:)`
  chains the selected `SalatType.units`; `isFirst`/`isLast` boundary handling
  (motion opener for subsequent units, P-23 once at end). Live spec `observances.md`
  added; README §4-5 + master Notes/Unit-identity reconciled; `observance-considerations.md`
  deleted. Decisions resolved: sunnah toggleable (already modelled via selectedUnitIds);
  I-1 once + I-24 motion opener for later units; P-23 at observance end; Hanafi locked.
  Snapshot regenerated (intentional diff, reviewed, green).
- **Stage 4 ✅ committed** (`0681db8`): unit identity on `PrayerState`, machine unit
  surfaces + per-unit rakat + `unitTransition` boundary hold, header unit chrome,
  `UnitTransitionCardView`. Builds + snapshot green; device-tested (worked first go).
- **Stage 5 ✅ committed** (`cdfabcd`): per-unit niyet identity (`niyetName`) + per-unit
  surahs (`surahs(for:unit:)`, Farḍ always opens Al-Ikhlas) in `content(for:unit:)`;
  `makeContent` removed. Spec: `observances.md` §5 + README §4/instructions.md/prayer-set
  placeholders. Snapshot regenerated (recitation-only diff, reviewed, green).
- **Language refactor parked** (`ed2b21b`, `LANGUAGE-REFACTOR.md`): its own deferred
  track; absorbs the P-23 translation-verification item.
- **Stage 6 ✅ committed** (`9f10564`): validation & cleanup. Phase-count checksums,
  ID sync, and README invariants 2–5 all pass; two README doc drifts fixed (subsequent-unit
  takbīr P-0, stale `makeContent` ref); `witrSequence()` kept (not redundant — sole
  standalone-Witr path + cue-less-opener coverage) with comment relabelled. Snapshot green,
  no regen.
- **The observance-sequencer arc is COMPLETE** (Stages 0–6). No further observance stages.
- **Next build arc → `CONGREGATIONAL-CONTAINER.md`** (THE vision this refactor was the
  skeleton for): the Muezzin frames the salah (Ezan/Iqāma/boundary du'ā/post-salah dhikr)
  but never recites it; **Silent Mode** = motion-gated, the worshipper's body is the clock.
  Supersedes the recitation-hybrid and largely dissolves the language refactor.
