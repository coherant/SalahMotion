import SwiftUI

// MARK: - Data

struct TrackerPosition: Identifiable, Equatable {
    let id: Int
    let transliteration: String
    let arabic: String
    /// True for a Muezzin (container) row — rendered distinctly: the spoken
    /// Arabic, tinted in the Muezzin hue, never confused with a posture.
    var isMuezzin: Bool = false
}

// MARK: - Pie progress shape

private struct PieProgress: Shape {
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        guard progress > 0 else { return Path() }
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(-90),
            endAngle: .degrees(-90 + 360 * progress),
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - Tracker view

struct PositionTrackerView: View {
    let positions: [TrackerPosition]
    let prayerTime: PrayerTime
    /// Confirmation progress for the current state: 0.0 → 1.0
    var progress: Double = 0
    /// True while TTS is playing
    var isSpeaking: Bool = false

    private var accent: Color { prayerTime.theme.accent }
    private var ink:    Color { prayerTime.theme.ink    }

    private var visible: [TrackerPosition] {
        Array(positions.suffix(3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 0)
            ForEach(Array(visible.enumerated()), id: \.element.id) { index, position in
                let isActive = index == visible.count - 1
                let isFirst  = index == 0
                let dimness  = isActive ? 1.0 : (index == visible.count - 2 ? 0.45 : 0.25)
                let dotColor = accent

                HStack(alignment: .top, spacing: 10) {
                    // Dot + connecting line column
                    VStack(spacing: 0) {
                        // Line above
                        if !isFirst {
                            Rectangle()
                                .fill(accent.opacity(0.18))
                                .frame(width: 1.5, height: 48)
                        }

                        // Dot
                        ZStack {
                            if isActive {
                                Circle()
                                    .fill(dotColor.opacity(0.28))
                                    .frame(width: 20, height: 20)
                            }
                            Circle()
                                .fill(isActive ? dotColor : dotColor.opacity(0.30))
                                .frame(
                                    width:  isActive ? 9 : 5,
                                    height: isActive ? 9 : 5
                                )
                        }
                        .frame(width: 20, height: 20)

                        // Line below + indicator for the active item
                        if isActive {
                            Rectangle()
                                .fill(Color.white.opacity(0.18))
                                .frame(width: 1.5, height: 20)

                            if isSpeaking {
                                // Audio pulse — shown while TTS is playing.
                                AudioPulseView(
                                    isActive: isSpeaking,
                                    prayerTime: prayerTime
                                )
                            } else {
                                // Pie chart — shown during motion confirmation hold
                                PieProgress(progress: progress)
                                    .fill(accent)
                                    .frame(width: 16, height: 16)
                                    .background(
                                        Circle()
                                            .stroke(accent.opacity(0.25), lineWidth: 1)
                                    )
                                    .animation(.linear(duration: 0.1), value: progress)
                            }
                        } else {
                            Rectangle()
                                .fill(accent.opacity(0.18))
                                .frame(width: 1.5, height: 48)
                        }
                    }

                    // Labels — Arabic right-justified (trailing). Muezzin rows show
                    // only the spoken Arabic, tinted in the Muezzin hue; posture rows
                    // show the position name with its Arabic beneath.
                    VStack(alignment: .trailing, spacing: 2) {
                        if position.isMuezzin {
                            // Spoken Arabic — theme ink.
                            Text(position.arabic)
                                .font(isActive ? Typography.arabicLabel : Typography.arabicCaption)
                                .environment(\.layoutDirection, .rightToLeft)
                                .multilineTextAlignment(.trailing)
                                .lineLimit(2)
                                .truncationMode(.tail)
                                .frame(maxWidth: 200, alignment: .trailing)
                                .foregroundStyle(ink.opacity(isActive ? 0.9 : dimness * 0.65))
                        } else {
                            Text(position.transliteration)
                                .font(isActive ? Typography.bodyDisplay : Typography.captionDisplay)
                                .fontWeight(isActive ? .semibold : .regular)
                                .foregroundStyle(ink.opacity(dimness))
                            Text(position.arabic)
                                .font(isActive ? Typography.arabicLabel : Typography.arabicCaption)
                                .environment(\.layoutDirection, .rightToLeft)
                                .foregroundStyle(ink.opacity(dimness * 0.65))
                        }
                    }
                    .padding(.top, isFirst ? 4 : 54)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal:   .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .animation(.easeOut(duration: 0.45), value: visible.map(\.id))
    }
}

// MARK: - Previews

#Preview("Fajr")    { TrackerPreview(prayerTime: .fajr) }
#Preview("Dhuhr")   { TrackerPreview(prayerTime: .dhuhr) }
#Preview("Asr")     { TrackerPreview(prayerTime: .asr) }
#Preview("Maghrib") { TrackerPreview(prayerTime: .maghrib) }
#Preview("Isha")    { TrackerPreview(prayerTime: .isha) }

#Preview("Progress scrubber") { ProgressPreview() }

private struct TrackerPreview: View {
    let prayerTime: PrayerTime
    private let samplePositions = [
        TrackerPosition(id: 0, transliteration: "Qiyam",  arabic: "قِيَام"),
        TrackerPosition(id: 1, transliteration: "Ruku",   arabic: "رُكُوع"),
        TrackerPosition(id: 2, transliteration: "Sujood", arabic: "سُجُود"),
    ]
    var body: some View {
        ZStack(alignment: .leading) {
            LinearGradient(
                colors: [prayerTime.theme.gradientTop, prayerTime.theme.gradientBottom],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
            PositionTrackerView(positions: samplePositions, prayerTime: prayerTime, progress: 0.65)
                .padding(.leading, 24)
        }
    }
}

private struct ProgressPreview: View {
    @State private var progress: Double = 0
    var body: some View {
        ZStack(alignment: .leading) {
            LinearGradient(
                colors: [PrayerTime.isha.theme.gradientTop, PrayerTime.isha.theme.gradientBottom],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
            VStack(alignment: .leading, spacing: 32) {
                PositionTrackerView(
                    positions: [
                        TrackerPosition(id: 0, transliteration: "Qiyam",  arabic: "قِيَام"),
                        TrackerPosition(id: 1, transliteration: "Ruku",   arabic: "رُكُوع"),
                        TrackerPosition(id: 2, transliteration: "Sujood", arabic: "سُجُود"),
                    ],
                    prayerTime: .isha,
                    progress: progress
                )
                Slider(value: $progress, in: 0...1)
                    .padding(.horizontal, 24)
                    .tint(PrayerTime.isha.theme.accent)
            }
            .padding(.leading, 24)
        }
    }
}
