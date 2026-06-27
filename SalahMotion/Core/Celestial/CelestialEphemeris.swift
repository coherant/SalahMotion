import Foundation

// MARK: - CelestialEphemeris
//
// The seam that makes everything else swappable and testable: anything that can
// report a body's sky state for a date + location. Concrete conformers:
//   • SolarEphemeris       — real Sun, via the vendored Adhan astronomy.
//   • SwiftAALunarEphemeris — real Moon, via SwiftAA (behind a canImport seam).
//   • OpposedEphemeris     — decorator: a body fixed 180° from another (concept).
//   • (tests)              — deterministic fakes.

protocol CelestialEphemeris {
    func sky(at date: Date, location: ObserverLocation) -> SkyState
}

// MARK: - OpposedEphemeris (decorator)
//
// Places a body diametrically opposite another along the daily arc. Used for the
// first concept (Moon opposite Sun) and as the obvious-not-real placeholder until
// SwiftAA is vendored — chosen precisely because "always opposite the Sun" fails
// VISIBLY rather than as a subtle, drifting wrong value.

// MARK: - UniformEphemeris
//
// A constant-velocity daily sweep that ignores real rise/set, so the arc moves at
// a uniform angular rate with NO velocity kink at the horizon. The real
// SolarEphemeris is honest about asymmetric day/night lengths — correct at real
// speed, but compressed into the 20s demo that asymmetry reads as a stutter as
// the body clears the horizon. The concept is about testing the motion, so it
// uses this; `.live` keeps the real Sun.
//
// Anchored so t=0 (rise, left corner) is 06:00, peak 12:00, set 18:00, nadir
// 00:00 — and the loop wrap lands exactly on the (clipped) nadir, so it's seamless.

struct UniformEphemeris: CelestialEphemeris {
    func sky(at date: Date, location: ObserverLocation) -> SkyState {
        let startOfDay = Calendar.gregorianUTC.startOfDay(for: date)
        let fractionOfDay = date.timeIntervalSince(startOfDay) / 86_400
        let raw = (fractionOfDay - 0.25).truncatingRemainder(dividingBy: 1)
        let phase = raw < 0 ? raw + 1 : raw
        let above = sin(Double.pi - 2 * .pi * phase) > 1e-9
        return SkyState(dayPhase: phase, isAboveHorizon: above, moonPhase: nil)
    }
}

struct OpposedEphemeris: CelestialEphemeris {
    let base: CelestialEphemeris
    /// Demo phase shown for the opposed body (concept only).
    var moonPhase: MoonPhase = MoonPhase(phase: 0.5)

    func sky(at date: Date, location: ObserverLocation) -> SkyState {
        let b = base.sky(at: date, location: location)
        let t = (b.dayPhase + 0.5).truncatingRemainder(dividingBy: 1)
        // above-horizon ⟺ t ∈ (0,0.5) ⟺ sin(π − 2πt) > 0
        let above = sin(Double.pi - 2 * .pi * t) > 0
        return SkyState(dayPhase: t, isAboveHorizon: above, moonPhase: moonPhase)
    }
}
