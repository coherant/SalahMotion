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

    /// Melbourne, Australia — where SalahMotion was made. Used until the device
    /// reports a real location, so times are sensible from launch. 🇦🇺
    static let defaultCoordinate = CLLocationCoordinate2D(latitude: -37.8136, longitude: 144.9631)
    static let defaultTimeZone = TimeZone(identifier: "Australia/Melbourne") ?? .current

    private(set) var coordinate = PrayerTimesEngine.defaultCoordinate
    /// Timezone of the current location. Prayer instants are absolute UTC, so this
    /// is what renders/schedules them at the location's wall-clock time.
    private(set) var timeZone = PrayerTimesEngine.defaultTimeZone
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

    /// Update to the location's timezone (from reverse-geocoding) and recompute,
    /// so times render/schedule at the location's wall-clock time.
    func setTimeZone(_ tz: TimeZone) {
        guard tz != timeZone else { return }
        timeZone = tz
        recompute()
    }

    /// Recompute if the calendar day has rolled over (call from a periodic timer).
    func refreshIfNeeded(now: Date = Date()) {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let day = cal.startOfDay(for: now)
        if computedForDay != day { recompute(now: now) }
    }

    // MARK: - Computation

    func recompute(now: Date = Date()) {
        let settings = PrayerCalculationSettings.shared
        let coords = Coordinates(latitude: coordinate.latitude, longitude: coordinate.longitude)

        var params = settings.method.params
        params.madhab = settings.madhab
        params.adjustments = settings.prayerAdjustments

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
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

        // Fajr override: a fixed 1.5h before sunrise, plus any user Fajr offset.
        if settings.fajrRule == .beforeSunrise {
            let off = settings.offsets[.fajr] ?? 0
            times[.fajr] = pt.sunrise.addingTimeInterval(TimeInterval(-90 * 60 + off * 60))
        }

        qiyam = SunnahTimes(from: pt)?.lastThirdOfTheNight
        computedForDay = cal.startOfDay(for: now)

        // Times just changed (location, settings, or day rollover) — keep the
        // scheduled prayer notifications in sync. No-op unless already authorized.
        NotificationManager.refreshIfAuthorized()
    }

    // MARK: - Queries

    /// The absolute instant of `prayer` today, or nil before the first compute.
    func date(for prayer: PrayerTime) -> Date? { times[prayer] }
}
