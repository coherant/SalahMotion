import Foundation

// MARK: - CelestialBody
//
// The two bodies the complication tracks. Platform-agnostic (no SwiftUI), so the
// whole Core/Celestial domain compiles unchanged on watchOS.

enum CelestialBody: String, CaseIterable, Equatable {
    case sun
    case moon
}
