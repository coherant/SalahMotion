import Foundation

enum GuidanceLevel: String, CaseIterable, Identifiable {
    case full   = "full"
    case prayer = "prayer"
    case silent = "silent"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .full:   return "Full guidance"
        case .prayer: return "Prayer only"
        case .silent: return "Silent guiding"
        }
    }

    var subtitle: String {
        switch self {
        case .full:   return "Instructions + prayers"
        case .prayer: return "Recitation, no cues"
        case .silent: return "Gentle motion only"
        }
    }

    /// Whether the reprompt countdown pie should be shown
    var showsTimer: Bool { self != .silent }

    /// Whether entry speech (movement instructions) plays
    var playsEntryGuidance: Bool { self == .full }

    /// Whether prayer utterances play
    var playsPrayers: Bool { self != .silent }
}
