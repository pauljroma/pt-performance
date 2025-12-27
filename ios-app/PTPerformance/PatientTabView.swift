import SwiftUI

struct PatientTabView: View {
    @StateObject private var onboardingCoordinator = OnboardingCoordinator.shared

    var body: some View {
        TabView {
            TodaySessionView()
                .tabItem {
                    Label("Today", systemImage: "list.bullet")
                }

            PatientHistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }

            // ProgressChartsView() - Disabled (missing dependencies)
            Text("Analytics Coming Soon")
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar.fill")
                }

            PatientSettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}

// MARK: - Patient Settings View

struct PatientSettingsView: View {
    @StateObject private var onboardingCoordinator = OnboardingCoordinator.shared

    var body: some View {
        NavigationStack {
            List {
                Section("Help & Support") {
                    Button {
                        onboardingCoordinator.resetOnboarding()
                    } label: {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.blue)
                            Text("View Tutorial")
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
