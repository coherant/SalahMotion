import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ReactivePrayerView()
                .tabItem { Label("Guided", systemImage: "moon.stars.fill") }
            CalibrationView()
                .tabItem { Label("Calibration", systemImage: "person.crop.circle.badge.checkmark") }
            GuidedRecordingView()
                .tabItem { Label("Global Calibration", systemImage: "figure.stand") }
        }
    }
}

#Preview {
    ContentView()
}
