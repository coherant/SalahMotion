import Foundation
import Observation

@Observable
final class UserPreferences {
    static let shared = UserPreferences()

    var language: Language {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: Keys.language) }
    }

    var pace: PrayerPace {
        didSet { UserDefaults.standard.set(pace.rawValue, forKey: Keys.pace) }
    }

    var guidanceLevel: GuidanceLevel {
        didSet { UserDefaults.standard.set(guidanceLevel.rawValue, forKey: Keys.guidance) }
    }

    private init() {
        let defaults = UserDefaults.standard
        language     = Language(rawValue:      defaults.string(forKey: Keys.language) ?? "") ?? .english
        pace         = PrayerPace(rawValue:    defaults.string(forKey: Keys.pace)     ?? "") ?? .medium
        guidanceLevel = GuidanceLevel(rawValue: defaults.string(forKey: Keys.guidance) ?? "") ?? .full
    }

    private enum Keys {
        static let language = "selectedPrayerLanguage"
        static let pace     = "selectedPrayerPace"
        static let guidance = "selectedGuidanceLevel"
    }
}
