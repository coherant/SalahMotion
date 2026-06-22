import Foundation

final class UserPreferences {
    static let shared = UserPreferences()
    private init() {}

    private let languageKey     = "selectedPrayerLanguage"
    private let paceKey         = "selectedPrayerPace"
    private let guidanceKey     = "selectedGuidanceLevel"

    var language: Language {
        get {
            guard let raw = UserDefaults.standard.string(forKey: languageKey),
                  let lang = Language(rawValue: raw) else { return .english }
            return lang
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: languageKey) }
    }

    var pace: PrayerPace {
        get {
            guard let raw = UserDefaults.standard.string(forKey: paceKey),
                  let pace = PrayerPace(rawValue: raw) else { return .medium }
            return pace
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: paceKey) }
    }

    var guidanceLevel: GuidanceLevel {
        get {
            guard let raw = UserDefaults.standard.string(forKey: guidanceKey),
                  let level = GuidanceLevel(rawValue: raw) else { return .full }
            return level
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: guidanceKey) }
    }
}
