# Celestial Complications — Sun & Moon arc in the Up Next Card

> Status: **CONCEPT BUILT & SIM-VERIFIED (2026-06-27).** The view-free
> `Core/Celestial/` domain + unit tests are in, and `CelestialArcView` is wired
> into the Up Next card in **concept mode** (Moon opposite Sun, 24h / 20s),
> confirmed animating + clipping on the iPhone 11 simulator. Still TODO:
> on-device tuning (topGap/bodyRadius), add **SwiftAA** → switch to `.live()` for
> the real Moon, and a coarser realtime TimelineView cadence (see §8).
> A "complication" here is the watch-face sense: a small live astronomical
> adornment inside the Up Next card.

The Up Next card on the Prayer Times screen gains a background animation: the
**Sun** and the **Moon** trace an arc across the card — rising from one bottom
corner, peaking near the top, setting at the other bottom corner — driven by the
real position of each body for the user's date and location. Below the horizon
they are clipped away. It is purely cosmetic (a **view** concern, not Core /
state-machine), and sits *behind* every existing fixture in the card.

---

## 1. Concept

- A celestial body's centre travels a full ellipse once per day. The ellipse's
  diameter is the card's **bottom edge** (the horizon). Only the part of the
  path above the horizon is visible; below it the body is clipped.
- A body crossing a bottom corner shows as a half-disc on the horizon — the
  sunrise / sunset (and moonrise / moonset) moment, which falls out of the
  geometry for free.
- **Concept / test mode:** Sun and Moon are diametrically opposed (180° apart)
  and sweep uniformly, 24 h compressed into 20 s, just to validate the motion.
- **Target / production mode:** each body sits at its *real* position for the
  current time + location (see §5–§7). Position is a pure function of time, so
  there is no animation state to preserve (see §8).

---

## 2. Geometry (the heart of it)

Inside the card's content rect (width `W`, height `H`):

```
horizonY = H            // card's literal bottom edge (DECISION: §4)
Rx       = W / 2        // path spans corner-to-corner
Ry       = H - bodyRadius - topGap   // arch height (DECISION: topGap ≈ 5 mm)
```

Phase `t ∈ [0,1)` is the fraction through the day. Angle and point:

```
θ_sun  = π − 2π·t            // t=0 → left corner, .25 → peak, .5 → right corner, .75 → nadir
θ_moon = θ_sun + π           // concept only — diametrically opposed

x(θ) = W/2 + Rx·cos(θ)       // cos π = −1 → x=0 (left); cos 0 = +1 → x=W (right)
y(θ) = horizonY − Ry·sin(θ)  // sin π/2 = 1 → peak; sin(−π/2) = −1 → below horizon
```

A body is **above the horizon** when `sin(θ) > 0`.

This `position(phase:in:) -> CGPoint` is a **pure function** — no SwiftUI — and is
the one piece that gets a unit test.

Because the card is wide and short, this is an **ellipse**, not a true circle: a
real circle of radius `W/2` would tower far above the card.

---

## 3. Layering & clipping discipline (the part to get exactly right)

Because the horizon **is** the card's literal edge, "below horizon" and "outside
the card" are the *same boundary* — the card's rounded silhouette. So a **single
clip authority** enforces everything.

Target structure of `upNextCard`:

```
VStack { up-next text · countdown · dayRail }      ← FIXTURES (unchanged, always on top)
  .padding(20)
  .background(
      ZStack {
          RoundedRectangle(r:24).fill(gradient)     ← existing card fill
          CelestialArc()                            ← sun + moon, GeometryReader-driven
      }
      .clipShape(RoundedRectangle(r:24))            ← THE single clip authority
      .overlay(RoundedRectangle(r:24).strokeBorder) ← border, applied AFTER the clip
  )
```

Guarantees this gives:

1. **Behind all fixtures** — the arc lives in `.background`, strictly behind the
   `VStack` content (text + rail). Structural, not an opacity trick.
2. **Never outside the card** — the `clipShape` wraps `{fill + celestial}` with
   the *exact* `RoundedRectangle(24)` that defines the card. Sides, rounded
   corners, and below the bottom edge (= below horizon) are all cut by one clip.
3. **Crisp border, behind the border** — the stroke is an `.overlay` applied
   *after* the clip, so bodies can't paint over the border and the border isn't
   clipped to half width.

Specific failure modes and the rule for each:

- **Single shape constant.** Define `RoundedRectangle(cornerRadius: 24)` once and
  reuse it for fill, clip, and stroke. If they drift you get leaks or a clipped
  border. No extra inset on the clip.
- **No second clip.** `CelestialArc` itself gets **no** `.clipShape`; the
  card-level clip is the only authority. A nested clip only risks a mismatch.
- **All glow/shadow lives *inside* the clip.** The Sun's radial-gradient glow and
  any `.shadow` are composed on the body *within* the clipped `ZStack`. Nothing
  with blur is applied after `.clipShape`, or a halo would bleed past the edge.
  The clip is the outermost cosmetic boundary.
