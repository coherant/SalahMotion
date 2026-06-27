import Foundation

// MARK: - MoonPhase
//
// The Moon's phase reduced to a single number: the elongation fraction
// (Moon − Sun ecliptic longitude, normalised to [0,1)). This one value encodes
// BOTH how lit the disc is AND the waxing/waning direction — illuminated fraction
// alone can't (first vs last quarter are both 50% lit), but elongation is
// monotonic through the cycle, so it disambiguates.
//
// Pure value type. Feeds `MoonPhaseShape` (same 0 = new, 0.5 = full convention).

struct MoonPhase: Equatable {

    /// Elongation fraction in [0,1): 0 = new, 0.25 = first quarter,
    /// 0.5 = full, 0.75 = last quarter.
    let phase: Double

    init(phase: Double) {
        self.phase = phase - floor(phase)   // wrap into [0,1)
    }

    init(elongationDegrees degrees: Double) {
        self.init(phase: degrees / 360.0)
    }

    /// Waxing for the first half of the cycle, waning for the second.
    var isWaxing: Bool { phase < 0.5 }

    /// Simplified circular-orbit illuminated fraction (0 = new, 1 = full).
    /// For a precise percentage label, prefer the value SwiftAA returns directly.
    var illuminatedFraction: Double { (1 - cos(2 * .pi * phase)) / 2 }

    enum Name: String {
        case new
        case waxingCrescent, firstQuarter, waxingGibbous
        case full
        case waningGibbous, lastQuarter, waningCrescent
    }

    /// Named phase, with a small tolerance (~half a day) around the four cardinal
    /// points so "First Quarter" etc. read at the moment they actually occur.
    var name: Name {
        let eps = 0.0167   // ~half a day of the synodic cycle
        switch phase {
        case ..<eps, (1 - eps)...:              return .new
        case (0.25 - eps)..<(0.25 + eps):       return .firstQuarter
        case (0.5 - eps)..<(0.5 + eps):         return .full
        case (0.75 - eps)..<(0.75 + eps):       return .lastQuarter
        case ..<0.25:                           return .waxingCrescent
        case ..<0.5:                            return .waxingGibbous
        case ..<0.75:                           return .waningGibbous
        default:                                return .waningCrescent
        }
    }
}
