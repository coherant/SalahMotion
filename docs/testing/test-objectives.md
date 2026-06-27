# Test Objectives — parking lot

> Status: **PARKING LOT (seeded 2026-06-27).** Captures requirements for unit &
> integration testing ahead of the dedicated test-scaffolding cycle. Sections
> marked `TODO` are for that cycle; the rest records what already exists and the
> constraints/decisions we've locked so we don't relitigate them.

---

## 1. Principles & constraints (locked)

- **Test the CORE, not the view.** The canonical state machine + domain logic are
  the priority; views render core and change freely. (See memory: Core vs View.)
- **Layer by where a test can run** (this drives infra choices in §3):
  - **Host-native** — pure Swift (Foundation/CoreGraphics, no UIKit/SwiftUI),
    deterministic. *Goal: run without a simulator.*
  - **Simulator-required** — anything bound to the iOS app test target as it
    stands today (`xcodebuild test` needs a sim destination; no device-less mode).
  - **Device-visual** — layout/safe-area/animation smoothness. **Manual, on the
    real device** — the simulator is not trustworthy here (the iPhone 11 header
    bug looked fine in-sim, broke on-device).
- **Run discipline:** do NOT boot a sim / run `xcodebuild test` / launch the app
  unless explicitly asked. Compile-only between changes; batch test runs on
  request. (Memory: No Sim/Device Testing Unless Asked; Build Cadence.)
- **New-file gotcha:** new `.swift` files auto-bundle (synced folders), but the
  **test target needs `xcodebuild clean`** before `@testable import` resolves them
  (app builds fine; test fails "Cannot find type X").

---

## 2. Test layers (the pyramid for this app)

| Layer | Tooling | Runs where | Examples |
|---|---|---|---|
| L1 Unit (pure) | Swift Testing (`import Testing`) | host-native *(goal, see §3)* | geometry, moon phase, daily-arc, clock |
| L2 Integration (logic) | Swift Testing | sim today | facade end-to-end, sequence generation |
| L3 Golden snapshot | Swift Testing + `__Snapshots__/` | sim today | guided sequences (`GuidedSnapshotTests`) |
| L4 Device-visual | manual | real device | layout, clipping, animation smoothness |

---

## 3. Infrastructure decisions (TODO — decide in the scaffolding cycle)

- [ ] **Device-free unit tests.** Extract the platform-agnostic domain (starting
      with `Core/Celestial`) into a **local Swift Package** so its tests run with
      `swift test` natively — no simulator — and the app + future watch target
      both depend on it (also serves watchOS portability). *Recommended.*
      - Interim: pure files can be `swiftc`-compiled host-side ad hoc.
- [ ] **Astronomy regression pinning.** Pin Sun/Moon position, rise/set, and phase
      to **USNO / JPL Horizons reference values across spread-out future dates**
      (2026, 2030, 2040…) so a coefficient regression fails before App Store
      submission. (See celestial-complications.md §6.)
- [ ] **CI?** Decide whether/where automated runs happen (and which layers).
- [ ] **Snapshot policy.** When is a golden-snapshot diff an intended update vs a
      regression? Document the review/approve flow.

---

## 4. Unit testing objectives (by area)

Legend: ✅ covered · 🟡 partial · ⬜ TODO

| Area | What to assert | Status |
|---|---|---|
| Celestial geometry | corners/peak/nadir, 5mm topGap, horizon symmetry | ✅ `CelestialDomainTests` |
| Moon phase | elongation→name, waxing/waning split, illuminated fraction, wrap | ✅ |
| Daily-arc mapping | rise/transit/set land on cardinal phases; night fill | ✅ |
| Celestial clock | realtime identity; demo stays within one day | ✅ |
| Uniform ephemeris | uniform velocity across rise; seamless nadir wrap | ✅ |
| Solar ephemeris (Adhan bridge) | phase vs known sunrise/sunset; polar fallback | ⬜ |
| Lunar ephemeris (SwiftAA) | phase + position vs reference; hemisphere flip | ⬜ (pending SwiftAA) |
| Call library (C- namespace) | IDs resolve, shapes, reuse invariants | ✅ `CallLibraryTests` |
| Prayer state machine | idempotency, sequence composition, transitions | ⬜ TODO |
| Prayer calculation | method/madhab/offsets → expected times | ⬜ TODO |
| Notifications | scheduling/toggle logic | ⬜ TODO |
| View-model logic | countdown, upNext wrap, rail fill (pure parts) | ⬜ TODO |

---

## 5. Integration testing objectives

- [ ] **Guided sequence generation** end-to-end → golden snapshot (exists:
      `GuidedSnapshotTests`); extend coverage as composition changes.
- [ ] **Muezzin container toggle** — off path emits byte-for-byte pre-container
      sequence; on path wraps correctly.
- [ ] **Celestial facade** — `CelestialSky.frame(atWallClock:)` composing
      clock + ephemeris + geometry produces a coherent frame for both modes.
- [ ] **Location → engine → times** — coordinate change propagates through
      `PrayerTimesEngine` to displayed/scheduled times (location-tz, not device-tz).
- [ ] TODO: list the cross-component flows that matter most to lock.

---

## 6. Parking lot / open questions
- TODO: prioritise which CORE areas get tests first in the scaffolding cycle.
- TODO: decide SPM extraction scope (just Celestial, or the whole prayer domain).
- TODO: target coverage bar (if any) and what's deliberately left to device-visual.

## Related
- `SalahMotionTests/` — existing suites (`CallLibraryTests`, `GuidedSnapshotTests`,
  `CelestialDomainTests`, `__Snapshots__/`).
- `docs/features/prayer-times/celestial-complications.md` — astronomy test pinning.
- Memory: No Sim/Device Testing Unless Asked · Build Cadence · Core vs View ·
  Synchronized-Group Clean Gotcha.
