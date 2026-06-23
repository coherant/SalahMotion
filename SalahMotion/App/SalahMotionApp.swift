import SwiftUI

@main
struct SalahMotionApp: App {
    @State private var router = Router()

    init() {
        FontRegistrar.registerAll()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(router)
                .environment(UserPreferences.shared)
        }
    }
}
