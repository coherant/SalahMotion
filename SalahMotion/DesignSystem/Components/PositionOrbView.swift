import SwiftUI

struct PositionOrbView: View {
    let arabicText: String
    let prayerTime: PrayerTime
    /// Drives the MoonPhaseShape: 0.0 = new, 0.25 = crescent, 0.5 = full,
    /// 0.75 = waning gibbous, 1.0 = new again.
    var currentPhase: Double = 0.5

    @State private var isPulsing = false
    @State private var moonStartDate = Date()

    private var theme: PrayerTimeTheme { prayerTime.theme }

    private func moonPhase(at date: Date) -> Double {
        let elapsed = date.timeIntervalSince(moonStartDate)
        return (elapsed / 240.0).truncatingRemainder(dividingBy: 1.0)
    }

    var body: some View {
        ZStack {
            // ── Layer 5 (back): Haze / radial glow ──
            Circle()
                .fill(
                    RadialGradient(
                        colors: [theme.orbB.opacity(0.95), theme.orbB.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 120
                    )
                )
                .frame(width: 260, height: 260)
                .scaleEffect(isPulsing ? 1.12 : 1.0)
                .opacity(isPulsing ? 0.9 : 0.6)
                .animation(
                    .easeInOut(duration: 10.0).repeatForever(autoreverses: true),
                    value: isPulsing
                )

            // ── Layer 4: Outer thin ring ──
            Circle()
                .stroke(theme.orbB.opacity(0.1), lineWidth: 1)
                .frame(width: 350, height: 250)

            // ── Layer 3: Dashed decorative ring ──
            Circle()
                .stroke(theme.orbB.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .frame(width: 180, height: 180)

            // ── Layers 2b & 2: Moon disc ──
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                let phase = moonPhase(at: context.date)
                ZStack {
                    // Layer 2b — dark-side disc in screen background colours
                    Circle()
                        .fill(
                            LinearGradient(
                                stops: theme.gradientStops,
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    // Layer 2 — lit crescent using orbA → orbB gradient
                    MoonPhaseShape(phase: phase)
                        .fill(
                            LinearGradient(
                                colors: [theme.orbA, theme.orbB],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .frame(width: 140, height: 140)
            }

            // ── Layer 1 (front): Arabic text ──
            Text(arabicText)
                .font(Typography.arabicOrb)
                .environment(\.layoutDirection, .rightToLeft)
                .foregroundColor(theme.orbInk)
                .multilineTextAlignment(.center)
        }
        .onAppear { isPulsing = true }
    }
}

// MARK: - Previews
// Each preview uses a different phase so all moon shapes are visible in the canvas.

#Preview("Fajr · waxing crescent")    { OrbPreview(prayerTime: .fajr,    phase: 0.10) }
#Preview("Dhuhr · first quarter")     { OrbPreview(prayerTime: .dhuhr,   phase: 0.25) }
#Preview("Asr · full moon")           { OrbPreview(prayerTime: .asr,     phase: 0.50) }
#Preview("Maghrib · waning gibbous")  { OrbPreview(prayerTime: .maghrib, phase: 0.65) }
#Preview("Isha · waning crescent")    { OrbPreview(prayerTime: .isha,    phase: 0.85) }

#Preview("Phase cycle") {
    PhaseCyclePreview()
}

private struct OrbPreview: View {
    let prayerTime: PrayerTime
    let phase: Double
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [prayerTime.theme.gradientTop, prayerTime.theme.gradientBottom],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
            PositionOrbView(arabicText: "سُجُود", prayerTime: prayerTime, currentPhase: phase)
        }
    }
}

private struct PhaseCyclePreview: View {
    @State private var phase: Double = 0.25
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [PrayerTime.isha.theme.gradientTop, PrayerTime.isha.theme.gradientBottom],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
            VStack(spacing: 32) {
                PositionOrbView(arabicText: "سُجُود", prayerTime: .isha, currentPhase: phase)
                Text(String(format: "phase: %.2f", phase))
                    .foregroundStyle(.white.opacity(0.6))
                    .font(.system(size: 12, weight: .medium).monospacedDigit())
                Slider(value: $phase, in: 0...1)
                    .padding(.horizontal, 48)
                    .tint(PrayerTime.isha.theme.accent)
            }
        }
    }
}
