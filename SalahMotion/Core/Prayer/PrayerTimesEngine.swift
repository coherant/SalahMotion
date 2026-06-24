import Foundation
import CoreLocation
import Observation

// MARK: - Prayer times engine
//
// Source of truth for the day's prayer times. Wraps the vendored Adhan library
// (Core/Prayer/Adhan) and computes the five daily times + sunrise + Qiyam from a
// coordinate, the current date, and PrayerCalculationSettings.
//
// PrayerTime.scheduledDate / .displayTime read from `shared` (falling back to
// fixed times only before the first computation), so the whole app gets real
// times without each call site knowing about the engine.
//
// Times are absolute `Date` instants (Adhan computes in UTC); display them with
// a locale/timezone-aware DateFormatter. Comparisons against `Date()` are correct
// as-is.

@Observable
final class PrayerTimesEngine {
    static let shared = PrayerTimesEngine()

    /// London — matches LocationManager's default city, used until the device
    /// reports a real location so times are sensible from launch.
    static let defaultCoordinate = CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)

    private(set) var coordinate = PrayerTimesEngine.defaultCoordinate
    private(set) var usingDeviceLocation = false

    /// Today's computed times, keyed by prayer. Empty only if computation failed.
    private(set) var times: [PrayerTime: Date] = [:]
    private(set) var sunrise: Date?
    /// Start of the last third of the night — the recommended time for Qiyam.
    private(set) var qiyam: Date?

    /// The calendar day `times` were computed for (start of day, local).
    private(set) var computedForDay: Date?

    private init() {
        recompute()
    }

    // MARK: - Inputs

    /// Update to the device's real coordinate and recompute.
    func setCoordinate(_ coord: CLLocationCoordinate2D) {
        coordinate = coord
        usingDeviceLocation = true
        recompute()
    }

    /// Recompute if the calendar day has rolled over (call from a periodic timer).
    func refreshIfNeeded(now: Date = Date()) {
        let day = Calendar.current.startOfDay(for: now)
        if computedForDay != day { recompute(now: now) }
    }

    // MARK: - Computation

    func recompute(now: Date = Date()) {
        let settings = PrayerCalculationSettings.shared
        let coords = Coordinates(latitude: coordinate.latitude, longitude: coordinate.longitude)

        var params = settings.method.params
        params.madhab = settings.madhab
        params.adjustments = settings.prayerAdjustments

        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents([.year, .month, .day], from: now)

        guard let pt = PrayerTimes(coordinates: coords, date: comps, calculationParameters: params) else {
            // Keep any previous values rather than wiping to fixed times.
            return
        }

        times = [
            .fajr:    pt.fajr,
            .dhuhr:   pt.dhuhr,
            .asr:     pt.asr,
            .maghrib: pt.maghrib,
            .isha:    pt.isha,
        ]
        sunrise = pt.sunrise
        qiyam = SunnahTimes(from: pt)?.lastThirdOfTheNight
        computedForDay = cal.startOfDay(for: now)
    }

    // MARK: - Queries

    /// The absolute instant of `prayer` today, or nil before the first compute.
    func date(for prayer: PrayerTime) -> Date? { times[prayer] }
}
