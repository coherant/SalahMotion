import SwiftUI

@main
struct PrayerMotionSpikeApp: App {
    @State private var router = Router()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(router)
        }
    }
}
