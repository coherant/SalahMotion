import UserNotifications

enum NotificationManager {

    private static let enabledKey = "notifications.enabledPrayers"

    // Stable identifier per prayer — used to cancel and replace on reschedule
    private static func identifier(for prayer: PrayerTime) -> String {
        "salahmotion.prayer.\(prayer.rawValue)"
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

    private static func scheduleEnabled() {
        let enabled = enabledPrayers()
        let allIds = PrayerTime.allCases.map { identifier(for: $0) }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: allIds)
        PrayerTime.allCases.filter { enabled.contains($0.rawValue) }.forEach { schedule($0) }
    }

    private static func schedule(_ prayer: PrayerTime) {
        let content = UNMutableNotificationContent()
        content.title = "\(prayer.displayName) · \(prayer.arabic)"
        content.body  = "It is time for prayer."
        content.sound = .default

        let components = Calendar.current.dateComponents([.hour, .minute], from: prayer.scheduledDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: identifier(for: prayer), content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private static func cancel(_ prayer: PrayerTime) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifier(for: prayer)])
    }
}
