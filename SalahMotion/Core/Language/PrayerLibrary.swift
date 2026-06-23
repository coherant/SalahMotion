import Foundation

// MARK: - Prayer ID

enum PrayerID: String {
    case p0  = "P-0"
    case p1  = "P-1"
    case p2  = "P-2"
    case p3  = "P-3"
    case p4  = "P-4"
    case p5  = "P-5"
    case p6  = "P-6"
    case p7  = "P-7"
    case p8  = "P-8"
    case p9  = "P-9"
    case p10 = "P-10"
    case p11 = "P-11"
    case p12 = "P-12"
    case p13 = "P-13"
    case p14 = "P-14"
    case p15 = "P-15"
    case p16 = "P-16"
    case p17 = "P-17"
    case p18 = "P-18"
    case p19 = "P-19"
    case p20 = "P-20"
    case p21 = "P-21"
    case p22 = "P-22"
}

// MARK: - Prayer Library
// Source of truth: SalahMotion/Resources/prayers.json
// To add or edit a prayer, update prayers.json only — no Swift changes needed.
// To add a new ID, add one case to PrayerID above and one entry in prayers.json.

enum PrayerLibrary {

    private struct Entry: Decodable {
        let id: String
        let name: String
        let arabic: String
        let turkish: String
        let english: String
    }

    private struct Payload: Decodable {
        let prayers: [Entry]
    }

    private static let cache: [String: Entry] = {
        guard
            let url  = Bundle.main.url(forResource: "prayers", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let payload = try? JSONDecoder().decode(Payload.self, from: data)
        else {
            assertionFailure("prayers.json missing or malformed")
            return [:]
        }
        return Dictionary(uniqueKeysWithValues: payload.prayers.map { ($0.id, $0) })
    }()

    static func text(_ id: PrayerID, _ language: Language) -> String {
        guard let entry = cache[id.rawValue] else {
            assertionFailure("Prayer \(id.rawValue) not found in prayers.json")
            return ""
        }
        switch language {
        case .arabic:  return entry.arabic
        case .turkish: return entry.turkish
        case .english: return entry.english
        }
    }
}
