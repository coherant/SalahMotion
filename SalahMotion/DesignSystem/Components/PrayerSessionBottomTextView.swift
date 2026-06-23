import SwiftUI

struct PrayerSessionBottomTextView: View {
    let positionName: String
    let positionMeaning: String
    let recitationText: String
    let instruction: String
    let prayerTime: PrayerTime
    let onEndPrayer: () -> Void

    private var theme: PrayerTimeTheme { prayerTime.theme }

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

            Text(recitationText)
                .font(Typography.recitation)
                .italic()
                .foregroundStyle(theme.ink.opacity(0.65))

            Spacer().frame(height: 6)

            Text(instruction)
                .font(Typography.labelSm)
                .foregroundStyle(theme.ink.opacity(0.38))
                .tracking(0.4)

            Spacer().frame(height: 24)

            Button(action: onEndPrayer) {
                Text("END PRAYER")
                    .eyebrowStyle()
                    .foregroundStyle(theme.accent)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .strokeBorder(theme.accent.opacity(0.5), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
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
            PrayerSessionBottomTextView(
                positionName: "Sujood",
                positionMeaning: "Prostration",
                recitationText: "Glory be to Allah the most high",
                instruction: "awaiting motion",
                prayerTime: prayerTime,
                onEndPrayer: {}
            )
            .padding(.bottom, 40)
        }
    }
}