- **Corners are intentional.** With `Rx = W/2`, sunrise/sunset centres sit at the
  rounded bottom corners, so a body *emerges from behind the rounded corner*
  rather than a sharp point. Natural look; revisit `Rx` inset on device if needed.
- **Position, don't rotate.** Place bodies by computed `.position` (kept upright),
  not `rotationEffect` around the corner — rotation would spin the crescent moon
  and need counter-rotation.

---

## 4. Locked decisions

| Decision | Choice |
|---|---|
| Horizon line | The card's **literal bottom edge**. The day-rail is a fixture and stays on top. |
| Legibility | Sun & Moon are **completely behind all fixtures** in the card (structural via `.background`). |
| Arch height | At the peak, the **top of the disc** sits **≈ 5 mm below the card's top edge**. → `Ry = H − bodyRadius − topGap`, `topGap ≈ 30 pt` (iOS ≈ 0.156 mm/pt; sanity-checked vs the 44 pt ≈ 7 mm tap-target heuristic). Tune on device. |
| Visible path track | **No** — only the moving bodies. |
| Astronomy library | **Vendor SwiftAA** (Meeus / AA+ wrapper) for the Moon. |

---

## 5. Astronomy model — the Sun (already in the repo)

`Core/Prayer/Adhan/Astronomy/` is a **vendored Meeus implementation** — the same
code that computes the shipping prayer times. It already provides the full chain:
`julianDay / julianCentury` → `apparentSolarLongitude` → obliquity + nutation →
RA/Dec → `meanSiderealTime` → `altitudeOfCelestialBody` / `correctedTransit` /
`correctedHourAngle`.

So the Sun needs **zero new astronomy**:
- sunrise → left corner, solar transit → peak, sunset → right corner;
- altitude between them drives height on the arc.

Deterministic, offline, already field-validated.

---

## 6. Astronomy model — the Moon (new, via SwiftAA)

The vendored Adhan code has only `meanLunarLongitude` + ascending node — present
**only for the nutation correction**. That is the Moon's *mean* longitude, which
can be ~6° from the truth (equation of centre, evection, variation). Using it
directly would visibly lag the real Moon. So the Moon is genuinely missing.

**Plan:** add **SwiftAA** (vendored, per the locked decision). Take the Moon's
geocentric coordinates from SwiftAA, convert to RA/Dec, and feed the **existing**
generic rise/set machinery (`altitudeOfCelestialBody`, `correctedHourAngle`,
sidereal time) — that engine is "celestial body" generic; it has only ever been
handed solar coordinates. Moonrise / transit / moonset and altitude fall out.

### Why there is **no drift risk** (the reputational concern)

Drift in production comes from exactly two things, both of which we avoid:

1. **Naive linear approximations** — e.g. "days since a known new moon ÷ 29.53".
   These accumulate error (off by a day after a few years) because the synodic
   month varies. **This is the trap; we do not use it.**
2. **Aging external data** — TLEs, high-precision ΔT / leap-second tables. Not
   relevant at our fidelity.

The Meeus / ELP periodic-term approach (what SwiftAA implements) is neither: it
evaluates `position = f(Julian date)` fresh every call, valid for **millennia**
with the stated accuracy. It cannot drift — it is not extrapolating from a fixed
epoch. The only time-varying fudge factor is ΔT (TT−UT), which is sub-pixel here.

**Accuracy vs. need:** the arc is ~300 pt wide for 24 h → ~5 min per point.
Meeus gives Moon position to < 0.01° and rise/set to ~1–2 min — pixel-perfect with
huge margin. Fully offline; inputs are only the device clock + the known location.

### Regression-proofing (so a future edit can't silently break it)

Pin unit tests to **JPL Horizons / USNO reference values across spread-out future
dates** (2026, 2030, 2040 …) for Sun & Moon position, rise/set, and phase. A
fat-fingered coefficient then fails CI before it ever reaches the App Store
review queue.

---

## 7. Moon phase — waxing / waning

Everything collapses to a **single number**, the elongation fraction:

```
phase = wrap360(λ_moon − λ_sun) / 360       // ∈ [0,1)
```

It encodes **both** how lit the disc is **and** the direction:

| phase | elongation | state |
|---|---|---|
| 0.0 | 0° | New |
| 0–0.25 | 0–90° | Waxing crescent |
| 0.25 | 90° | First quarter |
| 0.25–0.5 | 90–180° | Waxing gibbous |
| 0.5 | 180° | Full |
| 0.5–0.75 | 180–270° | Waning gibbous |
| 0.75 | 270° | Last quarter |
| 0.75–1.0 | 270–360° | Waning crescent |

- **Waxing vs waning is simply `phase < 0.5` vs `> 0.5`.** Illuminated fraction
  alone *cannot* tell first quarter from last quarter (both 50% lit); elongation
  is monotonic through the cycle, so it resolves the direction.
