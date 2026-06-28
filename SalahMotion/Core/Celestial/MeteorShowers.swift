import Foundation
#if canImport(SwiftAA)
import SwiftAA
#endif

// MARK: - MeteorShowers
//
// Tier 2 of the night-meteors feature (docs/features/prayer-times/night-meteors.md).
// A meteor itself is unpredictable, but a meteor SHOWER is an annual event on known
// dates with a known radiant (the sky point the meteors fly out of). This is the
// only astronomy in the feature: a static shower table + a radiant RA/Dec →
// local altitude/azimuth transform (SwiftAA sidereal time + spherical trig), so a
// shower only shows when its radiant is actually up for the user's location, and
// the streaks emanate from the right place.
//
// Radiants are RA (J2000, degrees) / Dec; peak dates + ZHR from the AMS / IMO 2026
// calendars. Radiants drift slightly year to year — fine for a decorative layer.

struct MeteorShower: Equatable {
    let name: String
    let peakMonth: Int
    let peakDay: Int
    let radiantRA: Double      // degrees (J2000)
    let radiantDec: Double     // degrees
    let zhr: Double            // zenithal hourly rate (relative strength)
}

enum MeteorShowers {

    static let all: [MeteorShower] = [
        MeteorShower(name: "Quadrantids",        peakMonth: 1,  peakDay: 3,  radiantRA: 230, radiantDec:  49, zhr: 120),
        MeteorShower(name: "Lyrids",             peakMonth: 4,  peakDay: 22, radiantRA: 271, radiantDec:  34, zhr: 18),
        MeteorShower(name: "Eta Aquariids",      peakMonth: 5,  peakDay: 6,  radiantRA: 338, radiantDec:  -1, zhr: 50),
        MeteorShower(name: "S. δ Aquariids",     peakMonth: 7,  peakDay: 30, radiantRA: 340, radiantDec: -16, zhr: 25),
        MeteorShower(name: "Perseids",           peakMonth: 8,  peakDay: 12, radiantRA:  48, radiantDec:  58, zhr: 100),
        MeteorShower(name: "Orionids",           peakMonth: 10, peakDay: 21, radiantRA:  95, radiantDec:  16, zhr: 20),
        MeteorShower(name: "Leonids",            peakMonth: 11, peakDay: 17, radiantRA: 152, radiantDec:  22, zhr: 15),
        MeteorShower(name: "Geminids",           peakMonth: 12, peakDay: 14, radiantRA: 112, radiantDec:  33, zhr: 150),
    ]

    /// ± days around the peak the shower is treated as active.
    static let windowDays = 2

    /// The shower active on `date` (nearest peak within ±`windowDays`), else nil.
    /// Checks the peak in the surrounding years too, so a Jan/Dec shower wraps.
    static func active(on date: Date, calendar: Calendar) -> MeteorShower? {
        let today = calendar.startOfDay(for: date)
        let year = calendar.component(.year, from: date)
        var best: (shower: MeteorShower, days: Int)?
        for shower in all {
            for y in [year - 1, year, year + 1] {
                guard let peak = calendar.date(from: DateComponents(year: y, month: shower.peakMonth, day: shower.peakDay))
                else { continue }
                let days = Int((today.timeIntervalSince(calendar.startOfDay(for: peak)) / 86_400).rounded())
                if abs(days) <= windowDays, best == nil || abs(days) < abs(best!.days) {
                    best = (shower, days)
                }
            }
        }
        return best?.shower
    }

    /// The shower whose peak is nearest to `date` (for the egg, so it always has a
    /// real radiant to stream from even off-season).
    static func nearest(to date: Date, calendar: Calendar) -> MeteorShower {
        let today = calendar.startOfDay(for: date)
        let year = calendar.component(.year, from: date)
        var best: (shower: MeteorShower, dist: TimeInterval) = (all[0], .greatestFiniteMagnitude)
        for shower in all {
            for y in [year - 1, year, year + 1] {
                guard let peak = calendar.date(from: DateComponents(year: y, month: shower.peakMonth, day: shower.peakDay))
                else { continue }
                let dist = abs(today.timeIntervalSince(calendar.startOfDay(for: peak)))
                if dist < best.dist { best = (shower, dist) }
            }
        }
        return best.shower
    }

    /// Radiant altitude & azimuth (degrees) for the observer at `date`. Altitude ≤ 0
    /// means the radiant is below the horizon (no shower visible).
    static func radiantAltAz(_ shower: MeteorShower,
                             location: ObserverLocation, date: Date) -> (altitude: Double, azimuth: Double) {
        let lstDeg = localSiderealTimeDegrees(date: date, longitude: location.longitude)
        let ha = (lstDeg - shower.radiantRA) * .pi / 180          // hour angle (rad)
        let lat = location.latitude * .pi / 180
        let dec = shower.radiantDec * .pi / 180

        let sinAlt = sin(lat) * sin(dec) + cos(lat) * cos(dec) * cos(ha)
        let alt = asin(min(1, max(-1, sinAlt)))
        let cosAz = (sin(dec) - sin(alt) * sin(lat)) / (cos(alt) * cos(lat) + 1e-9)
        var az = acos(min(1, max(-1, cosAz)))
        if sin(ha) > 0 { az = 2 * .pi - az }                      // east of meridian
        return (alt * 180 / .pi, az * 180 / .pi)
    }

    /// Local apparent sidereal time in degrees. Uses SwiftAA (matching the Moon
    /// path) when available; a standard GMST formula otherwise.
    private static func localSiderealTimeDegrees(date: Date, longitude: Double) -> Double {
        #if canImport(SwiftAA)
        // SwiftAA's sidereal time uses positively-WESTWARD longitude (as in LunarEphemeris).
        let lstHours = JulianDay(date).meanLocalSiderealTime(longitude: Degree(-longitude)).value
        return wrap360(lstHours * 15)
        #else
        let jd = 2_440_587.5 + date.timeIntervalSince1970 / 86_400
        let d = jd - 2_451_545.0
        let gmst = 280.46061837 + 360.98564736629 * d
        return wrap360(gmst + longitude)        // east-positive longitude
        #endif
    }

    private static func wrap360(_ deg: Double) -> Double {
        let r = deg.truncatingRemainder(dividingBy: 360)
        return r < 0 ? r + 360 : r
    }
}
