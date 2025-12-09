import SwiftUI

@main
struct PTPerformanceApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}

final class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var userRole: UserRole? = nil   // .patient or .therapist
    @Published var userId: String? = nil       // Authenticated user ID
}
