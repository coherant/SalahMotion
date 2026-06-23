import SwiftUI

struct AudioPulseView: View {
    let isActive: Bool
    let prayerTime: PrayerTime

    // Opacity bounds — tune these to adjust the visual intensity
    var opacityMin: Double = 0.10
    var opacityMax: Double = 0.45

    private var accent: Color { prayerTime.theme.accent }

    @State private var outerOpacity: Double = 0
    @State private var pulseTask: Task<Void, Never>?

    var body: some View {
        // Solid red core — layout anchor, matches pie chart size exactly
        Circle()
            .fill(accent)
            .frame(width: 16, height: 16)
            .opacity(isActive ? 1 : 0)
            .animation(.easeOut(duration: 0.2), value: isActive)
            .overlay(
                // Outer pulsing ring — extends beyond core without affecting layout
                Circle()
                    .fill(accent.opacity(outerOpacity))
                    .frame(width: 32, height: 32)
                    .animation(.easeOut(duration: 0.08), value: outerOpacity)
            )
        .onAppear   { if isActive { startPulsing() } }
        .onChange(of: isActive) { if isActive { startPulsing() } else { stopPulsing() } }
        .onDisappear { stopPulsing() }
    }

    private func startPulsing() {
        pulseTask?.cancel()
        pulseTask = Task { @MainActor in
            while !Task.isCancelled {
                outerOpacity = Double.random(in: opacityMin...opacityMax)
                try? await Task.sleep(for: .milliseconds(50))
            }
        }
    }

    private func stopPulsing() {
        pulseTask?.cancel()
        pulseTask = nil
        withAnimation(.easeOut(duration: 0.3)) {
            outerOpacity = 0
        }
    }
}

// MARK: - Previews

#Preview("Active") {
    ZStack {
        LinearGradient(colors: [PrayerTime.isha.theme.gradientTop, PrayerTime.isha.theme.gradientBottom], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
        AudioPulseView(isActive: true, prayerTime: .isha)
    }
}

#Preview("Inactive") {
    ZStack {
        LinearGradient(colors: [PrayerTime.isha.theme.gradientTop, PrayerTime.isha.theme.gradientBottom], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
        AudioPulseView(isActive: false, prayerTime: .isha)
    }
}

#Preview("Toggle") {
    AudioPulseTogglePreview()
}

private struct AudioPulseTogglePreview: View {
    @State private var isActive = false
    var body: some View {
        ZStack {
            LinearGradient(colors: [PrayerTime.isha.theme.gradientTop, PrayerTime.isha.theme.gradientBottom], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            VStack(spacing: 32) {
                AudioPulseView(isActive: isActive, prayerTime: .isha)
                Button(isActive ? "Stop" : "Speak") {
                    isActive.toggle()
                }
                .buttonStyle(.borderedProminent)
                .tint(isActive ? .red : .blue)
            }
        }
    }
}
