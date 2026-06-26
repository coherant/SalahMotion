import Foundation

// MARK: - Call ID
// The Muezzin's content namespace (the congregational container). Parallel to PrayerID
// (in-salah, P-) and InstructionID (guidance, I-). Binding policy: a Muezzin voice/recording
// binds ONLY to a C- id, never a P-id — the fiqh boundary, enforced by the type system.
// See docs/guided/CONGREGATIONAL-CONTAINER.md §A and docs/prayers/calls.md.

enum CallID: String {
    case c1  = "C-1"    // Adhān
    case c1F = "C-1F"   // Adhān (Fajr — carries aṣ-ṣalātu khayrun mina-n-nawm)
    case c2  = "C-2"    // Iqāma
    case c3  = "C-3"    // Boundary du'ā (= P-23, re-voiced post-salām)
    case c4  = "C-4"    // Istighfār ×3
    case c5  = "C-5"    // Āyat al-Kursī
    case c6  = "C-6"    // Tasbīḥ ×33
    case c7  = "C-7"    // Taḥmīd ×33
    case c8  = "C-8"    // Takbīr ×33
    case c9  = "C-9"    // Tahlīl (completes 100)
    case c10 = "C-10"   // Ṣalawāt
    case c11 = "C-11"   // Closing du'ā
}

// The Muezzin act each call performs — drives container placement (see the generator)
// and, later, the listen/count phase choice.
enum CallShape: String, Decodable {
    case call       // adhān / iqāma — listen, auto-paced
    case boundary   // post-salām du'ā after the farḍ
    case dhikr      // post-salah remembrance (some counted)
    case closing    // closing supplication, seals the session
}

// MARK: - Call Library
// Source of truth: SalahMotion/Resources/calls.json (graduated from CONGREGATIONAL-CONTAINER §A).
// To add or edit a call, update calls.json only — no Swift changes needed.
// To add a new ID, add one case to CallID above and one entry in calls.json.
//
// `verify: true` entries carry Arabic still pending the user's review before voice-binding
// (Stage 3). Nothing here is spoken in Stage 2 — it is content/display data only.

enum CallLibrary {

    struct Entry: Decodable {
        let id: String
        let name: String
        let shape: CallShape
        let count: Int          // 0 = not a counted dhikr; >0 = repeat count (tasbīḥ counter)
        let verify: Bool        // Arabic pending user verification before voicing
        let arabic: String
        let transliteration: String
        let english: String
    }

    private struct Payload: Decodable {
        let calls: [Entry]
    }

    private static let cache: [String: Entry] = {
        guard
            let url  = Bundle.main.url(forResource: "calls", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let payload = try? JSONDecoder().decode(Payload.self, from: data)
        else {
            assertionFailure("calls.json missing or malformed")
            return [:]
        }
        return Dictionary(uniqueKeysWithValues: payload.calls.map { ($0.id, $0) })
    }()

    private static func entry(_ id: CallID) -> Entry? {
        guard let entry = cache[id.rawValue] else {
            assertionFailure("Call \(id.rawValue) not found in calls.json")
            return nil
        }
        return entry
    }

    // The Muezzin voices Arabic; transliteration + meaning are for the follower's display.
    static func arabic(_ id: CallID) -> String          { entry(id)?.arabic ?? "" }
    static func transliteration(_ id: CallID) -> String { entry(id)?.transliteration ?? "" }
    static func meaning(_ id: CallID) -> String         { entry(id)?.english ?? "" }
    static func name(_ id: CallID) -> String            { entry(id)?.name ?? "" }
    static func shape(_ id: CallID) -> CallShape        { entry(id)?.shape ?? .call }
    static func count(_ id: CallID) -> Int              { entry(id)?.count ?? 0 }
}
