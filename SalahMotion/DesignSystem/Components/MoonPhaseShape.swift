import SwiftUI

// MARK: - MoonPhaseShape
//
// Draws geometrically correct moon phases for all phase values using a single
// closed Path. No blend modes — the illuminated region is constructed directly
// from two half-ellipse arcs built with cubic beziers.
//
// Algorithm:
//   The boundary of the lit region is formed by two arcs sharing the same
//   top/bottom endpoints (the poles of the moon circle):
//
//   1. Outer limb  — always a full semicircle on the lit side (right for waxing,
//                    left for waning). x-radius = ±R.
//
//   2. Terminator  — a half-ellipse that travels back from bottom to top.
//                    Its x-radius scales with the illuminated fraction f:
//                      aTerm = R * (1 − 2f)   for waxing
//                      aTerm = R * (2f − 1)   for waning
//                    At f=0 (new): terminator = same semicircle as limb → zero area
//                    At f=0.5 (quarter): aTerm=0 → straight vertical line → half circle
//                    At f=1 (full): terminator = opposite semicircle → full circle
//
//   The bezier control-point constant κ ≈ 0.5523 approximates a quarter-ellipse
//   with <0.04% geometric error.

struct MoonPhaseShape: Shape {
    /// 0.0 = new moon · 0.25 = waxing crescent · 0.5 = full moon
    /// 0.75 = waning gibbous · 1.0 = new moon again
    var phase: Double

    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let cx   = rect.midX
        let cy   = rect.midY
        let R    = min(rect.width, rect.height) / 2
        let κ: CGFloat = 0.5523

        let waxing = phase <= 0.5
        let f: Double       // illuminated fraction: 0 = new, 1 = full
        let aLimb: CGFloat  // outer limb x-radius (+R = right, -R = left)
        let aTerm: CGFloat  // terminator x-radius (bottom → top)

        if waxing {
            f     = 2.0 * phase
            aLimb = R
            aTerm = CGFloat(R * (1.0 - 2.0 * f))
        } else {
            f     = 2.0 * (1.0 - phase)
            aLimb = -R
            aTerm = CGFloat(R * (2.0 * f - 1.0))
        }

        var p = Path()
        p.move(to: CGPoint(x: cx, y: cy - R))

        // ── Outer limb: top → bottom (one half-ellipse, x-radius = aLimb) ──
        p.addCurve(
            to:       CGPoint(x: cx + aLimb,     y: cy),
            control1: CGPoint(x: cx + aLimb * κ, y: cy - R),
            control2: CGPoint(x: cx + aLimb,     y: cy - R * κ)
        )
        p.addCurve(
            to:       CGPoint(x: cx,              y: cy + R),
            control1: CGPoint(x: cx + aLimb,     y: cy + R * κ),
            control2: CGPoint(x: cx + aLimb * κ, y: cy + R)
        )

        // ── Terminator: bottom → top (half-ellipse, x-radius = aTerm) ──
        p.addCurve(
            to:       CGPoint(x: cx + aTerm,     y: cy),
            control1: CGPoint(x: cx + aTerm * κ, y: cy + R),
            control2: CGPoint(x: cx + aTerm,     y: cy + R * κ)
        )
        p.addCurve(
            to:       CGPoint(x: cx,              y: cy - R),
            control1: CGPoint(x: cx + aTerm,     y: cy - R * κ),
            control2: CGPoint(x: cx + aTerm * κ, y: cy - R)
        )

        p.closeSubpath()
        return p
    }
}

// MARK: - Previews

#Preview("Phase cycle — scrubber") {
    PhaseScrubberPreview()
}

private struct PhaseScrubberPreview: View {
    @State private var phase: Double = 0.25
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 32) {
                MoonPhaseShape(phase: phase)
                    .fill(.white.opacity(0.9))
                    .frame(width: 160, height: 160)
                    .animation(.easeInOut(duration: 0.3), value: phase)
                Text(phaseLabel)
                    .foregroundStyle(.white.opacity(0.7))
                    .font(.system(size: 13, weight: .medium))
                    .monospacedDigit()
                Slider(value: $phase, in: 0...1)
                    .padding(.horizontal, 40)
                    .tint(.white)
            }
        }
    }

    private var phaseLabel: String {
        switch phase {
        case 0.0..<0.05, 0.95...1.0: return String(format: "New moon (%.2f)", phase)
        case 0.05..<0.2:             return String(format: "Waxing crescent (%.2f)", phase)
        case 0.2..<0.3:              return String(format: "First quarter (%.2f)", phase)
        case 0.3..<0.45:             return String(format: "Waxing gibbous (%.2f)", phase)
        case 0.45..<0.55:            return String(format: "Full moon (%.2f)", phase)
        case 0.55..<0.7:             return String(format: "Waning gibbous (%.2f)", phase)
        case 0.7..<0.8:              return String(format: "Last quarter (%.2f)", phase)
        default:                     return String(format: "Waning crescent (%.2f)", phase)
        }
    }
}
