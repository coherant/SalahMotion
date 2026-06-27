import SwiftUI

struct GuidedPrayerBottomTextView: View {
    let positionName: String
    let positionMeaning: String
    let recitationText: String
    let instruction: String
    let prayerTime: PrayerTime
    let onCancel: () -> Void
    let onNavigate: () -> Void

    @State private var cancelled = false
    @State private var pulsing = false

    private var theme: PrayerTimeTheme { prayerTime.theme }
    private var accent: Color { theme.accent }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(positionName)
                    .font(Typography.prayerName)
                    .foregroundStyle(theme.ink)
                Text("· \(positionMeaning)")
                    .font(Typography.prayerNameSub)
                    .foregroundStyle(theme.ink.opacity(0.55))
            }

            Spacer().frame(height: 10)

            // Recitation text intentionally not shown — the experience is sound + recitation
            // in earphones, so we don't pull the user's attention to reading (and a long sūra
            // would push the layout up). The `recitationText` parameter is kept plumbed so it
            // is a one-line restore when wanted.
            Text(instruction)
                .font(Typography.labelSm)
                .foregroundStyle(theme.ink.opacity(0.38))
                .tracking(0.4)

            Spacer().frame(height: 24)

            // END PRAYER / Prayer Cancelled capsule
            Button {
                guard !cancelled else { return }
                cancelled = true
                onCancel()
                Task {
                    try? await Task.sleep(for: .milliseconds(250))
                    pulsing = true
                    try? await Task.sleep(for: .seconds(2))
                    onNavigate()
                }
            } label: {
                Text(cancelled ? "Prayer Cancelled" : "END PRAYER")
                    .eyebrowStyle()
                    .foregroundStyle(accent)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Capsule().strokeBorder(accent.opacity(0.5), lineWidth: 1))
                    .overlay(
                        Capsule()
                            .fill(accent)
                            .scaleEffect(x: pulsing ? 1.12 : 1.0,
                                         y: pulsing ? 1.5  : 1.0)
                            .opacity(pulsing ? 0 : 0.35)
                            .animation(
                                .easeOut(duration: 3.6).repeatForever(autoreverses: false),
                                value: pulsing
                            )
                    )
            }
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.2), value: cancelled)
        }
        .multilineTextAlignment(.center)
    }
}

#Preview("Fajr")    { BottomTextPreview(prayerTime: .fajr) }
#Preview("Dhuhr")   { BottomTextPreview(prayerTime: .dhuhr) }
#Preview("Asr")     { BottomTextPreview(prayerTime: .asr) }
#Preview("Maghrib") { BottomTextPreview(prayerTime: .maghrib) }
#Preview("Isha")    { BottomTextPreview(prayerTime: .isha) }

private struct BottomTextPreview: View {
    let prayerTime: PrayerTime
    var body: some View {
        ZStack(alignment: .bottom) {
            prayerTime.backgroundGradient.ignoresSafeArea()
            GuidedPrayerBottomTextView(
                positionName: "Sujood",
                positionMeaning: "Prostration",
                recitationText: "Glory be to Allah the most high",
                instruction: "awaiting motion",
                prayerTime: prayerTime,
                onCancel: {},
                onNavigate: {}
            )
            .padding(.bottom, 40)
        }
    }
}
