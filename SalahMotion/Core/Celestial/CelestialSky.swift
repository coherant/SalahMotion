import Foundation

// MARK: - CelestialSky
//
// The facade the view binds to. It owns the composition (clock + per-body
// ephemerides + location); the view hands it a wall-clock instant and gets back a
// `SkyFrame`. No SwiftUI here — a watchOS view consumes the identical facade.
//
// Two ready-made compositions:
//   • .concept(location:) — Moon opposite Sun, a full day every 20 s (idea test).
//   • .live(location:)    — real Sun (Adhan) + real Moon (SwiftAA), realtime.

struct CelestialSky {
    var location: ObserverLocation
    var clock: CelestialClock
    let sun: CelestialEphemeris
    let moon: CelestialEphemeris

    func frame(atWallClock wallClock: Date) -> SkyFrame {
        let instant = clock.evaluationDate(for: wallClock)
        return SkyFrame(
            sun: sun.sky(at: instant, location: location),
            moon: moon.sky(at: instant, location: location)
        )
    }
}

extension CelestialSky {

    /// First concept: uniform Sun sweep (no horizon velocity kink under time
    /// compression), Moon pinned 180° away, a full day every `secondsPerDay`.
    static func concept(location: ObserverLocation,
                        secondsPerDay: TimeInterval = 20) -> CelestialSky {
        let sun = UniformEphemeris()
        return CelestialSky(
            location: location,
            clock: .demo(secondsPerDay: secondsPerDay),
            sun: sun,
            moon: OpposedEphemeris(base: sun)
        )
    }

    /// Production: real Sun + real Moon at real time.
    static func live(location: ObserverLocation) -> CelestialSky {
        CelestialSky(
            location: location,
            clock: .realtime,
            sun: SolarEphemeris(),
            moon: Lunar.ephemeris
        )
    }
}
