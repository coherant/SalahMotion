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
  array (id, mode, utterances, durations, motionTrigger, capturesYaw, rakatNumber)
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

### Stage 4 — Runtime + UI chaining (highest risk; device-tested)
- `PrayerStateMachine` iterates the chained array; per-unit rakat numbering + unit
  index; observance-spanning progress.
- `GuidedPrayerView` advances unit→unit at TASLEEM instead of completing; unit-boundary
  affordance ("Sunnah complete → begin Fard"); History records the observance.
- **No snapshot net here** — needs real-device iteration. Expect a round or two.

### Stage 5 — Content correctness
- Unit-scoped niyet (names Sunnah vs Fard); surah verification per unit; Witr opener
  decision; P-23 placement confirmed; P-23 Arabic/Turkish verification (outstanding).

### Stage 6 — Validation & cleanup
- Phase counts re-derived as observance totals (checksums, not generators).
- Re-verify every README invariant; final MD↔code↔JSON sync sweep.

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
- **Stage 3 ✅ complete** (uncommitted): observance layer. `generate(…unitIds:)`
  chains the selected `SalatType.units`; `isFirst`/`isLast` boundary handling
  (motion opener for subsequent units, P-23 once at end). Live spec `observances.md`
  added; README §4-5 + master Notes/Unit-identity reconciled; `observance-considerations.md`
  deleted. Decisions resolved: sunnah toggleable (already modelled via selectedUnitIds);
  I-1 once + I-24 motion opener for later units; P-23 at observance end; Hanafi locked.
  Snapshot regenerated (intentional diff, reviewed, green).
- **Next action:** commit Stage 3, then Stage 4 — runtime + UI chaining (highest risk,
  no snapshot net, device-tested).
