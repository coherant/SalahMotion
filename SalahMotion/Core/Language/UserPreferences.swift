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

    var salatType: SalatType {
        didSet { UserDefaults.standard.set(salatType.rawValue, forKey: Keys.salatType) }
    }

    /// IDs of toggled sunnah/witr units (farḍ is always included, never stored here)
    var selectedUnitIds: Set<String> {
        didSet {
            let arr = Array(selectedUnitIds)
            UserDefaults.standard.set(arr, forKey: Keys.unitIds)
        }
    }

    var muezzinId: String {
        didSet { UserDefaults.standard.set(muezzinId, forKey: Keys.muezzin) }
    }

    /// When on, the Muezzin's congregational frame (iqāma · boundary du'ā · dhikr seal)
    /// wraps each guided prayer. Default off — the frame is silent until Stage 3 voice
    /// binding, so it stays opt-in until then. See CONGREGATIONAL-CONTAINER.md §4.
    var muezzinEnabled: Bool {
        didSet { UserDefaults.standard.set(muezzinEnabled, forKey: Keys.muezzinEnabled) }
    }

    private init() {
        let defaults = UserDefaults.standard
        language         = Language(rawValue:      defaults.string(forKey: Keys.language)  ?? "") ?? .english
        pace             = PrayerPace(rawValue:    defaults.string(forKey: Keys.pace)      ?? "") ?? .medium
        guidanceLevel    = GuidanceLevel(rawValue: defaults.string(forKey: Keys.guidance)  ?? "") ?? .full
        salatType        = SalatType(rawValue:     defaults.string(forKey: Keys.salatType) ?? "") ?? .maghrib
        selectedUnitIds  = Set(defaults.stringArray(forKey: Keys.unitIds) ?? [])
        muezzinId        = defaults.string(forKey: Keys.muezzin) ?? Muezzins.defaultID
        muezzinEnabled   = defaults.object(forKey: Keys.muezzinEnabled) as? Bool ?? false
    }

    private enum Keys {
        static let language  = "selectedPrayerLanguage"
        static let pace      = "selectedPrayerPace"
        static let guidance  = "selectedGuidanceLevel"
        static let salatType = "selectedSalatType"
        static let unitIds   = "selectedUnitIds"
        static let muezzin   = "selectedMuezzinId"
        static let muezzinEnabled = "muezzinModeEnabled"
    }
}