- **Renders for free:** this matches the convention `MoonPhaseShape.swift`
  already uses (`0 = new, 0.5 = full, waxing ≤ 0.5`). Feed it `phase`.
- **SwiftAA:** read `λ_moon`, `λ_sun` (geocentric ecliptic longitudes), subtract,
  normalise → `phase`. For an accurate "% illuminated" *label*, use SwiftAA's
  `illuminatedFraction()` directly (real orbit), not a derived value. SwiftAA
  does **not** expose a waxing/waning flag — that's why the longitude-difference
  is the technique.

### ⚠ Hemisphere flip (matters for the Melbourne default)

`MoonPhaseShape` lights the disc using the **Northern Hemisphere** convention
(waxing = lit on the right). The default / home location is **Melbourne**
(Southern Hemisphere), where the Moon appears **mirrored** (waxing crescent lit
on the **left**). Out of the box the crescent would face the wrong way for the
primary audience.

**Fix:** mirror the shape horizontally when `latitude < 0` (`.scaleEffect(x: -1)`
or a `southern` flag into the shape). Build this in from the start. (The fuller
version — parallactic-angle tilt that rotates the bright limb by sky position — is
over-engineering for a card; a hemisphere mirror is the right target.)

### Phase behaviour per mode
- **Real-time:** the crescent evolves correctly over days (~0.034 phase/day),
  imperceptible within a session but right whenever the screen reopens.
- **Demo (24 h / 20 s):** one compressed day barely changes phase — pin the demo
  to *today's* real phase. To actually watch it wax/wane, advance the *date* too
  (e.g. a lunar month per loop), but that decouples it from the daily solar arc,
  so keep separate unless requested.

---

## 8. Animation lifecycle & the "flag" (designed for target, not testing)

**Key insight:** if `position = f(realTime, location)`, there is no animation
state to pause or resume. Every frame renders `f(now)`. Leave the tab, background
the app, come back next week — it reads the clock and is instantly correct. No
bookkeeping, no resume drift. This is what makes "click around and return" work.

Production design:
- `isActive = (router.selectedTab == .prayerTimes) && (scenePhase == .active)`.
  `router.selectedTab` is reliable in a `TabView` (the view stays alive, so
  `onAppear` is **not** reliable per tab switch); `scenePhase` covers
  backgrounding.
- `TimelineView(.animation(paused: !isActive))` — off-screen / backgrounded it
  stops requesting frames (battery), and snaps to the correct current position
  the instant it becomes active again.
- **Cadence matched to motion.** Real-time: Moon ~0.5°/hr, Sun ~15°/hr →
  sub-pixel per second → a **once-a-minute** schedule is plenty, no 60 fps burn.
  Demo (24 h / 20 s): full frame rate via `.animation`.
- A `timeSource` abstraction — `.realtime` (production) or
  `.demo(secondsPerDay: 20)` — feeds the same geometry. Even in demo, base phase
  on `wallClock mod 20` (not an accumulating counter) so returning mid-loop is
  continuous and correct.

---

## 9. Tunables
`cycleDuration` (demo: 20 s), `bodyRadius`, `topGap` (≈ 5 mm / ~30 pt), `Rx`
inset, Sun/Moon colours + glow intensity, body opacity / z-order. (No path track.)

---

## 10. Build order

1. **Pure geometry helper** — `position(phase:in:)`; unit-tested.
2. **Vendor SwiftAA**; wrap Sun (reuse Adhan) + Moon (SwiftAA) into an ephemeris
   service returning, for a given date+location: each body's arc phase, above-
   horizon flag, and the Moon's `phase` (elongation fraction).
3. **Reference-value unit tests** (USNO / Horizons) for position, rise/set, phase.
4. **Body views** — `SunView` (glow internal) + Moon via existing
   `MoonPhaseShape` with hemisphere mirror.
5. **`CelestialArc`** — `GeometryReader` → `TimelineView(.animation(paused:))`,
   places bodies by `.position`; **no clip here**.
6. **Card integration** — restructure `upNextCard.background` into the clipped
   stack (§3). Card sizing unchanged → no layout shift to rail / list.
7. **Tune on device** (iPhone 11 — do **not** trust the simulator for layout /
   safe-area, per the header bug): `topGap`, `bodyRadius`, `Rx`, glow.

---

## 11. Open decisions
- Sun/Moon styling (glow palette, crescent treatment, sizes) — needs a design pass.
- Demo mode: pin to today's phase (default) vs. advance date to watch wax/wane.
- Whether the real-time tick is 1 min or coarser.

---

## Related
- `SalahMotion/Features/PrayerTimes/PrayerTimesView.swift` — `upNextCard`, `dayRail`.
- `SalahMotion/DesignSystem/Components/MoonPhaseShape.swift` — phase renderer.
- `SalahMotion/Core/Prayer/Adhan/Astronomy/` — vendored Meeus solar engine.
- Memory: PrayerTimes header device bug (verify layout on device, not sim).
