import SwiftUI

// MARK: - AuroraView
//
// A view-only ambient layer: soft aurora curtains that occasionally grace the
// night sky (and the egg's 4th stage). Rendered by the `Aurora.metal` shader via
// `colorEffect`, faded by a smoothed `intensity` from a reference-type model (same
// discipline as the birds/meteors). Spec: docs/features/prayer-times/aurora.md.

enum AuroraConfig {
    /// Master flag — `false` short-circuits to nothing.
    static let isEnabled = true

    /// TEMP (tuning): force the aurora fully on, ignoring night + schedule, so the
    /// shader can be dialled on device. Set back to false when done.
    static let forceOn = false

    /// Fade-in/out time constant (s) for the intensity envelope.
    static let fadeTau: Double = 2.5
    /// How often a fresh ambient episode is rolled for (s).
    static let checkGap: ClosedRange<Double> = 90...240
    /// Probability per roll that an episode begins (rare — the egg is the reliable path).
    static let eventChance: Double = 0.04
    /// How long an ambient aurora episode lasts (s).
    static let episodeDuration: ClosedRange<Double> = 45...110
}

// MARK: - AuroraField (reference type)
//
// Owns the rare-episode scheduler + the smoothed intensity. Mutated inside the
// TimelineView (a class, so invisible to SwiftUI; redraw driven by the timeline).

private final class AuroraField {
    private var current: Double = 0
    private var lastDate: Date?
    private var nextCheck: Date = .distantPast
    private var episodeEnd: Date?

    /// Current 0…1 aurora intensity. `forced` (the egg) overrides the rare schedule.
    func intensity(at date: Date, night: Double, forced: Bool) -> Double {
        if AuroraConfig.forceOn { return 1 }      // TEMP tuning bypass
        let dt = min(max(lastDate.map { date.timeIntervalSince($0) } ?? 0, 0), 0.1)
        lastDate = date

        // Roll for a rare ambient episode.
        if episodeEnd == nil, date >= nextCheck {
            nextCheck = date.addingTimeInterval(Double.random(in: AuroraConfig.checkGap))
            if night >= 0.5, Double.random(in: 0...1) < AuroraConfig.eventChance {
                episodeEnd = date.addingTimeInterval(Double.random(in: AuroraConfig.episodeDuration))
            }
        }
        if let end = episodeEnd, date >= end { episodeEnd = nil }

        // Smoothly chase the target (full while forced or mid-episode, gated by night).
        let target = (forced || episodeEnd != nil) ? min(1, night) : 0
        let k = 1 - exp(-dt / AuroraConfig.fadeTau)
        current += (target - current) * k
        return current
    }
}

// MARK: - AuroraView

struct AuroraView: View {
    /// Tick only while foreground & on this tab.
    var isActive: Bool
    /// 0…1 darkness; the aurora only shows after dark.
    var night: Double
    /// Egg stage 4: forces a full-intensity aurora on demand.
    var forced: Bool

    @State private var field = AuroraField()

    var body: some View {
        if AuroraConfig.isEnabled {
            GeometryReader { geo in
                TimelineView(.animation(paused: !isActive)) { timeline in
                    let intensity = field.intensity(at: timeline.date, night: night, forced: forced)
                    // Reduced time so Float keeps precision in the shader (wraps ~2.7h).
                    let t = timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 10_000)

                    if intensity > 0.002 {
                        Rectangle()
                            .colorEffect(ShaderLibrary.aurora(
                                .float2(geo.size),
                                .float(Float(t)),
                                .float(Float(intensity))))
                            .blendMode(.screen)
                    } else {
                        Color.clear
                    }
                }
            }
            .allowsHitTesting(false)
        }
    }
}
