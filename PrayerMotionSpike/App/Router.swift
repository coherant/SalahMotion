import SwiftUI

enum Route: Hashable {
    case home
    case prayerSession
    case settings
    case qiblaCompass
    case onboarding
}

@Observable
final class Router {
    var path = NavigationPath()

    func push(_ route: Route) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path = NavigationPath()
    }
}
