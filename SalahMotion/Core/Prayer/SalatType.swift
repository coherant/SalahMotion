import Foundation

// MARK: - Prayer unit (one selectable block within a session)
// Source: docs/features/prayer-setup/SPEC.md §4 & §5

struct PrayerUnit: Identifiable {
    enum Kind {
        case fard
        case sunnahBefore(emphasised: Bool)
        case sunnahAfter(emphasised: Bool)
        case witr
    }

    let id: String
    let kind: Kind
    let rakats: Int

    var isObligatory: Bool {
        if case .fard = kind { return true }
        return false
    }

    var displayName: String {
        switch kind {
        case .fard:                       return "Farḍ"
        case .sunnahBefore, .sunnahAfter: return "Sunnah"
        case .witr:                       return "Witr"
        }
    }

    var arabicName: String {
        switch kind {
        case .fard:                       return "فرض"
        case .sunnahBefore, .sunnahAfter: return "سنة"
        case .witr:                       return "وتر"
        }
    }

    var tagText: String {
        switch kind {
        case .fard:
            return "Obligatory"
        case .sunnahBefore(let emph):
            return "Before farḍ · \(emph ? "emphasised" : "optional")"
        case .sunnahAfter(let emph):
            return "After farḍ · \(emph ? "emphasised" : "optional")"
        case .witr:
            return "After ʿIshāʾ · witr"
        }
    }
}

// MARK: - Salat type

enum SalatType: String, CaseIterable, Identifiable {
    case fajr    = "fajr"
    case dhuhr   = "dhuhr"
    case asr     = "asr"
    case maghrib = "maghrib"
    case isha    = "isha"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fajr:    return "Fajr"
        case .dhuhr:   return "Dhuhr"
        case .asr:     return "Asr"
        case .maghrib: return "Maghrib"
        case .isha:    return "Isha"
        }
    }

    // Exact spellings from SPEC.md §6
    var arabicName: String {
        switch self {
        case .fajr:    return "الفجر"
        case .dhuhr:   return "الظهر"
        case .asr:     return "العصر"
        case .maghrib: return "المغرب"
        case .isha:    return "العشاء"
        }
    }

    var periodLabel: String {
        switch self {
        case .fajr:    return "Before sunrise"
        case .dhuhr:   return "Midday"
        case .asr:     return "Afternoon"
        case .maghrib: return "Sunset"
        case .isha:    return "Night"
        }
    }

    var prayerTime: PrayerTime {
        switch self {
        case .fajr:    return .fajr
        case .dhuhr:   return .dhuhr
        case .asr:     return .asr
        case .maghrib: return .maghrib
        case .isha:    return .isha
        }
    }

    // All units for this prayer in display order.
    // Farḍ is always first; sunnah before farḍ appears before it; witr last.
    var units: [PrayerUnit] {
        switch self {
        case .fajr:
            return [
                PrayerUnit(id: "fajr_sb",  kind: .sunnahBefore(emphasised: true),  rakats: 2),
                PrayerUnit(id: "fajr_f",   kind: .fard,                             rakats: 2),
            ]
        case .dhuhr:
            return [
                PrayerUnit(id: "dhuhr_sb", kind: .sunnahBefore(emphasised: true),  rakats: 4),
                PrayerUnit(id: "dhuhr_f",  kind: .fard,                             rakats: 4),
                PrayerUnit(id: "dhuhr_sa", kind: .sunnahAfter(emphasised: true),   rakats: 2),
            ]
        case .asr:
            return [
                PrayerUnit(id: "asr_sb",   kind: .sunnahBefore(emphasised: false), rakats: 4),
                PrayerUnit(id: "asr_f",    kind: .fard,                             rakats: 4),
            ]
        case .maghrib:
            return [
                PrayerUnit(id: "maghrib_f",  kind: .fard,                           rakats: 3),
                PrayerUnit(id: "maghrib_sa", kind: .sunnahAfter(emphasised: true),  rakats: 2),
            ]
        case .isha:
            return [
                PrayerUnit(id: "isha_f",    kind: .fard,                            rakats: 4),
                PrayerUnit(id: "isha_sa",   kind: .sunnahAfter(emphasised: true),   rakats: 2),
                PrayerUnit(id: "isha_witr", kind: .witr,                            rakats: 3),
            ]
        }
    }

    var fardRakats: Int { units.first(where: \.isObligatory)?.rakats ?? 0 }
}

// MARK: - Muezzin

struct Muezzin: Identifiable {
    let id: String
    let latinName: String
    let arabicName: String
    let arabicInitial: String
    let style: String
}

enum Muezzins {
    static let all: [Muezzin] = [
        Muezzin(id: "bilal",  latinName: "Bilāl",  arabicName: "بلال",   arabicInitial: "ب", style: "Madinah cadence · unhurried"),
        Muezzin(id: "idris",  latinName: "Idrīs",  arabicName: "إدريس",  arabicInitial: "إ", style: "Flowing · melodic"),
        Muezzin(id: "sadiq",  latinName: "Ṣādiq",  arabicName: "صادق",   arabicInitial: "ص", style: "Spacious · minimal"),
        Muezzin(id: "yunus",  latinName: "Yūnus",  arabicName: "يونس",   arabicInitial: "ي", style: "Bright · resonant"),
    ]
    static let defaultID = "bilal"
}
