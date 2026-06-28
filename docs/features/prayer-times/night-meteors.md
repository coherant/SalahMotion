# Night Meteors — the occasional shooting star

> Status: **BUILT (Tier 1 + Tier 2) — 2026-06-29, branch nature-animations.** A rare
> streak crosses the night sky (Tier 1); on the real dates of the major annual
> showers it intensifies and the streaks emanate from the shower's radiant, placed
> in the local sky via SwiftAA (Tier 2). View-only, night-gated, behind
> `MeteorConfig.isEnabled`. Also wired as the egg's **third** stage (celestial →
> birds → meteor shower). Files: `NightMeteorsView.swift`, `Core/Celestial/
> MeteorShowers.swift`; resolved in `PrayerTimesView.meteorShowerContext`.

A shooting star, every so often, after dark — a bright head with a fading trail
streaking across the sky among the stars. Pure ambience, like the starfield and
the birds. **Day = birds; night = the occasional meteor.**

---

## 1. Why no astronomy drives the meteor itself

SwiftAA (and positional astronomy generally) has **nothing on meteors** — an
individual shooting star is random atmospheric debris, fundamentally
unpredictable. There is no ephemeris to query, and we wouldn't want one. So a
meteor is a **cosmetic event**, scheduled by a simple random timer — exactly like
a bird spawn, not like the Sun/Moon arc.

What *is* predictable is a **meteor shower** (Earth crossing a comet's debris
stream on known annual dates), and that's where SwiftAA earns a role — but only in
Tier 2 (§4).

---

## 2. Placement & gating

A full-screen `NightMeteorsView` layer, mounted in `PrayerTimesView`'s ZStack
alongside the birds (behind the content). Mirrors `SkyBirdsView`:

- **Night-gated.** Shows only when it's dark — a `night` signal from the real sun
  (the inverse of `birdDaylight`), so meteors and birds never overlap: birds fade
  out, meteors fade in. The starfield is already up by then.
- **`isActive`** gate (foreground + Prayer Times tab), same as the birds — the
  loop pauses off-tab.
- **Feature flag** `MeteorConfig.isEnabled` → `EmptyView` when off, zero cost.
- `allowsHitTesting(false)` — pure scenery.

---

## 3. Tier 1 — the cosmetic streak (this build)

**Model — pure function of time** (same discipline as the birds): a `Meteor` is a
value with a spawn time, a start point, a unit direction, a speed, and a lifetime.
Position = `start + dir · speed · (now − spawn)`. Cull when its lifetime elapses.

- **Spawn:** a scheduler fires the next meteor after a randomized gap (rare — tens
  of seconds), only while it's night. Usually 0 on screen, occasionally 1.
- **Path:** starts in the upper sky, travels a **downward-leaning diagonal** (reads
  as "falling"), crossing a good fraction of the screen in ~0.8–1.4 s.
- **Look:** a bright **head** (small dot + soft glow) trailing a **tapering streak**
  that fades to nothing behind it; the whole meteor also fades in at birth and out
  at death so it never pops. Cool white, faint (it's distant).
- **Rendering:** a `Canvas` inside `TimelineView(.animation(paused:))`, drawing the
  head + a few trail segments of decreasing opacity. Cheap (0–1 meteors).

**Tunables (`MeteorConfig`):** `isEnabled`, spawn-gap range, speed, streak length,
head size, opacity, trail-segment count, downward-cone half-angle.

> Cost note: the `TimelineView` runs at frame rate while it's night & active even
> when no meteor is in flight (drawing nothing). Fine for now; if battery matters,
> a later pass can drive it only while a meteor is alive.

---

## 4. Tier 2 — shower awareness (designed-for, not built)

Where SwiftAA contributes. A tiny static table of major annual showers, each with
a date window, a **radiant** (RA/Dec — the sky point meteors fly *out of*), and a
rough peak rate: Quadrantids (~Jan 3), Lyrids (~Apr 22), Eta Aquariids (~May 6),
Perseids (~Aug 12), Orionids (~Oct 21), Leonids (~Nov 17), Geminids (~Dec 14).

During an active window:
- **Raise the spawn rate** (more meteors on the nights it's really happening).
- **Use SwiftAA** to convert the radiant's RA/Dec → **local altitude/azimuth** for
  the user's coordinates and time (equatorial→horizontal transform). If the radiant
  is below the horizon, stay sporadic; if it's up, **orient the streaks to emanate
  from it**, projected to screen.

The Tier 1 spawn function takes a direction, so Tier 2 is just: pick the direction
from the projected radiant instead of the random downward cone, and modulate the
rate. No rework.

---

## 5. Open decisions
- Base sporadic rate (delight vs realism — real sporadic is ~1 per 6–12 min; we'll
  likely want more like one per ~30–60 s).
- Rare "fireball" variant — brighter, slower, longer trail, maybe a faint colour?
- Should a meteor ever cross during the **egg**'s swept night, or only real night?

## Related
- [ambient-sky-birds.md](ambient-sky-birds.md) — the daytime counterpart; same
  view-only ambient-layer pattern and `f(now)` discipline.
- `SalahMotion/DesignSystem/Components/StarfieldView.swift` — the night stars these
  streak among.
- `SalahMotion/Core/Celestial/` — SwiftAA, for the Tier 2 radiant transform.
