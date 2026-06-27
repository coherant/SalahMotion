import CoreGraphics
import Foundation

// MARK: - CelestialArcGeometry
//
// The pure §2 ellipse projection: maps a daily-arc phase [0,1) to a point inside
// a given size. CoreGraphics only (no SwiftUI) — available on watchOS — and a
// pure function, so it's the one piece worth unit-testing.
//
// The ellipse's diameter is the size's bottom edge (the horizon). At the peak the
// disc's TOP sits `topGap` below the top edge (the locked ≈5 mm spec):
//     Ry = height − bodyRadius − topGap.

struct CelestialArcGeometry: Equatable {

    /// Gap from the size's top edge to the top of the disc at the arc's peak.
    /// ≈5 mm ≈ 30 pt (iOS ≈ 0.156 mm/pt); tune on device.
    var topGap: CGFloat = 30
    var bodyRadius: CGFloat = 13
    /// Pulls the rise/set points in from the corners if needed (0 = corner-to-corner).
    var horizontalInset: CGFloat = 0

    /// θ = π − 2π·t  →  t=0 left corner, .25 peak, .5 right corner, .75 nadir.
    func angle(forDayPhase t: Double) -> Double { .pi - 2 * .pi * t }

    func point(forDayPhase t: Double, in size: CGSize) -> CGPoint {
        let theta = angle(forDayPhase: t)
        let rx = size.width / 2 - horizontalInset
        let ry = size.height - bodyRadius - topGap
        let x = size.width / 2 + rx * CGFloat(cos(theta))
        let y = size.height - ry * CGFloat(sin(theta))
        return CGPoint(x: x, y: y)
    }

    /// Geometric horizon test. Agrees with `SkyState.isAboveHorizon` by
    /// construction; the card's clip is the authority for actual visibility.
    /// Uses an epsilon so the two horizon crossings (phase 0 and 0.5) both read
    /// as on-the-horizon — without it, `sin(π) ≈ 1.2e-16 > 0` makes phase 0
    /// asymmetric with phase 0.5 (`sin 0 == 0`).
    func isAboveHorizon(forDayPhase t: Double) -> Bool {
        sin(angle(forDayPhase: t)) > 1e-9
    }
}
