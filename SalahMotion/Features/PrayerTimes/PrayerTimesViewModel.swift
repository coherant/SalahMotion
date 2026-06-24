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

    var isInPrayerWindow: Bool {
        let start = prayerTime.scheduledDate
        return now >= start && now < start.addingTimeInterval(15 * 60)
    }

    var nextPrayer: PrayerTime {
        let all = PrayerTime.allCases
        let next = (all.firstIndex(of: prayerTime) ?? 0) + 1
        return all[next % all.count]
    }

    var isBeforeNextPrayer: Bool {
        var nextDate = nextPrayer.scheduledDate
        if prayerTime == .isha && nextPrayer == .fajr {
            nextDate = nextDate.addingTimeInterval(24 * 60 * 60)
        }
        let windowStart = nextDate.addingTimeInterval(-15 * 60)
        return now >= windowStart && now < nextDate
    }

    var ctaLabel: String {
        if isBeforeNextPrayer {
            return "Prepare for \(nextPrayer.displayName)"
        }
        if now >= prayerTime.scheduledDate {
            return "Pray \(prayerTime.displayName)"
        }
        if prayerTime == .fajr {
            return "Waiting for sunrise"
        }
        return "Waiting for \(prayerTime.displayName)"
    }

    var countdown: String {
        let interval = prayerTime.scheduledDate.timeIntervalSince(now)
        guard interval > 0 else { return "now" }
        let totalMinutes = Int(interval / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "in \(hours)h \(String(format: "%02d", minutes))m"
        }
        return "in \(minutes)m"
    }

    var continuousRailFill: Double {
        let c = Calendar.current.dateComponents([.hour, .minute], from: now)
        let nowMinutes = (c.hour ?? 0) * 60 + (c.minute ?? 0)

        let segments: [(start: Int, end: Int, fillStart: Double, fillEnd: Double)] = [
            (0,    292,  0.00, 0.05),
            (292,  741,  0.05, 0.38),
            (741,  947,  0.38, 0.56),
            (947,  1138, 0.56, 0.72),
            (1138, 1224, 0.72, 0.90),
            (1224, 1440, 0.90, 1.00),
        ]

        for seg in segments {
            if nowMinutes >= seg.start && nowMinutes < seg.end {
                let progress = Double(nowMinutes - seg.start) / Double(seg.end - seg.start)
                return seg.fillStart + progress * (seg.fillEnd - seg.fillStart)
            }
        }
        return 1.0
    }
}
