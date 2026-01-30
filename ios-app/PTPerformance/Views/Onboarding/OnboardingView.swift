import SwiftUI

/// Main onboarding view with page navigation
struct OnboardingView: View {
    @ObservedObject private var coordinator = OnboardingCoordinator.shared
    @State private var currentPage = 0
    @Environment(\.dismiss) private var dismiss

    private let totalPages = 5

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(.systemBackground), Color(.systemGray6)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < totalPages - 1 {
                        Button(action: handleSkip) {
                            Text("Skip")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.blue)
                                .padding()
                        }
                    }
                }
                .frame(height: 60)

                // Page content
                TabView(selection: $currentPage) {
                    // Page 1: Welcome
                    OnboardingPage(
                        icon: "figure.wave",
                        title: "Welcome to PT Performance",
                        description: "The complete platform for physical therapy program management and patient progress tracking.",
                        accentColor: .blue
                    )
                    .tag(0)

                    // Page 2: For Therapists
                    OnboardingPage(
                        icon: "list.clipboard",
                        title: "For Therapists",
                        description: "Create custom exercise programs, track patient compliance, and monitor progress in real-time.",
                        accentColor: .green
                    )
                    .tag(1)

                    // Page 3: For Patients
                    OnboardingPage(
                        icon: "figure.strengthtraining.traditional",
                        title: "For Patients",
                        description: "Log your workouts, track your sets and reps, and watch your progress improve over time.",
                        accentColor: .orange
                    )
                    .tag(2)

                    // Page 4: Analyze Progress
                    OnboardingPage(
                        icon: "chart.bar.fill",
                        title: "Analyze Progress",
                        description: "View detailed analytics, track personal records, and monitor compliance trends with powerful visualizations.",
                        accentColor: .purple
                    )
                    .tag(3)

                    // Page 5: Get Started
                    OnboardingPage(
                        icon: "checkmark.circle.fill",
                        title: "Get Started",
                        description: "You're all set! Log in to access your personalized dashboard and begin your PT journey.",
                        accentColor: .indigo
                    )
                    .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                // Bottom button area
                if currentPage == totalPages - 1 {
                    Button(action: handleGetStarted) {
                        Text("Get Started")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.blue)
                            .cornerRadius(12)
                            .padding(.horizontal, 40)
                    }
                    .padding(.bottom, 40)
                    .transition(.opacity)
                } else {
                    Color.clear
                        .frame(height: 96)
                }
            }
        }
        .onAppear {
            logOnboardingStart()
        }
    }

    // MARK: - Actions

    private func handleSkip() {
        ErrorLogger.shared.logUserAction(
            action: "onboarding_skipped",
            properties: ["current_page": currentPage]
        )
        coordinator.skipOnboarding()
        dismiss()
    }

    private func handleGetStarted() {
        ErrorLogger.shared.logUserAction(
            action: "onboarding_completed",
            properties: ["pages_viewed": totalPages]
        )
        coordinator.completeOnboarding()
        dismiss()
    }

    private func logOnboardingStart() {
        ErrorLogger.shared.logUserAction(
            action: "onboarding_started",
            properties: [:]
        )
    }
}

// MARK: - Preview

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
