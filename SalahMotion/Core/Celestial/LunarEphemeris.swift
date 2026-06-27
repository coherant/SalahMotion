import Foundation

// MARK: - Lunar ephemeris resolution
//
// `Lunar.ephemeris` is the single place the rest of the app asks for "the Moon".
// It resolves to the real SwiftAA-backed provider once that package is vendored,
// and otherwise to a deliberately-obvious placeholder.

enum Lunar {
    static var ephemeris: CelestialEphemeris {
        #if canImport(SwiftAA)
        return SwiftAALunarEphemeris()
        #else
        // PLACEHOLDER until SwiftAA is vendored. Deliberately the Sun's antipode,
        // so a missing dependency fails VISIBLY (a moon forever opposite the sun)
        // rather than shipping a subtly-wrong, drifting position. Never production.
        return OpposedEphemeris(base: SolarEphemeris())
        #endif
    }
}

// MARK: - SwiftAALunarEphemeris (real, behind the dependency seam)
//
// Active only once SwiftAA is added to the project. The phase is wired here
// (elongation = Moon − Sun ecliptic longitude); the arc position is left as the
// one TODO because the Moon's fast motion needs hourly interpolation through the
// rise/set engine rather than the Sun's once-per-day approximation.
//
// TODO(SwiftAA): verify the SwiftAA API names below against the vendored version,
// and compute dayPhase + isAboveHorizon from moonrise/transit/moonset for the
// observer (RA/Dec → altitude via Adhan's correctedHourAngle, interpolated).

#if canImport(SwiftAA)
import SwiftAA

struct SwiftAALunarEphemeris: CelestialEphemeris {
    func sky(at date: Date, location: ObserverLocation) -> SkyState {
        let julianDay = JulianDay(date)
        let moon = Moon(julianDay: julianDay)
        let sun = Sun(julianDay: julianDay)

        let moonLongitude = moon.eclipticCoordinates.celestialLongitude.value   // degrees
        let sunLongitude = sun.eclipticCoordinates.celestialLongitude.value     // degrees
        let phase = MoonPhase(elongationDegrees: moonLongitude - sunLongitude)

        // TODO(SwiftAA): real arc position + horizon from moonrise/transit/moonset.
        return SkyState(dayPhase: 0, isAboveHorizon: false, moonPhase: phase)
    }
}
#endif
