import SwiftUI

struct PrayerSessionScreen: View {
    let prayerTime: PrayerTime

    @State private var isSilenced = true

    // Static sample data — not wired to PrayerStateMachine yet
    private let samplePositions: [TrackerPosition] = [
        TrackerPosition(id: 0, transliteration: "Qiyām", arabic: "قِيَام"),
        TrackerPosition(id: 1, transliteration: "Rukū'", arabic: "رُكُوع"),
        TrackerPosition(id: 2, transliteration: "Sujūd", arabic: "سُجُود"),
    ]

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    prayerTime.theme.gradientTop,
                    prayerTime.theme.gradientBottom,
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                PrayerSessionHeaderView(
                    isSilenced: $isSilenced,
                    currentRakat: 2,
                    totalRakat: 4,
                    prayerTime: prayerTime
                )

                Spacer()

                // Middle: tracker (left) + orb (center-right)
                HStack(alignment: .center, spacing: 0) {
                    PositionTrackerView(
                        positions: samplePositions,
                        prayerTime: prayerTime
                    )
                    .padding(.leading, 24)

                    Spacer()

                    PositionOrbView(
                        arabicText: "سُجُود",
                        prayerTime: prayerTime
                    )
                    .padding(.trailing, 20)
                }

                Spacer()

                // Bottom text block
                PrayerSessionBottomTextView(
                    positionName: "Sujūd",
                    positionMeaning: "Prostration",
                    recitationText: "Subḥāna Rabbiyal-A'lā",
                    instruction: "held · 3 times",
                    prayerTime: prayerTime,
                    onEndPrayer: {}
                )
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Previews (one per prayer time)

#Preview("Fajr")    { PrayerSessionScreen(prayerTime: .fajr) }
#Preview("Dhuhr")   { PrayerSessionScreen(prayerTime: .dhuhr) }
#Preview("Asr")     { PrayerSessionScreen(prayerTime: .asr) }
#Preview("Maghrib") { PrayerSessionScreen(prayerTime: .maghrib) }
#Preview("Isha")    { PrayerSessionScreen(prayerTime: .isha) }
