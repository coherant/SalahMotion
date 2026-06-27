import Foundation

@Observable
final class PrayerTimesViewModel {

    private(set) var prayerTime: PrayerTime = .current
    private(set) var now: Date = Date()
    let location = LocationManager()

    private var minuteTimer: Timer?
    private var secondTimer: Timer?

    var cityName: String { location.cityName }

    init() {
        // 60s — refreshes which prayer period we're in, and recomputes times at day rollover
        minuteTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            PrayerTimesEngine.shared.refreshIfNeeded()
            self?.prayerTime = .current
        }
        // 1s — drives countdown and all time-sensitive computed properties
        secondTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.now = Date()
        }
    }

    deinit {
        minuteTimer?.invalidate()
        secondTimer?.invalidate()
    }

    var hijriDate: String {
        var cal = Calendar(identifier: .islamicCivil)
        cal.locale = Locale(identifier: "en")
        let offsetDays = PrayerCalculationSettings.shared.hijriOffsetDays
        let base = cal.date(byAdding: .day, value: offsetDays, to: now) ?? now
        let c = cal.dateComponents([.day, .month, .year], from: base)
        guard let day = c.day, let month = c.month, let year = c.year,
              (1...12).contains(month) else { return "" }
        let months = ["Muḥarram","Ṣafar","Rabīʿ al-Awwal","Rabīʿ al-Thānī",
                      "Jumādā al-Ūlā","Jumādā al-Ākhirah","Rajab","Shaʿbān",
                      "Ramaḍān","Shawwāl","Dhū al-Qaʿdah","Dhū al-Ḥijjah"]
        return "\(day) \(months[month - 1]) \(year)"
    }

    var gregorianDate: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d MMMM"
        return f.string(from: now)
    }

    /// True while the up-next prayer's 15-minute window is open — the only time
    /// the CTA is tappable. `upNext` keeps a prayer selected only through its
    /// window, so a non-future `upNext.date` means we're inside that window.
    var isInPrayerWindow: Bool {
        upNext.date <= now
    }

    /// The prayer the "Up next" card tracks, paired with the absolute instant to
    /// count down to. It's the next prayer whose 15-minute window hasn't elapsed
    /// (so a prayer still reads "now" through its window); once *every* window has
    /// passed — the stretch between Isha and the next dawn — it wraps to tomorrow's
    /// Fajr. Without the wrap the night counts down to a stale Isha, which after
    /// midnight (engine recomputed for the new day) reads as ~19h away.
    var upNext: (prayer: PrayerTime, date: Date) {
        let all = PrayerTime.allCases
        if let p = all.first(where: { now < $0.scheduledDate.addingTimeInterval(15 * 60) }) {
            return (p, p.scheduledDate)
        }
        return (.fajr, PrayerTime.fajr.scheduledDate.addingTimeInterval(24 * 60 * 60))
    }

    /// CTA copy, driven entirely by `upNext` so the button always agrees with the
    /// countdown card. Cascade by time remaining until that prayer:
    ///   • window already reached  → "Pray X"
    ///   • within 15 min before    → "Prepare for X"
    ///   • otherwise               → "Waiting for X"
    var ctaLabel: String {
        let (prayer, date) = upNext
        let secondsUntil = date.timeIntervalSince(now)
        if secondsUntil <= 0 {
            return "Pray \(prayer.displayName)"
        }
        if secondsUntil <= 15 * 60 {
            return "Prepare for \(prayer.displayName)"
        }
        return "Waiting for \(prayer.displayName)"
    }

    var countdown: String {
        let interval = upNext.date.timeIntervalSince(now)
        guard interval > 0 else { return "now" }
        let totalMinutes = Int(interval / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "in \(hours)h \(String(format: "%02d", minutes))m"
        }
        return "in \(minutes)m"
    }

    // MARK: - Day rail state (derived from real engine times)

    /// Node-fraction positions of the five prayers along the rail — must match
    /// `PrayerTimesView.nodePositions`.
    static let railNodeFractions: [Double] = [0.05, 0.38, 0.56, 0.72, 0.90]

    /// Index into `PrayerTime.allCases` of the prayer to treat as **current / up-next**:
    /// the next prayer whose time hasn't occurred yet. Prayers before it are "prayed",
    /// after it "future". Once Isha has passed it stays on Isha for the rest of the
    /// night; at the day rollover (`refreshIfNeeded` recomputes the new day's times)
    /// the next Fajr becomes current and the rail resets on its own.
    var currentPrayerIndex: Int {
        let all = PrayerTime.allCases
        if let next = all.firstIndex(where: { $0.scheduledDate > now }) {
            return next
        }
        return all.count - 1   // every prayer has passed → Isha is active through the night
    }

    var currentRailPrayer: PrayerTime { PrayerTime.allCases[currentPrayerIndex] }

    /// Continuous 0…1 fill for the day rail, anchored to the **actual** prayer
    /// instants: 0 at the start of the local day, each prayer's node fraction at its
    /// real time, 1.0 at midnight. Interpolated so the fill + pulse marker always
    /// line up with the nodes, and it resets cleanly at the day rollover.
    var continuousRailFill: Double {
        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: now)
        let endOfDay = startOfDay.addingTimeInterval(24 * 60 * 60)

        var anchors: [(date: Date, fill: Double)] = [(startOfDay, 0.0)]
        for (i, prayer) in PrayerTime.allCases.enumerated() {
            anchors.append((prayer.scheduledDate, Self.railNodeFractions[i]))
        }
        anchors.append((endOfDay, 1.0))

        for k in 0..<(anchors.count - 1) {
            let a = anchors[k], b = anchors[k + 1]
            guard now >= a.date && now < b.date else { continue }
            let span = b.date.timeIntervalSince(a.date)
            guard span > 0 else { return a.fill }
            let t = now.timeIntervalSince(a.date) / span
            return a.fill + t * (b.fill - a.fill)
        }
        return 1.0
    }
}
