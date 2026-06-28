# Aurora — shimmering night-sky curtains

> Status: **BUILDING (Tier 1) — 2026-06-29, branch nature-animations.** A soft,
> flowing aurora that occasionally graces the night sky, plus the egg's 4th stage.
> Metal-shader rendered. View-only, night-gated, behind `AuroraConfig.isEnabled`.
> Cosmetic (no latitude realism — Melbourne really did see aurora australis in the
> 2024 storms). No real-data (Kp) tier.

Green-and-magenta curtains of light, undulating slowly across the upper sky among
the stars — the most ambitious of the nature animations, and a night counterpart
to the daytime murmuration's "wow".

---

## 1. Render — a Metal shader

A `[[ stitchable ]]` fragment shader (`Aurora.metal`) drives the look, via SwiftUI's
`Rectangle().colorEffect(ShaderLibrary.aurora(...))` (iOS 17). Domain-warped
**fractal noise (FBM)** sculpts a soft vertical band whose height drifts, textured
with **vertical ray streaks**, mapped to a **green→magenta** gradient and confined
to the upper sky. Animated by a `time` uniform from a `TimelineView`; faded by an
`intensity` uniform. Composited with **`.blendMode(.screen)`** so it glows
emissively over the dark sky and starfield.

- Premultiplied output; alpha falls to 0 outside the band, so the night sky shows
  through.
- `time` is passed reduced (mod 10⁴ s) to keep Float precision in the shader.
- The shader only runs while `intensity > 0` (skipped otherwise — no GPU cost when
  there's no aurora).

## 2. Placement & gating

Full-screen `AuroraView`, mounted in `PrayerTimesView`'s ZStack **just above the
background/starfield** and below the birds/meteors — so stars and meteors read in
front of the glow. Mirrors the other layers:

- **Night-gated** (`nightFactor`); fades in only after dark.
- **`isActive`** (foreground + tab) pauses the `TimelineView` off-tab.
- Flag `AuroraConfig.isEnabled` → nothing when off. `allowsHitTesting(false)`.

## 3. Intensity — rare ambient + the egg

A single smoothed `intensity` scalar drives the fade, from a reference-type
`AuroraField` (mutated inside the timeline, like the birds/meteors models):

- **Rare ambient episode:** every so often it rolls (`checkGap`, `eventChance`) and,
  if it's night, starts an episode lasting `episodeDuration` — fade in, linger, fade
  out (exponential smoothing, `fadeTau`). Genuinely rare — the egg is the reliable
  way to summon it.
- **Egg (stage 4):** `TimeMachine` gains `auroraActive` and a 4th stage
  (celestial → birds → meteor → **aurora**). While active it forces intensity to
  full and forces night, so it shows on demand any time. Heavy haptic.

## 4. Tunables
- `AuroraConfig`: `fadeTau`, `checkGap`, `eventChance`, `episodeDuration`.
- In the shader: band height/width, ray frequency, colours, drift speed, opacity.

## 5. Open decisions
- Ambient frequency (currently ~once per long while of night viewing).
- Colour palette (classic green/magenta vs more violet/red) — a device pass.
- Whether a future Tier 2 ties ambient appearance to NOAA SWPC Kp data (parked).

## Related
- [night-meteors.md](night-meteors.md) / [ambient-sky-birds.md](ambient-sky-birds.md)
  — the other ambient sky layers; same view-only, night/day-gated pattern.
- `SalahMotion/DesignSystem/Components/StarfieldView.swift` — the stars it glows behind.
