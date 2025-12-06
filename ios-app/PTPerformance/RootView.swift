import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if !appState.isAuthenticated {
                AuthView()
            } else {
                if appState.userRole == .patient {
                    PatientTabView()
                } else if appState.userRole == .therapist {
                    TherapistTabView()
                } else {
                    Text("Determining role...")
                }
            }
        }
    }
}
