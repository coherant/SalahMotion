import UserNotifications

enum NotificationManager {

    private static let enabledKey = "notifications.enabledPrayers"

    // Stable identifier per prayer — used to cancel and replace on reschedule
    private static func identifier(for prayer: PrayerTime) -> String {
        "salahmotion.prayer.\(prayer.rawValue)"
    }

    // MARK: - Foreground presentation

    // Retained delegate so notifications still present while the app is open.
    // Without a UNUserNotificationCenterDelegate, iOS silently suppresses
    // foreground notifications (no banner, no sound) — they only land in the
    // notification list. Set this once at launch.
    private static let presenter = ForegroundPresenter()

    static func configurePresentation() {
        UNUserNotificationCenter.current().delegate = presenter
    }

    private final class ForegroundPresenter: NSObject, UNUserNotificationCenterDelegate {
        func userNotificationCenter(
            _ center: UNUserNotificationCenter,
            willPresent notification: UNNotification,
            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
        ) {
            completionHandler([.banner, .sound, .list])
        }
    }

    // MARK: - Permission

    static func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, _ in
            if granted { scheduleEnabled() }
        }
    }

    // Re-schedules only if permission is already granted — safe to call on every app open.
    static func refreshIfAuthorized() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                scheduleEnabled()
            }
        }
    }

    // MARK: - Per-prayer state (persisted in UserDefaults)

    // On first access, all prayers default to enabled.
    static func enabledPrayers() -> Set<String> {
        if let stored = UserDefaults.standard.array(forKey: enabledKey) as? [String] {
            return Set(stored)
        }
        let all = Set(PrayerTime.allCases.map(\.rawValue))
        UserDefaults.standard.set(Array(all), forKey: enabledKey)
        return all
    }

    static func isEnabled(_ prayer: PrayerTime) -> Bool {
        enabledPrayers().contains(prayer.rawValue)
    }

    static func toggle(_ prayer: PrayerTime) {
        var enabled = enabledPrayers()
        if enabled.contains(prayer.rawValue) {
            enabled.remove(prayer.rawValue)
            cancel(prayer)
        } else {
            enabled.insert(prayer.rawValue)
            schedule(prayer)
        }
        UserDefaults.standard.set(Array(enabled), forKey: enabledKey)
    }

    // MARK: - Scheduling

    // Daily hour/minute components in the LOCATION's timezone, so a repeating
    // trigger fires at the prayer's wall-clock time there (not the device's tz).
    // Prayer instants are absolute UTC; this projects them into the location tz.
    private static func dailyComponents(for date: Date) -> DateComponents {
        let tz = PrayerTimesEngine.shared.timeZone
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        var components = cal.dateComponents([.hour, .minute], from: date)
        components.timeZone = tz
        return components
    }

    private static func scheduleEnabled() {
        let enabled = enabledPrayers()
        let allIds = PrayerTime.allCases.map { identifier(for: $0) }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: allIds)
        PrayerTime.allCases.filter { enabled.contains($0.rawValue) }.forEach { schedule($0) }
        if isSuhoorEnabled() { scheduleSuhoor() } else { cancelSuhoor() }
    }

    private static func schedule(_ prayer: PrayerTime) {
        let content = UNMutableNotificationContent()
        content.title = "\(prayer.displayName) · \(prayer.arabic)"
        content.body  = "It is time for prayer."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dailyComponents(for: prayer.scheduledDate), repeats: true)
        let request = UNNotificationRequest(identifier: identifier(for: prayer), content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private static func cancel(_ prayer: PrayerTime) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifier(for: prayer)])
    }

    // MARK: - Suhoor ending reminder (Ramadan)

    private static let suhoorKey = "notifications.suhoorReminder"
    private static let suhoorId  = "salahmotion.suhoor"

    // Off by default — opt-in for Ramadan.
    static func isSuhoorEnabled() -> Bool {
        UserDefaults.standard.bool(forKey: suhoorKey)
    }

    static func setSuhoorEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: suhoorKey)
        if enabled { scheduleSuhoor() } else { cancelSuhoor() }
    }

    // Fires 15 minutes before Fajr (i.e. before Suhoor ends), repeating daily.
    private static func scheduleSuhoor() {
        let remindAt = PrayerTime.fajr.scheduledDate.addingTimeInterval(-15 * 60)
        let content = UNMutableNotificationContent()
        content.title = "Suhoor ending soon"
        content.body  = "About 15 minutes until Fajr."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dailyComponents(for: remindAt), repeats: true)
        let request = UNNotificationRequest(identifier: suhoorId, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private static func cancelSuhoor() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [suhoorId])
    }
}
