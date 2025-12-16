import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var onboardingCoordinator = OnboardingCoordinator.shared

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
        .fullScreenCover(isPresented: $onboardingCoordinator.shouldShowOnboarding) {
            OnboardingView()
        }
        .onAppear {
            // Check if we should show onboarding on first launch
            if onboardingCoordinator.isFirstLaunch && appState.isAuthenticated {
                onboardingCoordinator.shouldShowOnboarding = true
            }
        }
    }
}
