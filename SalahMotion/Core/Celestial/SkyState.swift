import Foundation

// MARK: - SkyState
//
// A body's renderable state at one instant — the boundary value the view binds
// to. Note what's absent: no CGPoint, no colours, no SwiftUI. The view maps
// `dayPhase` to a point via `CelestialArcGeometry` using its measured size; the
// domain never knows the card's dimensions.

struct SkyState: Equatable {

    /// Position along the daily arc in [0,1): 0 = rising at the left corner,
    /// 0.25 = transit (peak), 0.5 = setting at the right corner, 0.75 = nadir.
    let dayPhase: Double

    /// Real above-horizon state from the provider. Consistent with the geometry
    /// by construction (above ⟺ dayPhase ∈ [0,0.5)). The card's clip is the
    /// authority for *visibility*; this is for logic (e.g. labels).
    let isAboveHorizon: Bool

    /// Populated for the Moon only; `nil` for the Sun.
    let moonPhase: MoonPhase?
}

// MARK: - SkyFrame

/// Both bodies' states for a single instant.
struct SkyFrame: Equatable {
    let sun: SkyState
    let moon: SkyState

    func state(for body: CelestialBody) -> SkyState {
        switch body {
        case .sun:  return sun
        case .moon: return moon
        }
    }
}
