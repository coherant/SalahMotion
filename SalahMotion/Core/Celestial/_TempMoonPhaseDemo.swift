import Foundation

// ⚠️ TEMPORARY DEMO — REMOVE.
//
// Added so the MoonPhaseShape rendering can be eyeballed across the full synodic
// cycle before real positions/phase are wired. The moon follows the concept arc
// (opposite the Sun, so it's visible alone), but its illuminated phase sweeps
// new → full → new across TWO arc rotations.
//
// To remove: delete this whole file and revert
// `PrayerTimesView.celestialSky` from `.moonPhaseDemo(...)` back to `.concept(...)`.

struct PhaseSweepMoonEphemeris: CelestialEphemeris {
    /// Provides the moon's arc position; this decorator only overrides the phase.
    let base: CelestialEphemeris
    /// One arc rotation == one demo "day".
    let secondsPerRotation: TimeInterval

    func sky(at date: Date, location: ObserverLocation) -> SkyState {
        let positioned = base.sky(at: date, location: location)
        // Real wall clock (not the passed-in, per-rotation-wrapped instant) so the
        // phase progresses continuously. Full cycle over two rotations.
        let elapsed = Date().timeIntervalSinceReferenceDate
        let sweep = (elapsed / (2 * secondsPerRotation)).truncatingRemainder(dividingBy: 1)
        return SkyState(
            dayPhase: positioned.dayPhase,
            isAboveHorizon: positioned.isAboveHorizon,
            moonPhase: MoonPhase(phase: sweep)
        )
    }
}

extension CelestialSky {
    /// ⚠️ TEMPORARY — REMOVE with `PhaseSweepMoonEphemeris`.
    static func moonPhaseDemo(location: ObserverLocation,
                              secondsPerDay: TimeInterval = 20) -> CelestialSky {
        let sun = UniformEphemeris()
        return CelestialSky(
            location: location,
            clock: .demo(secondsPerDay: secondsPerDay),
            sun: sun,
            moon: PhaseSweepMoonEphemeris(base: OpposedEphemeris(base: sun),
                                          secondsPerRotation: secondsPerDay)
        )
    }
}
