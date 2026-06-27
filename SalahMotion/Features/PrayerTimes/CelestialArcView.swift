import SwiftUI

// MARK: - CelestialArcView
//
// The thin SwiftUI consumer of the Core/Celestial domain. It owns only timing
// (TimelineView) and measurement (GeometryReader); all astronomy/geometry comes
// from the platform-agnostic facade, so a watchOS view could differ here alone.
//
// It deliberately applies NO clip of its own — the Up Next card is the single
// clip authority (see docs/features/prayer-times/celestial-complications.md §3).
// All glow/shadow is composed here, INSIDE that clip, so nothing bleeds past the
// card edge.

struct CelestialArcView: View {
    let sky: CelestialSky
    var geometry = CelestialArcGeometry()
    /// Gate: tick only while the screen is foreground & active. Paused, the view
    /// holds the last correct frame and snaps to `now` on resume (position is a
    /// pure function of time, so there is no state to restore).
    var isActive: Bool

    var body: some View {
        GeometryReader { proxy in
            if let interval = sky.refreshInterval {
                // Realtime: bodies barely move — a coarse tick avoids recomputing
                // the ephemeris (incl. SwiftAA) every frame.
                TimelineView(.periodic(from: .now, by: interval)) { timeline in
                    arc(in: proxy.size, at: timeline.date)
                }
            } else {
                // Demo: smooth animation, paused while the screen isn't active.
                TimelineView(.animation(paused: !isActive)) { timeline in
                    arc(in: proxy.size, at: timeline.date)
                }
            }
        }
    }

    private func arc(in size: CGSize, at date: Date) -> some View {
        let frame = sky.frame(atWallClock: date)
        return ZStack {
            bodyView(.moon, state: frame.moon, in: size)
            bodyView(.sun, state: frame.sun, in: size)
        }
    }

    /// Positioning geometry with the arc-direction mirror applied for the
    /// observer's hemisphere (separate from the Moon's bright-limb mirror below).
    private var arcGeometry: CelestialArcGeometry {
        var g = geometry
        g.isNorthernHemisphere = sky.location.isNorthernHemisphere
        return g
    }

    @ViewBuilder
    private func bodyView(_ body: CelestialBody, state: SkyState, in size: CGSize) -> some View {
        let radius = arcGeometry.bodyRadius
        let point = arcGeometry.point(forDayPhase: state.dayPhase, in: size)
        Group {
            switch body {
            case .sun:
                Circle()
                    .fill(RadialGradient(
                        colors: [.white, Color(hex: "#FFD27A"), Color(hex: "#FFA82E")],
                        center: .center, startRadius: 0, endRadius: radius))
                    .shadow(color: Color(hex: "#FFB23E").opacity(0.85), radius: radius * 0.8)
            case .moon:
                MoonPhaseShape(phase: state.moonPhase?.phase ?? 0.5)
                    .fill(Color(hex: "#E8ECF2"))
                    // Southern-hemisphere mirror: the lit limb flips below the equator.
                    .scaleEffect(x: sky.location.isNorthernHemisphere ? 1 : -1)
                    .shadow(color: Color(hex: "#C9D4E6").opacity(0.5), radius: radius * 0.5)
            }
        }
        .frame(width: radius * 2, height: radius * 2)
        .position(point)
    }
}
