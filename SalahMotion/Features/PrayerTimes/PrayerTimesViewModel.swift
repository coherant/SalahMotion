import Foundation

@Observable
final class PrayerTimesViewModel {

    private(set) var prayerTime: PrayerTime = .current
    let location = LocationManager()
    private var timer: Timer?

    var cityName: String { location.cityName }

    init() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.prayerTime = .current
        }
    }

    deinit { timer?.invalidate() }

    var hijriDate: String {
        var cal = Calendar(identifier: .islamicCivil)
        cal.locale = Locale(identifier: "en")
        let c = cal.dateComponents([.day, .month, .year], from: Date())
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
        return f.string(from: Date())
    }

    var isInPrayerWindow: Bool {
        let now = Date()
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
        // If wrapping from Isha to Fajr, next Fajr is tomorrow
        if prayerTime == .isha && nextPrayer == .fajr {
            nextDate = nextDate.addingTimeInterval(24 * 60 * 60)
        }
        let windowStart = nextDate.addingTimeInterval(-15 * 60)
        let now = Date()
        return now >= windowStart && now < nextDate
    }

    var ctaLabel: String {
        let now = Date()

        // State 4 — 15 mins before next prayer
        if isBeforeNextPrayer {
            return "Prepare for \(nextPrayer.displayName)"
        }

        // States 2 & 3 — during or after the prayer window
        if now >= prayerTime.scheduledDate {
            return "Pray \(prayerTime.displayName)"
        }

        // State 1 — before the prayer has happened yet
        if prayerTime == .fajr {
            return "Waiting for sunrise"
        }
        return "Waiting for \(prayerTime.displayName)"
    }

    var countdown: String {
        let interval = prayerTime.scheduledDate.timeIntervalSince(Date())
        guard interval > 0 else { return "now" }
        let totalMinutes = Int(interval / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "in \(hours)h \(String(format: "%02d", minutes))m"
        }
        return "in \(minutes)m"
    }

    // Continuous rail fill — interpolates between prayer node positions
    // based on actual clock time so the marker drifts in real time.
    //
    // Node visual positions: Fajr=5%, Dhuhr=38%, Asr=56%, Maghrib=72%, Isha=90%
    // Segments: midnight→Fajr, Fajr→Dhuhr, Dhuhr→Asr, Asr→Maghrib, Maghrib→Isha, Isha→midnight
    var continuousRailFill: Double {
        let cal = Calendar.current
        let now = cal.dateComponents([.hour, .minute], from: Date())
        let nowMinutes = (now.hour ?? 0) * 60 + (now.minute ?? 0)

        // Prayer times in minutes from midnight (matches PrayerTime.scheduledDate)
        let segments: [(start: Int, end: Int, fillStart: Double, fillEnd: Double)] = [
            (0,    292,  0.00, 0.05),   // midnight  → Fajr    4:52
            (292,  741,  0.05, 0.38),   // Fajr      → Dhuhr  12:21
            (741,  947,  0.38, 0.56),   // Dhuhr     → Asr     3:47
            (947,  1138, 0.56, 0.72),   // Asr       → Maghrib 6:58
            (1138, 1224, 0.72, 0.90),   // Maghrib   → Isha    8:24
            (1224, 1440, 0.90, 1.00),   // Isha      → midnight
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
