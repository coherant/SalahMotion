import SwiftUI

struct PositionOrbView: View {
    let arabicText: String
    let prayerTime: PrayerTime

    @State private var isPulsing = false

    private var glow: Color { prayerTime.theme.orbGlow }

    var body: some View {
        ZStack {
            // Outermost dashed decorative ring
            Circle()
                .strokeBorder(
                    glow.opacity(0.12),
                    style: StrokeStyle(lineWidth: 0.8, dash: [3, 6])
                )
                .frame(width: 240, height: 240)

            // Outer faint ring
            Circle()
                .strokeBorder(glow.opacity(0.18), lineWidth: 0.8)
                .frame(width: 214, height: 214)

            // Animated glow layer (breathing pulse)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [glow.opacity(0.55), glow.opacity(0.50)],
                        center: .center,
                        startRadius: 20,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .scaleEffect(isPulsing ? 1.08 : 1.0)
                .opacity(isPulsing ? 0.35 : 0.65)
                .animation(
                    .easeInOut(duration: 2.5).repeatForever(autoreverses: true),
                    value: isPulsing
                )

            // Main orb body
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            glow.opacity(0.92),
                            glow.opacity(0.50),
                            glow.opacity(0.08),
                        ],
                        center: .center,
                        startRadius: 8,
                        endRadius: 88
                    )
                )
                .frame(width: 176, height: 176)

            // Crescent moon highlight — offset light source gives the moon-like face
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.8), .clear],
                        center: UnitPoint(x: 0.5, y: 0.5),
                        startRadius: 0,
                        endRadius: 90
                    )
                )
                .frame(width: 176, height: 176)

            // Arabic position text
            Text(arabicText)
                .font(.system(size: 30, weight: .regular))
                .foregroundStyle(.black.opacity(0.8))
        }
        .onAppear { isPulsing = true }
    }
}

#Preview("Fajr")    { OrbPreview(prayerTime: .fajr) }
#Preview("Dhuhr")   { OrbPreview(prayerTime: .dhuhr) }
#Preview("Asr")     { OrbPreview(prayerTime: .asr) }
#Preview("Maghrib") { OrbPreview(prayerTime: .maghrib) }
#Preview("Isha")    { OrbPreview(prayerTime: .isha) }

private struct OrbPreview: View {
    let prayerTime: PrayerTime
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [prayerTime.theme.gradientTop, prayerTime.theme.gradientBottom],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
            PositionOrbView(arabicText: "سُجُود", prayerTime: prayerTime)
        }
    }
}
