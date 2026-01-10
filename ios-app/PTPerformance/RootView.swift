import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var onboardingCoordinator = OnboardingCoordinator.shared
    @AppStorage("hasAcceptedPrivacyNotice") private var hasAcceptedPrivacyNotice = false
    @State private var showPrivacyNotice = false

    var body: some View {
        Group {
            if !appState.isAuthenticated {
                AuthView()
            } else {
                // Show privacy notice if not accepted (HIPAA requirement)
                if !hasAcceptedPrivacyNotice {
                    PrivacyNoticeView(onAccept: {
                        hasAcceptedPrivacyNotice = true
                        showPrivacyNotice = false
                    })
                } else if appState.userRole == .patient {
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
